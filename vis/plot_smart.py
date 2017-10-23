from astropy.coordinates import SkyCoord
import astropy.units as u


fits='/Users/sophie/Dropbox/hmi.M_720s.20110621_040000_TAI.fits'
map=sunpy.map.Map(fits)

fig, ax = plt.subplots()
map.plot(vmin=-500,vmax=500)
cbar=plt.colorbar(ticks=[-500, -250, 0, 250, 500])
cbar.ax.set_title('Gauss')
plt.savefig('smart_full.eps')
plt.close()

xr = SkyCoord(-100*u.arcsec, 100*u.arcsec, frame=map.coordinate_frame)
yr = SkyCoord(400*u.arcsec, 400*u.arcsec, frame=map.coordinate_frame)
submap=map.submap(xr,yr)

fig, ax = plt.subplots()
submap.plot(vmin=-500,vmax=500)
cbar=plt.colorbar(ticks=[-500, -250, 0, 250, 500])
plt.savefig('smart_zoom.eps')
plt.close()
