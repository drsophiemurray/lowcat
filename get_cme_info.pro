;+
; IDL Version:				8.5 (linux x86_64 m64)
; Journal File for:		somurray@lindau
; Working directory:	/home/somurray/Dropbox/helcats_project/helcats.git
; Date: 							Wed July 7 10:14:25 2016
; Purpose:						Given the HELCATS CME list,
;											get correspdonding CME properties.
; Input:							HELCATS CME info from STEREO A or B.
; Output:							CACTUS database information
;											- see http://secchi.nrl.navy.mil/cactus/secchi_cmecat_combo.sav
; Uses:								Part of wider helcats_list.pro
; Last Update:				2016-07-22 S Murray
;

function get_cme_info, cme_list=cme_list, i=i, secchia_combo=secchia_combo, secchib_combo=secchib_combo, cme_exist=cme_exist

	; ---- Global settings ----
	COMMON FOLDERS
	; The below speeds were defined by P. Zucca based on Yurchyshyn et al
	; http://www.bbso.njit.edu/~vayur/CME_Speeds.html
	cor2_min = 150.
	cor2_max = 1500.
	r_sun = 6.957e5
	angle_range = 10.

	cme_exist = 0. 

; Set up output structure
	cmestr = {hi_sc:' ', hi_time:' ', hi_pan: 0., hi_pas: 0., $
						cor2_ts: ' ', cor2_tf: ' ', cor2_time: ' ', $
						cor2_pa: 0., cor2_width: 0., $
						cor2_v: 0., cor2_vsigma: 0., cor2_vmin: 0., cor2_vmax: 0., $
						cor2_type:' ', cor2_halo:' '}

	; Set up initial parameters
	hi_t = cme_list.data[1, i] ;YYYY-MM-DD HH:MM
	hi_pan = cme_list.data[4, i] ; deg N
	hi_pas = cme_list.data[6, i] ; deg S
	hi_r = 12. * r_sun  ; km
	cor2_r = 2. * r_sun ; km

	; Output HI info
	cmestr.hi_sc = cme_list.data[2, i]
	cmestr.hi_time = anytim(hi_t, /vms)
	cmestr.hi_pan = num2str(hi_pan)
	cmestr.hi_pas = num2str(hi_pas)

	; ==== Get COR2 properties ====

	; Calculate search time in COR2 (comment this)
	cor2_ts = anytim(hi_t) - (hi_r - cor2_r) / cor2_min  
	cor2_tf = anytim(hi_t) - (hi_r - cor2_r) / cor2_max
;  	; Include error to calculate time search window
;  	cor2_del = ssw_deltat(cor2_ts, cor2_tf, /minutes) * (10./575.)
;  	window_start = anytim(addtime(anytim(cor2_ts, /vms), delta_min=-cor2_del))
;  	window_end = anytim(addtime(anytim(cor2_tf, /vms), delta_min=cor2_del))

	; Output search window
	cmestr.cor2_ts = anytim(cor2_ts, /vms)
	cmestr.cor2_tf = anytim(cor2_tf, /vms)

	; Depending if STEREO A or B find the matching CME
	if (cmestr.hi_sc eq 'A') then begin    
		; Get secchi times in a usable format
		secchia_times = anytim(secchia_combo.date + 'T' + secchia_combo.time)
		; Find events within time search window
		event_candidates = where((secchia_times ge anytim(cmestr.cor2_ts)) and (secchia_times le anytim(cmestr.cor2_tf)) and $
															(secchia_combo.angle ge (fix(hi_pan) - angle_range)) and $ 
															(secchia_combo.angle le (fix(hi_pas) + angle_range)))
		cme_candidates = where((secchia_times ge anytim(cmestr.cor2_ts)) and (secchia_times le anytim(cmestr.cor2_tf)) and $
															(secchia_combo.angle ge (fix(hi_pan) - angle_range)) and $ 
															(secchia_combo.angle le (fix(hi_pas) + angle_range)) and $
															(secchia_combo.type eq 'CME'))
		flow_candidates = where((secchia_times ge anytim(cmestr.cor2_ts)) and (secchia_times le anytim(cmestr.cor2_tf)) and $
															(secchia_combo.angle ge (fix(hi_pan) - angle_range)) and $ 
															(secchia_combo.angle le (fix(hi_pas) + angle_range)) and $
															(secchia_combo.type eq 'Flow'))
 		if (event_candidates[0] ne -1) then begin
;		TO DO: Thinking I should avoid flows?
;		if (cme_candidates[0] ne -1) then begin
			; Choose event with angle that most closely matches STEREO event
			hi_pa = (fix(hi_pan) + fix(hi_pas))/2
 			if cme_candidates[0] eq -1 then begin 
 				clos = closest(secchia_combo[flow_candidates].angle, hi_pa)
 				cme_candidate = secchia_combo[flow_candidates[clos]]
 			endif else begin 
				clos = closest(secchia_combo[cme_candidates].angle, hi_pa)
				cme_candidate = secchia_combo[cme_candidates[clos]]
 			endelse
			; This defines a CME has been found
			cme_exist = 1.
			cmestr.cor2_time = anytim(cme_candidate.date + ' ' + cme_candidate.time, /vms)
			cmestr.cor2_pa = cme_candidate.angle
			cmestr.cor2_width = cme_candidate.width
			cmestr.cor2_v = cme_candidate.speed
			cmestr.cor2_vsigma = cme_candidate.speedsigma
			cmestr.cor2_vmin = cme_candidate.min_speed
			cmestr.cor2_vmax = cme_candidate.max_speed
			cmestr.cor2_type = cme_candidate.type
			switch 1 of
				cme_candidate.width GT 120.: cmestr.cor2_halo = 'II' ;90.
				cme_candidate.width GT 180.: cmestr.cor2_halo = 'III'
				cme_candidate.width GT 270.: cmestr.cor2_halo = 'IV'
			endswitch
		endif else begin
			print, 'No COR2 CME found in catalogue for ', cme_list.data[0, i]
			; This defines no CME was found
			cme_exist = 0.
		endelse
	endif
  
	if (cmestr.hi_sc eq 'B') then begin
		secchib_times = anytim(secchib_combo.date + 'T' + secchib_combo.time)
		event_candidates = where((secchib_times ge anytim(cmestr.cor2_ts)) and (secchib_times le anytim(cmestr.cor2_tf)) and $
															(secchib_combo.angle ge (fix(hi_pas) - angle_range)) and $ 
															(secchib_combo.angle le (fix(hi_pan) + angle_range)))
		cme_candidates = where((secchib_times ge anytim(cmestr.cor2_ts)) and (secchib_times le anytim(cmestr.cor2_tf)) and $
															(secchib_combo.angle ge (fix(hi_pas) - angle_range)) and $ 
															(secchib_combo.angle le (fix(hi_pan) + angle_range)) and $
														(secchib_combo.type eq 'CME'))
		flow_candidates = where((secchib_times ge anytim(cmestr.cor2_ts)) and (secchib_times le anytim(cmestr.cor2_tf)) and $
															(secchib_combo.angle ge (fix(hi_pas) - angle_range)) and $ 
															(secchib_combo.angle le (fix(hi_pan) + angle_range)) and $
															(secchib_combo.type eq 'Flow'))
 		if (event_candidates[0] ne -1) then begin
;		if (cme_candidates[0] ne -1) then begin
			hi_pa = (fix(hi_pan) + fix(hi_pas))/2
 			if cme_candidates[0] eq -1 then begin 
 				clos = closest(secchib_combo[flow_candidates].angle, hi_pa)
 				cme_candidate = secchib_combo[flow_candidates[clos]]
 			endif else begin 
				clos = closest(secchib_combo[cme_candidates].angle, hi_pa)
				cme_candidate = secchib_combo[cme_candidates[clos]]
 			endelse
			cme_exist = 1.
			cmestr.cor2_time = anytim(cme_candidate.date + ' ' + cme_candidate.time, /vms)
			cmestr.cor2_pa = cme_candidate.angle
			cmestr.cor2_width = cme_candidate.width
			cmestr.cor2_v = cme_candidate.speed
			cmestr.cor2_vsigma = cme_candidate.speedsigma
			cmestr.cor2_vmin = cme_candidate.min_speed
			cmestr.cor2_vmax = cme_candidate.max_speed
			cmestr.cor2_type = cme_candidate.type
			switch 1 of
				cme_candidate.width GT 120.: cmestr.cor2_halo = 'II' ;90.
				cme_candidate.width GT 180.: cmestr.cor2_halo = 'III'
				cme_candidate.width GT 270.: cmestr.cor2_halo = 'IV'
			endswitch
		endif else begin
			print, 'No COR2 CME found in catalogue for ', cme_list.data[0, i]
			cme_exist = 0.
		endelse
	endif

	return, cmestr

end
