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
	outstr = {fl_ts:' ', fl_tf: ' ', $
						fl_type:' ', $
						fl_starttime: ' ', fl_endtime: ' ', $
						fl_peaktime: ' ', fl_goes: ' ', fl_loc: ' ', $
						srs_time:' ', $
						srs_no: 0., srs_loc: ' ' , $
						srs_mcintosh: ' ', srs_hale: ' ' , $
						srs_area: 0., srs_ll: 0., srs_nn: 0.}

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
; ; 	; Redefine search window to include error
; 	flare_ts = anytim(addtime(anytim(flare_ts,/vms), delta_min = -flare_del))
; 	flare_tf = anytim(addtime(anytim(flare_tf,/vms), delta_min = flare_del))

	outstr.fl_ts = anytim(flare_ts, /vms)
	outstr.fl_tf = anytim(flare_tf, /vms)

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
	sswstr = lmsalssw_search(window_start = outstr.fl_ts, window_end = outstr.fl_tf, $
													hi_pan = cme_properties.hi_pan, hi_pas = cme_properties.hi_pas, cor2_pa = cme_properties.cor2_pa, cor2_halo = cme_properties.cor2_halo, $
													flare = flare, cme_exist = cme_exist, $
													hcx_range = hcx_range, hcy_range = hcy_range)
	
	; Output this info
; 	if typename(sswstr) ne 'STRING' then begin
	if sswstr.fl_starttime ne ' ' then begin
		outstr.fl_type = sswstr.fl_type
		outstr.fl_starttime = sswstr.fl_starttime
		outstr.fl_endtime = sswstr.fl_endtime
		outstr.fl_peaktime = sswstr.fl_peaktime
		outstr.fl_goes = sswstr.fl_goes
		outstr.fl_loc = sswstr.fl_loc
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
			swpcstr = swpc_search_flares(window_start = outstr.fl_ts, window_end = outstr.fl_tf, $
																	hi_pan = cme_properties.hi_pan, hi_pas = cme_properties.hi_pas, cor2_pa = cme_properties.cor2_pa, cor2_halo = cme_properties.cor2_halo, $
																	flare = flare, cme_exist = cme_exist, $
																	hcx_range = hcx_range, hcy_range = hcy_range)

			; Output this info
;			if typename(swpcstr) ne 'STRING' then begin
			if swpcstr.fl_starttime ne ' ' then begin
				outstr.fl_type = swpcstr.fl_type
				outstr.fl_starttime = swpcstr.fl_starttime
				outstr.fl_endtime = swpcstr.fl_endtime
				outstr.fl_peaktime = swpcstr.fl_peaktime
				outstr.fl_goes = swpcstr.fl_goes
				outstr.srs_no = swpcstr.srs_no
				flare = swpcstr.flare
				;found some swpc events with the wrong location listed so this is to remove spurious polar regions
				if (abs(swpcstr.hgy) le 45.) then begin
					outstr.fl_loc = swpcstr.fl_loc
					hgx = swpcstr.hgx
					hgy = swpcstr.hgy
					hcx = swpcstr.hcx
					hcy = swpcstr.hcy
				endif
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
		hessistr = hessi_search_flares(window_start = outstr.fl_ts, window_end = outstr.fl_tf, $
																	hi_pan = cme_properties.hi_pan, hi_pas = cme_properties.hi_pas, cor2_pa = cme_properties.cor2_pa, cor2_halo = cme_properties.cor2_halo, $
																	flare = flare, cme_exist = cme_exist, $
																	hcx_range = hcx_range, hcy_range = hcy_range)

		; Output this info
;		if typename(hessistr) ne 'STRING' then begin
		if hessistr.fl_starttime ne ' ' then begin
			outstr.fl_type = hessistr.fl_type
			outstr.fl_starttime = hessistr.fl_starttime
			outstr.fl_endtime = hessistr.fl_endtime
			outstr.fl_peaktime = hessistr.fl_peaktime
			outstr.fl_goes = hessistr.fl_goes
			outstr.fl_loc = hessistr.fl_loc
			outstr.srs_no = hessistr.srs_no
			flare = hessistr.flare
			hgx = hessistr.hgx
			hgy = hessistr.hgy
			hcx = hessistr.hcx
			hcy = hessistr.hcy
		endif
		
	endif else begin
		if outstr.fl_loc eq " " then begin
			print, 'Getting location from HESSI'
			;Only grab location if there is an active region number
			swpc_hessi_list = hsi_read_flarelist()
			swpc_hessi_polar =  625.

			case cme_exist of
				0: begin
				hi_pa = (cme_properties.hi_pan + cme_properties.hi_pas) / 2.
					if (hi_pa GE 0. and hi_pa LT 180.) then begin
						if (hi_pa GE 0. and hi_pa LT 90.) then swpc_hessi_dates = where((swpc_hessi_list.peak_time ge anytim(outstr.fl_ts)) and $
																																						(swpc_hessi_list.peak_time le anytim(outstr.fl_tf)) and $
																																						(swpc_hessi_list.sflag1 eq 1.) and (swpc_hessi_list.flags[17] eq 1.) and (swpc_hessi_list.flags[16] le 4.) and $
																																						(swpc_hessi_list.x_position LE hcx_range) and (swpc_hessi_list.y_position GE -hcy_range) and $
																																						(swpc_hessi_list.y_position LE swpc_hessi_polar) and (swpc_hessi_list.y_position GE -swpc_hessi_polar) and $
																																						(swpc_hessi_list.active_region eq outstr.srs_no))
						if (hi_pa GE 90. and hi_pa LT 180.) then swpc_hessi_dates = where((swpc_hessi_list.peak_time ge anytim(outstr.fl_ts)) and $
																																							(swpc_hessi_list.peak_time le anytim(outstr.fl_tf)) and $
																																							(swpc_hessi_list.sflag1 eq 1.) and (swpc_hessi_list.flags[17] eq 1.) and (swpc_hessi_list.flags[16] le 4.) and $
																																							(swpc_hessi_list.x_position LE hcx_range) and (swpc_hessi_list.y_position LE hcy_range) and $
																																							(swpc_hessi_list.y_position LE swpc_hessi_polar) and (swpc_hessi_list.y_position GE -swpc_hessi_polar) and $
																																							(swpc_hessi_list.active_region eq outstr.srs_no))
					endif
					if (hi_pa GE 180. and hi_pa LE 360.) then begin
						if (hi_pa GE 180. and hi_pa LT 270.) then swpc_hessi_dates = where((swpc_hessi_list.peak_time ge anytim(outstr.fl_ts)) and $
																																							(swpc_hessi_list.peak_time le anytim(outstr.fl_tf)) and $
																																							(swpc_hessi_list.sflag1 eq 1.) and (swpc_hessi_list.flags[17] eq 1.) and (swpc_hessi_list.flags[16] le 4.) and $
																																							(swpc_hessi_list.x_position GE -hcx_range) and (swpc_hessi_list.y_position LE hcy_range) and $
																																							(swpc_hessi_list.y_position LE swpc_hessi_polar) and (swpc_hessi_list.y_position GE -swpc_hessi_polar) and $
																																							(swpc_hessi_list.active_region eq outstr.srs_no))
						if (hi_pa GE 270. and hi_pa LT 360.) then swpc_hessi_dates = where((swpc_hessi_list.peak_time ge anytim(outstr.fl_ts)) and $
																																							(swpc_hessi_list.peak_time le anytim(outstr.fl_tf)) and $
																																							(swpc_hessi_list.sflag1 eq 1.) and (swpc_hessi_list.flags[17] eq 1.) and (swpc_hessi_list.flags[16] le 4.) and $
																																							(swpc_hessi_list.x_position GE -hcx_range) and (swpc_hessi_list.y_position GE -hcy_range) and $
																																							(swpc_hessi_list.y_position LE swpc_hessi_polar) and (swpc_hessi_list.y_position GE -swpc_hessi_polar) and $
																																							(swpc_hessi_list.active_region eq outstr.srs_no))
					endif
				end
				1: begin
					if (cme_properties.cor2_halo) EQ 'II' or (cme_properties.cor2_halo) EQ 'III' or (cme_properties.cor2_halo) EQ 'IV' then begin
						swpc_hessi_dates = where((swpc_hessi_list.peak_time ge anytim(outstr.fl_ts)) and $
																			(swpc_hessi_list.peak_time le anytim(outstr.fl_tf)) and $
																			(swpc_hessi_list.sflag1 eq 1.) and (swpc_hessi_list.flags[17] eq 1.) and (swpc_hessi_list.flags[16] le 4.) and $
																			(swpc_hessi_list.y_position LE swpc_hessi_polar) and (swpc_hessi_list.y_position GE -swpc_hessi_polar) and $
																			(swpc_hessi_list.active_region eq outstr.srs_no))
					endif else begin
						if (cme_properties.cor2_pa GE 0. and cme_properties.cor2_pa LT 180.) then begin
							if (cme_properties.cor2_pa GE 0. and cme_properties.cor2_pa LT 90.) then swpc_hessi_dates = where((swpc_hessi_list.peak_time ge anytim(outstr.fl_ts)) and $
																																																								(swpc_hessi_list.peak_time le anytim(outstr.fl_tf)) and $
																																																								(swpc_hessi_list.sflag1 eq 1.) and (swpc_hessi_list.flags[17] eq 1.) and (swpc_hessi_list.flags[16] le 4.) and $
																																																								(swpc_hessi_list.x_position LE hcx_range) and (swpc_hessi_list.y_position GE -hcy_range) and $
																																																								(swpc_hessi_list.y_position LE swpc_hessi_polar) and (swpc_hessi_list.y_position GE -swpc_hessi_polar) and $
																																																								(swpc_hessi_list.active_region eq outstr.srs_no))
							if (cme_properties.cor2_pa GE 90. and cme_properties.cor2_pa LT 180.) then swpc_hessi_dates = where((swpc_hessi_list.peak_time ge anytim(outstr.fl_ts)) and $
																																																								(swpc_hessi_list.peak_time le anytim(outstr.fl_tf)) and $
																																																								(swpc_hessi_list.sflag1 eq 1.) and (swpc_hessi_list.flags[17] eq 1.) and (swpc_hessi_list.flags[16] le 4.) and $
																																																								(swpc_hessi_list.x_position LE hcx_range) and (swpc_hessi_list.y_position LE hcy_range) and $
																																																								(swpc_hessi_list.y_position LE swpc_hessi_polar) and (swpc_hessi_list.y_position GE -swpc_hessi_polar) and $
																																																								(swpc_hessi_list.active_region eq outstr.srs_no))
						endif
						if (cme_properties.cor2_pa GE 180. and cme_properties.cor2_pa LE 360.) then begin
							if (cme_properties.cor2_pa GE 180. and cme_properties.cor2_pa LT 270.) then swpc_hessi_dates = where((swpc_hessi_list.peak_time ge anytim(outstr.fl_ts)) and $
																																																								(swpc_hessi_list.peak_time le anytim(outstr.fl_tf)) and $
																																																								(swpc_hessi_list.sflag1 eq 1.) and (swpc_hessi_list.flags[17] eq 1.) and (swpc_hessi_list.flags[16] le 4.) and $
																																																								(swpc_hessi_list.x_position GE -hcx_range) and (swpc_hessi_list.y_position LE hcy_range) and $
																																																								(swpc_hessi_list.y_position LE swpc_hessi_polar) and (swpc_hessi_list.y_position GE -swpc_hessi_polar) and $
																																																								(swpc_hessi_list.active_region eq outstr.srs_no))
							if (cme_properties.cor2_pa GE 270. and cme_properties.cor2_pa LT 360.) then swpc_hessi_dates = where((swpc_hessi_list.peak_time ge anytim(outstr.fl_ts)) and $
																																																								(swpc_hessi_list.peak_time le anytim(outstr.fl_tf)) and $
																																																								(swpc_hessi_list.sflag1 eq 1.) and (swpc_hessi_list.flags[17] eq 1.) and (swpc_hessi_list.flags[16] le 4.) and $
																																																								(swpc_hessi_list.x_position GE -hcx_range) and (swpc_hessi_list.y_position GE -hcy_range) and $
																																																								(swpc_hessi_list.y_position LE swpc_hessi_polar) and (swpc_hessi_list.y_position GE -swpc_hessi_polar) and $
																																																								(swpc_hessi_list.active_region eq outstr.srs_no))
						endif
					endelse
				end
			endcase

			if swpc_hessi_dates(0) ne -1 then begin
				swpc_hessi_index = closest(anytim(swpc_hessi_list(swpc_hessi_dates).start_time), anytim(outstr.fl_ts))
				swpc_hessi_candidate = (swpc_hessi_list(swpc_hessi_dates(swpc_hessi_index)))
				if swpc_hessi_candidate.x_position ne 0. then begin
					hcx = swpc_hessi_candidate.x_position
					hcy = swpc_hessi_candidate.y_position
					hc2hg, hcx, hcy, hgx, hgy, date = anytim(swpc_hessi_candidate.peak_time, /vms)
					flarelocstring = locint2string(latitude=hgy, longitude=hgx)
					outstr.fl_loc = flarelocstring
				endif
			endif 

		endif else begin
			print, 'Skipping HESSI'
		endelse

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
		srsstr = srs_search(starttime = outstr.fl_starttime, endtime = outstr.fl_endtime, peaktime = outstr.fl_peaktime, no = outstr.srs_no, $
												srs_template = srs_template, $
												hgx = hgx, hgy = hgy, hcx = hcx, hcy = hcy, $
												lat_range, lon_range)

		; Output this info
		if typename(srsstr) ne 'STRING' then begin
			outstr.srs_time = srsstr.srs_time
			outstr.srs_no = srsstr.srs_no
			outstr.srs_loc = srsstr.srs_loc
			outstr.srs_mcintosh = srsstr.srs_mcintosh
			outstr.srs_hale = srsstr.srs_hale
			outstr.srs_area = srsstr.srs_area
			outstr.srs_ll = srsstr.srs_ll
			outstr.srs_nn = srsstr.srs_nn
			
			; If still no flare location, uses SRS location
			if ((outstr.fl_loc eq " ") and (outstr.srs_loc ne " ")) then begin
				srs_hg = locstring2int(location=outstr.srs_loc)
				hg2hc, srs_hg[1], srs_hg[0], fl_hcx, fl_hcy, date = outstr.srs_time, rotdate = outstr.fl_peaktime 
				hc2hg, fl_hcx, fl_hcy, fl_hgx, fl_hgy, date = outstr.fl_peaktime
				fl_hg = locint2string(latitude = fl_hgy, longitude = fl_hgx)
				outstr.fl_loc = fl_hg
				hgx = fl_hgx
				hgy = fl_hgy
				hcx = fl_hcx
				hcy = fl_hcy
			endif

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
