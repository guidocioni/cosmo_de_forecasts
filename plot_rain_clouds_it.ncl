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

fils = systemfunc ("ls "+folder+"cosmo-d2_single-level_RAIN_GSP_*_hourly.nc") ; file paths
f_rain    = addfiles (fils, "r")  
ListSetType (f_rain, "cat")

fils = systemfunc ("ls "+folder+"cosmo-d2_single-level_SNOW_GSP_*_hourly.nc") ; file paths
f_snow    = addfiles (fils, "r")  
ListSetType (f_snow, "cat")

fils = systemfunc ("ls "+folder+"cosmo-d2_single-level_CLCH*") ; file paths
f_clch    = addfiles (fils, "r")  
ListSetType (f_clch, "cat")

fils = systemfunc ("ls "+folder+"cosmo-d2_single-level_CLCL*") ; file paths
f_clcl    = addfiles (fils, "r")  
ListSetType (f_clcl, "cat")

plot_description="Low clouds (grey shadings), high clouds (red shadings) and hourly rain/snow"

tot_prec=f_rain[:]->RAIN_GSP
clcl=f_clcl[:]->CLCL(:,0,:,:)
clch=f_clch[:]->CLCH(:,0,:,:)
depth_snow=f_snow[:]->SNOW_GSP

lon = f_rain[:]->lon 
lat = f_rain[:]->lat
time= f_clch[:]->time 

date_string=toint(time)
run_time=str_sub_str(time@units,"hours since ","")
run_string="Run: "+run_time

delete([/fils, f_rain/])

rain = tot_prec 
rain = 0.0
delete(rain@units)

do i=1,dimsizes(time)-1
  rain(i,:,:)=tot_prec(i,:,:)-tot_prec(i-1,:,:) 
end do 

change_snow=depth_snow
change_snow=0

do i=1,dimsizes(time)-1
  change_snow(i,:,:)=depth_snow(i,:,:)-depth_snow(i-1,:,:)
end do 

; change_snow=mask(change_snow, change_snow .le. 0.5, False)

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
ResC@gsnStringFontHeightF=0.01
ResC@cnConstFLabelOn = False 

ResC@cnFillOn = True ; do color fill
; ResC@cnFillMode = "rasterfill"
ResC@cnLinesOn=False
ResC2=ResC
ResC3=ResC
ResC5=ResC

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
ResC@mpNationalLineThicknessF = 3
ResC@mpDataSetName         = "Earth..4"
; ResC@mpOutlineOn = True
ResC@tmXBLabelFontHeightF = 0.01
ResC@pmTickMarkDisplayMode = True

ResC@cnLevelSelectionMode = "ManualLevels"
ResC@cnMinLevelValF = 50
ResC@cnMaxLevelValF = 100 
ResC@cnLevelSpacingF = 10
ResC@lbLabelBarOn = False 
ResC@cnInfoLabelOn = False 
ResC@cnLineLabelsOn = False 

colors=(/"white","grey80","grey75","grey70","grey65","grey60","grey55"/)
rgb = span_named_colors(colors,False)
cmap_r              = rgb
; cmap_r(0,3)         = 0.0    ; Fully transparent
ResC@cnFillPalette = cmap_r

ResC2@cnLevelSelectionMode = "ExplicitLevels"
ResC2@cnLevels = (/1.75, 2.0, 2.25, 2.5, 5, 6, 7, 8, 9, 10, 12, 15, 20, 25, 30, 40, 50/)

cmap2_r              = read_colormap_file("precip2_17lev")
cmap2_r(0,:)=0.0
ResC2@cnFillPalette = cmap2_r

ResC2@lbOrientation = "Horizontal"
ResC2@pmLabelBarHeightF = 0.04
; ResC2@pmLabelBarWidthF = 0.15
ResC2@pmLabelBarOrthogonalPosF = 0.
ResC2@lbLabelFontHeightF = 0.005
ResC2@lbTitleOn = True 
ResC2@lbTitleString = "Rain [mm]"
ResC2@lbTitlePosition = "Right"
ResC2@lbTitleFontHeightF = 0.008
ResC2@lbTitleDirection = "Across"

ResC@gsnLeftString = "COSMO-D2"
ResC@gsnRightString = "Copyright DWD"

ResC3@cnLevelSelectionMode = "ManualLevels"
ResC3@cnMinLevelValF = 50
ResC3@cnMaxLevelValF = 100 
ResC3@cnLevelSpacingF = 10
ResC3@cnFillOpacityF = 0.5
ResC3@lbLabelBarOn = False 
ResC3@cnInfoLabelOn = False 
ResC3@cnLineLabelsOn = False

cmap3_r              = read_colormap_file("WhiteYellowOrangeRed")
cmap3_r(0,3)         = 0.0    ; Fully transparent
ResC3@cnFillPalette = cmap3_r

cmap5_r              = read_colormap_file("MPL_PuRd")
; cmap5_r(0,4)         = 0.2 
cmap5_r(20,3) = 0  
ResC5@cnFillPalette = cmap5_r(20:,:)
ResC5@pmLabelBarHeightF = 0.04
ResC5@lbLabelFontHeightF = 0.005
ResC5@pmLabelBarOrthogonalPosF = 0.05
ResC5@cnLevelSelectionMode = "ExplicitLevels"
ResC5@cnLevels = (/0.25, 0.5, 1, 1.5, 2, 2.5, 3, 4, 5, 10, 20/)
ResC5@lbTitleOn = True 
ResC5@lbTitleString = "Snow [cm]"
ResC5@lbTitlePosition = "Right"
ResC5@lbTitleFontHeightF = 0.008
ResC5@lbTitleDirection = "Across"

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

do time_i=1,dimsizes(time)-1
 ResC@gsnCenterString= "Forecast for "+cd_string(time(time_i), "%d %c. %Y")+" at "+cd_string(time(time_i), "%H:%M")+" UTC"
 wks = gsn_open_wks(wkstype,folder_output+"precip_clouds_"+date_string(time_i))

 plot = gsn_csm_contour_map(wks,clcl(time_i,:,:),ResC)
 over_clouds=gsn_csm_contour(wks,clch(time_i,:,:), ResC3)
 over=gsn_csm_contour(wks, rain(time_i,:,:), ResC2)
 over_snow=gsn_csm_contour(wks, change_snow(time_i,:,:), ResC5)


 text=gsn_create_text(wks, plot_description, txres)
 description=gsn_add_annotation(plot, text, amres)

 text2=gsn_create_text(wks, run_string, txres)
 run_annotation=gsn_add_annotation(plot, text2, amres2)

 id=gsn_add_shapefile_polylines(wks,plot,"/home/mpim/m300382/shapefiles/ITA_adm_shp/ITA_adm1.shp",True)

 overlay(plot,over_clouds)
 overlay(plot,over)
 overlay(plot,over_snow)

 draw(plot)

 frame(wks)
end do



end
