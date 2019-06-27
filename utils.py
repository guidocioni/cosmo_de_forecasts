# Configuration file for some common variables to all script 
from mpl_toolkits.basemap import Basemap  # import Basemap matplotlib toolkit
import numpy as np
from matplotlib.offsetbox import AnchoredText
import matplotlib.colors as colors
import seaborn as sns
import metpy.calc as mpcalc
from metpy.units import units
import pandas as pd
from matplotlib.colors import from_levels_and_colors
import seaborn as sns
import __main__ as main
import os
import matplotlib.patheffects as path_effects
import matplotlib.cm as mplcm

import warnings
warnings.filterwarnings(
    action='ignore',
    message='The unit of the quantity is stripped.'
)

folder = '/scratch/local1/m300382/cosmo_de_forecasts/'
input_file=folder+'cosmo-d2_*.nc' 
folder_images = folder 
chunks_size = 10 
processes = 5
figsize_x = 10 
figsize_y = 8

# Options for savefig
options_savefig={
    'dpi':100,
    'bbox_inches':'tight',
    'transparent':True
}

# Dictionary to map the output folder based on the projection employed
subfolder_images={
    'de' : folder_images,
    'it' : folder_images+'it',
    'nord' : folder_images+'nord'    
}

folder_glyph = '/home/mpim/m300382/icons_weather/yrno_png/'
WMO_GLYPH_LOOKUP_PNG={
        '0' : '01',
        '1' : '02',
        '2' : '02',
        '3' : '04',
        '5' : '15',
        '10': '15',
        '14': '15',
        '30': '15',
        '40': '15',
        '41': '15',
        '42': '15',
        '43': '15',
        '44': '15',
        '45': '15',
        '46': '15',
        '47': '15',
        '50': '46',
        '60': '09',
        '61': '09',
        '63': '10',
        '64': '41',
        '65': '12',
        '68': '47',
        '69': '48',
        '70': '13',
        '71': '49',
        '73': '50',
        '74': '45',
        '75': '48',
        '80': '05',
        '81': '05',
        '83': '41',
        '84': '32',
        '85': '08',
        '86': '34',
        '87': '45',
        '89': '43',
        '90': '30',
        '91': '30',
        '92': '25',
        '93': '33',
        '94': '34',
        '95': '25',
}

def get_weather_icons(ww, time):
    from matplotlib._png import read_png
    """
    Get the path to a png given the weather representation 
    """
    weather = [WMO_GLYPH_LOOKUP_PNG[w.astype(int).astype(str)] for w in ww.values]
    weather_icons=[]
    for date, weath in zip(time, weather):
        if date.hour >= 6 and date.hour <= 18:
            add_string='d'
        elif date.hour >=0 and date.hour < 6:
            add_string='n'
        elif date.hour >18 and date.hour < 24:
            add_string='n'

        pngfile=folder_glyph+'%s.png' % (weath+add_string)
        if os.path.isfile(pngfile):
            weather_icons.append(read_png(pngfile))
        else:
            pngfile=folder_glyph+'%s.png' % weath
            weather_icons.append(read_png(pngfile))

    return(weather_icons)

def print_message(message):
    """Formatted print"""
    print(main.__file__+' : '+message)

def get_coordinates(dataset):
    """Get the lat/lon coordinates from the dataset and convert them to degrees."""
    dataset['lon'].metpy.convert_units('degreeN')
    dataset['lat'].metpy.convert_units('degreeE')
    # We have to return an array otherwise Basemap 
    # will complain
    
    return(dataset['lon'].values, dataset['lat'].values)

def get_city_coordinates(city):
    """Get the lat/lon coordinates of a city given its name using geopy."""
    from geopy.geocoders import Nominatim
    geolocator =Nominatim(user_agent='meteogram')
    loc = geolocator.geocode(city)
    
    return(loc.longitude, loc.latitude)

def get_projection(lon, lat, projection="de", countries=True, regions=True, labels=False):
    if projection=="de":
        m = Basemap(projection='cyl', llcrnrlon=5, llcrnrlat=46.5,\
               urcrnrlon=16, urcrnrlat=56,  resolution='i',epsg=4269)
        if regions:
            m.readshapefile('/home/mpim/m300382/shapefiles/DEU_adm_shp/DEU_adm1',
                            'DEU_adm1',linewidth=0.2,color='black',zorder=5)
        if labels:
            m.drawparallels(np.arange(-80.,81.,2), linewidth=0.2, color='white',
                labels=[True, False, False, True], fontsize=7)
            m.drawmeridians(np.arange(-180.,181.,2), linewidth=0.2, color='white',
                labels=[True, False, False, True], fontsize=7)
    elif projection=="it":
        m = Basemap(projection='cyl', llcrnrlon=5.5, llcrnrlat=43.5,\
               urcrnrlon=14.5, urcrnrlat=48.,  resolution='i',epsg=4269)
        if regions:
            m.readshapefile('/home/mpim/m300382/shapefiles/ITA_adm_shp/ITA_adm1',
                            'ITA_adm1',linewidth=0.2,color='black',zorder=5)
        if labels:
            m.drawparallels(np.arange(-80.,81.,2), linewidth=0.2, color='white',
                labels=[True, False, False, True], fontsize=7)
            m.drawmeridians(np.arange(-180.,181.,2), linewidth=0.2, color='white',
                labels=[True, False, False, True], fontsize=7)
    elif projection=="nord":
        m = Basemap(projection='cyl', llcrnrlon=4., llcrnrlat=50.,\
               urcrnrlon=12., urcrnrlat=56.,  resolution='i',epsg=4269)
        if regions:
            m.readshapefile('/home/mpim/m300382/shapefiles/DEU_adm_shp/DEU_adm1',
                            'DEU_adm1',linewidth=0.2,color='black',zorder=5)
        if labels:
            m.drawparallels(np.arange(-80.,81.,2), linewidth=0.2, color='white',
                labels=[True, False, False, True], fontsize=7)
            m.drawmeridians(np.arange(-180.,181.,2), linewidth=0.2, color='white',
                labels=[True, False, False, True], fontsize=7)
        
    m.drawcoastlines(linewidth=0.5, linestyle='solid', color='black', zorder=5)
    if countries:
        m.drawcountries(linewidth=0.5, linestyle='solid', color='black', zorder=5)

    x, y = m(lon,lat)
    
    return(m, x, y)

def chunks(l, n):
    """Yield successive n-sized chunks from l."""
    for i in range(0, len(l), n):
        yield l[i:i + n]

# Annotation run, models 
def annotation_run(ax, time, loc='upper right',fontsize=8):
    """Put annotation of the run obtaining it from the
    time array passed to the function."""
    at = AnchoredText('Run %s'% time[0].strftime('%Y%m%d %H UTC'), 
                       prop=dict(size=fontsize), frameon=True, loc=loc)
    at.patch.set_boxstyle("round,pad=0.,rounding_size=0.1")
    at.zorder = 10
    ax.add_artist(at)
    
    return(at)

def annotation_forecast(ax, time, loc='upper left', fontsize=8, local=True):
    """Put annotation of the forecast time."""
    if local: # convert to local time
        time = convert_timezone(time)
        at = AnchoredText('Valid %s' % time.strftime('%A %d %b %Y at %H (Berlin)'), 
                       prop=dict(size=fontsize), frameon=True, loc=loc)
    else:
        at = AnchoredText('Forecast for %s' % time.strftime('%A %d %b %Y at %H UTC'), 
                       prop=dict(size=fontsize), frameon=True, loc=loc)
    at.patch.set_boxstyle("round,pad=0.,rounding_size=0.1")
    at.zorder = 10
    ax.add_artist(at)
    
    return(at)    

def convert_timezone(dt_from, from_tz='utc', to_tz='Europe/Berlin'):
    """Convert between two timezones. dt_from needs to be a Timestamp 
    object, don't know if it works otherwise."""
    dt_to = dt_from.tz_localize(from_tz).tz_convert(to_tz)
    # remove again the timezone information
    
    return dt_to.tz_localize(None)

def annotation_forecast_radar(ax, time, loc='upper left', fontsize=8, local=True):
    """Put annotation of the forecast time."""
    if local: # convert to local time
        time = convert_timezone(time)
        at = AnchoredText('Valid %s' % time.strftime('%A %d %b %Y at %H:%M (Berlin)'), 
                       prop=dict(size=fontsize), frameon=True, loc=loc)
    else:
        at = AnchoredText('Valid %s' % time.strftime('%A %d %b %Y at %H:%M UTC'), 
                       prop=dict(size=fontsize), frameon=True, loc=loc)
    at.patch.set_boxstyle("round,pad=0.,rounding_size=0.1")
    at.zorder = 10
    ax.add_artist(at)
    
    return(at) 

def annotation(ax, text, loc='upper right',fontsize=8):
    """Put a general annotation in the plot."""
    at = AnchoredText('%s'% text, prop=dict(size=fontsize), frameon=True, loc=loc)
    at.patch.set_boxstyle("round,pad=0.,rounding_size=0.1")
    at.zorder = 10
    ax.add_artist(at)
    
    return(at)

def truncate_colormap(cmap, minval=0.0, maxval=1.0, n=256):
    """Truncate a colormap by specifying the start and endpoint."""
    new_cmap = colors.LinearSegmentedColormap.from_list(
        'trunc({n},{a:.2f},{b:.2f})'.format(n=cmap.name, a=minval, b=maxval),
        cmap(np.linspace(minval, maxval, n)))
    
    return(new_cmap)

def get_colormap(cmap_type):
    """Create a custom colormap."""
    colors_tuple = pd.read_csv('/home/mpim/m300382/cosmo_de_forecasts/cmap_%s.rgba' % cmap_type).values 
         
    cmap = colors.LinearSegmentedColormap.from_list(cmap_type, colors_tuple, colors_tuple.shape[0])
    
    return(cmap)

def get_colormap_norm(cmap_type, levels):
    """Create a custom colormap."""
    if cmap_type == "rain":
        cmap, norm = from_levels_and_colors(levels, sns.color_palette("Blues", n_colors=len(levels)),
                                                    extend='max')
    elif cmap_type == "snow":
        cmap, norm = from_levels_and_colors(levels, sns.color_palette("PuRd", n_colors=len(levels)),
                                                    extend='max')
    elif cmap_type == "snow_discrete":    
        colors = ["#DBF069","#5AE463","#E3BE45","#65F8CA","#32B8EB",
                    "#1D64DE","#E97BE4","#F4F476","#E78340","#D73782","#702072"]
        cmap, norm = from_levels_and_colors(levels, colors, extend='max')
    elif cmap_type == "rain_acc":    
        cmap, norm = from_levels_and_colors(levels, sns.color_palette('gist_stern_r', n_colors=len(levels)),
                         extend='max')
    elif cmap_type == "rain_new":
        colors_tuple = pd.read_csv('/home/mpim/m300382/cosmo_de_forecasts/cmap_prec.rgba').values    
        cmap, norm = from_levels_and_colors(levels, sns.color_palette(colors_tuple, n_colors=len(levels)),
                         extend='max')

    return(cmap, norm)

def remove_collections(elements):
    """Remove the collections of an artist to clear the plot without
    touching the background, which can then be used afterwards."""
    for element in elements:
        try:
            for coll in element.collections: 
                coll.remove()
        except AttributeError:
            try:
                for coll in element:
                    coll.remove()
            except ValueError:
                print('WARNING: Collection is empty')
            except TypeError:
                element.remove() 
        except ValueError:
            print('WARNING: Collection is empty')

def plot_maxmin_points(ax, lon, lat, data, extrema, nsize, symbol, color='k',
                       random=False):
    """
    This function will find and plot relative maximum and minimum for a 2D grid. The function
    can be used to plot an H for maximum values (e.g., High pressure) and an L for minimum
    values (e.g., low pressue). It is best to used filetered data to obtain  a synoptic scale
    max/min value. The symbol text can be set to a string value and optionally the color of the
    symbol and any plotted value can be set with the parameter color
    lon = plotting longitude values (2D)
    lat = plotting latitude values (2D)
    data = 2D data that you wish to plot the max/min symbol placement
    extrema = Either a value of max for Maximum Values or min for Minimum Values
    nsize = Size of the grid box to filter the max and min values to plot a reasonable number
    symbol = String to be placed at location of max/min value
    color = String matplotlib colorname to plot the symbol (and numerica value, if plotted)
    plot_value = Boolean (True/False) of whether to plot the numeric value of max/min point
    The max/min symbol will be plotted on the current axes within the bounding frame
    (e.g., clip_on=True)
    """
    from scipy.ndimage.filters import maximum_filter, minimum_filter

    # We have to first add some random noise to the field, otherwise it will find many maxima
    # close to each other. This is not the best solution, though...
    if random:
        data = np.random.normal(data, 0.2)

    if (extrema == 'max'):
        data_ext = maximum_filter(data, nsize, mode='nearest')
    elif (extrema == 'min'):
        data_ext = minimum_filter(data, nsize, mode='nearest')
    else:
        raise ValueError('Value for hilo must be either max or min')

    mxy, mxx = np.where(data_ext == data)
    # Filter out points on the border 
    mxx, mxy = mxx[(mxy != 0) & (mxx != 0)], mxy[(mxy != 0) & (mxx != 0)]

    texts = []
    for i in range(len(mxy)):
        texts.append( ax.text(lon[mxy[i], mxx[i]], lat[mxy[i], mxx[i]], symbol, color=color, size=15,
                clip_on=True, horizontalalignment='center', verticalalignment='center',
                path_effects=[path_effects.withStroke(linewidth=1, foreground="black")], zorder=6) )
        texts.append( ax.text(lon[mxy[i], mxx[i]], lat[mxy[i], mxx[i]], '\n' + str(data[mxy[i], mxx[i]].astype('int')),
                color="gray", size=10, clip_on=True, fontweight='bold',
                horizontalalignment='center', verticalalignment='top', zorder=6) )
    
    return(texts)

def add_vals_on_map(ax, bmap, var, levels, density=50,
                     cmap='rainbow', shift_x=0., shift_y=0., fontsize=9, lcolors=True):
    '''Given an input projection, a variable containing the values and a plot put
    the values on a map exlcuing NaNs and taking care of not going
    outside of the map boundaries, which can happen.
    - shift_x and shift_y apply a shifting offset to all text labels
    - colors indicate whether the colorscale cmap should be used to map the values of the array'''

    norm = colors.Normalize(vmin=levels.min(), vmax=levels.max())
    m = mplcm.ScalarMappable(norm=norm, cmap=cmap)
    
    lon_min, lon_max, lat_min, lat_max = bmap.llcrnrlon, bmap.urcrnrlon, bmap.llcrnrlat, bmap.urcrnrlat

    # Remove values outside of the extents
    var = var.sel(lat=slice(lat_min+0.15, lat_max-0.15), lon=slice(lon_min+0.15, lon_max-0.15))[::density, ::density]
    var = var.dropna(dim='lon')
    var = var.dropna(dim='lat')
    lons = var.lon
    lats = var.lat

    at = []
    for ilat, ilon in np.ndindex(var.shape):
        if lcolors:
            at.append(ax.annotate(('%d'%var[ilat, ilon]), (lons[ilon]+shift_x, lats[ilat]+shift_y),
                             color = m.to_rgba(float(var[ilat, ilon])), weight='bold', fontsize=fontsize,
                              path_effects=[path_effects.withStroke(linewidth=1, foreground="black")], zorder=5))
        else:
            at.append(ax.annotate(('%d'%var[ilat, ilon]), (lons[i]+shift_x, lats[i]+shift_y),
                             color = 'white', weight='bold', fontsize=fontsize,
                              path_effects=[path_effects.withStroke(linewidth=1, foreground="black")], zorder=5))

    return at

