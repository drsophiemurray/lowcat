;+
; IDL Version:				8.5 (linux x86_64 m64)
; Written by:					Dr Sophie A. Murray, Trinity College Dublin, 2016
; Working directory:	/home/somurray/Dropbox/helcats_project/helcats.git
; Date: 							Mon July 11 12:27:00 2016
; Purpose:						Given a string location convert to integer latitude and longitude
; Input: 							String in format e.g., 'N01E01'
; Output: 						Integer array with latitude 0th element and longitude 1st element.
;											Note, will output a NaN if input not correct format.
; Uses:								To convert NOAA Solar Region Summary location format to that of SMART.
;											- see get_flare_ar_info.pro for use with wider code helcats_cme_flare_ar_list.pro

function locstring2int, location = location

	converted = strarr(2)

	latdir = strmid(location, 0, 1)
	latcoord = strmid(location, 1, 2)
	if latdir eq 'S' then lat = -fix(latcoord) else $
	if latdir eq 'N' then lat = fix(latcoord) else $
	lat = !Values.F_NAN

	londir = strmid(location, 3, 1)
	loncoord = strmid(location, 4, 2)
	if londir eq 'E' then lon = -fix(loncoord) else $
	if londir eq 'W' then lon = fix(loncoord) else $
	lon = !Values.F_NAN

	converted[0] = string(lat)
	converted[1] = string(lon)

	return, converted

end