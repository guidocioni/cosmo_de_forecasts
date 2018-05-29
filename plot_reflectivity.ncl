load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"

begin
; Open model level output file
wkstype="png"
wkstype@wkWidth = 800
wkstype@wkHeight = 800

if .not. isvar("min_lon") then 
 min_lon=5 
end if 
if .not. isvar("max_lon") then 
 max_lon=16 
end if 
if .not. isvar("min_lat") then 
 min_lat=46 
end if
if .not. isvar("max_lat") then 
 max_lat=56 
end if
if .not. isvar("folder_output") then 
 folder_output="./" 
end if

folder="/scratch/local1/m300382/cosmo_de_forecasts/"

fils = systemfunc ("ls "+folder+"cosmo-d2_single-level_DBZ*") ; file paths
f    = addfiles (fils, "r")  
ListSetType (f, "cat")

dbz=f[:]->DBZ_CMAX 

plot_description="Simulated radar reflectivity every 15 minutes"

lon = f[:]->lon 
lat = f[:]->lat
time= f[:]->time 

dbz@lat2d=lat 
dbz@lon2d=lon

date=cd_calendar(time,-5)
date_string=sprinti("%0.2i",toint(time))+sprinti("%0.2i", date(:,4))

run_time=str_sub_str(time@units,"hours since ","")
run_string="Run: "+run_time
delete([/fils, f/])

; create plot

ResC = True
ResC@gsnDraw = False
ResC@gsnFrame = False
ResC@gsnAddCyclic = False  
ResC@gsnMaximize   = True         ; Maximize plot in frame.
ResC@gsnLeftString = ""
ResC@gsnRightString = ""
ResC@tiXAxisString =""
ResC@tiYAxisString =""

ResC@cnFillOn = True ; do color fill
; ResC@cnFillMode = "rasterfill"
ResC@cnLinesOn=False

ResC@mpOutlineOn = True
ResC@mpFillOn     = True
ResC@mpLimitMode = "LatLon"                   ;
ResC@mpMaxLonF    = max_lon                      ; specify the plot domain
ResC@mpMinLonF    = min_lon                      ;
ResC@mpMinLatF    = min_lat                     ;
ResC@mpMaxLatF    = max_lat                     ;
ResC@mpDataBaseVersion  = "MediumRes"
ResC@mpGeophysicalLineThicknessF = 4
ResC@mpGeophysicalLineColor ="black"
ResC@mpOutlineBoundarySets = "AllBoundaries"     ; more outlines
ResC@mpNationalLineThicknessF = 3
ResC@mpDataSetName         = "Earth..4"     
; ResC@mpOutlineOn = True
ResC@tmXBLabelFontHeightF = 0.01
ResC@pmTickMarkDisplayMode = True

cmap_r              = read_colormap_file("radar")
cmap_r(0,3)         = 0.0    ; Fully transparent
ResC@cnFillPalette = cmap_r

; ResC@cnFillPalette = "radar_1"
ResC@cnLevelSelectionMode = "ManualLevels"
ResC@cnMinLevelValF = 10
ResC@cnMaxLevelValF = 70 
ResC@cnLevelSpacingF = 5

ResC@lbOrientation = "Vertical"
ResC@pmLabelBarWidthF = 0.05
ResC@gsnLeftString = "COSMO-D2"
ResC@gsnRightString = "Copyright DWD"

txres                       = True
txres@txPerimOn             = True
txres@txBackgroundFillColor = "White"
txres@txFontHeightF         = 0.01

amres=True 
amres@amParallelPosF   = -0.5    ; This is the right edge of the plot.
amres@amOrthogonalPosF = 0.5    ; This is the bottom edge of the plot.
amres@amJust = "BottomLeft"

amres2=True 
amres2@amParallelPosF   = -0.5    ; This is the right edge of the plot.
amres2@amOrthogonalPosF = -0.5    ; This is the bottom edge of the plot.
amres2@amJust = "TopLeft"

do time_i=0,dimsizes(time)-1
   ResC@gsnCenterString= "Forecast for "+cd_string(time(time_i), "%d %c. %Y")+" at "+cd_string(time(time_i), "%H:%M")+" UTC"
   wks = gsn_open_wks(wkstype,folder_output+"radar_"+date_string(time_i))
   
   plot = gsn_csm_contour_map(wks,dbz(time_i,:,:),ResC)
   text=gsn_create_text(wks, plot_description, txres)
   description=gsn_add_annotation(plot, text, amres)
   text2=gsn_create_text(wks, run_string, txres)
   run_annotation=gsn_add_annotation(plot, text2, amres2)

   id=gsn_add_shapefile_polylines(wks,plot,"/home/mpim/m300382/shapefiles/DEU_adm_shp/DEU_adm1.shp",True)
   draw(plot)
   frame(wks)
end do
end
