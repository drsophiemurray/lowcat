import scipy.io
import sunpy.map
import matplotlib.pyplot as plt
import astropy.units as u
import sunpy.wcs

test=scipy.io.readsav('flare_ar_loc.sav')
#[‘flare_latlon’],[‘ar_latlon’],[‘flare_colors’],[‘ar_colors’]

map = sunpy.map.Map('/Users/sophie/Dropbox/lowcat/results/AIA20140606_0000_0094.fits')
map.data[:,:]=[500.]

jb0 = map.heliographic_latitude.value*u.deg

cm = plt.cm.get_cmap('viridis')

#ar plot
colors = test['ar_colors']
loc = test['ar_latlon']
fig, ax = plt.subplots()
map.plot(title = '', cmap = 'Blues')
map.draw_grid(color = 'k', lw = 0.5)

for i in range(len(loc)):
    sc=sunpy.wcs.convert_hg_hpc(loc[i][1], loc[i][0], b0_deg=jb0, l0_deg=0, angle_units='arcsec')
    plt.scatter(sc[0], sc[1], c=colors[i], s=50, cmap=cm, vmin=min(colors), vmax=max(colors), linewidth=0.0)
    
plt.title('AR')
cbar=plt.colorbar(ticks=[0, 127.5, 255])
cbar.ax.set_yticklabels(['2007-05-17', '2012-07-27', '2016-12-07'])
plt.ylim(map.yrange.value)
plt.xlim(map.xrange.value)
plt.savefig('ar_loc.eps')
plt.close()

#flare plot
colors = test['flare_colors']
loc = test['flare_latlon']
fig, ax = plt.subplots()
map.plot(title = '', cmap = 'Blues')
map.draw_grid(color = 'k', lw = 0.5)

for i in range(len(loc)):
    sc=sunpy.wcs.convert_hg_hpc(loc[i][1], loc[i][0], b0_deg=jb0, l0_deg=0, angle_units='arcsec')
    plt.scatter(sc[0], sc[1], c=colors[i], s=50, cmap=cm, vmin=min(colors), vmax=max(colors), linewidth=0.0)
    
plt.title('Flare')
cbar=plt.colorbar(ticks=[0, 127.5, 255])
cbar.ax.set_yticklabels(['2007-05-17', '2012-07-27', '2016-12-07'])
plt.ylim(map.yrange.value)
plt.xlim(map.xrange.value)
plt.savefig('flare_loc.eps')
plt.close()