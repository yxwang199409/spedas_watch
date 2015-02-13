;+
;PROCEDURE:   mvn_swe_sundir
;PURPOSE:
;  Determines the direction of the Sun in SWEA coordinates.  The result is
;  stored in TPLOT variables.
;
;USAGE:
;  mvn_swe_sundir, trange
;
;INPUTS:
;       trange:   Time range for calculating the Sun direction.
;
;KEYWORDS:
;       DT:       Time resolution (sec).  Default = 1.
;
;       PANS:     Named variable to hold the tplot variables created.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-02-11 12:09:42 -0800 (Wed, 11 Feb 2015) $
; $LastChangedRevision: 16953 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sundir.pro $
;
;CREATED BY:    David L. Mitchell  09/18/13
;-
pro mvn_swe_sundir, trange, dt=dt, pans=pans

  @mvn_swe_com

  if (size(trange,/type) eq 0) then begin
    tplot_options, get_opt=topt
    if (max(topt.trange_full) gt time_double('2013-11-18')) then trange = topt.trange_full
    if (size(trange,/type) eq 0) then begin
      print,"You must specify a time range."
      return
    endif
  endif
  tmin = min(time_double(trange), max=tmax)

  mk = spice_test('*', verbose=-1)
  indx = where(mk ne '', count)
  if (count eq 0) then mvn_swe_spice_init, trange=[tmin,tmax]

  if not keyword_set(dt) then dt = 1D else dt = double(dt[0])
  
  if (tmax lt t_mtx[2]) then begin
    print,"Using stowed SWEA frame."
    swe_frame = 'MAVEN_SWEA_STOW'
  endif else begin
    print,"Using deployed SWEA frame."
    swe_frame = 'MAVEN_SWEA'
  endelse

  npts = floor((tmax - tmin)/dt) + 1L
  x = tmin + dt*dindgen(npts)
  y = replicate(1.,npts) # [1.,0.,0.]  ; MAVEN_SSO direction of Sun
  store_data,'Sun',data={x:x, y:y, v:indgen(3)}
  options,'Sun','labels',['X','Y','Z']
  options,'Sun','labflag',1
  options,'Sun',spice_frame='MAVEN_SSO',spice_master_frame='MAVEN_SPACECRAFT'
  spice_vector_rotate_tplot,'Sun','MAVEN_SPACECRAFT',trange=[tmin,tmax]
  spice_vector_rotate_tplot,'Sun',swe_frame,trange=[tmin,tmax]

  get_data,('Sun_' + swe_frame),data=sun
  xyz_to_polar, sun, theta=the, phi=phi, /ph_0_360
  store_data,'Sun_The',data=the
  store_data,'Sun_Phi',data=phi
  options,'Sun_The','ynozero',1
  options,'Sun_Phi','ynozero',1
  options,'Sun_The','psym',3
  options,'Sun_Phi','psym',3
  
  pans = ['Sun_The','Sun_Phi']
  
  return

end