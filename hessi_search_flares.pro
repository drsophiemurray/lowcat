;+
; This searches using RHESSI list

function hessi_search_flares, $
					window_start=window_start, window_end=window_end, $
					hi_pan=hi_pan, hi_pas=hi_pas, cor2_pa=cor2_pa, cor2_halo=cor2_halo, $
					flare=flare, cme_exist=cme_exist, $
					hcx_range=hcx_range, hcy_range=hcy_range
					
	; Set up output structure
	hessistr = {obstype:' ', $
						starttime: ' ', endtime: ' ', $
						peaktime: ' ', goes: ' ', flareloc: ' ', no: 0., $
						flare: 0., hgx: 0., hgy: 0., hcx: 0., hcy: 0.}

	hessistr.hcx = !Values.F_NAN
	hessistr.hcy = !Values.F_NAN
	hessistr.hgx = !Values.F_NAN
	hessistr.hgy = !Values.F_NAN
	hessistr.flare = flare

	hessi_list = hsi_read_flarelist()
	;hsi_read_flarelist(info=info)
	;print,info.flag_ids
	;SAA_AT_START SAA_AT_END SAA_DURING_FLARE ECLIPSE_AT_START ECLIPSE_AT_END ECLIPSE_DURING_FLARE FLARE_AT_SOF FLARE_AT_EOF NON_SOLAR FAST_RATE_MODE FRONT_DECIMATION ATT_STATE_AT_PEAK DATA_GAP_AT_START DATA_GAP_AT_END DATA_GAP_DURING_FLARE PARTICLE_EVENT DATA_QUALITY POSITION_QUALITY ATTEN_0 ATTEN_1 ATTEN_2 ATTEN_3 REAR_DECIMATION MAGNETIC_REGION IMAGE_STATUS SPECTRUM_STATUS SOLAR_UNCONFIRMED SOLAR    
	; will use hessi_list.flags[17] which is position quality, as well as hessi_list.flags[16] which is data quality (max is 7)
	
	; Define y position above which dont want events
	polar = 750.

	; Get the closest flare to the search time window and CME position
	; Note that 'sflag = 1' means a solar event - could say 'ne 0' which would include the maybes (2)
	hessi_dates = -1

	; Check location of CME vs flare. Use position angle from CME identified by COR2.
	; If no COR2 event identified then use HI angle.
	; If theres a halo dont restrict the location

	case cme_exist of
		0: begin
			hi_pa = (hi_pan + hi_pas) / 2.
			if (hi_pa GE 0. and hi_pa LT 180.) then begin
				if (hi_pa GE 0. and hi_pa LT 90.) then hessi_dates = where((hessi_list.start_time ge anytim(window_start)) and $
																																		(hessi_list.start_time le anytim(window_end)) and $
																																		(hessi_list.sflag1 eq 1.) and (hessi_list.flags[17] eq 1.) and (hessi_list.flags[16] le 4.) and $
																																		(hessi_list.x_position LE hcx_range) and (hessi_list.y_position GE -hcy_range) and $
																																		(hessi_list.y_position LE polar))
				if (hi_pa GE 90. and hi_pa LT 180.) then hessi_dates = where((hessi_list.start_time ge anytim(window_start)) and $
																																			(hessi_list.start_time le anytim(window_end)) and $
																																			(hessi_list.sflag1 eq 1.) and (hessi_list.flags[17] eq 1.) and (hessi_list.flags[16] le 4.) and $
																																			(hessi_list.x_position LE hcx_range) and (hessi_list.y_position LE hcy_range) and $
																																			(hessi_list.y_position LE polar))
			endif
			if (hi_pa GE 180. and hi_pa LE 360.) then begin
				if (hi_pa GE 180. and hi_pa LT 270.) then hessi_dates = where((hessi_list.start_time ge anytim(window_start)) and $
																																			(hessi_list.start_time le anytim(window_end)) and $
																																			(hessi_list.sflag1 eq 1.) and (hessi_list.flags[17] eq 1.) and (hessi_list.flags[16] le 4.) and $
																																			(hessi_list.x_position GE -hcx_range) and (hessi_list.y_position LE hcy_range) and $
																																			(hessi_list.y_position LE polar))
				if (hi_pa GE 270. and hi_pa LT 360.) then hessi_dates = where((hessi_list.start_time ge anytim(window_start)) and $
																																			(hessi_list.start_time le anytim(window_end)) and $
																																			(hessi_list.sflag1 eq 1.) and (hessi_list.flags[17] eq 1.) and (hessi_list.flags[16] le 4.) and $
																																			(hessi_list.x_position GE -hcx_range) and (hessi_list.y_position GE -hcy_range) and $
																																			(hessi_list.y_position LE polar))
			endif
		end
		1: begin
			if (cor2_halo) EQ 'II' or (cor2_halo) EQ 'III' or (cor2_halo) EQ 'IV' then begin
				hessi_dates = where((hessi_list.start_time ge anytim(window_start)) and $
														(hessi_list.start_time le anytim(window_end)) and $
														(hessi_list.sflag1 eq 1.) and (hessi_list.flags[17] eq 1.) and (hessi_list.flags[16] le 4.) and $
														(hessi_list.y_position LE polar))
			endif else begin
				if (cor2_pa GE 0. and cor2_pa LT 180.) then begin
					if (cor2_pa GE 0. and cor2_pa LT 90.) then hessi_dates = where((hessi_list.start_time ge anytim(window_start)) and $
																																																				(hessi_list.start_time le anytim(window_end)) and $
																																																				(hessi_list.sflag1 eq 1.) and (hessi_list.flags[17] eq 1.) and (hessi_list.flags[16] le 4.) and $
																																																				(hessi_list.x_position LE hcx_range) and (hessi_list.y_position GE -hcy_range) and $
																																																				(hessi_list.y_position LE polar))
					if (cor2_pa GE 90. and cor2_pa LT 180.) then hessi_dates = where((hessi_list.start_time ge anytim(window_start)) and $
																																																					(hessi_list.start_time le anytim(window_end)) and $
																																																					(hessi_list.sflag1 eq 1.) and (hessi_list.flags[17] eq 1.) and (hessi_list.flags[16] le 4.) and $
																																																					(hessi_list.x_position LE hcx_range) and (hessi_list.y_position LE hcy_range) and $
																																																					(hessi_list.y_position LE polar))
				endif
				if (cor2_pa GE 180. and cor2_pa LE 360.) then begin
					if (cor2_pa GE 180. and cor2_pa LT 270.) then hessi_dates = where((hessi_list.start_time ge anytim(window_start)) and $
																																																					(hessi_list.start_time le anytim(window_end)) and $
																																																					(hessi_list.sflag1 eq 1.) and (hessi_list.flags[17] eq 1.) and (hessi_list.flags[16] le 4.) and $
																																																					(hessi_list.x_position GE -hcx_range) and (hessi_list.y_position LE hcy_range) and $
																																																					(hessi_list.y_position LE polar))
					if (cor2_pa GE 270. and cor2_pa LT 360.) then hessi_dates = where((hessi_list.start_time ge anytim(window_start)) and $
																																																					(hessi_list.start_time le anytim(window_end)) and $
																																																					(hessi_list.sflag1 eq 1.) and (hessi_list.flags[17] eq 1.) and (hessi_list.flags[16] le 4.) and $
																																																					(hessi_list.x_position GE -hcx_range) and (hessi_list.y_position GE -hcy_range) and $
																																																					(hessi_list.y_position LE polar))
				endif
			endelse
		end
	endcase

	if (hessi_dates(0) ne -1) then begin

		; Get closest match based on start time
		; Search for X, then M, then C - 
		hessi_x = where(strmid(hessi_list(hessi_dates).goes_class,0,1) eq 'X')
		hessi_m = where(strmid(hessi_list(hessi_dates).goes_class,0,1) eq 'M')
		hessi_c = where(strmid(hessi_list(hessi_dates).goes_class,0,1) eq 'C')
		hessi_b = where((strmid(hessi_list(hessi_dates).goes_class,0,1) eq 'B') or (strmid(hessi_list(hessi_dates).goes_class,0,1) eq 'A'))
		;Note here it is not allowing any that dont have a class 
		if (hessi_x(0) or hessi_m(0) or hessi_c(0) or hessi_b(0)) ne -1 then begin

			if hessi_x(0) ne -1 then begin
				hessi_candidate_index = closest(anytim(hessi_list(hessi_dates(hessi_x)).start_time), anytim(window_start))
				hessi_candidate = hessi_list(hessi_dates(hessi_x(hessi_candidate_index)))
			endif else begin
				if hessi_m(0) ne -1 then begin
					hessi_candidate_index = closest(anytim(hessi_list(hessi_dates(hessi_m)).start_time), anytim(window_start))
					hessi_candidate = hessi_list(hessi_dates(hessi_m(hessi_candidate_index)))
				endif else begin
					if hessi_c(0) ne -1 then begin
						hessi_candidate_index = closest(anytim(hessi_list(hessi_dates(hessi_c)).start_time), anytim(window_start))
						hessi_candidate = hessi_list(hessi_dates(hessi_c(hessi_candidate_index)))
					endif else begin
						hessi_candidate_index = closest(anytim(hessi_list(hessi_dates(hessi_b)).start_time), anytim(window_start))
						hessi_candidate = hessi_list(hessi_dates(hessi_b(hessi_candidate_index)))
					endelse
				endelse
			endelse

			if typename(hessi_candidate) ne 'INT' then hessistr.flare = 1.

			; Output this initial info
			hessistr.starttime = anytim(hessi_candidate.start_time, /vms)
			hessistr.endtime = anytim(hessi_candidate.end_time, /vms)
			hessistr.peaktime = anytim(hessi_candidate.peak_time, /vms)
			hessistr.goes = STRTRIM(hessi_candidate.goes_class)
			hessistr.no = hessi_candidate.active_region
			hessistr.obstype = 'hessi'

			; Get position coordinates for later use with NOAA SRS and running SMART
			if hessi_candidate.x_position ne 0. then begin
				hcx = hessi_candidate.x_position
				hcy = hessi_candidate.y_position
				hc2hg, hcx, hcy, hgx, hgy, date = hessistr.peaktime
				flarelocstring = locint2string(latitude=hgy, longitude=hgx)
				hessistr.flareloc = flarelocstring
				hessistr.hcx = hcx
				hessistr.hcy = hcy
				hessistr.hgx = hgx
				hessistr.hgy = hgy
			endif else begin
				; If no position information...
				hessistr.hcx = !Values.F_NAN
				hessistr.hcy = !Values.F_NAN
				hessistr.hgx = !Values.F_NAN
				hessistr.hgy = !Values.F_NAN
			endelse

		;Here theres no class defined in the structure so just choose closest start time
		endif else begin
			hessi_candidate_index = closest(anytim(hessi_list(hessi_dates).start_time), anytim(window_start))
			hessi_candidate = hessi_list(hessi_dates(hessi_candidate_index))

			if typename(hessi_candidate) ne 'INT' then hessistr.flare = 1.

			; Output this initial info
			hessistr.starttime = anytim(hessi_candidate.start_time, /vms)
			hessistr.endtime = anytim(hessi_candidate.end_time, /vms)
			hessistr.peaktime = anytim(hessi_candidate.peak_time, /vms)
			hessistr.goes = STRTRIM(hessi_candidate.goes_class)
			hessistr.no = hessi_candidate.active_region
			hessistr.obstype = 'hessi'

			; Get position coordinates for later use with NOAA SRS and running SMART
			if hessi_candidate.x_position ne 0. then begin
				hcx = hessi_candidate.x_position
				hcy = hessi_candidate.y_position
				hc2hg, hcx, hcy, hgx, hgy, date = hessistr.peaktime
				flarelocstring = locint2string(latitude=hgy, longitude=hgx)
				hessistr.flareloc = flarelocstring
				hessistr.hcx = hcx
				hessistr.hcy = hcy
				hessistr.hgx = hgx
				hessistr.hgy = hgy
			endif else begin
				; If no position information...
				hessistr.hcx = !Values.F_NAN
				hessistr.hcy = !Values.F_NAN
				hessistr.hgx = !Values.F_NAN
				hessistr.hgy = !Values.F_NAN
			endelse

		endelse

	; No flare identified
	endif else begin
		hessistr.flare = 0.
	endelse

	return, hessistr
	
end
