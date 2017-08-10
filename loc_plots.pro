pro loc_plots

; ==== Load data ====
DIR = '/home/somurray/Dropbox/lowcat/results/'


restore, DIR+ 'lowcat.sav'

; ==== Set up ====
!p.charthick = 4
!p.thick = 4
;!p.symthick = 4
!p.charsize = 1
;!p.ythick=4
;!p.xthick=4
loadct,39
set_plot,'ps'


; ==== CME plots ====

ind = where(outstr.cor2_pa le 0.)
outstr[ind].cor2_pa= !Values.F_NAN
hi_pa = (outstr.hi_pan+outstr.hi_pas)/2


; ==== Flare plots ====
; ---- flare location ----
latlon = fltarr(2, n_elements(outstr.fl_loc))
for i = 0, n_elements(outstr.fl_loc) - 1 do begin
  latlon(*, i) = locstring2int(location = outstr[i].fl_loc)
endfor
ind=where(finite(latlon(0,*)) eq 1.)

lat=latlon(0,ind)
lon=latlon(1,ind)

latlon = fltarr(2, n_elements(lat))
latlon(0,*) = lat
latlon(1,*) = lon

mkviridis
val = abs(anytim(outstr[ind].fl_ts))
colors_s = bytscl(val, /nan, min=min(val), max=max(val))

draw_grid, latlon=latlon, symsize=0.5, thick=2.0, color=500
device, file = DIR + 'flareloc.eps', $
        /encapsulated, color = 1, bits_per_pixel = 8
draw_grid_jg, latlon=latlon, color=1, symsize=1, thick=2.0, scolors=colors_s
device,/close

device, file = DIR + 'flarelocbar.eps', $
        /encapsulated, color = 1, bits_per_pixel = 8
colorbar,yrange=[min(colors_s),max(colors_s)],divisions=2,/vertical,/right,$
        position=[0.6,0.1,0.65,0.8],ticknames=['!6 2007-05-17','!6 2012-07-27','!6 2016-12-07']
device,/close

loadct, 39

; ---- AR location -----
;first srs_loc
latlon = fltarr(2, n_elements(outstr.srs_loc))
for i = 0, n_elements(outstr.srs_loc) - 1 do begin
  latlon(*, i) = locstring2int(location = outstr[i].srs_loc)
endfor
ind=where(finite(latlon(0,*)) eq 1.)
lat=latlon(0,ind)
lon=latlon(1,ind)
latlon = fltarr(2, n_elements(lat))
latlon(0,*) = lat
latlon(1,*) = lon
mkviridis
val = abs(anytim(outstr[ind].fl_ts))
colors_s = bytscl(val, /nan, min=min(val), max=max(val))
;draw_grid, latlon=latlon, symsize=0.5, thick=2.0, color=500
device, file = DIR + 'srsloc.eps', $
        /encapsulated, color = 1, bits_per_pixel = 8
draw_grid_jg, latlon=latlon, color=1, symsize=1, thick=2.0, scolors=colors_s
device,/close


;then smart_hglatlon
latlon = fltarr(2, n_elements(outstr.smart_hglatlon))
for i = 0, n_elements(outstr.smart_hglatlon) - 1 do begin
  latlon(*, i) = locstring2int(location = outstr[i].smart_hglatlon)
endfor
ind=where(finite(latlon(0,*)) eq 1.)
lat=latlon(0,ind)
lon=latlon(1,ind)
latlon = fltarr(2, n_elements(lat))
latlon(0,*) = lat
latlon(1,*) = lon
mkviridis
val = abs(anytim(outstr[ind].fl_ts))
colors_s = bytscl(val, /nan, min=min(val), max=max(val))
;draw_grid, latlon=latlon, symsize=0.5, thick=2.0, color=500
device, file = DIR + 'smartloc.eps', $
        /encapsulated, color = 1, bits_per_pixel = 8
draw_grid_jg, latlon=latlon, color=1, symsize=1, thick=2.0, scolors=colors_s
device,/close



end