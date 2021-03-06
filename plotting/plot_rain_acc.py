import numpy as np
from multiprocessing import Pool
from functools import partial
from utils import *
import sys

debug = False
if not debug:
    import matplotlib
    matplotlib.use('Agg')

import matplotlib.pyplot as plt

# The one employed for the figure name when exported 
variable_name = 'precip_acc'

print_message('Starting script to plot '+variable_name)

# Get the projection as system argument from the call so that we can
# span multiple instances of this script outside
if not sys.argv[1:]:
    print_message(
        'Projection not defined, falling back to default (euratl)')
    projection = 'de'
else:
    projection = sys.argv[1]


def main():
    """In the main function we basically read the files and prepare the variables to be plotted.
    This is not included in utils.py as it can change from case to case."""
    dset = read_dataset(variables=['TOT_PREC', 'PMSL'],
                        projection=projection)
    dset = dset.resample(time="1H").nearest(tolerance="1H")
    dset['prmsl'].metpy.convert_units('hPa')

    levels_precip = (5, 6, 7, 8, 9, 10, 12, 15, 20, 25, 30, 35, 40,
                    45, 50, 60, 70, 80, 90, 100, 150, 200, 250, 300, 400, 500)

    cmap, norm = get_colormap_norm("rain_new", levels_precip)

    _ = plt.figure(figsize=(figsize_x, figsize_y))
    ax  = plt.gca()
    # Get coordinates from dataset
    m, x, y = get_projection(dset, projection, labels=True)
    # additional maps adjustment for this map
    m.fillcontinents(color='lightgray', lake_color='whitesmoke', zorder=0)

    dset = dset.drop(['lon', 'lat']).load()

    levels_mslp = np.arange(dset['prmsl'].min().astype("int"),
                    dset['prmsl'].max().astype("int"), 4.)

    # All the arguments that need to be passed to the plotting function
    args=dict(x=x, y=y, ax=ax,
             levels_precip=levels_precip,
             levels_mslp=levels_mslp, time=dset.time,
             cmap=cmap, norm=norm)

    print_message('Pre-processing finished, launching plotting scripts')
    if debug:
        plot_files(dset.isel(time=slice(0, 2)), **args)
    else:
        # Parallelize the plotting by dividing into chunks and processes
        dss = chunks_dataset(dset, chunks_size)
        plot_files_param = partial(plot_files, **args)
        p = Pool(processes)
        p.map(plot_files_param, dss)


def plot_files(dss, **args):
    first = True
    for time_sel in dss.time:
        data = dss.sel(time=time_sel)
        time, run, cum_hour = get_time_run_cum(data)
        # Build the name of the output image
        filename = subfolder_images[projection] + '/' + variable_name + '_%s.png' % cum_hour

        cs = args['ax'].contourf(args['x'], args['y'],
                                 data['tp'],
                                 extend='max',
                                 cmap=args['cmap'],
                                 norm=args['norm'],
                                 levels=args['levels_precip'])

        c = args['ax'].contour(args['x'], args['y'],
                               data['prmsl'],
                                levels=args['levels_mslp'], colors='black', linewidths=1.)

        labels = args['ax'].clabel(c, c.levels, inline=True, fmt='%4.0f' , fontsize=6)

        maxlabels = plot_maxmin_points(args['ax'], args['x'], args['y'], data['prmsl'],
                                        'max', 150, symbol='H', color='royalblue', random=True)
        minlabels = plot_maxmin_points(args['ax'], args['x'], args['y'], data['prmsl'],
                                        'min', 150, symbol='L', color='coral', random=True)

        an_fc = annotation_forecast(args['ax'], time)
        an_var = annotation(args['ax'], 'Accumulated precipitation and MSLP [hPa]',
            loc='lower left', fontsize=6)
        an_run = annotation_run(args['ax'], run)
        logo = add_logo_on_map(ax=args['ax'], zoom=0.1, pos=(0.95, 0.08))

        if first:
            plt.colorbar(cs, orientation='horizontal', label='Accumulated precipitation [mm]', pad=0.035, fraction=0.035)

        if debug:
            plt.show(block=True)
        else:
            plt.savefig(filename, **options_savefig)        

        remove_collections([c, cs, labels, an_fc, an_var, an_run, maxlabels, minlabels, logo])

        first = False


if __name__ == "__main__":
    import time
    start_time=time.time()
    main()
    elapsed_time=time.time()-start_time
    print_message("script took " + time.strftime("%H:%M:%S", time.gmtime(elapsed_time)))

