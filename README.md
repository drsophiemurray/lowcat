helcats
=======

*Obtaining the source regions of CME events determined with STEREO/HI for the FP7 [HELCATS](http://www.helcats-fp7.eu/) project.*

The original code developed by Pietro Zucca outputted a .html file that can currently be viewed on the Rosse Observatory [webpages](http://data.rosseobservatory.ie/helcats/lowcat/). This code has been modified and extended (``helcats_list.pro``) to obtain active region properties also.

The Solar Monitor Active Region Tracker ([SMART](http://arxiv.org/abs/1006.5898)), written by Paul Higgins, has been further developed to provide active region properties for a particular flare event source region. The code ``get_smart_info.pro``, takes the following inputs:
*  **start_time**: event start time in format DD-Mon-YYYY HH:MM:SS
*  **end_time**: event end time in format DD-Mon-YYYY HH:MM:SS
*  **peak_time**: event peak time in format DD-Mon-YYYY HH:MM:SS
*  **lat**: heliographic latitude location of source region (degrees North)
*  **lon**: heliographic longitude location of source region (degrees West)
This will output a structure of active region properties for the closest identified region to the location provided.

In order to run SMART locally, the following repositries need to be cloned:
*  https://github.com/pohuigin/smart_library
*  https://github.com/pohuigin/gen_library

SMART has been integrated with ``helcats_list.pro`` to provide active region properties for the [CME database](http://www.helcats-fp7.eu/catalogues/wp2_cat.html) created for the HELCATS project, in particular v3 of the catalogue. The main functions of note are:
*  ``helcats_list.pro``
    *  The main code calling Pietro's CME identification and other developed codes listed below. Keywords allow choice of what flare databases to search. It is currently set up to run on WP2 data from HELCATS, but this is easily changeable.
*  ``get_cme_info.pro``
    *  Pietro's helcats_list_new.pro as a function, outputting CME information from the CACTUS database based on STEREO/HI input info.
*  ``get_flarear_info.pro``
    *  Using CME information get corresponding flare event information (from GEVLOC/SWPC/HESSI lists) and AR source information (from NOAA Solar Region Summary). The current version checks the CME PA vs flare lat/lon position to ensure in correct solar quadrant beyond just matching the time ranges.
*  ``get_smart_info.pro``
    * Using identified flare location, run SMART on region to get magnetic properties.

Results are output in .txt, .json, and IDL .sav formats. Computation time on Linux Mint 17 Cinnamon 64-bit with Intel Xeon CPU 3.75GHz x4 with 15.6Gb memory was 168 minutes.

License
-------

The content of this project is licensed under the [Creative Commons Attribution 4.0 license](https://creativecommons.org/licenses/by/4.0/), and the underlying source code used to format and display that content is licensed under the [MIT license](https://opensource.org/licenses/mit-license.php).
