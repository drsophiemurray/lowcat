;+
; This searches using Hong's code

function swpc_search_flares, $
					window_start=window_start, window_end=window_end, $
					hi_pan=hi_pan, hi_pas=hi_pas, cor2_pa=cor2_pa, cor2_halo=cor2_halo, $
					flare=flare, cme_exist=cme_exist, $
					hcx_range=hcx_range, hcy_range=hcy_range

	; Define y position above which dont want events
	polar = 40.
	
	; Set up output structure
	swpcstr = {fl_type:' ', $
						fl_starttime: ' ', fl_endtime: ' ', $
						fl_peaktime: ' ', fl_goes: ' ', fl_loc: ' ', srs_no: 0., $
						flare: 0., hgx: 0., hgy: 0., hcx: 0., hcy: 0.}

	swpcstr.hcx = !Values.F_NAN
	swpcstr.hcy = !Values.F_NAN
	swpcstr.hgx = !Values.F_NAN
	swpcstr.hgy = !Values.F_NAN
	swpcstr.flare = flare

	noaa_list = find_goes_flare_info(time2file(anytim(window_start, /vms)), time2file(anytim(window_end, /vms)))

	if (noaa_list(0).stime ne -1) then begin
		noaa_list_hg = fltarr(2, n_elements(noaa_list.location))
		noaa_list_hg(*, *) =  !Values.F_NAN
		noaa_list_hc = noaa_list_hg
		for i = 0, n_elements(noaa_list.location) - 1 do begin
			noaa_list_hg(*, i) = locstring2int(location = noaa_list(i).location)
			hg2hc, noaa_list_hg(1, i), noaa_list_hg(0, i), temphcx, temphcy, date = anytim(noaa_list(i).ptime,/vms)
			noaa_list_hc(*, i) = [temphcy, temphcx]
		endfor

		noaa_dates = -1
		; Check for CME location and search window - if no flare position then will not give result!
		case cme_exist of
			; If no COR2 event identified then use HI angle
			0: begin
					hi_pa = (hi_pan + hi_pas) / 2.
				if (hi_pa GE 0. and hi_pa LT 180.) then begin
					;TO DO: INLCUDE PEAK/END TIMES HERE!!!!! start OR peak OR end
					if (hi_pa GE 0. and hi_pa LT 90.) then noaa_dates = where((anytim(noaa_list.stime) ge anytim(window_start)) and $
																																			(anytim(noaa_list.stime) le anytim(window_end)) and $
																																			(noaa_list_hc(1, *) LE hcx_range) and (noaa_list_hc(0, *) GE -hcy_range) and $
																																			(noaa_list_hg(0, *) LE polar))
					if (hi_pa GE 90. and hi_pa LT 180.) then noaa_dates = where((anytim(noaa_list.stime) ge anytim(window_start)) and $
																																			(anytim(noaa_list.stime) le anytim(window_end)) and $
																																			(noaa_list_hc(1, *) LE hcx_range) and (noaa_list_hc(0, *) LE hcy_range) and $
																																			(noaa_list_hg(0, *) LE polar))
				endif
				if (hi_pa GE 180. and hi_pa LE 360.) then begin
					if (hi_pa GE 180. and hi_pa LT 270.) then noaa_dates = where((anytim(noaa_list.stime) ge anytim(window_start)) and $
																																				(anytim(noaa_list.stime) le anytim(window_end)) and $
																																				(noaa_list_hc(1, *) GE -hcx_range) and (noaa_list_hc(0, *) LE hcy_range) and $
																																				(noaa_list_hg(0, *) LE polar))
					if (hi_pa GE 270. and hi_pa LT 360.) then noaa_dates = where((anytim(noaa_list.stime) ge anytim(window_start)) and $
																																				(anytim(noaa_list.stime) le anytim(window_end)) and $
																																				(noaa_list_hc(1, *) GE -hcx_range) and (noaa_list_hc(0, *) GE -hcy_range) and $
																																				(noaa_list_hg(0, *) LE polar))
				endif
			end
			; Use position angle from CME identified by COR2
			1: begin
				; If theres a halo dont restrict the location
				if (cor2_halo) EQ 'II' or (cor2_halo) EQ 'III' or (cor2_halo) EQ 'IV' then begin
					noaa_dates = where((anytim(noaa_list.stime) ge anytim(window_start)) and $
														(anytim(noaa_list.stime) le anytim(window_end)) and $
														(noaa_list_hg(0, *) LE polar))
				endif else begin
					if (cor2_pa GE 0. and cor2_pa LT 180.) then begin
						if (cor2_pa GE 0. and cor2_pa LT 90.) then noaa_dates = where((anytim(noaa_list.stime) ge anytim(window_start)) and $
																																																				(anytim(noaa_list.stime) le anytim(window_end)) and $
																																																				(noaa_list_hc(1, *) LE hcx_range) and (noaa_list_hc(0, *) GE -hcy_range) and $
																																																				(noaa_list_hg(0, *) LE polar))
						if (cor2_pa GE 90. and cor2_pa LT 180.) then noaa_dates = where((anytim(noaa_list.stime) ge anytim(window_start)) and $
																																																					(anytim(noaa_list.stime) le anytim(window_end)) and $
																																																					(noaa_list_hc(1, *) LE hcx_range) and (noaa_list_hc(0, *) LE hcy_range) and $
																																																					(noaa_list_hg(0, *) LE polar))
					endif
					if (cor2_pa GE 180. and cor2_pa LE 360.) then begin
						if (cor2_pa GE 180. and cor2_pa LT 270.) then noaa_dates = where((anytim(noaa_list.stime) ge anytim(window_start)) and $
																																																						(anytim(noaa_list.stime) le anytim(window_end)) and $
																																																						(noaa_list_hc(1, *) GE -hcx_range) and (noaa_list_hc(0, *) LE hcy_range) and $
																																																						(noaa_list_hg(0, *) LE polar))
						if (cor2_pa GE 270. and cor2_pa LT 360.) then noaa_dates = where((anytim(noaa_list.stime) ge anytim(window_start)) and $
																																																						(anytim(noaa_list.stime) le anytim(window_end)) and $
																																																						(noaa_list_hc(1, *) GE -hcx_range) and (noaa_list_hc(0, *) GE -hcy_range) and $
																																																						(noaa_list_hg(0, *) LE polar))
					endif
				endelse
			end
		endcase

		if (noaa_dates(0) ne -1) then begin
			; Search for X, then M, then C
			noaa_x = where(strmid(noaa_list(noaa_dates).magnitude,0,1) eq 'X')
			noaa_m = where(strmid(noaa_list(noaa_dates).magnitude,0,1) eq 'M')
			noaa_c = where(strmid(noaa_list(noaa_dates).magnitude,0,1) eq 'C') 
			noaa_b = where((strmid(noaa_list(noaa_dates).magnitude,0,1) eq 'B') or (strmid(noaa_list(noaa_dates).magnitude,0,1) eq 'A'))
			if noaa_x(0) ne -1 then begin
				noaa_candidate_index = closest(anytim(noaa_list(noaa_dates(noaa_x)).stime), anytim(window_start))
				noaa_candidate = noaa_list(noaa_dates(noaa_x(noaa_candidate_index)))
			endif else begin
				if noaa_m(0) ne -1 then begin
					noaa_candidate_index = closest(anytim(noaa_list(noaa_dates(noaa_m)).stime), anytim(window_start))
					noaa_candidate = noaa_list(noaa_dates(noaa_m(noaa_candidate_index)))
				endif else begin
					if noaa_c(0) ne -1 then begin
						noaa_candidate_index = closest(anytim(noaa_list(noaa_dates(noaa_c)).stime), anytim(window_start))
						noaa_candidate = noaa_list(noaa_dates(noaa_c(noaa_candidate_index)))
					endif else begin
						noaa_candidate_index = closest(anytim(noaa_list(noaa_dates(noaa_b)).stime), anytim(window_start))
						noaa_candidate = noaa_list(noaa_dates(noaa_b(noaa_candidate_index)))
					endelse
				endelse
			endelse
			
			if typename(noaa_candidate) ne 'INT' then swpcstr.flare = 1.

			; Output this initial info
			swpcstr.fl_starttime = noaa_candidate.stime
			swpcstr.fl_endtime = noaa_candidate.etime
			swpcstr.fl_peaktime = noaa_candidate.ptime
			swpcstr.fl_goes = noaa_candidate.magnitude
			swpcstr.srs_no = noaa_candidate.region
			swpcstr.fl_type = 'swpc'

			; Output position coordinates for later use with SMART
			noaa_latlon = locstring2int(location = noaa_candidate.location)
			if (finite(noaa_latlon(0)) ne 0.) then begin
				hgy = noaa_latlon[0]
				hgx = noaa_latlon[1]
				hg2hc, hgx, hgy, hcx, hcy, date = swpcstr.fl_peaktime 
				swpcstr.fl_loc = noaa_candidate.location
				swpcstr.hcx = hcx
				swpcstr.hcy = hcy
				swpcstr.hgx = hgx
				swpcstr.hgy = hgy
			endif else begin
				; If no position information...
				swpcstr.hcx = !Values.F_NAN
				swpcstr.hcy = !Values.F_NAN
				swpcstr.hgx = !Values.F_NAN
				swpcstr.hgy = !Values.F_NAN
			endelse

		endif 

	endif

	return, swpcstr
	
end