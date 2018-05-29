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

fils = systemfunc ("ls "+folder+"cosmo-d2_single-level_PMSL*") ; file paths
f_pres    = addfiles (fils, "r")  
ListSetType (f_pres, "cat")

fils = systemfunc ("ls "+folder+"cosmo-d2_germany_pressure-level_*") ; file paths
f_temp    = addfiles (fils, "r")  
ListSetType (f_temp, "cat")

plot_description="MSLP (white contours) and temperature at 850hPa (colors)"

mslp=f_pres[:]->prmsl 
temp=f_temp[:]->t

lev=850*100.

lon = f_pres[:]->lon 
lat = f_pres[:]->lat
time= f_pres[:]->time 

date_string=time
run_time=str_sub_str(time@units,"hours since ","")
run_string="Run: "+run_time

delete([/fils, f_pres, f_temp/])

; conversion 

mslp = mslp/100.
temp=temp-273.15
temp_850=temp(:,{lev},:,:)

mslp@lat2d=lat 
mslp@lon2d=lon
temp_850@lat2d=lat 
temp_850@lon2d=lon

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
ResC2@cnLineLabelFontHeightF= 0.01
ResC@cnFillOn = True ; do color fill
; ResC@cnFillMode = "rasterfill"
;ResC@gsnSpreadColors=True
ResC@cnLinesOn=False

ResC@mpFillOn     = False
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
ResC2@cnLevelSelectionMode = "ManualLevels"
ResC2@cnMinLevelValF = round(min(mslp), 0)
ResC2@cnMaxLevelValF = round(max(mslp), 0) 
ResC2@cnLevelSpacingF = 2
ResC2@cnLineThicknessF = 3
ResC2@cnLineColor = "white"
ResC2@cnLineLabelFontHeightF = 0.005
ResC2@cnInfoLabelOn = False 
ResC2@cnLowLabelsOn = True
ResC2@cnLowLabelBackgroundColor = -1

ResC@lbOrientation = "Vertical"
ResC@pmLabelBarWidthF = 0.05
ResC@gsnLeftString = "COSMO-D2"
ResC@gsnRightString = "Copyright DWD"

ResC@cnFillPalette = "BkBlAqGrYeOrReViWh200"
ResC@cnLevelSelectionMode = "ManualLevels"
ResC@cnMinLevelValF = -10
ResC@cnMaxLevelValF = 25 
ResC@cnLevelSpacingF = 1

txres                       = True
txres@txPerimOn             = True
txres@txBackgroundFillColor = "White"
txres@txFontHeightF         = 0.015

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
   wks = gsn_open_wks(wkstype,folder_output+"t850_pres_"+date_string(time_i))

   plot = gsn_csm_contour_map(wks,temp_850(time_i,:,:),ResC)
   over = gsn_csm_contour(wks,mslp(time_i,:,:),ResC2)
   text=gsn_create_text(wks, plot_description, txres)
   description=gsn_add_annotation(plot, text, amres)

   text2=gsn_create_text(wks, run_string, txres)
   run_annotation=gsn_add_annotation(plot, text2, amres2)

   id=gsn_add_shapefile_polylines(wks,plot,"/home/mpim/m300382/shapefiles/DEU_adm_shp/DEU_adm1.shp",True)

   overlay(plot, over)
   draw(plot)
   frame(wks)
end do
end
