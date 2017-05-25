; NAME:
;    helcats_property_list
;
; PURPOSE:
;    Creates an HTML table for the HELCATS website,
;    Reads in HI CME list and back-propagates to COR2 and
;    Flare/Filamant Location. 
;
; INPUTS:
;    http://www.helcats-fp7.eu/catalogues/wp2_cat.html
;    
; OUTPUTS:
;    http://data.rosseobservatory.ie/helcats/lowcat/
;   
; NOTE:
;    list_loc needs to be provided as a string.
;
; HISTORY:
;    28-May-2015 Code to populate list: Pietro Zucca
;    30-May-2015 Added helcats_connect to find time-window for COR2: Peter Gallagher, Pietro Zucca 
;    14-Jul-2015 Updated list structure; Pietro Zucca
;    27-Jul-2015 Added code to create the html table rows; Pietro Zucca
;    05-Aug-2015 Modified table rows and restructured the HTML formatting for legibility; Pietro Zucca
;    23-Jun-2016 Added NOAA SRS and SMART functionality, updated inputs, created text output instead of html; Sophie Murray
;    08-Jul-2016 Split the code into functions, fixed bugs, added .json, .sav, and .txt output; Sophie Murray
;    09-Aug-2016 Optional searches of SWPC and HESSI events lists, with GEVLOC the default method; Sophie Murray
;    23-Sep-2016 Added searching for flares in quadrants depending on PA, rather than entire solar disk; Sophie Murray
;    20-Dec-2016 Removed bad RHESSI events and spurious polar events, plus some other minor fixes; Sophie Murray
;
; DEPENDANCIES:
;   SSWIDL, including RHESSI, MDI, and HMI packages.
;   SMART IDL code developed by P. Higgins
; 
; EXAMPLE: 
;	helcats_list, /swpc_search, /hessi_search 

pro helcats_list, list_loc = list_loc, swpc_search = swpc_search, hessi_search = hessi_search

	; ==== Global settings ====
	COMMON FOLDERS, SMART_FOLDER, OUT_FOLDER, IN_FOLDER, DATA_FOLDER
	SMART_FOLDER = '/home/somurray/Dropbox/helcats_project/smart.git/'
	OUT_FOLDER = '/home/somurray/lowcat/results/'
	IN_FOLDER = '/home/somurray/Dropbox/helcats_project/helcats.git/data/'
	DATA_FOLDER = '/home/somurray/data/helcats/'

	sys_time = systim(/utc)   ;system time

	; Open the files to be output, and define the headers

  ; -------------------------------------------------------------------------------------------------------
	; ---- Output data ----
	; .txt format
	openw, 1, OUT_FOLDER + 'lowcat.txt'
	header = ['No.', 'ID', $
						'SC', 'HI time', 'HI PA N', 'HI PA S', $
						'COR2 window start', 'COR2 window end', 'COR2 candidate time', $
						'C2_PA', 'C2width', $
						'C2_v', 'C2_vsig', 'C2_vmin', 'C2_vmax', $
						'C2type', 'C2halo', $
						'Flare window start', 'Flare window end', $
						'Obs type', $
						'Flare candidate start', 'Flare candidate end', 'Flare candidate peak', $
						'GOES', 'Flare Loc', $
						'SRS time', $
						'NOAANo', 'NOAA Loc', $
						'McIntosh', 'Hale', 'Area', $
						'NOAA LL', 'NOAA NN', $
						'SMART time', 'Location', 'Limb', $
						'Total flux', 'Pos flux', 'Neg flux', 'Frac flux', $
						'Mag area', 'Pos area', 'Neg area', $
						'B_min', 'B_max', 'B mean', $
						'PSL length', 'R value', 'WLSG', 'Bip_sep']	    	    
	printf, 1, header, format = '((A8, 3X, A20, 3X, A8, 3X, A20, 3X, A8, 3X, A8, 3X, A20, 3X, A20, 3X, A20, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X,   A20, 3X, A20, 3X, A8, 3X, A20, 3X, A20, 3X, A20, 3X, A8, 3X, A8, 3X,   A20, 3X, A8, 3X, A8, 3X, A8, 3X, A20, 3X, A8, 3X, A8, 3X, A8, 3X,   A20, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8, 3X, A8))'

	openw, 2, OUT_FOLDER + 'lowcat.html'
	fonts_style = '<td bgcolor="white" align="center"> <font size="-1" face="Sans-Serif, Helvetica, Arial" color="black">'
	
	; ---- Structures ----
	; .sav format
	cmestr = {hi_sc:' ', hi_time:' ', hi_pan: 0., hi_pas: 0., $
						cor2_ts: ' ', cor2_tf: ' ', cor2_time: ' ', $
						cor2_pa: 0., cor2_width: 0., $
						cor2_v: 0., cor2_vsigma: 0., cor2_vmin: 0., cor2_vmax: 0., $
						cor2_type: ' ', cor2_halo:' '}
	flarestr = {fl_ts:' ', fl_tf: ' ', $
							fl_type: ' ', $
							fl_starttime: ' ', fl_endtime: ' ', $
							fl_peaktime: ' ', fl_goes: ' ', fl_loc: ' ', $
							srs_time: ' ', $
							srs_no: 0., srs_loc: ' ' , $
							srs_mcintosh: ' ', srs_hale: ' ' , $
							srs_area: 0., srs_ll: 0., srs_nn: 0.}
	smartstr = {smart_time:' ', smart_hglatlon:' ', smart_limb:' ', $
							smart_totflx:0., smart_posflx:0., smart_negflx:0., smart_frcflx:0d, $
							smart_totarea:0., smart_posarea:0., smart_negarea:0., $
							smart_bmin:0., smart_bmax:0., smart_bmean:0., $
							smart_psllen:0., smart_rvalue:0., smart_wlsg:0., smart_bipolesep:0.}

  ; -------------------------------------------------------------------------------------------------------
	; ==== Load the HELCATS CME list ====

	; Download file from webpage if not defined when calling code
;	if (n_elements(list_loc) eq 0) then begin
;		spawn, 'wget https://www.helcats-fp7.eu/catalogues/data/HCME_WP2_V03.json -O ' + IN_FOLDER + 'HCME_WP2_V03.json'
;	endif
	cme_list = json_parse(IN_FOLDER + 'HCME_WP2_V04.json', /toarray, /tostruct)

	; List size (ignore first line as header)
	list_size = n_elements(cme_list.data[0, *])
	; Replicate structures
	cmestr = replicate(cmestr, list_size)
	flarestr = replicate(flarestr, list_size)
	smartstr = replicate(smartstr, list_size)

	; Download the latest COR2 CME CACTUS database
; 	cactus = webget("http://secchi.nrl.navy.mil/cactus/secchi_cmecat_combo.sav", $
; 									copyfile=IN_FOLDER+'secchi_cmecat_combo.sav')
	restore, IN_FOLDER + 'secchi_cmecat_combo.sav', /verb ; Loads SECCHIA_COMBO and SECCHIB_COMBO

  ; -------------------------------------------------------------------------------------------------------
	; ==== Get properties ====
	for i = 0, list_size-1 do begin

		print, 'Running for event ',  strtrim(i, 1) + 1, ': ', cme_list.data[0, i]
		; ---- Get CME information ----
		cme_properties = get_cme_info(cme_list=cme_list, i=i, $
				                          secchia_combo=secchia_combo, secchib_combo=secchib_combo, $
				                          cme_exist=cme_exist) 
		cmestr[i] = cme_properties

		; ---- Get flare information ----
		; Note previously used get_flare_ar_info for hessi events only
		if keyword_set(swpc_search) and keyword_set(hessi_search) then begin
			flare_ar_properties = get_flarear_info(cme_properties=cme_properties, $
			                                        cme_exist=cme_exist, flare=flare, ar=ar, $
                                              hgx=hgx, hgy=hgy, hcx=hcx, hcy=hcy, $
                                              /swpc_search, /hessi_search)
		endif
		if keyword_set(swpc_search) and not keyword_set(hessi_search) then begin
			flare_ar_properties = get_flarear_info(cme_properties=cme_properties, $
                                              cme_exist=cme_exist, flare=flare, ar=ar, $
                                              hgx=hgx, hgy=hgy, hcx=hcx, hcy=hcy, $
                                              /swpc_search)
		endif
		if keyword_set(hessi_search) and not keyword_set(swpc_search) then begin
			flare_ar_properties = get_flarear_info(cme_properties=cme_properties, $
                                              cme_exist=cme_exist, flare=flare, ar=ar, $
                                              hgx=hgx, hgy=hgy, hcx=hcx, hcy=hcy, $
                                              /hessi_search)
		endif
		if not keyword_set(swpc_search) and not keyword_set(hessi_search) then begin
			flare_ar_properties = get_flarear_info(cme_properties=cme_properties, $
                                              cme_exist=cme_exist, flare=flare, ar=ar, $
                                              hgx=hgx, hgy=hgy, hcx=hcx, hcy=hcy)
		endif
		flarestr[i] = flare_ar_properties

		; ---- Get SMART properties ---- 
		smart_properties = get_smart_info(start_time=flare_ar_properties.fl_starttime, end_time=flare_ar_properties.fl_endtime, peak_time=flare_ar_properties.fl_peaktime, $
                                      hgy=hgy, hgx=hgx, hcx=hcx, hcy=hcy)
		smartstr[i] = smart_properties

  ; -------------------------------------------------------------------------------------------------------

		; ==== Save to text file ====
		printf, 1, num2str(i+1), cme_list.data[0, i], $
		cme_properties, flare_ar_properties, smart_properties, $
		format = '((I8, 3X, A20, 3X, A8, 3X, A20, 3X, I8, 3X, I8, 3X, A20, 3X, A20, 3X, A20, 3X, I8, 3X, I8, 3X, I8, 3X, I8, 3X, I8, 3X, I8, 3X, A8, 3X, A8, 3X,   A20, 3X, A20, 3X, A8, 3X, A20, 3X, A20, 3X, A20, 3X, A8, 3X, A8, 3X,   A20, 3X, I8, 3X, A8, 3X, A8, 3X, A20, 3X, I8, 3X, I8, 3X, I8, 3X,   A20, 3X, A8, 3X, A8, 3X, E8.2, 3X, E8.2, 3X, E8.2, 3X, F8.4, 3X, F8.2, 3X, F8.2, 3X, F8.2, 3X, F8.2, 3X, F8.2, 3X, F8.2, 3X, F8.2, 3X, E8.2, 3X, E8.2, 3X, F8.2))'    

		; === Now Pietro's html table === 
		printf, 2, '<tr>'
		printf, 2, fonts_style + cme_list.data[0, i] + '</font></td>'  ;HELCATS ID
		if cme_properties.cor2_time eq ' ' then begin
			printf, 2, fonts_style + ' ' + '</font></td>'
		endif else begin
			printf, 2, fonts_style + time2file(cme_properties.cor2_time) + '</font></td>'
		endelse
			if cme_properties.cor2_pa eq 0. then begin
			printf, 2, fonts_style + ' ' + '</font></td>'
		endif else begin
			printf, 2, fonts_style + num2str(cme_properties.cor2_pa, format = '(i8)') + '</font></td>'
		endelse
		if cme_properties.cor2_width eq 0. then begin
			printf, 2, fonts_style + ' ' + '</font></td>'
		endif else begin		
			printf, 2, fonts_style + num2str(cme_properties.cor2_width, format = '(i8)') + '</font></td>'
		endelse
		if cme_properties.cor2_v eq 0. then begin
			printf, 2, fonts_style + ' ' + '</font></td>'
		endif else begin
			printf, 2, fonts_style + num2str(cme_properties.cor2_v, format = '(i8)') + '</font></td>'
		endelse
		if flare_ar_properties.fl_peaktime eq ' ' then begin
			printf, 2, fonts_style + ' ' + '</font></td>'
		endif else begin
			printf, 2, fonts_style + time2file(flare_ar_properties.fl_peaktime) + '</font></td>'
		endelse
		printf, 2, fonts_style + flare_ar_properties.fl_goes + '</font></td>'
		printf, 2, fonts_style + flare_ar_properties.fl_loc + '</font></td>'
		if flare_ar_properties.srs_no eq 0. then begin
			printf, 2, fonts_style + ' ' + '</font></td>'
		endif else begin
			printf, 2, fonts_style + num2str(flare_ar_properties.srs_no,format='(i8)') + '</font></td>'
		endelse
		printf, 2, fonts_style + flare_ar_properties.srs_mcintosh + '</font></td>'
		if smart_properties.smart_totarea eq 0. then begin
			printf, 2, fonts_style + ' ' + '</font></td>'
		endif else begin
			printf, 2, fonts_style + num2str(smart_properties.smart_totarea,format='(f8.2)') + '</font></td>'
		endelse
		if smart_properties.smart_totflx eq 0. then begin
			printf, 2, fonts_style + ' ' + '</font></td>'
		endif else begin
			printf, 2, fonts_style + num2str(smart_properties.smart_totflx,format='(e8.2)') + '</font></td>'
		endelse
		if smart_properties.smart_rvalue eq 0. then begin
			printf, 2, fonts_style + ' ' + '</font></td>'
		endif else begin
			printf, 2, fonts_style + num2str(smart_properties.smart_rvalue,format='(e8.2)') + '</font></td>'
		endelse
		if smart_properties.smart_wlsg eq 0. then begin
			printf, 2, fonts_style + ' ' + '</font></td>'
		endif else begin
			printf, 2, fonts_style + num2str(smart_properties.smart_wlsg,format='(e8.2)') + '</font></td>'
		endelse
		printf, 2, '</tr>'
	
	endfor

	close, 1
	close, 2


	; ==== Create json file ====

	; Grab the HELCATS ID and merge the separate structures for CME, flare, and AR information
	liststr = {hel_id:' '}
	liststr = replicate(liststr, list_size)
	outstr = {hel_id:' ', $
						hi_sc:' ', hi_time:' ', hi_pan: 0., hi_pas: 0., $
						cor2_ts: ' ', cor2_tf: ' ', cor2_time: ' ', $
						cor2_pa: 0., cor2_width: 0., $
						cor2_v: 0., cor2_vsigma: 0., cor2_vmin: 0., cor2_vmax: 0., $
						cor2_type: ' ', cor2_halo:' ', $
						fl_ts:' ', fl_tf: ' ', $
						fl_type: ' ', $
						fl_starttime: ' ', fl_endtime: ' ', $
						fl_peaktime: ' ', fl_goes: ' ', fl_loc: ' ', $
						srs_time: ' ', $
						srs_no: 0., srs_loc: ' ' , $
						srs_mcintosh: ' ', srs_hale: ' ' , $
						srs_area: 0., srs_ll: 0., srs_nn: 0., $
						smart_time:' ', smart_hglatlon:' ', smart_limb:' ', $
						smart_totflx:0., smart_posflx:0., smart_negflx:0., smart_frcflx:0d, $
						smart_totarea:0., smart_posarea:0., smart_negarea:0., $
						smart_bmin:0., smart_bmax:0., smart_bmean:0., $
						smart_psllen:0., smart_rvalue:0., smart_wlsg:0., smart_bipolesep:0.}
	outstr = replicate(outstr, list_size)

	for i = 0, (list_size - 1) do begin
		liststr[i].hel_id = cme_list.data[0, i]
		outstr[i] = create_struct(liststr[i], cmestr[i], flarestr[i], smartstr[i])
	endfor

	; Create JSON
	outjson = json_serialize(outstr)

	; Save output
	openw, lun, OUT_FOLDER + 'lowcat.json', /get_lun
	printf, lun, outjson
	close, lun

	; ==== Create IDL .sav file ====
	save, cme_list, outstr, file = OUT_FOLDER + 'lowcat.sav'
	
	; -------------------------------------------------------------------------------------------------------
	; ==== End of code ====
	print, 'Computation time = ', fix((anytim(systim(/utc)) - anytim(sys_time))/60.), ' minutes'

; stop
  
end