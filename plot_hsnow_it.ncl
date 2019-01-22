load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"

begin
; Open model level output file
wkstype="png"
wkstype@wkWidth = 1100
wkstype@wkHeight = 1100

if .not. isvar("min_lon") then 
 min_lon=6 
end if 
if .not. isvar("max_lon") then 
 max_lon=15 
end if 
if .not. isvar("min_lat") then 
 min_lat=43 
end if
if .not. isvar("max_lat") then 
 max_lat=48 
end if
if .not. isvar("folder_output") then 
 folder_output="./it/" 
end if

folder="/scratch/local1/m300382/cosmo_de_forecasts/"

fils = systemfunc ("ls "+folder+"cosmo-d2_single-level_H_SNOW*") ; file paths
f_depthsnow    = addfiles (fils, "r")  
ListSetType (f_depthsnow, "cat")

fils = systemfunc ("ls "+folder+"cosmo-d2_single-level_SNOWLMT*") ; file paths
f_hsnow    = addfiles (fils, "r")  
ListSetType (f_hsnow, "cat")

plot_description="Snow depth change since initialization time (cm) and limit of snowfall (m)"

height_snow=f_hsnow[:]->SNOWLMT
depth_snow=f_depthsnow[:]->sd

lon = f_hsnow[:]->lon 
lat = f_hsnow[:]->lat
time= f_hsnow[:]->time 

date_string=toint(time)
run_time=str_sub_str(time@units,"hours since ","")
run_string="Run: "+run_time

depth_snow=depth_snow*100.
change_snow=depth_snow
change_snow=0

do i=1,dimsizes(time)-1
    change_snow(i,:,:)=depth_snow(i,:,:)-depth_snow(0,:,:)
end do 

delete([/fils, f_hsnow, f_depthsnow/])

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

ResC2=ResC
ResC2@cnFillOn = False
ResC2@cnLinesOn= True
ResC2@cnLineLabelFontHeightF= 0.008
ResC@cnFillOn = True ; do color fill
ResC@cnLinesOn=False

ResC@mpFillOn     = False
ResC@mpLimitMode = "LatLon"                   ;
ResC@mpMaxLonF    = max_lon                      ; specify the plot domain
ResC@mpMinLonF    = min_lon                      ;
ResC@mpMinLatF    = min_lat                     ;
ResC@mpMaxLatF    = max_lat                     ;
ResC@mpDataBaseVersion  = "MediumRes"
ResC@mpGeophysicalLineThicknessF = 3
ResC@mpGeophysicalLineColor ="black"
ResC@mpOutlineBoundarySets = "AllBoundaries"     ; more outlines
ResC@mpDataSetName         = "Earth..4"     
ResC@tmXBLabelFontHeightF = 0.01
ResC@pmTickMarkDisplayMode = True
ResC@mpNationalLineThicknessF = 3

ResC2@cnLevelSelectionMode = "ManualLevels"
ResC2@cnMinLevelValF = 500
ResC2@cnMaxLevelValF = 3000
ResC2@cnInfoLabelOn = False  
ResC2@cnLevelSpacingF = 500
ResC2@cnLineThicknessF = 3
ResC2@cnLineColor = "gray"
ResC2@cnLineLabelFontHeightF = 0.005

cmap_r              = read_colormap_file("precip4_diff_19lev")
; cmap_r(0,3)         = 0.0    ; Fully transparent
ResC@cnFillPalette = cmap_r

ResC@cnLevelSelectionMode = "ExplicitLevels"
ResC@cnLevels = (/-40, -30, -20, -10, -5, -2.5, -2, -1, -0.5, 0, 0.5, 1, 2, 2.5, 5, 10, 20, 30, 40/)
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


amres3=True 
amres3@amParallelPosF   = 0.5    ; This is the right edge of the plot.
amres3@amOrthogonalPosF = -0.5    ; This is the bottom edge of the plot.
amres3@amJust = "TopRight"

do time_i=1,dimsizes(time)-1
 ResC@gsnCenterString= "Forecast for "+cd_string(time(time_i), "%d %c. %Y")+" at "+cd_string(time(time_i), "%H:%M")+" UTC"
   wks = gsn_open_wks(wkstype,folder_output+"hsnow_"+date_string(time_i))

   plot = gsn_csm_contour_map(wks,change_snow(time_i,:,:),ResC)
   over = gsn_csm_contour(wks,height_snow(time_i,:,:),ResC2)

   text=gsn_create_text(wks, plot_description, txres)
   description=gsn_add_annotation(plot, text, amres)

   text2=gsn_create_text(wks, run_string, txres)
   run_annotation=gsn_add_annotation(plot, text2, amres2)

   max_snow=sprintf("%3.1f", max(change_snow(time_i,:,:)) )
   min_snow=sprintf("%3.1f", min(change_snow(time_i,:,:)) )

   text3=gsn_create_text(wks, "max = "+max_snow+" cm | min = "+min_snow+" cm", txres)
   extremes_annotation=gsn_add_annotation(plot, text3, amres3)

   id=gsn_add_shapefile_polylines(wks,plot,"/home/mpim/m300382/shapefiles/ITA_adm_shp/ITA_adm1.shp",True)

   overlay(plot, over)
   draw(plot)
   frame(wks)
end do
end
