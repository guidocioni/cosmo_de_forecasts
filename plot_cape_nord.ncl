load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"

begin
; Open model level output file

wkstype="png"
wkstype@wkWidth = 900
wkstype@wkHeight = 900

if .not. isvar("min_lon") then 
 min_lon=4 
end if 
if .not. isvar("max_lon") then 
 max_lon=12 
end if 
if .not. isvar("min_lat") then 
 min_lat=50 
end if
if .not. isvar("max_lat") then 
 max_lat=56 
end if
if .not. isvar("folder_output") then 
 folder_output="./nord/" 
end if

folder="/scratch/local1/m300382/cosmo_de_forecasts/"
 
fils = systemfunc ("ls "+folder+"cosmo-d2_single-level_CAPE_ML*") ; file paths
f_cape    = addfiles (fils, "r")  
ListSetType (f_cape, "cat")

fils = systemfunc ("ls "+folder+"cosmo-d2_single-level_CIN_ML*") ; file paths
f_cin    = addfiles (fils, "r")  
ListSetType (f_cin, "cat")

fils = systemfunc ("ls "+folder+"cosmo-d2_germany_pressure-level_*") ; file paths
f_u    = addfiles (fils, "r")  
ListSetType (f_u, "cat")

plot_description="CAPE (colors) and CIN (blue contours only 100 J/kg isoline); winds at 500 hPa (red barbs) and 850 hPa (black barbs)"

lev1=850.*100.
lev2=500.*100.

cape=f_cape[:]->CAPE_ML 
cin=f_cin[:]->CIN_ML
u=f_u[:]->u
v=f_u[:]->v

lon = f_cape[:]->lon 
lat = f_cape[:]->lat
time= f_cape[:]->time 

cape@lat2d=lat 
cape@lon2d=lon
cin@lat2d=lat 
cin@lon2d=lon
u@lat2d=lat 
u@lon2d=lon
v@lat2d=lat 
v@lon2d=lon

date_string=time
run_time=str_sub_str(time@units,"hours since ","")
run_string="Run: "+run_time

delete([/fils, f_cape, f_cin/])

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
ResV=ResC

ResC@cnFillOn = True ; do color fill
;ResC@cnFillMode = "rasterfill"
ResC@cnLinesOn=False
ResC2@cnFillOn = False 
ResC2@cnLinesOn=True

ResC@mpFillOn     = False
ResC@mpOutlineOn  = True
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
ResC@cnMinLevelValF = 200
ResC@cnMaxLevelValF = 2000 
ResC@cnLevelSpacingF = 50

cmap_r              = read_colormap_file("WhBlGrYeRe")
; cmap_r              = read_colormap_file("MPL_YlOrRd")
cmap_r(0:10,3)         = 0.0    ; Fully transparent
ResC@cnFillPalette = cmap_r

ResC@lbOrientation = "Vertical"
ResC@pmLabelBarWidthF = 0.05
ResC@gsnLeftString = "COSMO-D2"
ResC@gsnRightString = "Copyright DWD"

ResC2@cnLevelSelectionMode = "ExplicitLevels"
ResC2@cnLevels = (/100/)
ResC2@cnLineLabelsOn = False
ResC2@cnInfoLabelOn = False
ResC2@cnLineThicknessF = 2
ResC2@cnLineColor = "blue" 

ResV@gsnLeftString = ""
ResV@gsnRightString = ""
ResV@vcRefMagnitudeF           = 5             ; define vector ref mag
ResV@vcRefLengthF              = 0.015           ; define length of vec ref
ResV@vcMinDistanceF            = 0.02
ResV@vcRefAnnoOn               = False 
ResV@vcGlyphStyle              = "WindBarb"     
ResV@vcWindBarbLineThicknessF = 2.0               ; change vector thickness

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
   wks = gsn_open_wks(wkstype,folder_output+"cape_cin_"+date_string(time_i))

   plot = gsn_csm_contour_map(wks,cape(time_i,0,:,:),ResC)
   over = gsn_csm_contour(wks, cin(time_i,0,:,:), ResC2)
   ResV@vcWindBarbColor          = "red"           ; change vector color
   over_vector=gsn_csm_vector(wks, u(time_i,{lev2},:,:), v(time_i,{lev2},:,:), ResV)
   ResV@vcWindBarbColor          = "black"           ; change vector color
   over_vector_2=gsn_csm_vector(wks, u(time_i,{lev1},:,:), v(time_i,{lev1},:,:), ResV)

   text=gsn_create_text(wks, plot_description, txres)
   description=gsn_add_annotation(plot, text, amres)

   text2=gsn_create_text(wks, run_string, txres)
   run_annotation=gsn_add_annotation(plot, text2, amres2)

   id=gsn_add_shapefile_polylines(wks,plot,"/home/mpim/m300382/shapefiles/DEU_adm_shp/DEU_adm1.shp",True)

   overlay(plot,over)
   overlay(plot,over_vector)
   overlay(plot,over_vector_2)

   draw(plot)
   frame(wks)
end do
end
