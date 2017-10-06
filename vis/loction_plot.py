# -*- coding: utf-8 -*-
"""
Created on Tue Jul 25 12:13:48 2017

@author: jguerraa
"""

import astropy.units as u
import sunpy.map
import sunpy.data.sample
import numpy as np
import pickle
import matplotlib.pyplot as plt
import matplotlib as mpl
import json
from scipy.interpolate import interp1d
#import matplotlib.colors as colors
import matplotlib.cm as cmx
import scipy.interpolate
import scipy.stats
from astropy.coordinates import SkyCoord
import sunpy.coordinates



def location(loc):

    loc1 = []
    if loc != ' ':
        slat1 = loc[0:1]
        slon1 = loc[3:4]
        if slat1 == 'N':
            slat = 1
        else:
            slat = -1
        if slon1 == 'E':
            slon = -1
        else:
            slon = 1
        lat = int(float(loc[1:3]))
        lon = int(float(loc[4:6]))
        loc1.append(slat*lat)
        loc1.append(slon*lon)
        #loc1.append(lat)
        #loc1.append(lon)
        return loc1

#data = pd.read_json('alpha_exp_cwt_blos_fl_full_db_24h.txt')
with open('helcats_list_flarecast_properties_28July17.txt') as data_file:
    data = json.load(data_file)
#
prop = 'fc_data_q'
#
loc, quality = [], []
for event in enumerate(data):
    try:
        quality.append(event[1]['FC_data'][prop])
        #print x
        loc.append(location(event[1]['FL_LOC']))
    except:
        continue

#sunpy.data.download_sample_data()
#header = {'b0':0.0}
map1 = sunpy.map.Map(sunpy.data.sample.AIA_171_IMAGE)
map1.data = np.zeros(map1.data.shape)
jb0 = map1.heliographic_latitude.value*u.deg
#map1 = sunpy.map.Map((mapp.data,header))

fig, ax = plt.subplots()
#fig = plt.figure(figsize=(15, 10))

map1.plot(title = '', cmap = 'Blues')
map1.draw_grid(color = 'k', lw = 0.5)
colors=np.array(quality)
cm = plt.cm.get_cmap('viridis')

for i in range(len(loc)):
    sc=sunpy.wcs.convert_hg_hpc(loc[i][1], loc[i][0], b0_deg=jb0,
l0_deg=0, angle_units='arcsec')
    plt.scatter(sc[0], sc[1], c=colors[i], s=100, cmap=cm,
vmin=min(colors), vmax=15, linewidth=0.0)

plt.title('Region Matching Quality Factor')
plt.colorbar(label='[degree]')
plt.ylim(map1.yrange.value)
plt.xlim(map1.xrange.value)
plt.savefig('data_quality1.pdf')
plt.close()