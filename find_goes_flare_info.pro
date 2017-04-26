;+
; NAME: find_goes_flare_info
; 
; Explanation:  finds all the information of GOES soft X-ray flares 
;
; CALLING SEQUENCE:
;          find_goes_flare_info, t_start, t_end, dt=dt
;
; INPUT PARAMETERS:
;          t_start : a string of the start time for searching GOES flares (in the format of YYYYMMDD_HHMM, e.g., '20130114_0826',)
;          t_end   : a string of the end time for searching GOES flares (in the format of YYYYMMDD_HHMM, e.g., '20130115_0826',)
;           
; OUTPUT: 
;          out.mag    : flare magnitute
;          out.date   : flare occurrence date
;          out.stime  : flare start stime
;          out.ptime  : flare peak stime
;          out.etime  : flare end stime
;          out.tflux  : flare total Soft X-ray flux
;          out.region : flare source active region number
;          out.loc    : flare location
;          * If there is no flare at the date, then out is assigned with -1.
;                 
; MODIFICATION HISTORY:
;           Written February 2013 by Sung-Hong Park             
;           Updated August 2016 by Sophie Murray (for use with HELCATS structures)
;           Bug fix in January 2017 by Sophie Murray (to allow flare end/peak date to be the next day rather than just using start date)
;           Updated in February 2017 by Sophie Murray (use flare start/end/peak instead of just flare start to search for flares)

function find_goes_flare_info, t_start, t_end, dt=dt

	COMMON FOLDERS
; 	DATA_FOLDER = '/home/somurray/data/helcats/'

	; Create output structure (S Murray)
	outstr = {stime:' ', etime: ' ', ptime: ' ', $
						magnitude: ' ', tflux: ' ', $
						region: 0., location: ' '}

	if not isvalid(dt) then dt = 0.

	date_start = julday(fix(strmid(t_start, 4, 2)), fix(strmid(t_start, 6, 2)), fix(strmid(t_start, 0, 4)))
	date_end = julday(fix(strmid(t_end, 4, 2)), fix(strmid(t_end, 6, 2)), fix(strmid(t_end, 0, 4))) + fix(dt)

	julday_start = julday(fix(strmid(t_start, 4, 2)), fix(strmid(t_start, 6, 2)), fix(strmid(t_start, 0, 4)), $ 
												fix(strmid(t_start, 9, 2)), fix(strmid(t_start, 11, 2)))
	julday_end = julday(fix(strmid(t_end, 4, 2)), fix(strmid(t_end, 6, 2)), fix(strmid(t_end, 0, 4)), $
											fix(strmid(t_end, 9, 2)), fix(strmid(t_end, 11, 2))) + dt

	dates = strarr(fix(date_end - date_start) + 1)

	flist_mag = strarr(1)
	flist_date = strarr(1)
	flist_stime = strarr(1)
	flist_ptime = strarr(1)
	flist_etime = strarr(1)
	flist_tflux = strarr(1)
	flist_region = strarr(1)
	flist_loc = strarr(1)

	for i = 0, fix(date_end - date_start) do begin

		caldat, (date_start + i), mo, da, yr
  
		if (mo ge 10) then begin
			mo = strtrim(string(mo), 2)
		endif else begin
			mo = '0' + strtrim(string(mo), 2)
		endelse
  
		if (da ge 10) then begin
			da = strtrim(string(da), 2)
		endif else begin
			da = '0' + strtrim(string(da), 2)
		endelse
  
		dates[i] = strtrim(string(yr), 2) + mo + da

		if yr ge 2016 then begin
			sock_list, 'ftp://ftp.swpc.noaa.gov/pub/warehouse/' + strtrim(string(yr), 2) + '/' + strtrim(string(yr), 2) + '_events/' + dates[i] + 'events.txt', events, err = error
			while (error ne '') do begin
				sock_list, 'ftp://ftp.swpc.noaa.gov/pub/warehouse/' + strtrim(string(yr), 2) + '/' + strtrim(string(yr), 2) + '_events/' + dates[i] + 'events.txt', events, err = error
			endwhile
		endif else begin
			file = file_search(DATA_FOLDER + 'noaa_events/' + dates[i] + 'events.txt')
			openr, lun, file, /GET_LUN
			events = ''
			line = ''
			while not eof(lun) do begin & $
				readf, lun, line & $
				events = [events, line] & $
			endwhile
				events = events[1:*]
			free_lun, lun
		endelse

		start = where(events eq '#Event    Begin    Max       End  Obs  Q  Type  Loc/Frq   Particulars       Reg#') + 2
  
		for j = start[0], fix(n_elements(events)) - 1 do begin
    
			if strpos(events[j], '1-8A') ne -1 then begin
     
				; The original commented code was taking the flare start and associating it with the range
				; I have changed to instead use start/end/peak for HELCATS, considering the windows are big estimates (S Murray)
; 				flist_julday = julday(fix(strmid(events[2], 12, 2)), fix(strmid(events[2], 15, 2)), fix(strmid(events[2], 7, 4)), $
; 															fix(strmid(events[j], 11, 2)), fix(strmid(events[j], 13, 2)))
 				flist_julday_start = julday(fix(strmid(events[2], 12, 2)), fix(strmid(events[2], 15, 2)), fix(strmid(events[2], 7, 4)), $
 															fix(strmid(events[j], 11, 2)), fix(strmid(events[j], 13, 2)))
				flist_julday_end = julday(fix(strmid(events[2], 12, 2)), fix(strmid(events[2], 15, 2)), fix(strmid(events[2], 7, 4)), $
															fix(strmid(events[j], 28, 2)), fix(strmid(events[j], 30, 2)))
				flist_julday_peak = julday(fix(strmid(events[2], 12, 2)), fix(strmid(events[2], 15, 2)), fix(strmid(events[2], 7, 4)), $
															fix(strmid(events[j], 18, 2)), fix(strmid(events[j], 20, 2)))
     
				if ((flist_julday_start ge julday_start) and (flist_julday_start lt julday_end)) or $
						((flist_julday_end ge julday_start) and (flist_julday_end lt julday_end)) or $
						((flist_julday_peak ge julday_start) and (flist_julday_peak lt julday_end)) then begin
					f_id = strmid(events[j], 0, 4)
					flist_mag = [flist_mag, strmid(events[j], strpos(events[j], '1-8A') + 10, 4)] 
					flist_date = [flist_date, strmid(events[2], 7, 4) + '-' + strmid(events[2], 12, 2) + '-' + strmid(events[2], 15, 2)]
					flist_stime = [flist_stime, strmid(events[j], 11, 2) + ':' + strmid(events[j], 13, 2)]
					flist_ptime = [flist_ptime, strmid(events[j], 18, 2) + ':' + strmid(events[j], 20, 2)]
					flist_etime = [flist_etime, strmid(events[j], 28, 2) + ':' + strmid(events[j], 30, 2)]
					flist_tflux = [flist_tflux, strmid(events[j], strpos(events[j], '1-8A') + 18, 7)]
					flist_region = [flist_region, strmid(events[j], strpos(events[j], '1-8A') + 28, 4)]

					s = 0
					for jj = start[0], fix(n_elements(events)) - 1 do begin
						if (strmid(events[jj], 0, 4) eq f_id) and (strmid(events[jj], 43, 3) eq 'FLA') then begin
							f_loc = strmid(events[jj], strpos(events[jj], 'FLA') + 5, 6)
							s = s + 1
						endif   
					endfor       
        
					if s eq 0 then begin
						flist_loc = [flist_loc, '      ']
					endif else begin
						flist_loc = [flist_loc, f_loc]
					endelse
          
				endif  
     
			endif 
   
		endfor 
  
	endfor

	if n_elements(flist_mag) gt 1 then begin 
		flist_mag = flist_mag[1:*]
		flist_date = flist_date[1:*]
		flist_stime = flist_stime[1:*]
		flist_ptime = flist_ptime[1:*]
		flist_etime = flist_etime[1:*]
		flist_tflux = flist_tflux[1:*]
		flist_region = flist_region[1:*]
		; Dont want the below format so have commented out (S Murray)
		;flist_region(where(flist_region ne '    '))='1'+flist_region(where(flist_region ne '    '))
		;flist_region(where(flist_region eq '    '))=' '+flist_region(where(flist_region eq '    '))
		flist_loc=flist_loc[1:*]
	endif else begin
		; Commented out old structure format (S Murray)
; 		out={mag:-1, date:-1, stime:-1, ptime:-1, etime:-1, tflux:-1, region:-1, loc:-1}
		outstr.stime = -1
		outstr.etime = -1
		outstr.ptime = -1
		outstr.magnitude = -1
		outstr.tflux = -1
		outstr.region = -1
		outstr.location = -1
		return, outstr
	endelse

	list_size = n_elements(flist_mag)
	outstr = replicate(outstr, list_size) 
	for i = 0, list_size - 1 do begin
		outstr[i].stime = anytim(flist_date[i] + ' ' + flist_stime[i],/vms)
		outstr[i].etime = anytim(flist_date[i] + ' ' + flist_etime[i],/vms)
		outstr[i].ptime = anytim(flist_date[i] + ' ' + flist_ptime[i],/vms)
		; Added below to inlcude flares going into next day (S Murray)
		if flist_date[i] NE '' then begin
			timediff = anytim(flist_etime[i])-anytim(flist_stime[i])
			next_day = anytim(addtime(outstr[i].etime, delta_min=24*60),/vms)
			if timediff LT 0. then outstr[i].etime = next_day
			timediff = anytim(flist_ptime[i])-anytim(flist_stime[i])
			next_day = anytim(addtime(outstr[i].ptime, delta_min=24*60),/vms)
			if timediff LT 0. then outstr[i].ptime = next_day
		endif
		outstr[i].magnitude = flist_mag[i]
		outstr[i].tflux = flist_tflux[i]
		if (flist_region[i] eq '    ') then begin
			outstr[i].region = 0.
		endif else begin
			outstr[i].region = strtrim(fix(flist_region[i]), 1)
		endelse
		outstr[i].location = flist_loc[i]
	endfor 
	
	; Commented out old structure format (S Murray)
; 	out = {mag:flist_mag, date:flist_date, $
; 				stime:flist_stime, ptime:flist_ptime, etime:flist_etime, $
; 				tflux:flist_tflux, region:flist_region, loc:flist_loc}

	return, outstr

end