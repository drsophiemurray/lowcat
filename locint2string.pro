;+
; IDL Version:				 8.5 (linux x86_64 m64)
; Written by:						Dr Sophie A. Murray, Trinity College Dublin, 2016
; Working directory:		/home/somurray/Dropbox/helcats_project/helcats.git
; Date: 								Mon July 11 12:27:00 2016
; Purpose:							Given a latitude and longitude integer location, convert to NOAA format string
; Input:								Integer array with latitude 0th element and longitude 1st element.
;												Note, will output a NaN if input not correct format.
; Output:								String in format e.g., 'N01E01'
; Uses:									To convert SMART location format to that of NOAA Solar Region Summary.
;												- see get_flare_ar_info.pro for use with wider code helcats_cme_flare_ar_list.pro


function locint2string, latitude = latitude, longitude = longitude

	if fix(latitude) lt 0. then latdir = 'S' else $ 
	if fix(latitude) ge 0. then latdir = 'N' ;else $ 
;   latdir = !Values.F_NAN
	latcoord = int2str(fix(round(abs(latitude))), 2)
  
	if fix(longitude) lt 0. then londir = 'E' else $ 
	if fix(longitude) ge 0. then londir = 'W' ;else $ 
;   londir = !Values.F_NAN
	loncoord = int2str(fix(round(abs(longitude))), 2)
  
	if n_elements(latdir) eq 0. or n_elements(londir) eq 0. then begin
		return, !Values.F_NAN
	endif else begin
		location = strcompress(latdir + latcoord + londir + loncoord, /remove_all)
	endelse 
  
	return, location

end