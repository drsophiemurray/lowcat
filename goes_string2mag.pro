;+
; IDL Version:		 		8.5 (linux x86_64 m64)
; Written by:					Dr Sophie A. Murray, Trinity College Dublin, 2016
; Working directory:	/home/somurray/Dropbox/helcats_project/helcats.git
; Date: 							Thurs July 28 14:38:00 2016
; Purpose:						Given a string of GOES class, convert to float.
; Input:							String with class and magnitude, e.g., 'M2.5'
; Output:							Magnitude as float, e.g, 2.5e-5
;											Note, will output a NaN if input not correct format.
; Uses:								To use for flare magnitude analysis with HELCATS project.
;											- see get_flare_ar_info.pro for use with wider code helcats_cme_flare_ar_list.pro

function goes_string2mag, goes = goes

	class = strmid(goes, 0, 1)
	mag = strmid(goes, 1, 3)

	case class of
		'A' : out = mag * 1.0e-8 
		'B' : out = mag * 1.0e-7
		'C' : out = mag * 1.0e-6 
		'M' : out = mag * 1.0e-5 
		'X' : out = mag * 1.0e-4 
		else : out = !Values.F_NAN
	endcase

	return, out

end