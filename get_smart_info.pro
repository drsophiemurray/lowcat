;+
; IDL Version:				8.5 (linux x86_64 m64)
; Journal File for:		somurray@lindau
; Working directory:	/home/somurray/Dropbox/helcats_project/helcats.git
; Date:								Wed Jun 16 11:55:32 2016
; Purpose:						- Given a time, get the corresponding magnetogram
; 											(MDI or HMI line of sight) and then run SMART
; 											to obtain magnetic properties of chosen region.
; 										- SMART code originally developed by Paul Higgins is used
; 											to determine the properties once identified (see
; 											https://github.com/pohuigin/smart_library)	
; 										- Note created specifically to run some events
; 											not obtained with kincat_ar_properties.
; Input:							Expecting time strings of form 'YYYY-MM-DD HH:MM:SS' 
; 										that are the start, end, and peak of the event.
; Output:							Magnetic and polarity separation line properties
; 										printed onto screen, image of region saved as eps.
; Note:								I've defined ARs near limb as >60 = II, >70 = III, > 80 = IV

function get_smart_info, start_time=start_time, end_time=end_time, peak_time=peak_time, hgx=hgx, hgy=hgy, hcx=hcx, hcy=hcy

	; ---- Global settings ----
	COMMON FOLDERS

	; Set up structure of properties that are wanted
	arstr = {smart_time:' ', smart_hglatlon:' ', lsmart_imb:' ', $
						smart_totflx:0., smart_posflx:0., smart_negflx:0., smart_frcflx:0d, $
						smart_totarea:0., smart_posarea:0., smart_negarea:0., $
						smart_bmin:0., smart_bmax:0., smart_bmean:0., $
						smart_psllen:0., smart_rvalue:0., smart_wlsg:0., smart_bipolesep:0.}

	; If no locations given, then dont bother running below code
	if finite(hgx) eq 0. or finite(hgy) eq 0. then return, arstr
	if start_time eq ' ' then return, arstr

	; ---- Get magnetogram ----
	catch, jsoc_error
	if jsoc_error ne 0. then begin 
		catch, cancel
		print, 'Issue with jsoc search for flare event ', anytim(peak_time, /vms)
		return, arstr
	endif

	; Download from MDI or HMI depending on date
	if anytim(peak_time) le anytim('2010-04-01') then begin
		print, 'Magnetogram selected: ', anytim(peak_time, /vms), ' MDI'
		meta = vso_search(anytim(peak_time, /vms), inst='mdi', $
											physobs='los_magnetic_field', extent='fulldisk', $
											/flat, /url, count=count)
		if count eq 0. then return, arstr
		ind = closest(anytim(meta.time_start), peak_time)
		out = vso_get(meta[ind], out_dir=DATA_FOLDER+'mdi/', filenames=fname) 

	endif else begin
		; Searching JSOC seems to be a bit bugging so adding some error handling here
		catch, jsoc_error
		if jsoc_error ne 0. then begin 
			catch, cancel
			print, 'Issue with JSOC search for event starting at ', anytim(start_time, /vms)
			return, arstr
		endif

		ssw_jsoc_time2data, start_time, end_time, index, data, $
												ds = 'hmi.M_720s', max_files = 1, $
												outdir_top = DATA_FOLDER + 'hmi/', count = count ;locfiles=locfiles;hmi.M_720s_nrt
		if n_elements(data) eq 0. then return, arstr
		fname = DATA_FOLDER + 'hmi/' + 'HMI' + time2file(index.date_obs, /sec) + '_6173.fits'
		print, fname
	endelse

	; ---- Set up SMART ----
	fparam = SMART_FOLDER + 'ar_param_hmi.txt'   ; settings can be edited
	params = ar_loadparam(fparam = fparam)
	thismap = ar_readmag(fname, outindex = indhmi) 
	; If data not 1024 x 1024 then compress for quicker analysis
	if (size(thismap.data))[1] EQ 4096. then thismap = map_rebin(thismap, /rebin1k) 
    
	; Turn on median filtering due to the noise...  
	params.DOMEDIANFILT = 0
	params.DOCOSMICRAY = 0
  
	; Process magnetogram
	magproc = ar_processmag(thismap, cosmap=cosmap, limbmask=limbmask, $
													params = params, /nofilter, /nocosmicray)
	; Create AR masks - will use core detections
	thissm = ar_detect(magproc, params=params, status=smartstatus, $
											cosmap=cosmap, limbmask=limbmask)
	thisar = ar_detect_core(magproc, smartmask=thissm.data, $
													cosmap=cosmap, limbmask=limbmask, pslmaskmap=pslmap, $
													params=params, doplot=debug, $
													status=corestatus)             
	thismask = ar_core2mask(thisar.data, smartmask=coresmblob, $
													coresmartmask=coresmblob_conn)

; --- Get properties ----
	; Grab position information
	posprop = ar_posprop(map=magproc, mask=thismask, $
												cosmap=cosmap, params=params, $
												outpos=outpos, outneg=outneg, $
												/nosigned, status=posstatus, $
												datafile=thisdatafile)    

	; Now calculate magnetic properties 
	magprop = ar_magprop(map=magproc, mask=thismask, cosmap=cosmap, $
												params=params, fparam=fparam, $
												datafile=thisdatafile, status=magstatus)

	; Get PSL stuff, e.g., R value and total gradient along PSL
	pslprop = ar_pslprop(magproc, thismask, fparam=fparam, param=params, $
												doproj=1,  projmaxscale=1024);, outpslmask = outpslmask)

	; ---- Choose region ----
	; Find the closest SMART region to the flare location
	; First convert the flare location to time of SMART
	hc2hg, hcx, hcy, flare_hgx, flare_hgy, date = peak_time, rotdate = thismap.time
  
	; Convert minima and maxima from pixels to lat/lon
	ar_hgxmin = fltarr(n_elements(posprop))
	ar_hgymin = fltarr(n_elements(posprop))
	ar_hgxmax = fltarr(n_elements(posprop))
	ar_hgymax = fltarr(n_elements(posprop))
  
	for i = 0, n_elements(posprop)-1 do begin
		px2hc, posprop[i].xminbnd, posprop[i].yminbnd, hcxmin, hcymin, $
						dx = thismap.dx, dy = thismap.dy, xc = thismap.xc, yc = thismap.yc, $
						xs = (size(thismap.data, /dim))[0], ys = (size(thismap.data, /dim))[0]
		hc2hg, hcxmin, hcymin, hgxmin, hgymin, carxbnd, $
						date = thismap.time, rsunarcsec = thismap.rsun
		ar_hgxmin[i] = hgxmin
		ar_hgymin[i] = hgymin
    
		px2hc, posprop[i].xmaxbnd, posprop[i].ymaxbnd, hcxmax, hcymax, $
						dx = thismap.dx, dy = thismap.dy, xc = thismap.xc, yc = thismap.yc, $
						xs = (size(thismap.data, /dim))[0], ys = (size(thismap.data, /dim))[0]
		hc2hg, hcxmax, hcymax, hgxmax, hgymax, carxbnd, $
						date = thismap.time, rsunarcsec = thismap.rsun
		ar_hgxmax[i] = hgxmax
		ar_hgymax[i] = hgymax
	endfor
  
	; Find closest lat/lon
	closest_hgx = closest(posprop.hglonbnd, flare_hgx)
	closest_hgy = closest(posprop.hglatbnd, flare_hgy)
;   arno = where((flare_hgx ge ar_hgxmin) and (flare_hgx le ar_hgxmax) and (flare_hgy ge ar_hgymin) and (flare_hgy le ar_hgymax))
	arno = -1
	if (flare_hgx ge ar_hgxmin[closest_hgy]) and (flare_hgx le ar_hgxmax[closest_hgy]) and (flare_hgy ge ar_hgymin[closest_hgy]) and (flare_hgy le ar_hgymax[closest_hgy]) then begin
		arno = closest_hgy
	endif
	if (arno eq -1) then begin
		if (flare_hgx ge ar_hgxmin[closest_hgx]) and (flare_hgx le ar_hgxmax[closest_hgx]) and (flare_hgy ge ar_hgymin[closest_hgx]) and (flare_hgy le ar_hgymax[closest_hgx]) then begin
			arno = closest_hgx
		endif
	endif

	; Exit code if no region identified
	if arno eq -1 then begin
		return, arstr
;     ; Manual selection if nothing fits the coordinates 
;     closelat = closest(posprop.hglatbnd, lat)
;     closelon = closest(posprop.hglonbnd, lon)
;     print, "Closest lat is ", posprop[closelat].arid, " (", lat, ")"
;     print, "Closest lon is ", posprop[closelon].arid, " (", lon, ")"
;     print, "Check picture and type in region number to analyse"
; 
;     ; Plot regions to choose one
;     loadct, 0, /sil
;     setcolors, /sil, /sys
;     tmpmap = magproc 
;     tmpmap.data = rot(magproc.data, -magproc.roll_angle)     ;correct for rotation   
;     plot_map, tmpmap, dmin = -500, dmax = 500       
;     tmpar = thisar
;     tmpar.data = rot(tmpar.data, -magproc.roll_angle)
;     plot_map, tmpar, /over, color = !blue, thick = 2
; ;   plot_map, pslmap, /over, color = !cyan, thick = 1
;     plots, (posprop.hcxbnd), (posprop.hcybnd), ps = 4, color = !black, thick = 4
;     plots, (posprop.hcxbnd), (posprop.hcybnd), ps = 4, color = !red, thick = 1
;     xyouts, (posprop.hcxbnd), (posprop.hcybnd), posprop.arid, $
; 	    color = !black, charthick = 4, charsize = 3, alignment = 0.75
;     xyouts, (posprop.hcxbnd), (posprop.hcybnd), posprop.arid, $
; 	    color = !red, charthick = 1, charsize = 3, alignment = 0.75
; 
;     ; Define what active region you want based on what you just saw in the above plot!
;     response = 1.
;     read, response
;     arno = float(response) - 1.

	endif else begin
		print, "Most likely candidate is ", arno, ' (', fix(posprop[arno].hglatbnd), ',', fix(posprop[arno].hglonbnd), ')' 
		arlocstring = locint2string(latitude=posprop[arno].hglatbnd, longitude=posprop[arno].hglonbnd)
	endelse  
	    
	; ---- Save image ----
	set_plot, 'ps'
	!p.charsize = 2
	!p.charthick = 3
	device, file = OUT_FOLDER + thismap.time + '.eps', $
					/encapsulated, color = 1, bits_per_pixel = 8, $
					xsize = 40, ysize = 40
	loadct, 0, /sil
	setcolors, /sil, /sys
	tmpmap = thismap 
	tmpmap.data = rot(tmpmap.data, -thismap.roll_angle)	;correct for rotation   
	plot_map, tmpmap, dmin = -500, dmax = 500       
	tmpar = thisar
	tmpar.data = rot(tmpar.data, -thismap.roll_angle)
	plot_map, tmpar, /over, color = !blue, thick = 4
	;if you dont want to plot PIL comment out next two lines
; 	pslmap.data = rot(pslmap.data, -thismap.roll_angle)
; 	plot_map, pslmap, /over, color = !cyan, thick = 1
	plots, (posprop[arno].hcxbnd), (posprop[arno].hcybnd), ps = 4, color = !black, thick = 6
	plots, (posprop[arno].hcxbnd), (posprop[arno].hcybnd), ps = 4, color = !red, thick = 3
	xyouts, (posprop[arno].hcxbnd), (posprop[arno].hcybnd), posprop[arno].arid, $
						color = !black, charthick = 6, charsize = 3, alignment = 0.75
	xyouts, (posprop[arno].hcxbnd), (posprop[arno].hcybnd), posprop[arno].arid, $
						color = !red, charthick = 3, charsize = 3, alignment = 0.75
	device, /close
	loadct, 0
	set_plot,'x'

	; ---- Output results ----
	arstr.smart_time = thismap.time
	arstr.smart_hglatlon = arlocstring
	switch 1 of
		(fix(posprop[arno].hglonbnd) GE 60.) or (fix(posprop[arno].hglonbnd) LE -60.): arstr.smart_limb = 'II' 
		(fix(posprop[arno].hglonbnd) GE 70.) or (fix(posprop[arno].hglonbnd) LE -70.): arstr.smart_limb = 'III' 
		(fix(posprop[arno].hglonbnd) GE 80.) or (fix(posprop[arno].hglonbnd) LE -80.): arstr.smart_limb = 'IV' 
	endswitch
	arstr.smart_totflx = magprop[arno].totflx
	arstr.smart_posflx = magprop[arno].posflx
	arstr.smart_negflx = magprop[arno].negflx
	arstr.smart_frcflx = magprop[arno].frcflx	
	arstr.smart_totarea = magprop[arno].totarea / 3.
	arstr.smart_posarea = magprop[arno].posarea / 3.
	arstr.smart_negarea = magprop[arno].negarea / 3.
	arstr.smart_bmin = magprop[arno].bmin
	arstr.smart_bmax = magprop[arno].bmax
	arstr.smart_bmean = magprop[arno].bmean
	arstr.smart_psllen = pslprop[arno].psllength
	arstr.smart_rvalue = pslprop[arno].rvalue
	arstr.smart_wlsg = pslprop[arno].wlsg
	arstr.smart_bipolesep = pslprop[arno].bipolesep_mm

	; Print structure and output
	header = ['SMART time', 'Location', 'Limb', 'Total flux', 'Pos flux', 'Neg flux', 'Frac flux', 'Mag area', 'Pos area', 'Neg area', 'B_min', 'B_max', 'B mean', 'PSL length', 'R value', 'WLSG', 'Bip_sep']
	print, header, format = '((A20, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8))'
	print, arstr, format='((A20, 3X, A8, 3X, A8, 3X, E8.2, 3X, E8.2, 3X, E8.2, 3X, F8.4, 3X, F8.2, 3X, F8.2, 3X, F8.2, 3X, F8.2, 3X, F8.2, 3X, F8.2, 3X, F8.2, 3X, E8.2, 3X, E8.2, 3X, F8.2))'

	return, arstr
  
end