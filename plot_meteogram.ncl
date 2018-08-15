load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

; These variables are provided outside when the script is called 
if .not. isvar("lat_point") then 
 lat_point=53.550556 
end if 
if .not. isvar("lon_point") then 
 lon_point=9.993333 
end if 
if .not. isvar("city") then 
 city="Hamburg" 
end if

;***********************************************
begin
;***********************************************
folder="/scratch/local1/m300382/cosmo_de_forecasts/"

fils:= systemfunc ("ls "+folder+"cosmo-d2_germany_pressure-level_*") ; file paths
f_in    = addfiles (fils, "r")  
ListSetType (f_in, "cat")

time= f_in[:]->time
temp=f_in[:]->t
temp=temp-273.15
u=f_in[:]->u
v=f_in[:]->v
rh=f_in[:]->r

fils := systemfunc ("ls "+folder+"cosmo-d2_single-level_SNOW_GSP_*_hourly.nc") ; file paths
f_snow    = addfiles (fils, "r")  
ListSetType (f_snow, "cat")
snow_acc=f_snow[:]->SNOW_GSP

fils := systemfunc ("ls "+folder+"cosmo-d2_single-level_RAIN_GSP_*_hourly.nc") ; file paths
f_rain    = addfiles (fils, "r")  
ListSetType (f_rain, "cat")
rain_acc=f_rain[:]->RAIN_GSP

fils:= systemfunc ("ls "+folder+"cosmo-d2_single-level_T_2M_*") ; file paths
f_t2m    = addfiles (fils, "r")  
ListSetType (f_t2m, "cat")
t2m=f_t2m[:]->2t 
t2m=t2m-273.15

fils:= systemfunc ("ls "+folder+"cosmo-d2_single-level_TD_2M_*") ; file paths
f_td2m    = addfiles (fils, "r")  
ListSetType (f_td2m, "cat")
dewp=f_td2m[:]->2d 
dewp=dewp-273.15

fils:= systemfunc ("ls "+folder+"cosmo-d2_single-level_PMSL_*") ; file paths
f_pmsl    = addfiles (fils, "r")  
ListSetType (f_pmsl, "cat")
mslp=f_pmsl[:]->prmsl
mslp=mslp/100.

fils = systemfunc ("ls "+folder+"cosmo-d2_single-level_VMAX_10M*") ; file paths
f_vmax    = addfiles (fils, "r")  
ListSetType (f_vmax, "cat")
gust=f_vmax[:]->10fg3
gust=gust*3.6

u&plev=u&plev/100.
v&plev=v&plev/100.
temp&plev=temp&plev/100.
rh&plev=rh&plev/100.

run_time=str_sub_str(time@units,"hours since ","")
run_string="Run: "+run_time

rain=rain_acc
rain=rain*0.
snow=snow_acc
snow=snow*0.
do i=1,dimsizes(time)-1
  rain(i,:,:)=rain_acc(i,:,:)-rain_acc(i-1,:,:) 
end do 
do i=1,dimsizes(time)-1
  snow(i,:,:)=snow_acc(i,:,:)-snow_acc(i-1,:,:) 
end do 

; Select the data at the point 
temp_point_test=temp(:,:,{lat_point},{lon_point})
temp_point=temp_point_test(plev|:,time|:)
delete(temp_point_test)
u_point_test=u(:,:,{lat_point},{lon_point})
u_point=u_point_test(plev|:,time|:)
delete(u_point_test)
v_point_test=v(:,:,{lat_point},{lon_point})
v_point=v_point_test(plev|:,time|:)
delete(v_point_test)
rh_point_test=rh(:,:,{lat_point},{lon_point})
rh_point=rh_point_test(plev|:,time|:)
delete(rh_point_test)

mslp_point=mslp(:,{lat_point},{lon_point})
gust_point=gust(:,0,{lat_point},{lon_point})
t2m_point=t2m(:,0,{lat_point},{lon_point})
dewp_point=dewp(:,0,{lat_point},{lon_point})
snow_point=snow(:,{lat_point},{lon_point})
rain_point=rain(:,{lat_point},{lon_point})
snow_acc_point=snow_acc(:,{lat_point},{lon_point})
rain_acc_point=rain_acc(:,{lat_point},{lon_point})

;-----------------------------------------------------------------------
res2D = True                            ; Set basic resources 
res2D@gsnDraw              = False      ; Don't draw individual plot.
res2D@gsnFrame             = False      ; Don't advance frame.
res2D@vpWidthF             = 0.70       ; width
res2D@vpHeightF            = 0.35       ; height

; res2D@tmYROn = False 
res2D@tmXBOn = False 
res2D@tiXAxisString = ""

res2D@gsnLeftString =  "COSMO-D2"
res2D@gsnRightString = "Copyright DWD"
res2D@gsnLeftStringFontHeightF = 0.01
res2D@gsnRightStringFontHeightF = 0.01
res2D@trYReverse = True
res2D@tiYAxisString = "pressure [hPa]"

tt_res = res2D
tt_res@tiMainFontHeightF =0.02
tt_res@cnFillPalette ="NCV_jet" 
tt_res@cnFillOn                 = True             ; turns on color fill
tt_res@cnLevelSelectionMode     = "ManualLevels"   ; set levels manually
tt_res@cnMinLevelValF           = -50.
tt_res@cnMaxLevelValF           = 25.
tt_res@cnLevelSpacingF          = 2.5
; tt_res@cnLinesOn                = False
tt_res@cnLineThicknessF = 0.005
tt_res@gsnContourZeroLineThicknessF = 3
tt_res@cnLineLabelsOn           = False
tt_res@cnInfoLabelOn            = False
; tt_res@pmLabelBarDisplayMode    = "Always"         ; Add a label bar
tt_res@tmYROn = False 

tt_res@lbOrientation = "Vertical"
tt_res@pmLabelBarWidthF = 0.08
tt_res@pmLabelBarHeightF = 0.35
tt_res@pmLabelBarOrthogonalPosF = -0.01
; tt_res@lbLabelPosition  = "Center"             ; label position
; tt_res@lbLabelAlignment = "BoxCenters"         ; label orientation
tt_res@lbLabelFontHeightF = 0.009
tt_res@lbTitleOn = True 
tt_res@lbTitleString = "[C]"
tt_res@lbTitlePosition = "Bottom"
tt_res@lbTitleFontHeightF = 0.008
tt_res@lbTitleDirection = "Across"
tt_res@lbOrientation = "Vertical"

uv_res = res2D
uv_res@vcRefAnnoOn      = False         ; turns off the ref vector
uv_res@vcRefLengthF     = 0.015         ; set length of ref vector
uv_res@vcMapDirection = False 
uv_res@vcMinDistanceF    = 0.015
uv_res@vcGlyphStyle     = "WindBarb"    ; turn on wind barbs
uv_res@vcWindBarbLineThicknessF = 4
uv_res@vcWindBarbColor = "grey60"

rh_res=res2D 
rh_res@cnFillOn=False 
rh_res@cnLinesOn = True 
rh_res@cnLevelSelectionMode = "ExplicitLevels"
rh_res@cnLevels = (/30, 50, 70, 100/)
rh_res@cnLineThicknessF = 3
rh_res@cnLineColor = "white"
rh_res@cnInfoLabelOn = False 
rh_res@cnLineLabelFontHeightF = 0.006

amres=True 
amres@amParallelPosF   = -0.25    ; This is the right edge of the plot.
amres@amOrthogonalPosF = -0.5    ; This is the bottom edge of the plot.
amres@amJust = "BottomLeft"

txres                       = True
txres@txPerimOn             = True
txres@txBackgroundFillColor = "White"
txres@txFontHeightF         = 0.01

;-----------------------------------------------------------------------

res1D = True                            ; Set basic resources both will use
res1D@vpWidthF          = 0.70          ; The Width of the plot box
res1D@vpHeightF         = 0.11          ; The height of the plot box
res1D@tmXTOn            = False         ; turn off the top tick marks
res1D@xyLineThicknessF = 4             ; increase line thickness
res1D@gsnDraw           = False         ; Don't draw individual plot.
res1D@gsnFrame          = False         ; Don't advance frame.
res1D@trXMinF = min(time)
res1D@trXMaxF = max(time)
res1D@tmYLLabelFontHeightF = 0.005

res_xy = res1D
res_xy@trYMinF = 0.
res_xy@xyLineColors     = (/"blue","purple"/)         ; set line color
res_xy@xyDashPattern = 0
res_xy@tiYAxisString   = "Rain/snow"        ; set y-axis string
res_xy@tmXBLabelsOn = False
res_xy@tmYLLabelsOn = True
res_xy@tmYRLabelsOn = False
res_xy@tmYLLabelDeltaF = .2
res_xy@tmYMajorGrid = True 
res_xy@tmYMajorGridThicknessF = 0.4

res_xy2 =res_xy
res_xy2@tmYLLabelsOn = False
res_xy2@tmYRLabelsOn = True
res_xy2@tiYAxisString   = ""
res_xy2@xyDashPattern = 1
res_xy2@xyLineThicknessF = 3 
res_xy2@tmYMajorGrid = False 

res_xy@pmLegendDisplayMode    = "Always"
res_xy@pmLegendSide           = "Bottom"               ; Change location of 
res_xy@pmLegendParallelPosF   = 0.5                 ; move units right
res_xy@pmLegendOrthogonalPosF = -0.95                ; move units down
res_xy@pmLegendWidthF         = 0.07                ; Change width and
res_xy@pmLegendHeightF        = 0.02                ; height of legend.
res_xy@lgLabelFontHeightF     = .007                 ; change font height
res_xy@lgPerimFill            = "SolidFill"      ; Fill legend box w/white
res_xy@lgPerimFillColor       = "white"          ; so it masks XY curves
res_xy@lgOrientation          = "vertical"
res_xy@lgPerimOn              = True               ; turn off box
res_xy@xyExplicitLegendLabels = (/"Rain [mm]","Snow [mm eq]"/)

t2_res = res1D
t2_res@vpHeightF         = 0.13          ; The height of the plot box
t2_res@xyLineColors      = (/"black","blue"/)        ; set line color
t2_res@tiYAxisString   = "2m Temp - T~B~D~N~ [C]"        ; set y-axis string
t2_res@tiYAxisSide  = "Right"
t2_res@tmXBLabelFontHeightF = 0.0005
t2_res@tmXBLabelAngleF = 90
t2_res@tmYMajorGrid = True 
t2_res@tmYMajorGridThicknessF = 0.4
t2_res@tmXBLabelDeltaF = 2.

slp_res = res1D
slp_res@tmYLLabelDeltaF = 3.0

wind_res= res1D
wind_res@xyLineColor = "red"
wind_res@tiYAxisString=""
wind_res@tmYRLabelFontColor = "red"
wind_res@tmYRMajorLineColor = "red"
wind_res@tmYRMinorLineColor = "red"
wind_res@tmYMajorGrid = True 
wind_res@tmYMajorGridThicknessF = 0.4
wind_res@tmYMajorGridLineColor = "red"
wind_res@tmYRLabelDeltaF = 2.

slp_res@xyLineColor      = "black"        ; set line color
slp_res@tiYAxisString   = "MSLP - winds [km/h]"        ; set y-axis string
slp_res@tiYAxisSide  = "Right"
slp_res@tiYAxisOffsetXF = 0.05

;-----------------------------------------------------------------------

wks = gsn_open_wks("png","meteogram_"+city)    ; open a workstation

tt_res@tiMainString= "Meteogram for "+city+" | "+run_string
ttfill    = gsn_csm_contour(wks,temp_point({1000:50},:),tt_res)
rhcont    = gsn_csm_contour(wks, rh_point, rh_res)
windlayer = gsn_csm_vector(wks,u_point({1000:50},:),v_point({1000:50},:),uv_res)

overlay(ttfill,windlayer)
overlay(ttfill,rhcont)

plot_description="Temperature, winds and cloud cover [%]"

text=gsn_create_text(wks, plot_description, txres)
description=gsn_add_annotation(windlayer, text, amres)

; Set special resources for the time axis
resTick                = True
resTick@ttmFormat      = "%d %c %H"
resTick@ttmMajorStride = 2
; Set resources necessary to customize Y axis labels
time_axis_labels( time,  t2_res, resTick )

rain_snow_plot  = gsn_csm_xy2(wks,time,(/rain_point, snow_point/),(/rain_acc_point, snow_acc_point/),res_xy,res_xy2)
mslp_wind_plot  = gsn_csm_xy2(wks, time, mslp_point, gust_point, slp_res, wind_res)

;obtain average of the plot 
avg_mslp=(max(mslp_point)+min(mslp_point))/2.

t2_plot         = gsn_csm_xy(wks,time,(/t2m_point,dewp_point/),t2_res)

res1                     = True
res2                     = True
res1@gsnMaximize         = True
res2@gsnAttachPlotsXAxis = True

amid = gsn_attach_plots(ttfill,(/rain_snow_plot, mslp_wind_plot, t2_plot/),res1,res2)

draw(ttfill)
frame(wks)                            ; now frame the plot   

end
