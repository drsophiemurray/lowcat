function srs_search, $ 
					starttime = starttime, endttime = endtime, peakttime = peaktime, no = no, $
					srs_template = srs_template, $
					hgx = hgx, hgy = hgy, hcx = hcx, hcy = hcy, $
					lat_range, lon_range
											
	COMMON FOLDERS 
		
	srsstr = {srs_time:' ', $
						srs_no: 0., srs_loc: ' ' , $
						srs_mcintosh: ' ', srs_hale: ' ' , $
						srs_area: 0., srs_ll: 0., srs_nn: 0., $
						ar: 0.}

		; ---- Load NOAA SRS file ----
		file = time2file(starttime, /date_only)    
		; Have read in an ascii template earlier for use - it is in format 'no, loc, lo, area, mcintosh, ll, nn, hale'
		srs = read_ascii(DATA_FOLDER + 'noaa_srs/' + file + 'SRS.txt', template=srs_template)
  
		; -- If no region defined yet, see if any of the NOAA locations from that date matches the flare location --
		if (no eq 0.) then begin
			noaa_ar_index = -1

			; Check if flare position listed
			if (finite(hgx) eq 0.) or (finite(hgy) eq 0.) then begin
				srsstr.ar = 0 
			endif else begin
				; Convert NOAA string location to integer version
				srs_hg = fltarr(2, n_elements(srs.loc))
				srs_hg(*, *) =  !Values.F_NAN
				flare_hg = fltarr(2, n_elements(srs.loc))
				flare_hg(*, *) =  !Values.F_NAN
				; Check all NOAA SRS locations for a match
				for i = 0, n_elements(srs.loc) - 1 do begin
					srs_hg(*, i) = locstring2int(location=srs.loc[i])
					if (finite(srs_hg(0, i)) eq 0.) or (finite(srs_hg(1, i)) eq 0.) then begin
						continue
					endif else begin
						; Here rotate SRS location to time of flare peak
						srs_time = anytim(anytim(peaktime, /vms, /date_only) + ' 00:30', /vms)
						hg2hc, srs_hg(1, i), srs_hg(0, i), outhcx, outhcy, date = srs_time, rotdate = peaktime 
						hc2hg, outhcx, outhcy, outhgx, outhgy, date = peaktime 
						flare_hg(0, i) = outhgy
						flare_hg(1, i) = outhgx
					endelse
				endfor	    
				; Now see if something matches within a pre-defined range
				lon_min = hgx - lon_range
				lon_max = hgx + lon_range
				lat_min = hgy - lat_range
				lat_max = hgy + lon_range
				closest_lat = closest(flare_hg(0, *), hgy)
				closest_lon = closest(flare_hg(1, *), hgx)
				if (flare_hg(0, closest_lat) ge lat_min) and (flare_hg(0, closest_lat) le lat_max) and (flare_hg(1, closest_lat) ge lon_min) and (flare_hg(1, closest_lat) le lon_max) then begin
					noaa_ar_index = closest_lat
				endif	  
				if (noaa_ar_index eq -1) then begin
					if (flare_hg(0, closest_lon) ge lat_min) and (flare_hg(0, closest_lon) le lat_max) and (flare_hg(1, closest_lon) ge lon_min) and (flare_hg(1, closest_lon) le lon_max) then begin
						noaa_ar_index = closest_lon
					endif
				endif
				; Try original longitude
				if (noaa_ar_index eq -1) then begin
					closest_lat = closest(srs_hg(0, *), hgy)
					if (srs_hg(0, closest_lat) ge lat_min) and (srs_hg(0, closest_lat) le lat_max) and (srs_hg(1, closest_lat) ge lon_min) and (srs_hg(1, closest_lat) le lon_max) then begin
						noaa_ar_index = closest_lat
					endif	  
				endif
			endelse

		; if there is a NOAA no from the flare event list
		endif else begin
			noaa_ar_index = where(srs.no eq no)
			srs_time = anytim(anytim(starttime, /vms, /date_only) + ' 00:30', /vms)
		endelse

		; -- If still no region identified, check next day (maybe new region) --
		if (noaa_ar_index eq -1) then begin
			next_time = addtime(anytim(starttime, /vms), delta_min=24*60)
			next_day = time2file(next_time, /date_only)
			srs_time = anytim(anytim(next_time, /vms, /date_only) + ' 00:30', /vms)
			srs_next = read_ascii(DATA_FOLDER + 'noaa_srs/' + next_day + 'SRS.txt', template=srs_template)
			noaa_ar_index = where(srs_next.no eq no)
			srs=srs_next
			; Or maybe the previous day if an old region
			if (noaa_ar_index eq -1) then begin
				previous_time = addtime(anytim(starttime, /vms), delta_min=-24*60)
				previous_day = time2file(previous_time, /date_only)
				srs_time = anytim(anytim(previous_time, /vms, /date_only) + ' 00:30', /vms)
				srs_previous = read_ascii(DATA_FOLDER + 'noaa_srs/' + previous_day + 'SRS.txt', template=srs_template)
				noaa_ar_index = where(srs_previous.no eq no)
				srs=srs_previous
			endif
		endif

		; If it still doesnt exist flag it     
		if (noaa_ar_index eq -1) then begin        
			srsstr.ar = 0. 
		endif else begin
			; If found a region output details to structure
			srsstr.ar = 1.
			srsstr.srs_time = srs_time
			srsstr.srs_no = srs.no[noaa_ar_index]
			srsstr.srs_loc = srs.loc[noaa_ar_index]
			; Check there is actually something to output for the sunspot info (sometimes its a halpha region)
			; Changed srs.mcintosh to srs.nn to remove string/float conversion issue
			if (finite(srs.nn[noaa_ar_index]) ne 0.) then begin
				srsstr.srs_mcintosh = srs.mcintosh[noaa_ar_index]
				srsstr.srs_hale = srs.hale[noaa_ar_index]
				srsstr.srs_area = srs.area[noaa_ar_index]
				srsstr.srs_ll = srs.ll[noaa_ar_index]
				srsstr.srs_nn = srs.nn[noaa_ar_index]
			endif
		endelse

	return, srsstr

end