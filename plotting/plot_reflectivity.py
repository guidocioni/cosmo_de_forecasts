debug = False 
if not debug:
    import matplotlib
    matplotlib.use('Agg')

import matplotlib.pyplot as plt
from metpy.units import units
from glob import glob
import numpy as np
import pandas as pd
from multiprocessing import Pool
from functools import partial
from utils import *
import sys

# The one employed for the figure name when exported 
variable_name = 'radar'

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
    dset, time, cum_hour  = read_dataset(variables=['DBZ_CMAX'])

    # Select 850 hPa level using metpy
    dbz = dset['DBZ_CMAX'].load()

    levels_dbz = np.arange(20, 70, 2.5)

    cmap = truncate_colormap(plt.get_cmap('nipy_spectral'), 0.1, 1.0)
    
    for projection in projections:# This works regardless if projections is either single value or array
        print_message('Projection = %s' % projection)
        fig = plt.figure(figsize=(figsize_x, figsize_y))
        
        ax  = plt.gca()        

        dbz = subset_arrays([dbz], projection)[0]

        lon, lat = get_coordinates(dbz)
        lon2d, lat2d = np.meshgrid(lon, lat)

        m, x, y = get_projection(lon2d, lat2d, projection, labels=True)
        # All the arguments that need to be passed to the plotting function
        m.fillcontinents(color='lightgray', lake_color='whitesmoke', zorder=0)
        
        args=dict(m=m, x=x, y=y, ax=ax, cmap=cmap,
                 dbz=dbz, levels_dbz=levels_dbz, time=time,
                 projection=projection, cum_hour=cum_hour)
        
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
        filename = subfolder_images[args['projection']]+'/'+variable_name+'_%03d.png' % args['cum_hour'][i]#date.strftime('%Y%m%d%H')#

        cs = args['ax'].contourf(args['x'], args['y'], args['dbz'][i], extend='max', cmap=args['cmap'],
                                    levels=args['levels_dbz'])

        
        an_fc = annotation_forecast_radar(args['ax'],args['time'][i])
        an_var = annotation(args['ax'], 'Radar reflectivity [dBz]' ,loc='lower left', fontsize=6)
        an_run = annotation_run(args['ax'], args['time'])

        if first:
            plt.colorbar(cs, orientation='horizontal', label='Reflectivity', pad=0.03, fraction=0.04)
        
        if debug:
            plt.show(block=True)
        else:
            plt.savefig(filename, **options_savefig)        
        
        remove_collections([cs, an_fc, an_var, an_run])

        first = False 

if __name__ == "__main__":
    import time
    start_time=time.time()
    main()
    elapsed_time=time.time()-start_time
    print_message("script took " + time.strftime("%H:%M:%S", time.gmtime(elapsed_time)))
