function lmsalssw_search, $
					window_start=window_start, window_end=window_end, $
					hi_pan=hi_pan, hi_pas=hi_pas, cor2_pa=cor2_pa, cor2_halo=cor2_halo, $
					flare=flare, cme_exist=cme_exist, $
					hcx_range = hcx_range, hcy_range = hcy_range

	; Choose y position above which no events
	polar = 750.
	
	; Set up output structure
	sswstr = {fl_type:' ', $
						fl_starttime: ' ', fl_endtime: ' ', $
						fl_peaktime: ' ', fl_goes: ' ', fl_loc: ' ', $
						flare: 0., hgx: 0., hgy: 0., hcx: 0., hcy: 0.}

	sswstr.hcx = !Values.F_NAN
	sswstr.hcy = !Values.F_NAN
	sswstr.hgx = !Values.F_NAN
	sswstr.hgy = !Values.F_NAN

	ssw_list = les_archive_info(anytim(window_start, /vms), anytim(window_end, /vms))

	; Catching error if no events are found in the archive
	if (typename(ssw_list) eq 'STRING') then begin
		ssw_dates = -1
		sswstr.flare = 0.
	endif else begin
		; Choose flares related to position of CME, plus within search time range
		; (if les_archive_info() doesnt find anything it outputs a few days worth of events)
		ssw_dates = -1
		; If no COR2 event identified then use HI angle,  else use position angle from CME identified by COR2
		case cme_exist of
			0: begin
				hi_pa = (hi_pan + hi_pas) / 2.
				if (hi_pa GE 0. and hi_pa LT 180.) then begin
					if (hi_pa GE 0. and hi_pa LT 90.) then ssw_dates = where((anytim(ssw_list.fstart) ge anytim(window_start)) and $
																																		(anytim(ssw_list.fstart) le anytim(window_end)) and $
																																		(ssw_list.xcen LE hcx_range) and (ssw_list.ycen GE -hcy_range) and $
																																		(ssw_list.ycen LE polar))
					if (hi_pa GE 90. and hi_pa LT 180.) then ssw_dates = where((anytim(ssw_list.fstart) ge anytim(window_start)) and $
																																		(anytim(ssw_list.fstart) le anytim(window_end)) and $
																																		(ssw_list.xcen LE hcx_range) and (ssw_list.ycen LE hcy_range) and $
																																		(ssw_list.ycen LE polar))
				endif
				if (hi_pa GE 180. and hi_pa LE 360.) then begin
					if (hi_pa GE 180. and hi_pa LT 270.) then ssw_dates = where((anytim(ssw_list.fstart) ge anytim(window_start)) and $
																																			(anytim(ssw_list.fstart) le anytim(window_end)) and $
																																			(ssw_list.xcen GE -hcx_range) and (ssw_list.ycen LE hcy_range) and $
																																			(ssw_list.ycen LE polar))
					if (hi_pa GE 270. and hi_pa LT 360.) then ssw_dates = where((anytim(ssw_list.fstart) ge anytim(window_start)) and $
																																			(anytim(ssw_list.fstart) le anytim(window_end)) and $
																																			(ssw_list.xcen GE -hcx_range) and (ssw_list.ycen GE -hcy_range) and $
																																			(ssw_list.ycen LE polar))
				endif
			end
			1: begin
				; If theres a halo dont restrict the location
				if (cor2_halo) EQ 'II' or (cor2_halo) EQ 'III' or (cor2_halo) EQ 'IV' then begin
					ssw_dates = where((anytim(ssw_list.fstart) ge anytim(window_start)) and $
														(anytim(ssw_list.fstart) le anytim(window_end)) and $
														(ssw_list.ycen LE polar))
				endif else begin
					if (cor2_pa GE 0. and cor2_pa LT 180.) then begin
						if (cor2_pa GE 0. and cor2_pa LT 90.) then ssw_dates = where((anytim(ssw_list.fstart) ge anytim(window_start)) and $
																																																			(anytim(ssw_list.fstart) le anytim(window_end)) and $
																																																			(ssw_list.xcen LE hcx_range) and (ssw_list.ycen GE -hcy_range) and $
																																																			(ssw_list.ycen LE polar))
						if (cor2_pa GE 90. and cor2_pa LT 180.) then ssw_dates = where((anytim(ssw_list.fstart) ge anytim(window_start)) and $
																																																				(anytim(ssw_list.fstart) le anytim(window_end)) and $
																																																				(ssw_list.xcen LE hcx_range) and (ssw_list.ycen LE hcy_range) and $
																																																				(ssw_list.ycen LE polar))
					endif
					if (cor2_pa GE 180. and cor2_pa LE 360.) then begin
						if (cor2_pa GE 180. and cor2_pa LT 270.) then ssw_dates = where((anytim(ssw_list.fstart) ge anytim(window_start)) and $
																																																					(anytim(ssw_list.fstart) le anytim(window_end)) and $
																																																					(ssw_list.xcen GE -hcx_range) and (ssw_list.ycen LE hcy_range) and $
																																																					(ssw_list.ycen LE polar))
						if (cor2_pa GE 270. and cor2_pa LT 360.) then ssw_dates = where((anytim(ssw_list.fstart) ge anytim(window_start)) and $
																																																					(anytim(ssw_list.fstart) le anytim(window_end)) and $
																																																					(ssw_list.xcen GE -hcx_range) and (ssw_list.ycen GE -hcy_range) and $
																																																					(ssw_list.ycen LE polar))
					endif
				endelse
			end
		endcase
	endelse

	if (ssw_dates(0) ne -1.) then begin
		sswstr.flare = 1.
		; Search for X, then M, then C
		ssw_x = where(strmid(ssw_list(ssw_dates).class,0,1) eq 'X')
		ssw_m = where(strmid(ssw_list(ssw_dates).class,0,1) eq 'M')
		ssw_c = where(strmid(ssw_list(ssw_dates).class,0,1) eq 'C')
		ssw_b = where((strmid(ssw_list(ssw_dates).class,0,1) eq 'B') or (strmid(ssw_list(ssw_dates).class,0,1) eq 'A'))
		if ssw_x(0) ne -1 then begin
			; Choose candidate closest in time to start time window
			ssw_candidate_index = closest(anytim(ssw_list(ssw_dates(ssw_x)).fstart), anytim(window_start))
			ssw_candidate = ssw_list(ssw_dates(ssw_x(ssw_candidate_index)))
		endif else begin
			if ssw_m(0) ne -1 then begin
				ssw_candidate_index = closest(anytim(ssw_list(ssw_dates(ssw_m)).fstart), anytim(window_start))
				ssw_candidate = ssw_list(ssw_dates(ssw_m(ssw_candidate_index)))
			endif else begin
				if ssw_c(0) ne -1 then begin
					ssw_candidate_index = closest(anytim(ssw_list(ssw_dates(ssw_c)).fstart), anytim(window_start))
					ssw_candidate = ssw_list(ssw_dates(ssw_c(ssw_candidate_index)))
				endif else begin
					ssw_candidate_index = closest(anytim(ssw_list(ssw_dates(ssw_b)).fstart), anytim(window_start))
					ssw_candidate = ssw_list(ssw_dates(ssw_b(ssw_candidate_index)))
				endelse
			endelse
		endelse

		; Output this initial info
		sswstr.fl_starttime = anytim(ssw_candidate.fstart, /vms)
		sswstr.fl_endtime = anytim(ssw_candidate.fstop, /vms)
		sswstr.fl_peaktime = anytim(ssw_candidate.fpeak, /vms)
		sswstr.fl_goes = ssw_candidate.class
		sswstr.fl_type = 'gevloc'

		; Output position coordinates for later use with SMART
		if (ssw_candidate.xcen ne 0.) then begin
			hcx = ssw_candidate.xcen
			hcy = ssw_candidate.ycen
			hc2hg, hcx, hcy, hgx, hgy, date = anytim(ssw_candidate.fpeak, /vms)
			sswstr.fl_loc = ssw_candidate.helio
			sswstr.hcx = hcx
			sswstr.hcy = hcy
			sswstr.hgx = hgx
			sswstr.hgy = hgy
		endif else begin
			; If no position information...
			sswstr.hcx = !Values.F_NAN
			sswstr.hcy = !Values.F_NAN
			sswstr.hgx = !Values.F_NAN
			sswstr.hgy = !Values.F_NAN
		endelse

	endif else begin
		sswstr.flare = 0.
	endelse

	return, sswstr

end