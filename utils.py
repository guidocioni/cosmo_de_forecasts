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
    ax.add_artist(at)
    return(at)

def annotation_forecast(ax, time, loc='upper left',fontsize=8):
    """Put annotation of the forecast time."""
    at = AnchoredText('Forecast for %s' % time.strftime('%A %d %b %Y at %H UTC'), 
                       prop=dict(size=fontsize), frameon=True, loc=loc)
    at.patch.set_boxstyle("round,pad=0.,rounding_size=0.1")
    ax.add_artist(at)
    return(at)    

def annotation_forecast_radar(ax, time, loc='upper left',fontsize=8):
    """Put annotation of the forecast time."""
    at = AnchoredText('Forecast for %s' % time.strftime('%A %d %b %Y at %H:%M UTC'), 
                       prop=dict(size=fontsize), frameon=True, loc=loc)
    at.patch.set_boxstyle("round,pad=0.,rounding_size=0.1")
    ax.add_artist(at)
    return(at)

def annotation(ax, text, loc='upper right',fontsize=8):
    """Put a general annotation in the plot."""
    at = AnchoredText('%s'% text, prop=dict(size=fontsize), frameon=True, loc=loc)
    at.patch.set_boxstyle("round,pad=0.,rounding_size=0.1")
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
    if cmap_type == "winds":
      colors_tuple = pd.read_csv('/home/mpim/m300382/cosmo_de_forecasts/cmap_winds.rgba').values 
    elif cmap_type == "temp":
      colors_tuple = pd.read_csv('/home/mpim/m300382/cosmo_de_forecasts/cmap_temp.rgba').values
    elif cmap_type == "rh":
      colors_tuple = pd.read_csv('/home/mpim/m300382/cosmo_de_forecasts/cmap_rh.rgba').values

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
