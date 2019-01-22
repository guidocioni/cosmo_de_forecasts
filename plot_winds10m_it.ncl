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

fils = systemfunc ("ls "+folder+"cosmo-d2_single-level_PMSL*") ; file paths
f_pres    = addfiles (fils, "r")  
ListSetType (f_pres, "cat")

fils = systemfunc ("ls "+folder+"cosmo-d2_single-level_VMAX_10M*") ; file paths
f_vmax    = addfiles (fils, "r")  
ListSetType (f_vmax, "cat")

fils = systemfunc ("ls "+folder+"cosmo-d2_single-level_U_10M*") ; file paths
f_u10m    = addfiles (fils, "r")  
ListSetType (f_u10m, "cat")

fils = systemfunc ("ls "+folder+"cosmo-d2_single-level_V_10M*") ; file paths
f_v10m    = addfiles (fils, "r")  
ListSetType (f_v10m, "cat")


plot_description="MSLP (black contours, hPa); winds at 10m (vectors and intensity in colors, km/h)"

vmax_10m=f_vmax[:]->10fg3
u_10m=f_u10m[:]->10u
v_10m=f_v10m[:]->10v
mslp=f_pres[:]->prmsl

time= f_pres[:]->time

date_string=time
run_time=str_sub_str(time@units,"hours since ","")
run_string="Run: "+run_time

delete([/fils, f_pres/])

; conversion 
mslp = mslp/100.
vmax_10m=vmax_10m*3.6

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
;ResC@cnFillMode = "rasterfill"
;ResC@gsnSpreadColors=True
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
ResC@mpNationalLineThicknessF = 2     
ResC@tmXBLabelFontHeightF = 0.01
ResC@pmTickMarkDisplayMode = True

ResC2@cnLevelSelectionMode = "ManualLevels"
ResC2@cnMinLevelValF = round(min(mslp), 0)
ResC2@cnMaxLevelValF = round(max(mslp), 0)
ResC2@cnInfoLabelOn = False  
ResC2@cnLevelSpacingF = 3
ResC2@cnLineThicknessF = 4
ResC2@cnLineColor = "black"
ResC2@cnLineLabelFontHeightF = 0.005

ResC@cnFillPalette = "wind_17lev"
ResC@cnLevelSelectionMode = "ManualLevels"
ResC@cnMinLevelValF = 15
ResC@cnMaxLevelValF = 115 
ResC@cnLevelSpacingF = 5
ResC@lbOrientation = "Vertical"
ResC@pmLabelBarWidthF = 0.05
ResC@gsnLeftString = "COSMO-D2"
ResC@gsnRightString = "Copyright DWD"

ResV@vcRefMagnitudeF           = 10             ; define vector ref mag
ResV@vcRefLengthF              = 0.045           ; define length of vec ref
ResV@vcMinDistanceF            = 0.015
ResV@vcRefAnnoOn = False 
ResV@vcGlyphStyle            = "CurlyVector"     ; turn on curly vectors
ResV@vcLineArrowColor        = "grey40"           ; change vector color
ResV@vcLineArrowThicknessF   = 1.0               ; change vector thickness

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
 wks = gsn_open_wks(wkstype,folder_output+"winds10m_"+date_string(time_i))
 
 plot = gsn_csm_contour_map(wks,vmax_10m(time_i,0,:,:),ResC)
 over = gsn_csm_contour(wks,mslp(time_i,:,:),ResC2)
 over_vector=gsn_csm_vector(wks, u_10m(time_i,0,:,:), v_10m(time_i,0,:,:), ResV)

 text=gsn_create_text(wks, plot_description, txres)
 description=gsn_add_annotation(plot, text, amres)

 text2=gsn_create_text(wks, run_string, txres)
 run_annotation=gsn_add_annotation(plot, text2, amres2)

 id=gsn_add_shapefile_polylines(wks,plot,"/home/mpim/m300382/shapefiles/ITA_adm_shp/ITA_adm1.shp",True)

 overlay(plot, over)
 overlay(plot,over_vector)
 draw(plot)
 frame(wks)
end do
end
