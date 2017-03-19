;+
;PROCEDURE:   mvn_ramdir
;PURPOSE:
;  Calculates the spacecraft orbital velocity relative to the body-fixed
;  rotating Mars frame (IAU_MARS).  If you sit on the spacecraft and look
;  in this direction, the flow will be in your face.
;
;  This vector can be rotated into any coordinate frame recognized by
;  SPICE.  The default is MAVEN_SPACECRAFT.
;
;  The co-rotation velocity in the IAU_MARS frame as a function of altitude
;  (h) and latitude (lat) is:
;
;      V_corot = (240 m/s)*[1 + h/3390]*cos(lat)
;
;  Models (LMD and MTGCM) predict that peak horizontal winds are 190-315 m/s 
;  near the exobase and 155-165 m/s near the homopause.  These are comparable 
;  to the co-rotation velocity.  The spacecraft velocity is ~4200 m/s in this 
;  altitude range, so winds could result in up to a ~4-deg angular offset of 
;  the actual flow from the nominal ram direction.
;
;  You must have SPICE installed for this routine to work.  If SPICE is 
;  already initialized (e.g., mvn_swe_spice_init), this routine will use the 
;  current loadlist.  Otherwise, this routine will try to initialize SPICE
;  based on the current timespan.
;
;USAGE:
;  mvn_ramdir, trange
;
;INPUTS:
;       trange:   Optional.  Time range for calculating the RAM direction.
;                 If not specified, then use current range set by timespan.
;
;KEYWORDS:
;       DT:       Time resolution (sec).  Default is to use the time resolution
;                 of maven_orbit_tplot (usually 10 sec).
;
;       FRAME:    String or string array for specifying one or more frames
;                 to transform the ram direction into.  Any frame recognized
;                 by SPICE is allowed.  The default is 'MAVEN_SPACECRAFT'.
;                 Other possibilities are: 'MAVEN_APP', 'MAVEN_STATIC', etc.
;
;       POLAR:    If set, convert the direction to polar coordinates and
;                 store as additional tplot variables.
;                    Phi = atan(y,x)*!radeg  ; [  0, 360]
;                    The = asin(z)*!radeg    ; [-90, +90]
;
;       MSO:      Calculate ram vector in the MSO frame instead of the
;                 rotating IAU_MARS frame.  May be useful at high altitudes.
;
;       PANS:     Named variable to hold the tplot variables created.  For the
;                 default frame, this would be 'V_sc_MAVEN_SPACECRAFT'.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-03-18 16:07:47 -0700 (Sat, 18 Mar 2017) $
; $LastChangedRevision: 22982 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_ramdir.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_ramdir, trange, dt=dt, pans=pans, frame=frame, mso=mso, polar=polar

  @maven_orbit_common

  if (size(trange,/type) eq 0) then begin
    tplot_options, get_opt=topt
    if (max(topt.trange_full) gt time_double('2013-11-18')) then trange = topt.trange_full
    if (size(trange,/type) eq 0) then begin
      print,"You must specify a time range."
      return
    endif
  endif
  tmin = min(time_double(trange), max=tmax)

  if (size(state,/type) eq 0) then maven_orbit_tplot, /loadonly
  if (size(frame,/type) ne 7) then frame = 'MAVEN_SPACECRAFT'
  dopol = keyword_set(polar)

  mk = spice_test('*', verbose=-1)
  indx = where(mk ne '', count)
  if (count eq 0) then mvn_swe_spice_init, trange=[tmin,tmax]

; First store the spacecraft velocity in the IAU_MARS (or MSO) frame

  if keyword_set(mso) then begin
    if keyword_set(dt) then begin
      npts = ceil((tmax - tmin)/dt)
      Tsc = tmin + dt*dindgen(npts)
      Vsc = fltarr(npts,3)
      Vsc[*,0] = spline(state.time, state.mso_v[*,0], Tsc)
      Vsc[*,1] = spline(state.time, state.mso_v[*,1], Tsc)
      Vsc[*,2] = spline(state.time, state.mso_v[*,2], Tsc)
    endif else begin
      Tsc = state.time
      Vsc = state.mso_v
    endelse
    store_data,'V_sc',data={x:Tsc, y:Vsc, v:[0,1,2]}
    options,'V_sc',spice_frame='MAVEN_SSO',spice_master_frame='MAVEN_SPACECRAFT'
  endif else begin
    if keyword_set(dt) then begin
      npts = ceil((tmax - tmin)/dt)
      Tsc = tmin + dt*dindgen(npts)
      Vsc = fltarr(npts,3)
      Vsc[*,0] = spline(state.time, state.geo_v[*,0], Tsc)
      Vsc[*,1] = spline(state.time, state.geo_v[*,1], Tsc)
      Vsc[*,2] = spline(state.time, state.geo_v[*,2], Tsc)
    endif else begin
      Tsc = state.time
      Vsc = state.geo_v
    endelse
    store_data,'V_sc',data={x:Tsc, y:Vsc, v:[0,1,2]}
    options,'V_sc',spice_frame='IAU_MARS',spice_master_frame='MAVEN_SPACECRAFT'
  endelse

; Next calculate the ram direction in frame(s) specified by keyword FRAME
  
  pans = ['']
  
  indx = where(frame ne '', nframes)
  for i=0,(nframes-1) do begin
    to_frame = strupcase(frame[indx[i]])
    spice_vector_rotate_tplot,'V_sc',to_frame,trange=[tmin,tmax]

    labels = ['X','Y','Z']
    fname = strmid(to_frame, strpos(to_frame,'_')+1)
    case strupcase(fname) of
      'MARS'       : fname = 'Mars'
      'SPACECRAFT' : fname = 'PL'
      'APP'        : labels = ['I','J','K']
      else         : ; do nothing
    endcase

    vname = 'V_sc_' + to_frame
    options,vname,'ytitle','RAM (' + fname + ')!ckm/s'
    options,vname,'labels',labels
    options,vname,'labflag',1
    options,vname,'constant',0
    pans = [pans, vname]

    if (dopol) then begin
      get_data, vname, data=Vsc
      xyz_to_polar, Vsc, theta=the, phi=phi, /ph_0_360

      the_name = 'V_sc_' + fname + '_The'
      store_data,the_name,data=the
      options,the_name,'ytitle','RAM The!c'+fname
      options,the_name,'ynozero',1
      options,the_name,'psym',3

      phi_name = 'V_sc_' + fname + '_Phi'
      store_data,phi_name,data=phi
      ylim,phi_name,0,360,0
      options,phi_name,'ytitle','RAM Phi!c'+fname
      options,phi_name,'yticks',4
      options,phi_name,'yminor',3
      options,phi_name,'ynozero',1
      options,phi_name,'psym',3

      pans = [pans, the_name, phi_name]
    endif
  endfor
  
  pans = pans[1:*]
  store_data,'V_sc',/delete

  return

end
