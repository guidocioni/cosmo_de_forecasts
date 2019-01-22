# import matplotlib
# matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap # Import the Basemap toolkit
import numpy as np # Import the Numpy package
from datetime import datetime
from mpl_toolkits.axes_grid.anchored_artists import AnchoredText
from glob import glob
import xarray as xr
import utils
import pandas as pd
from matplotlib.colors import ListedColormap

diri='/scratch/local1/m300382/cosmo_de_forecasts/'
fileslist=[glob(diri+'cosmo-d2_single-level_H_SNOW_*.nc')[0], glob(diri+'cosmo-d2_single-level_TOT_PREC_*[!hourly].nc')[0]]

# .sel(lon=slice(6, 15), lat=slice(43, 49))

h_snow_dset = xr.open_dataset(fileslist[0])
tot_prec_dset = xr.open_dataset(fileslist[1]).sel(time=h_snow_dset.time)

dset = xr.merge([h_snow_dset, tot_prec_dset])
time = pd.to_datetime(h_snow_dset['time'].values)
cum_hour=np.array((time-time[0]) / pd.Timedelta('1 hour')).astype("int")

h_snow_2 = dset['sd']
h_snow_2 = h_snow_2*100.
h_snow = h_snow_2*0.
for i in range(1, np.shape(h_snow_2)[0]):
	h_snow[i,:,:] = h_snow_2[i,:,:] - h_snow_2[0,:,:]

dset['hsnow'] = h_snow

########## Italy plots  ####################
diri_images='/scratch/local1/m300382/cosmo_de_forecasts/it/'
fig = plt.figure(figsize=(10,6))

m = utils.get_projection("italy")

# Temporary dataset with cut data so that maximum is correct
ds1 = dset.sel(lon=slice(m.llcrnrlon, m.urcrnrlon), lat=slice(m.llcrnrlat, m.urcrnrlat))
lon2d, lat2d = np.meshgrid(ds1['lon'], ds1['lat'])

ax = plt.gca()

first = True 
for i, date in enumerate(time):
    print(date)
    cr = ax.contourf(lon2d, lat2d, ds1.tp[i,:,:], levels=utils.levels_rain,
     cmap=utils.cmap_rain, norm=utils.norm_rain, extend='max', alpha=0.75)
    cs = ax.contourf(lon2d, lat2d, ds1.hsnow[i,:,:], levels=utils.levels_snow,
     cmap=utils.cmap_snow, norm=utils.norm_snow, extend='max', alpha=0.85)
    
    ax.set_title('Tot. precipitation & Freshsnow | '+date.strftime('%d %b %Y at %H UTC'))
    utils.annotation_run(ax, time)
    utils.annotation(ax, text='COSMO-D2', loc='upper left')
    utils.annotation(ax, text='www.meteoindiretta.it', loc='lower right')
    max_value_snow = np.nanmax(ds1.hsnow[i,:,:])
    max_value_rain = np.nanmax(ds1.tp[i,:,:])

    utils.annotation(ax, text='Snow max. = %4.1f'%max_value_snow, loc='lower left')

    if first: 
        # First method, doesn't work
        p0 = plt.gca().get_position().get_points().flatten()
        ax_cbar = plt.gcf().add_axes([p0[0], 0.1, (p0[2]-p0[0])/2., 0.01])
        ax_cbar_2 = plt.gcf().add_axes([(p0[2]-p0[0])/2.+0.15, 0.1, p0[2]-0.55, 0.01])
        plt.gcf().colorbar(cs, cax=ax_cbar, orientation='horizontal',
         label='Snow depth [cm]', ticks=utils.levels_snow)
        plt.gcf().colorbar(cr, cax=ax_cbar_2, orientation='horizontal',
         label='Total precipitation [mm]', ticks=utils.levels_rain)
  
    plt.savefig(diri_images+'winter_%s.png' % cum_hour[i], dpi=120, bbox_inches='tight')
    # This is needed to have contour which not overlap
    for coll in cs.collections: 
        coll.remove()
    for coll in cr.collections: 
        coll.remove()
    # for label in labels:
    #     label.remove()
    first=False

plt.close('all')

############################################

########## Germany plots  ####################
diri_images='/scratch/local1/m300382/cosmo_de_forecasts/'
fig = plt.figure(figsize=(8,8))

m = utils.get_projection("germany")

# Temporary dataset with cut data so that maximum is correct
ds2 = dset.sel(lon=slice(m.llcrnrlon, m.urcrnrlon), lat=slice(m.llcrnrlat, m.urcrnrlat))
lon2d, lat2d = np.meshgrid(ds2['lon'], ds2['lat'])

ax = plt.gca()

first = True 
for i, date in enumerate(time):
    print(date)
    cr = ax.contourf(lon2d, lat2d, ds2.tp[i,:,:], levels=utils.levels_rain,
     cmap=utils.cmap_rain, norm=utils.norm_rain, extend='max', alpha=0.75)
    cs = ax.contourf(lon2d, lat2d, ds2.hsnow[i,:,:], levels=utils.levels_snow,
     cmap=utils.cmap_snow, norm=utils.norm_snow, extend='max', alpha=0.85)
    
    ax.set_title('Tot. precipitation & Freshsnow | '+date.strftime('%d %b %Y at %H UTC'))
    utils.annotation_run(ax, time)
    utils.annotation(ax, text='COSMO-D2', loc='upper left')
    utils.annotation(ax, text='www.meteoindiretta.it', loc='lower right')
    max_value_snow = np.nanmax(ds2.hsnow[i,:,:])
    max_value_rain = np.nanmax(ds2.tp[i,:,:])

    utils.annotation(ax, text='Snow max. = %4.1f'%max_value_snow, loc='lower left')

    if first: 
        # First method, doesn't work
        p0 = plt.gca().get_position().get_points().flatten()
        ax_cbar = plt.gcf().add_axes([p0[0], 0.1, (p0[2]-p0[0])/2., 0.01])
        ax_cbar_2 = plt.gcf().add_axes([(p0[2]-p0[0])/2.+0.15, 0.1, p0[2]-0.55, 0.01])
        plt.gcf().colorbar(cs, cax=ax_cbar, orientation='horizontal',
         label='Snow depth [cm]', ticks=utils.levels_snow)
        plt.gcf().colorbar(cr, cax=ax_cbar_2, orientation='horizontal',
         label='Total precipitation [mm]', ticks=utils.levels_rain)
    plt.savefig(diri_images+'winter_%s.png' % cum_hour[i], dpi=120, bbox_inches='tight')
    # This is needed to have contour which not overlap
    for coll in cs.collections: 
        coll.remove()
    for coll in cr.collections: 
        coll.remove()
    # for label in labels:
    #     label.remove()
    first=False

plt.close('all')

############################################
