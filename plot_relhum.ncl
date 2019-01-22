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

fils = systemfunc ("ls "+folder+"cosmo-d2_germany_pressure-level_*") ; file paths
f_in    = addfiles (fils, "r")  
ListSetType (f_in, "cat")

rh=f_in[:]->r
u=f_in[:]->u
v=f_in[:]->v
lon = f_in[:]->lon 
lat = f_in[:]->lat
time= f_in[:]->time 

date_string=time
run_time=str_sub_str(time@units,"hours since ","")
run_string="Run: "+run_time

levels=(/925, 850, 700, 500/)*100.

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

ResC@cnFillOn = True ; do color fill
ResC@cnFillMode = "rasterfill"
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
ResC@mpNationalLineThicknessF = 2
ResC@mpDataSetName         = "Earth..4"     
; ResC@mpOutlineOn = True
ResC@tmXBLabelFontHeightF = 0.01
ResC@pmTickMarkDisplayMode = True

ResC@cnFillPalette = "rh_19lev"
ResC@cnLevelSelectionMode = "ManualLevels"
ResC@cnMinLevelValF = 0
ResC@cnMaxLevelValF = 100
ResC@cnLevelSpacingF = 5
ResC@lbOrientation = "Vertical"
ResC@pmLabelBarWidthF = 0.05
ResC@gsnLeftString = "COSMO-D2"
ResC@gsnRightString = "Copyright DWD"

ResV@gsnLeftString = ""
ResV@gsnRightString = ""
ResV@vcRefMagnitudeF           = 5             ; define vector ref mag
ResV@vcRefLengthF              = 0.015           ; define length of vec ref
ResV@vcMinDistanceF            = 0.018
ResV@vcRefAnnoOn               = False 
ResV@vcGlyphStyle              = "CurlyVector"     
ResV@vcWindBarbLineThicknessF = 2.0               ; change vector thickness
ResV@vcWindBarbColor = "grey60"

txres                       = True
txres@txPerimOn             = True
txres@txBackgroundFillColor = "White"
txres@txFontHeightF         = 0.013

amres=True 
amres@amParallelPosF   = -0.5    ; This is the right edge of the plot.
amres@amOrthogonalPosF = 0.5    ; This is the bottom edge of the plot.
amres@amJust = "BottomLeft"
amres2=True 
amres2@amParallelPosF   = -0.5    ; This is the right edge of the plot.
amres2@amOrthogonalPosF = -0.5    ; This is the bottom edge of the plot.
amres2@amJust = "TopLeft"

do j=0,dimsizes(levels)-1
   lev=levels(j)
   plot_description="Winds and relative humidity at "+lev/100.+" hPa"
   do time_i=0,dimsizes(time)-1
     ResC@gsnCenterString= "Forecast for "+cd_string(time(time_i), "%d %c. %Y")+" at "+cd_string(time(time_i), "%H:%M")+" UTC"
     wks = gsn_open_wks(wkstype,folder_output+"rh_"+lev/100.+"_"+date_string(time_i))

     plot = gsn_csm_contour_map(wks,rh(time_i,{lev},:,:),ResC)
     over_vector=gsn_csm_vector(wks, u(time_i,{lev},:,:), v(time_i,{lev},:,:), ResV)

     text=gsn_create_text(wks, plot_description, txres)
     description=gsn_add_annotation(plot, text, amres)
     text2=gsn_create_text(wks, run_string, txres)
     run_annotation=gsn_add_annotation(plot, text2, amres2)

     id=gsn_add_shapefile_polylines(wks,plot,"/home/mpim/m300382/shapefiles/DEU_adm_shp/DEU_adm1.shp",True)

     overlay(plot,over_vector)
     draw(plot)
     frame(wks)
  end do
end do 

end
