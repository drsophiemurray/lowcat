;+
; IDL Version:				8.5 (linux x86_64 m64)
; Journal File for:		somurray@lindau
; Working directory:	/home/somurray/Dropbox/helcats_project/helcats.git
; Date: 							Wed July 7 10:14:25 2016
; Purpose:						Given the CME event info, see if there are any
;											corresponding flare events and active regions.
; Input:							CME information, location.
; Output:							Flare and AR information.
; Uses:								Part of wider helcats_cme_flare_ar_list.pro
; Last Update:				2016-08-12 S Murray
; Note wanted to remove any polar events - 60deg is 840arcsec. 50 is 750. 40 is 625


function get_flarear_info, $
					cme_properties=cme_properties, cme_exist=cme_exist, $
					flare=flare, ar=ar, $
					hgx=hgx, hgy=hgy, hcx=hcx, hcy=hcy, $
					swpc_search=swpc_search, hessi_search=hessi_search
  
	; ---- Global settings ----
	COMMON FOLDERS
	; Template for loading NOAA Solar Region Summaries
	restore, IN_FOLDER + 'srs_template.sav'
	; The below speeds defined by P. Zucca based on Yurchyshyn et al
	; http://www.bbso.njit.edu/~vayur/CME_Speeds.html
	cme_min = 200. 
	cme_max = 800.
	r_sun = 695e3
	
	; Initial parameters
	flare_r = 0.5 * r_sun ; km
	cor2_r = 2. * r_sun ; km

	; Defining a latitude and longitude range to search for ARs correpsonding to flare location
	lat_range = 12.;10.
	lon_range = 12.;10.
	hcx_range = 200.;200.
	hcy_range = 150.;100.
  
	hcx = !Values.F_NAN
	hcy = !Values.F_NAN
	hgx = !Values.F_NAN
	hgy = !Values.F_NAN

	; Set up output structure
	outstr = {window_start:' ', window_end: ' ', $
						obstype:' ', $
						starttime: ' ', endtime: ' ', $
						peaktime: ' ', goes: ' ', flareloc: ' ', $
						srstime:' ', $
						no: 0., noaaloc: ' ' , $
						mcintosh: ' ', hale: ' ' , $
						area: 0., ll: 0., nn: 0.}

	; --------------------------------------------------------------------------------------------------------------------------------------------
	; =============================== 
	; ==== Get flare information ==== 
	; =============================== 

	; If a CME was identified use its time as the input, if not just use the original search window start time
	case cme_exist of
		0: cme_time = cme_properties.cor2_ts
		1: cme_time = cme_properties.cor2_time
	endcase
; 	cme_time = cme_properties.cor2_ts
  
	; Define search window to match flare event to CME
	flare_ts = anytim(cme_time) - ((cor2_r - flare_r) / cme_min) 
	flare_tf = anytim(cme_time) - ((cor2_r - flare_r) / cme_max)

; 	; Calculate error
; 	case cme_exist of
; 		0: flare_del = ssw_deltat(flare_ts, flare_tf, /minutes) * (10./500.)
; 		1: flare_del = ssw_deltat(flare_ts, flare_tf, /minutes) * (float(cme_properties.cor2_vsigma)/float(cme_properties.cor2_v))
; 	endcase
; 	; Redefine search window to include error
; 	window_start = anytim(addtime(anytim(flare_ts,/vms), delta_min = -flare_del))
; 	window_end = anytim(addtime(anytim(flare_tf,/vms), delta_min = flare_del))

	outstr.window_start = anytim(flare_ts, /vms)
	outstr.window_end = anytim(flare_tf, /vms)

	; --------------------------------------------------------------------------------------------------------------------------------------------
	; ==== Check solarsoft latest event list archive ====
	; Worth noting here that get_gevloc_data() gives you latest events rather than archive

	; Sometimes this search wont work if theres no events in the time range, so heres some error handling
	catch, ssw_error
	if ssw_error ne 0. then begin 
		catch, cancel
		print, 'Issue with ssw search for event ', anytim(cme_properties.hi_time, /vms)
		sswstr = 'nothing'
		flare = 0.
	endif

	flare = 0.
	sswstr = lmsalssw_search(window_start = outstr.window_start, window_end = outstr.window_end, $
													hi_pan = cme_properties.hi_pan, hi_pas = cme_properties.hi_pas, cor2_pa = cme_properties.cor2_pa, cor2_halo = cme_properties.cor2_halo, $
													flare = flare, cme_exist = cme_exist, $
													hcx_range = hcx_range, hcy_range = hcy_range)
	
	; Output this info
; 	if typename(sswstr) ne 'STRING' then begin
	if sswstr.starttime ne ' ' then begin
		outstr.obstype = sswstr.obstype
		outstr.starttime = sswstr.starttime
		outstr.endtime = sswstr.endtime
		outstr.peaktime = sswstr.peaktime
		outstr.goes = sswstr.goes
		outstr.flareloc = sswstr.flareloc
		flare = sswstr.flare
		hgx = sswstr.hgx
		hgy = sswstr.hgy
		hcx = sswstr.hcx
		hcy = sswstr.hcy
	endif
	
	; --------------------------------------------------------------------------------------------------------------------------------------------
	; ==== Check NOAA event list for anything there using Hong's code ====
	
	catch, swpc_error
	if swpc_error ne 0. then begin 
		catch, cancel
		print, 'Issue with swpc search for event ', anytim(cme_properties.hi_time, /vms)
		swpcstr = 'nothing'
		flare = 0.
	endif

	if keyword_set(swpc_search) and flare eq 0. then begin
			swpcstr = swpc_search_flares(window_start = outstr.window_start, window_end = outstr.window_end, $
																	hi_pan = cme_properties.hi_pan, hi_pas = cme_properties.hi_pas, cor2_pa = cme_properties.cor2_pa, cor2_halo = cme_properties.cor2_halo, $
																	flare = flare, cme_exist = cme_exist, $
																	hcx_range = hcx_range, hcy_range = hcy_range)
 
			; Output this info
			if typename(swpcstr) ne 'STRING' then begin
				outstr.obstype = swpcstr.obstype
				outstr.starttime = swpcstr.starttime
				outstr.endtime = swpcstr.endtime
				outstr.peaktime = swpcstr.peaktime
				outstr.goes = swpcstr.goes
				outstr.flareloc = swpcstr.flareloc
				outstr.no = swpcstr.no
				flare = swpcstr.flare
				hgx = swpcstr.hgx
				hgy = swpcstr.hgy
				hcx = swpcstr.hcx
				hcy = swpcstr.hcy
			endif

	endif else begin
		print, 'Skipping SWPC'
	endelse 
;  
	; --------------------------------------------------------------------------------------------------------------------------------------------
	; ==== Check HESSI list ====
	
	catch, hessi_error
	if hessi_error ne 0. then begin 
		catch, cancel
		print, 'Issue with hessi search for event ', anytim(cme_properties.hi_time, /vms)
		hessistr = 'nothing'
		flare = 0.
	endif

	if keyword_set(hessi_search) and flare eq 0. then begin
 		hessistr = hessi_search_flares(window_start = outstr.window_start, window_end = outstr.window_end, $
																	hi_pan = cme_properties.hi_pan, hi_pas = cme_properties.hi_pas, cor2_pa = cme_properties.cor2_pa, cor2_halo = cme_properties.cor2_halo, $
																	flare = flare, cme_exist = cme_exist, $
																	hcx_range = hcx_range, hcy_range = hcy_range)
		
		; Output this info
		if typename(hessistr) ne 'STRING' then begin
			outstr.obstype = hessistr.obstype
			outstr.starttime = hessistr.starttime
			outstr.endtime = hessistr.endtime
			outstr.peaktime = hessistr.peaktime
			outstr.goes = hessistr.goes
			outstr.flareloc = hessistr.flareloc
			outstr.no = hessistr.no
			flare = hessistr.flare
			hgx = hessistr.hgx
			hgy = hessistr.hgy
			hcx = hessistr.hcx
			hcy = hessistr.hcy
		endif
		
	endif else begin
		print, 'Skipping HESSI'
	endelse
; 
	; --------------------------------------------------------------------------------------------------------------------------------------------
	; ================================
	; ==== Get active region info ====
	; ================================

	catch, srs_error
	if srs_error ne 0. then begin 
		catch, cancel
		print, 'Issue with srs search for event ', anytim(cme_properties.hi_time, /vms)
		ar = 0.
		return, arstr
	endif

	; == If a flare has been identified ==
	if (flare eq 1.) then begin
		srsstr = srs_search(starttime = outstr.starttime, endttime = outstr.endtime, peakttime = outstr.peaktime, no = outstr.no, $
												srs_template = srs_template, $
												hgx = hgx, hgy = hgy, hcx = hcx, hcy = hcy, $
												lat_range, lon_range)

		; Output this info
		if typename(srsstr) ne 'STRING' then begin
			outstr.srstime = srsstr.srstime
			outstr.no = srsstr.no
			outstr.noaaloc = srsstr.noaaloc
			outstr.mcintosh = srsstr.mcintosh
			outstr.hale = srsstr.hale
			outstr.area = srsstr.area
			outstr.ll = srsstr.ll
			outstr.nn = srsstr.nn
		endif

	; == When there are no flare candidates ==
	endif else begin
		;print, 'No flare for ', anytim(cme_time, /vms)
		ar = 0.
		hcx = !Values.F_NAN
		hcy = !Values.F_NAN
		hgx = !Values.F_NAN
		hgy = !Values.F_NAN
	endelse

	return, outstr
  
end
