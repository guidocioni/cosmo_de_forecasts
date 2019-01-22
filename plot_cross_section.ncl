load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"

;***********************************************
begin
;***********************************************
 
folder="/scratch/local1/m300382/temp/cosmo/"

fils = systemfunc ("ls "+folder+"_T_*") ; file paths
f_t    = addfiles (fils, "r")  
ListSetType (f_t, "cat")

fils = systemfunc ("ls "+folder+"COSMODE_model_level_elements_U_*") ; file paths
f_u    = addfiles (fils, "r")  
ListSetType (f_u, "cat")

fils = systemfunc ("ls "+folder+"COSMODE_model_level_elements_W_*") ; file paths
f_w    = addfiles (fils, "r")  
ListSetType (f_w, "cat")

delete(fils)

fils = systemfunc ("ls "+folder+"COSMODE_single_level_elements_SNOW_GSP_*") ; file paths
f_snow    = addfiles (fils, "r")  
ListSetType (f_snow, "cat")

fils = systemfunc ("ls "+folder+"COSMODE_single_level_elements_RAIN_GSP_*") ; file paths
f_rain    = addfiles (fils, "r")  
ListSetType (f_rain, "cat")

fils = systemfunc ("ls "+folder+"COSMODE_single_level_elements_T_2M_*") ; file paths
f_t2m    = addfiles (fils, "r")  
ListSetType (f_t2m, "cat")

orography=addfile("/home/mpim/m300382/cosmo_de_forecasts/COSMO_DE_invariant.nc", "r")
oro=orography->HHL(0,:,:,:)

time= f_u[:]->time 


t=f_t[:]->t(:,::-1,:,:)
t=t-273.15
u=f_u[:]->u(:,::-1,:,:)
w=f_w[:]->wz(:,1:27,:,:)
w=w(:,::-1,:,:)*5.
t2m=f_t2m[:]->2t(:,0,:,:)
t2m=t2m-273.15

u=mask(u, u.lt.5 .and. u.gt.-5, False)

snow_acc=f_snow[:]->SNOW_GSP
rain_acc=f_rain[:]->RAIN_GSP

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

lon = f_u[:]->lon 
lat = f_u[:]->lat
time= f_u[:]->time 

indices_oro=ispan(0, 25, 1)+0.5
height=oro({indices_oro},:,:)
;************************************
; calculate great circle along transect
;************************************
  leftlat  =  55.425
  rightlat =  48.1

  leftlon  =  6.65
  rightlon =  12.125

  npts     =   200                    ; number of points in resulting transect

  dist     = gc_latlon(leftlat,leftlon,rightlat,rightlon,npts,2)
  points   = ispan(0,npts-1,1)*1.0 

;********************************
; interpolate data to great circle
;********************************
  trans_t   = linint2_points(lon,lat,t,True,dist@gclon,dist@gclat,2)
  trans_u   = linint2_points(lon,lat,u,True,dist@gclon,dist@gclat,2)
  trans_oro = linint2_points(lon,lat,height,True,dist@gclon,dist@gclat,2)
  trans_w   = linint2_points(lon,lat,w,True,dist@gclon,dist@gclat,2)

  trans_snow   = linint2_points(lon,lat,snow,True,dist@gclon,dist@gclat,2)
  trans_rain   = linint2_points(lon,lat,rain,True,dist@gclon,dist@gclat,2)
  trans_t2m   = linint2_points(lon,lat,t2m,True,dist@gclon,dist@gclat,2)

  oro_yaxis= dim_avg_n_Wrap(trans_oro, 1)/1000.

  copy_VarAtts(t,trans_t)          ; copy attributes
  copy_VarAtts(u,trans_u)          ; copy attributes

ind_levmax = 26
 
;-----------------------------------------------------------------------
  res2D = True                            ; Set basic resources 
  res2D@gsnDraw              = False      ; Don't draw individual plot.
  res2D@gsnFrame             = False      ; Don't advance frame.
  res2D@vpWidthF             = 0.70       ; width
  res2D@vpHeightF            = 0.40       ; height
  res2D@tmXBMode            = "Explicit"    ; explicitly label x-axis
  res2D@tmXBValues          = (/points(0),points(npts-1)/) ; points to label
  res2D@tmXBLabels          = (/leftlat +", "+leftlon,rightlat+", "+rightlon/)
  res2D@tmYLMode             = "Explicit"
  res2D@tmYLValues           = ispan(1, 26, 1)
  res2D@tmYLLabels           = round(oro_yaxis(::-1),0)
  res2D@tmYLLabelJust        = "CenterCenter"
  res2D@tmYLLabelFontHeightF = .001
  ; res2D@tiMainString    = 
  res2D@tiMainFontHeightF = 0.015
  res2D@gsnLeftString =  ""
  res2D@gsnRightString = ""

  tt_res = res2D
  tt_res@cnFillPalette ="NCV_jet" 
  tt_res@cnFillOn                 = True             ; turns on color fill
  tt_res@cnLevelSelectionMode     = "ManualLevels"   ; set levels manually
  tt_res@cnMinLevelValF           = -20.
  tt_res@cnMaxLevelValF           = 10.
  tt_res@cnLevelSpacingF          = 1.
  ; tt_res@cnLinesOn                = False
  tt_res@cnLineThicknessF = 0.01
  tt_res@gsnContourZeroLineThicknessF = 3
  tt_res@cnLineLabelsOn           = False
  tt_res@cnInfoLabelOn            = False
  ; tt_res@pmLabelBarDisplayMode    = "Always"         ; Add a label bar
  tt_res@lbLabelAutoStride        = True
  tt_res@lbPerimOn                = False
  tt_res@lbBoxLinesOn             = False
  tt_res@pmLabelBarWidthF         = 0.08
  tt_res@pmLabelBarHeightF        = 0.35
  tt_res@lbOrientation       = "vertical"   ; vertical label bar
  tt_res@pmLabelBarOrthogonalPosF = -0.04        ; move label bar closer to plot

  uv_res = res2D
  uv_res@vcRefAnnoOn      = False         ; turns off the ref vector
  uv_res@vcRefLengthF     = 0.015         ; set length of ref vector
  uv_res@vcMapDirection = False 
  uv_res@vcMinDistanceF    = 0.015
  uv_res@vcGlyphStyle     = "WindBarb"    ; turn on wind barbs
  uv_res@vcWindBarbLineThicknessF = 3
  uv_res@vcWindBarbColor = "grey60"


  ; clc_res=res2D
  ; clc_res@cnFillOn                 = False             ; turns on color fill
  ; clc_res@cnLevelSelectionMode     = "ManualLevels"   ; set levels manually
  ; clc_res@cnMinLevelValF           = 0.
  ; clc_res@cnMaxLevelValF           = 1.
  ; clc_res@cnLevelSpacingF          = 0.5
  ; clc_res@cnLinesOn                = True
  ; clc_res@cnLineLabelsOn           = False
  ; clc_res@cnInfoLabelOn            = False
  ; clc_res@cnLineThicknessF         = 2
  ; clc_res@cnLineColor              = "gray50"
 
;-----------------------------------------------------------------------

  res1D = True                            ; Set basic resources both will use
  res1D@vpWidthF          = 0.70          ; The Width of the plot box
  res1D@vpHeightF         = 0.15          ; The height of the plot box
  res1D@tmXTOn            = False         ; turn off the top tick marks
  res1D@xyLineThicknesses = 4             ; increase line thickness
  res1D@gsnDraw           = False         ; Don't draw individual plot.
  res1D@gsnFrame          = False         ; Don't advance frame.
  ; res1D@tiXAxisString     = "Hour"

  res_xy = res1D
  res_xy2 = res1D
  res_xy@trYMinF = 0.
  res_xy2@trYMinF = 0.
  res_xy@xyLineColor     = "blue"         ; set line color
  res_xy2@xyLineColor =    "purple"
  res_xy@tiYAxisString   = "Rain and snow"        ; set y-axis string
  res_xy@tmXBLabelsOn = False
  res_xy@tmYLLabelsOn = False
  res_xy@tmYRLabelsOn = True

  t2_res = res1D
  t2_res@xyLineColor      = "black"        ; set line color
  t2_res@tiYAxisString   = "2m temp"        ; set y-axis string
  t2_res@tiYAxisSide  = "Right"

;-----------------------------------------------------------------------

; do time_i=0,dimsizes(time)-1
do time_i=3,3
    wks = gsn_open_wks("x11§","cross_section_21_"+time_i)    ; open a workstation

  tt_res@tiMainString= "Forecast for "+cd_string(time(time_i), "%d %c. %Y")+" at "+cd_string(time(time_i), "%H:%M")+" UTC"
  ttfill    = gsn_csm_contour(wks,trans_t(time_i,0:ind_levmax,:),tt_res)
  windlayer = gsn_csm_vector(wks,trans_u(time_i,0:ind_levmax,:),trans_w(time_i,0:ind_levmax,:),uv_res)
  overlay(ttfill,windlayer)

  slp_plot  = gsn_csm_xy2(wks,points,trans_rain(time_i,:),trans_snow(time_i,:),res_xy,res_xy2)
  t2_plot  = gsn_csm_xy(wks,points,trans_t2m(time_i,:),t2_res)

  res1                     = True
  res2                     = True
  res1@gsnMaximize         = True
  res2@gsnAttachPlotsXAxis = True

  amid = gsn_attach_plots(ttfill,(/slp_plot, t2_plot/),res1,res2)

  draw(ttfill)
  frame(wks)                            ; now frame the plot   

end do 

;-----------------------------------------------------------------------

 end
