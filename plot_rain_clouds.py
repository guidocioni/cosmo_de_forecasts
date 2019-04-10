debug = False
if not debug:
    import matplotlib
    matplotlib.use('Agg')

import matplotlib.pyplot as plt
import xarray as xr 
import metpy.calc as mpcalc
from metpy.units import units
from glob import glob
import numpy as np
import pandas as pd
from multiprocessing import Pool
from functools import partial
import os 
from utils import *
import sys

# The one employed for the figure name when exported 
variable_name = 'precip_clouds'

print_message('Starting script to plot '+variable_name)

# Get the projection as system argument from the call so that we can 
# span multiple instances of this script outside
if not sys.argv[1:]:
    print_message('Projection not defined, falling back to default (de, it, nord)')
    projections = ['de','it','nord']
else:    
    projections=sys.argv[1:]

def main():
    """In the main function we basically read the files and prepare the variables to be plotted.
    This is not included in utils.py as it can change from case to case."""
    files = glob(input_file)
    dset = xr.open_mfdataset(files)
    # Only take hourly data 
    dset = dset.sel(time=pd.date_range(dset.time[0].values, dset.time[-1].values, freq='H'))
    dset = dset.metpy.parse_cf()

    time = pd.to_datetime(dset.time.values)
    increments = (time[1:] - time[:-1]) / pd.Timedelta('1 hour') 
    cum_hour=np.array((time-time[0]) / pd.Timedelta('1 hour')).astype("int")

    # Compute rain and snow 
    # Note that we have to load since they are Dask arrays
    rain_acc = dset['RAIN_GSP']
    snow_acc = dset['SNOW_GSP']
    rain = rain_acc.diff(dim='time', n=1)
    snow = snow_acc.diff(dim='time', n=1)
    # Unfortunately we have to convert to Numpy array 
    rain = rain.values / increments.values[:, np.newaxis, np.newaxis]
    snow = snow.values / increments.values[:, np.newaxis, np.newaxis]
    rain = np.insert(arr=rain, obj=0, axis=0, values=np.zeros_like(rain[0]))
    snow = np.insert(arr=snow, obj=0, axis=0, values=np.zeros_like(snow[0]))

    mslp = dset['prmsl'].metpy.unit_array.to('hPa')
    # This should be fixed to use the levels that do not contain only NaNs
    clouds_low = dset['CLCL'].load().metpy.sel(vertical=400. * units.hPa)
    clouds_high = dset['CLCH'].load().metpy.sel(vertical=200. * units.hPa)

    lon, lat = get_coordinates(dset)
    lon2d, lat2d = np.meshgrid(lon, lat)

    levels_rain   = (0.1, 0.2, 0.4, 0.6, 0.8, 1., 1.5, 2., 2.5, 3.0, 4.,
                     5, 7.5, 10., 15., 20., 30., 40., 60., 80., 100., 120.)
    levels_snow   = (0.1, 0.2, 0.4, 0.6, 0.8, 1., 1.5, 2., 2.5, 3.0, 4.,
                     5, 7.5, 10., 15.)
    levels_clouds = np.arange(30, 100, 5)
    levels_mslp = np.arange(np.nanmin(mslp).astype("int"), np.nanmax(mslp).astype("int"), 5.)

    cmap_snow, norm_snow = get_colormap_norm("snow", levels_snow)
    cmap_rain, norm_rain = get_colormap_norm("rain_new", levels_rain)
    cmap_clouds = truncate_colormap(plt.get_cmap('Greys'), 0., 0.5)
    cmap_clouds_high = truncate_colormap(plt.get_cmap('Oranges'), 0., 0.5)

    for projection in projections:# This works regardless if projections is either single value or array
        print_message('Projection = %s' % projection)
        fig = plt.figure(figsize=(figsize_x, figsize_y))
        ax  = plt.gca()
        m, x, y =get_projection(lon2d, lat2d, projection)

        #m.shadedrelief(scale=0.4, alpha=0.8)

        # All the arguments that need to be passed to the plotting function
        args=dict(m=m, x=x, y=y, ax=ax,
                 rain=rain, snow=snow, mslp=mslp, clouds_low=clouds_low, clouds_high=clouds_high,
                 levels_mslp=levels_mslp, levels_rain=levels_rain, levels_snow=levels_snow,
                 levels_clouds=levels_clouds, time=time, projection=projection, cum_hour=cum_hour,
                 cmap_rain=cmap_rain, cmap_snow=cmap_snow, cmap_clouds=cmap_clouds,
                 cmap_clouds_high=cmap_clouds_high, norm_snow=norm_snow, norm_rain=norm_rain)
        
        print_message('Pre-processing finished, launching plotting scripts')
        if debug:
            plot_files(time[1:2], **args)
        else:
            # Parallelize the plotting by dividing into chunks and processes 
            dates = chunks(time, chunks_size)
            plot_files_param=partial(plot_files, **args)
            p = Pool(processes)
            p.map(plot_files_param, dates)

def plot_files(dates, **args):
    # Using args we don't have to change the prototype function if we want to add other parameters!
    first = True
    for date in dates:
        # Find index in the original array to subset when plotting
        i = np.argmin(np.abs(date - args['time'])) 
        # Build the name of the output image
        filename = subfolder_images[args['projection']]+'/'+variable_name+'_%s.png' % args['cum_hour'][i]#date.strftime('%Y%m%d%H')#

        cs_rain = args['ax'].contourf(args['x'], args['y'], args['rain'][i],
                         extend='max', cmap=args['cmap_rain'], norm=args['norm_rain'],
                         levels=args['levels_rain'], zorder=3)
        cs_snow = args['ax'].contourf(args['x'], args['y'], args['snow'][i],
                         extend='max', cmap=args['cmap_snow'], norm=args['norm_snow'],
                         levels=args['levels_snow'], zorder=4)
        cs_clouds_low = args['ax'].contourf(args['x'], args['y'], args['clouds_low'][i],
                         extend='max', cmap=args['cmap_clouds'],
                         levels=args['levels_clouds'], zorder=2)
        cs_clouds_high = args['ax'].contourf(args['x'], args['y'], args['clouds_high'][i],
                         extend='max', cmap=args['cmap_clouds_high'],
                         levels=args['levels_clouds'], zorder=1, alpha=0.7)

        c = args['ax'].contour(args['x'], args['y'], args['mslp'][i],
                             levels=args['levels_mslp'], colors='red', linewidths=1., zorder=5, alpha=0.6)

        labels = args['ax'].clabel(c, c.levels, inline=True, fmt='%4.0f' , fontsize=6)

        maxlabels = plot_maxmin_points(args['ax'], args['x'], args['y'], args['mslp'][i],
                                       'max', 80, symbol='H', color='royalblue', random=True)
        minlabels = plot_maxmin_points(args['ax'], args['x'], args['y'], args['mslp'][i], 
                                       'min', 80, symbol='L', color='coral', random=True)
        
        an_fc = annotation_forecast(args['ax'],args['time'][i])
        an_var = annotation(args['ax'], 'Clouds, rain, snow and MSLP' ,loc='lower left', fontsize=6)
        an_run = annotation_run(args['ax'], args['time'])

        if first:
            if args['projection'] == "it": 
                x_cbar_0, y_cbar_0, x_cbar_size, y_cbar_size     = 0.15, 0.2, 0.35, 0.02
                x_cbar2_0, y_cbar2_0, x_cbar2_size, y_cbar2_size = 0.55, 0.2, 0.35, 0.02  
            elif args['projection'] == "de":
                x_cbar_0, y_cbar_0, x_cbar_size, y_cbar_size     = 0.17, 0.07, 0.32, 0.02
                x_cbar2_0, y_cbar2_0, x_cbar2_size, y_cbar2_size = 0.55, 0.07, 0.32, 0.02 
            elif args['projection'] == "nord":
                x_cbar_0, y_cbar_0, x_cbar_size, y_cbar_size     = 0.15, 0.09, 0.35, 0.02
                x_cbar2_0, y_cbar2_0, x_cbar2_size, y_cbar2_size = 0.55, 0.09, 0.35, 0.02 
            ax_cbar = plt.gcf().add_axes([x_cbar_0, y_cbar_0, x_cbar_size, y_cbar_size])
            ax_cbar_2 = plt.gcf().add_axes([x_cbar2_0, y_cbar2_0, x_cbar2_size, y_cbar2_size])
            cbar_snow = plt.gcf().colorbar(cs_snow, cax=ax_cbar, orientation='horizontal',
             label='Snow [cm/hr]')
            cbar_rain = plt.gcf().colorbar(cs_rain, cax=ax_cbar_2, orientation='horizontal',
             label='Rain [mm/hr]')
            cbar_snow.ax.tick_params(labelsize=8) 
            cbar_rain.ax.tick_params(labelsize=8)
        
        if debug:
            plt.show(block=True)
        else:
            plt.savefig(filename, **options_savefig)        
        
        remove_collections([c, cs_rain, cs_snow, cs_clouds_low, cs_clouds_high,
                            labels, an_fc, an_var, an_run, maxlabels, minlabels])

        first = False 

if __name__ == "__main__":
    main()
