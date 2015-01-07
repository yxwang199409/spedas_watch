;+
;PROCEDURE: 
;	MVN_SWIA_MSE_PLOT
;PURPOSE: 
;	Routine to plot any scalar or vector quantity in MSE
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_MSE_PLOT
;INPUTS:
;KEYWORDS:
;	TR: Time range (uses current tplot if not set)
;	XRANGE, YRANGE, ZRANGE: Obvious
;	PRANGE: Color plot range for scalar plots
;	PLOG: Log scale color plots
;	LEN: Length to scale vectors to for vector plots
;	PDATA: Tplot variable for position data (defaults to MSO position)
;	IDATA: Tplot variable for IMF direction (defaults to 'bsw')
;	SDATA: Tplot variable for quantity to display
;	SINDEX: Vector component to plot as scalar (1-3, after rotation to MSE. If not given, produces vector plot)
;	NBX: Number of bins in x
;	NBY: Number of bins in y (or r for cylindrical)
;	NBZ: Number of bins in z
;	QNORM: Quantity to normalize plots by
;	QFILT: Quantity to filter plots by
;	QRANGE: Range of quantity to filter plots by
;
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2015-01-05 09:58:59 -0800 (Mon, 05 Jan 2015) $
; $LastChangedRevision: 16585 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_mse_plot.pro $
;
;-

pro mvn_swia_mse_plot, tr = tr,xrange = xrange, yrange = yrange,zrange = zrange, pdata = pdata, idata = idata, sdata = sdata, sindex = sindex, nbx = nbx, nby = nby, nbz = nbz, prange = prange, len = len, plog = plog, qrange = qrange, qfilt = qfilt, qnorm = qnorm


RM = 3397.

if not keyword_set(xrange) then xrange = [-8e3,8e3]
if not keyword_set(yrange) then yrange = [-8e3,8e3]
if not keyword_set(zrange) then zrange = [-8e3,8e3]
if not keyword_set(pdata) then pdata = 'MAVEN_POS_(MARS-MSO)'
if not keyword_set(bdata) then idata = 'bsw'
if not keyword_set(sdata) then sdata = 'mvn_swim_density'
if not keyword_set(nbx) then nbx = 100
if not keyword_set(nby) then nby = 100
if not keyword_set(nbz) then nbz = 100
if not keyword_set(plog) then plog = 0
if not keyword_set(len) then len = 1

rrange = [0,sqrt(max(abs(yrange))^2 + max(abs(zrange))^2)]

dx = (xrange[1]-xrange[0])/nbx
dy = (yrange[1]-yrange[0])/nby
dz = (zrange[1]-zrange[0])/nbz
dr = (rrange[1]-rrange[0])/nby


@tplot_com

if not keyword_set(tr) then tr = tplot_vars.options.trange

get_data,pdata,data = pos
get_data,idata,data = imf
get_data,sdata,data = plot
if keyword_set(qnorm) then get_data,qnorm,data = qn
if keyword_set(qfilt) then get_data,qfilt,data = qf

w = where(plot.x ge tr[0] and plot.x le tr[1],nel)

time = plot.x[w]

x = interpol(pos.y[*,0],pos.x,time)
y = interpol(pos.y[*,1],pos.x,time)
z = interpol(pos.y[*,2],pos.x,time)


psize = size(plot.y)
if psize[0] eq 1 then begin
	ptype = 'scalar'
	pq = plot.y[w]
endif else begin
	ptype = 'vector'
	pq = plot.y[w,0:2]
endelse

imfx = interpol(imf.y[*,0],imf.x,time)
imfy = interpol(imf.y[*,1],imf.x,time)
imfz = interpol(imf.y[*,2],imf.x,time)

theta = atan(imfz,imfy)
xmse = x
ymse = y*cos(theta) + z*sin(theta)
zmse = -1*y*sin(theta) + z*cos(theta)

w = where(xmse ge xrange[0] and xmse le xrange[1] and ymse ge yrange[0] and ymse le yrange[1] and zmse ge zrange[0] and zmse le zrange[1],nel)

xmse = xmse[w]
ymse = ymse[w]
zmse = zmse[w]
time = time[w]
theta = theta[w]

if ptype eq 'vector' then begin
	pqx = pq[w,0]
	pqy = pq[w,1]*cos(theta) + pq[w,2]*sin(theta)
	pqz = -1*pq[w,1]*sin(theta) + pq[w,2]*cos(theta)
	pq = pqx
	if keyword_set(sindex) then begin
		ptype = 'scalar'
		if sindex eq 1 then pq = pqx
		if sindex eq 2 then pq = pqy
		if sindex eq 3 then pq = pqz
	endif

endif else begin

	pq = pq[w]
endelse

if keyword_set(qnorm) then begin
	uqn = interpol(qn.y,qn.x,time)
	if ptype eq 'vector' then begin
		pqx = pqx/uqn
		pqy = pqy/uqn
		pqz = pqz/uqn
	endif 
	pq = pq/uqn
endif

if keyword_set(qfilt) then begin
	uqf = interpol(qf.y,qf.x,time)
	if not keyword_set(qrange) then qrange = [min(uqf),max(uqf)]
	w = where(uqf ge qrange[0] and uqf le qrange[1],nel)
	if ptype eq 'vector' then begin
		pqx = pqx[w]
		pqy = pqy[w]
		pqz = pqz[w]
	endif
	pq = pq[w]

	xmse = xmse[w]
	ymse = ymse[w]
	zmse = zmse[w]
endif

binxy = fltarr(nbx,nby,3)
normxy = fltarr(nbx,nby)
binxz = fltarr(nbx,nbz,3)
normxz = fltarr(nbx,nbz)
bincyl = fltarr(nbx,nby,3)
normcyl = fltarr(nbx,nby)
binyz = fltarr(nby,nbz,3)
normyz = fltarr(nby,nbz)

i1 = floor(xmse-xrange[0])/dx
i2 = floor(ymse-yrange[0])/dy
i3 = floor(zmse-zrange[0])/dz
i4 = floor(sqrt(ymse^2+zmse^2)-rrange[0])/dr

for i = 0,nel-1 do begin
	if finite(pq[i]) then begin
		binxy[i1[i],i2[i],0] = binxy[i1[i],i2[i],0] + pq[i]
		normxy[i1[i],i2[i]] = normxy[i1[i],i2[i]] + 1
		binxz[i1[i],i3[i],0] = binxz[i1[i],i3[i],0] + pq[i]
		normxz[i1[i],i3[i]] = normxz[i1[i],i3[i]] + 1
		bincyl[i1[i],i4[i],0] = bincyl[i1[i],i4[i],0] + pq[i]
		normcyl[i1[i],i4[i]] = normcyl[i1[i],i4[i]] + 1
		binyz[i2[i],i3[i],0] = binyz[i2[i],i3[i],0] + pq[i]
		normyz[i2[i],i3[i]] = normyz[i2[i],i3[i]] + 1

		if ptype eq 'vector' then begin
			binxy[i1[i],i2[i],1] = binxy[i1[i],i2[i],1] + pqy[i]
			binxz[i1[i],i3[i],1] = binxz[i1[i],i3[i],1] + pqy[i]
			bincyl[i1[i],i4[i],1] = bincyl[i1[i],i4[i],1] + (pqy[i]*ymse[i] + pqz[i]*zmse[i])/sqrt(ymse[i]^2+zmse[i]^2) 
			binyz[i2[i],i3[i],1] = binyz[i2[i],i3[i],1] + pqy[i]
			binxy[i1[i],i2[i],2] = binxy[i1[i],i2[i],2] + pqz[i]
			binxz[i1[i],i3[i],2] = binxz[i1[i],i3[i],2] + pqz[i]
			bincyl[i1[i],i4[i],2] = bincyl[i1[i],i4[i],2] + sqrt(pqy[i]^2 + pqz[i]^2) - ((pqy[i]*ymse[i])^2 + (pqz[i]*zmse[i])^2)/sqrt(ymse[i]^2+zmse[i]^2) 
			binyz[i2[i],i3[i],2] = binyz[i2[i],i3[i],2] + pqz[i]
		endif
	endif
endfor

binxy[*,*,0] = binxy[*,*,0]/(normxy>1)
binxz[*,*,0] = binxz[*,*,0]/(normxz>1)
bincyl[*,*,0] = bincyl[*,*,0]/(normcyl>1)
binyz[*,*,0] = binyz[*,*,0]/(normyz>1)
binxy[*,*,1] = binxy[*,*,1]/(normxy>1)
binxz[*,*,1] = binxz[*,*,1]/(normxz>1)
bincyl[*,*,1] = bincyl[*,*,1]/(normcyl>1)
binyz[*,*,1] = binyz[*,*,1]/(normyz>1)
binxy[*,*,2] = binxy[*,*,2]/(normxy>1)
binxz[*,*,2] = binxz[*,*,2]/(normxz>1)
bincyl[*,*,2] = bincyl[*,*,2]/(normcyl>1)
binyz[*,*,2] = binyz[*,*,2]/(normyz>1)

if not keyword_set(prange) then prange = [min(bincyl),max(bincyl)]
xp = xrange[0]+findgen(nbx)*dx + dx/2.
yp = yrange[0]+findgen(nby)*dy + dy/2.
zp = zrange[0]+findgen(nbz)*dz + dz/2.
rp = rrange[0]+findgen(nby)*dr + dr/2.


ang = findgen(360)*!pi/180

if ptype eq 'scalar' then begin
	
	window,0
	specplot,xp,yp,binxy[*,*,0],limits = {xrange:xrange,yrange:yrange,xstyle:1,ystyle:1,zrange:prange,zlog:plog,no_interp:1,xtitle:'X [km]',ytitle:'Y [km]',position:[0.1,0.1,0.85,0.9]}
	plots,RM*cos(ang),RM*sin(ang)

	window,1
	specplot,xp,zp,binxz[*,*,0],limits = {xrange:xrange,yrange:zrange,xstyle:1,ystyle:1,zrange:prange,zlog:plog,no_interp:1,xtitle:'X [km]',ytitle:'Z [km]',position:[0.1,0.1,0.85,0.9]}
	plots,RM*cos(ang),RM*sin(ang)

	window,2
	specplot,xp,rp,bincyl[*,*,0],limits = {xrange:xrange,yrange:rrange,xstyle:1,ystyle:1,zrange:prange,zlog:plog,no_interp:1,xtitle:'X [km]',ytitle:'R_YZ [km]',position:[0.1,0.1,0.85,0.9]}
	oplot,RM*cos(ang),RM*sin(ang)

	window,3
	specplot,yp,zp,binyz[*,*,0],limits = {xrange:yrange,yrange:zrange,xstyle:1,ystyle:1,zrange:prange,zlog:plog,no_interp:1,xtitle:'Y [km]',ytitle:'Z [km]',position:[0.1,0.1,0.85,0.9]}
	plots,RM*cos(ang),RM*sin(ang)
	
endif else begin
	window,0
	velovect,binxy[*,*,0],binxy[*,*,1],xp,yp,xrange = xrange, yrange = yrange, xtitle = 'X [km]',ytitle = 'Y [km]', len = len
	plots,RM*cos(ang),RM*sin(ang)

	window,1
	velovect,binxz[*,*,0],binxz[*,*,2],xp,zp,xrange = xrange, yrange = zrange, xtitle = 'X [km]',ytitle = 'Z [km]', len = len
	plots,RM*cos(ang),RM*sin(ang)

	window,2
	velovect,bincyl[*,*,0],bincyl[*,*,1],xp,rp,xrange = xrange, yrange = rrange, xtitle = 'X [km]',ytitle = 'R_YZ [km]', title = 'In Plane', len = len	
	oplot,RM*cos(ang),RM*sin(ang)

	window,3
	velovect,binyz[*,*,1],binyz[*,*,2],yp,zp,xrange = yrange, yrange = zrange, xtitle = 'Y [km]',ytitle = 'Z [km]', len = len
	plots,RM*cos(ang),RM*sin(ang)
endelse

end