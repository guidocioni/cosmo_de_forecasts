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
variable_name = 't_v_pres'

print('Starting script to plot '+variable_name)

# Get the projection as system argument from the call so that we can 
# span multiple instances of this script outside
if not sys.argv[1:]:
    print('Projection not defined, falling back to default (de, it, nord)')
    projections = ['de','it','nord']
else:    
    projections=sys.argv[1:]

def main():
    """In the main function we basically read the files and prepare the variables to be plotted.
    This is not included in utils.py as it can change from case to case."""
    files = glob(input_file)
    dset = xr.open_mfdataset(files)
    # Only take hourly data 
    dset = dset.sel(time=pd.date_range(dset.time[0].values, dset.time[-1].values, freq='H')).load()
    dset = dset.metpy.parse_cf()

    # Select 850 hPa level using metpy
    u = dset['10u'].metpy.sel(height=10 * units.m)
    v = dset['10v'].metpy.sel(height=10 * units.m)
    t2m = dset['2t'].metpy.sel(height=2 * units.m).metpy.unit_array.to('degC')
    mslp = dset['prmsl'].metpy.unit_array.to('hPa')

    lon, lat = get_coordinates(dset)
    lon2d, lat2d = np.meshgrid(lon, lat)

    time = pd.to_datetime(dset.time.values)
    cum_hour=np.array((time-time[0]) / pd.Timedelta('1 hour')).astype("int")

    levels_t2m = np.arange(np.nanmin(t2m).astype("int"), np.nanmax(t2m).astype("int"), 1)
    levels_mslp = np.arange(np.nanmin(mslp).astype("int"), np.nanmax(mslp).astype("int"), 5.)

    cmap = get_colormap("temp")
    
    for projection in projections:# This works regardless if projections is either single value or array
        fig = plt.figure(figsize=(figsize_x, figsize_y))
        ax  = plt.gca()        
        m, x, y =get_projection(lon2d, lat2d, projection, labels=True)

        # All the arguments that need to be passed to the plotting function
        args=dict(m=m, x=x, y=y, ax=ax, cmap=cmap,
                 t2m=t2m, u=u, v=v, mslp=mslp, levels_t2m=levels_t2m, levels_mslp=levels_mslp,
                 time=time, projection=projection, cum_hour=cum_hour)
        
        print('Pre-processing finished, launching plotting scripts')
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

        cs = args['ax'].contourf(args['x'], args['y'], args['t2m'][i], extend='both', cmap=args['cmap'],
                                    levels=args['levels_t2m'])
        c = args['ax'].contour(args['x'], args['y'], args['mslp'][i],
                             levels=args['levels_mslp'], colors='white', linewidths=1.)
        labels = args['ax'].clabel(c, c.levels, inline=True, fmt='%4.0f' , fontsize=6)

        # We need to reduce the number of points before plotting the vectors,
        # these values work pretty well
        density = 15 
        cv = args['ax'].quiver(args['x'][::density,::density], args['y'][::density,::density],
                     args['u'][i,::density,::density], args['v'][i,::density,::density], scale=None,
                     alpha=0.7, color='gray')

        an_fc = annotation_forecast(args['ax'],args['time'][i])
        an_var = annotation(args['ax'], 'MSLP [hPa], Winds@10m and Temperature@2m' ,loc='lower left', fontsize=6)
        an_run = annotation_run(args['ax'], args['time'])

        if first:
            plt.colorbar(cs, orientation='horizontal', label='Temperature [C]', pad=0.03, fraction=0.04)
        
        if debug:
            plt.show(block=True)
        else:
            plt.savefig(filename, **options_savefig)        
        
        remove_collections([cs, c, labels, an_fc, an_var, an_run])

        first = False 

if __name__ == "__main__":
    main()
