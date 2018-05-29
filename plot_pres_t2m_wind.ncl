load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"

begin
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

fils = systemfunc ("ls "+folder+"cosmo-d2_single-level_T_2M*") ; file paths
f_t2m    = addfiles (fils, "r")  
ListSetType (f_t2m, "cat")

fils = systemfunc ("ls "+folder+"cosmo-d2_single-level_U_10M*") ; file paths
f_u10m    = addfiles (fils, "r")  
ListSetType (f_u10m, "cat")

fils = systemfunc ("ls "+folder+"cosmo-d2_single-level_V_10M*") ; file paths
f_v10m    = addfiles (fils, "r")  
ListSetType (f_v10m, "cat")

plot_description="MSLP (white contours), temperature at 2m (colors) and winds at 10m (vectors)"

mslp=f_pres[:]->prmsl 
t_2m=f_t2m[:]->2t
u_10m=f_u10m[:]->10u
v_10m=f_v10m[:]->10v

lon = f_pres[:]->lon 
lat = f_pres[:]->lat
time= f_pres[:]->time 

date_string=time
run_time=str_sub_str(time@units,"hours since ","")
run_string="Run: "+run_time

delete([/fils, f_pres, f_t2m, f_u10m, f_v10m/])

; conversion 

mslp = mslp/100.
t_2m=t_2m-273.15

mslp@lat2d=lat 
mslp@lon2d=lon
t_2m@lat2d=lat 
t_2m@lon2d=lon
u_10m@lat2d=lat 
u_10m@lon2d=lon
v_10m@lat2d=lat 
v_10m@lon2d=lon

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
ResV=ResC
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
ResC@mpGeophysicalLineThicknessF = 5
ResC@mpGeophysicalLineColor ="black"
ResC@mpOutlineBoundarySets = "AllBoundaries"     ; more outlines
ResC@mpNationalLineThicknessF = 5
ResC@mpDataSetName         = "Earth..4"     
; ResC@mpOutlineOn = True
ResC@mpOutlineDrawOrder = "PostDraw"

ResC@tmXBLabelFontHeightF = 0.01
ResC@pmTickMarkDisplayMode = True
ResC2@cnLevelSelectionMode = "ManualLevels"
ResC2@cnMinLevelValF = round(min(mslp), 0)
ResC2@cnMaxLevelValF = round(max(mslp), 0) 
ResC2@cnLevelSpacingF = 3
ResC2@cnLineThicknessF = 4
ResC2@cnLineColor = "white"
ResC2@cnLineLabelFontHeightF = 0.005
ResC2@cnInfoLabelOn = False 
ResC2@cnLowLabelsOn = True
ResC2@cnLowLabelBackgroundColor = -1 

ResC@cnFillPalette = "BkBlAqGrYeOrReViWh200"
ResC@cnLevelSelectionMode = "ManualLevels"
ResC@cnMinLevelValF = -15
ResC@cnMaxLevelValF = 35
ResC@cnLevelSpacingF = 1

ResC@lbOrientation = "Vertical"
ResC@pmLabelBarWidthF = 0.05
ResC@gsnLeftString = "COSMO-D2"
ResC@gsnRightString = "Copyright DWD"

ResV@vcRefMagnitudeF           = 5             ; define vector ref mag
ResV@vcRefLengthF              = 0.045           ; define length of vec ref
ResV@vcMinDistanceF            = 0.015
ResV@vcGlyphStyle            = "CurlyVector"     ; turn on curly vectors
ResV@vcLineArrowColor        = "grey40"           ; change vector color
ResV@vcLineArrowThicknessF   = 1.5               ; change vector thickness
ResV@vcRefAnnoOn = False

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
   wks = gsn_open_wks(wkstype,folder_output+"t_v_pres_"+date_string(time_i))

   plot = gsn_csm_contour_map(wks,t_2m(time_i,0,:,:),ResC)
   over = gsn_csm_contour(wks,mslp(time_i,:,:),ResC2)
   over_vector=gsn_csm_vector(wks, u_10m(time_i,0,:,:), v_10m(time_i,0,:,:), ResV)

   text=gsn_create_text(wks, plot_description, txres)
   description=gsn_add_annotation(plot, text, amres)

   text2=gsn_create_text(wks, run_string, txres)
   run_annotation=gsn_add_annotation(plot, text2, amres2)

   id=gsn_add_shapefile_polylines(wks,plot,"/home/mpim/m300382/shapefiles/DEU_adm_shp/DEU_adm1.shp",True)

   overlay(plot,over_vector)
   overlay(plot, over)
   draw(plot)
   frame(wks)
end do
end
