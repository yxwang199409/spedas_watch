;+
;PROCEDURE:   mvn_sta_mag_load
;
;PURPOSE:
;  Load Magnetometer data and insert values into STATIC
;  common block structures. Also creates tplot variables.
;
;USAGE:
;  mvn_sta_mag_load
;
;KEYWORDS:       
;  frame:       Mag data frame of reference (currently STATIC)
;  verbose:     Display information.
;  stacom:      Set if you want STATIC common blocks filled



pro mvn_sta_mag_load, frame=frame, verbose=verbose, stacom=stacom



  if keyword_set(verbose) then print, 'Loading Magnetometer Data...'
  if ~keyword_set(frame) then frame='MAVEN_STATIC'


  ;-------------------------------------------------------------------------
  ;Declare all the common block arrays
  common mvn_2a,mvn_2a_ind,mvn_2a_dat 
  common mvn_c0,mvn_c0_ind,mvn_c0_dat
  common mvn_c2,mvn_c2_ind,mvn_c2_dat
  common mvn_c4,mvn_c4_ind,mvn_c4_dat
  common mvn_c6,mvn_c6_ind,mvn_c6_dat
  common mvn_c8,mvn_c8_ind,mvn_c8_dat
  common mvn_ca,mvn_ca_ind,mvn_ca_dat
  common mvn_cc,mvn_cc_ind,mvn_cc_dat
  common mvn_cd,mvn_cd_ind,mvn_cd_dat
  common mvn_ce,mvn_ce_ind,mvn_ce_dat
  common mvn_cf,mvn_cf_ind,mvn_cf_dat
  common mvn_d0,mvn_d0_ind,mvn_d0_dat
  common mvn_d1,mvn_d1_ind,mvn_d1_dat
  common mvn_d2,mvn_d2_ind,mvn_d2_dat
  common mvn_d3,mvn_d3_ind,mvn_d3_dat
  common mvn_d4,mvn_d4_ind,mvn_d4_dat
  common mvn_d6,mvn_d6_ind,mvn_d6_dat
  common mvn_d7,mvn_d7_ind,mvn_d7_dat
  common mvn_d8,mvn_d8_ind,mvn_d8_dat
  common mvn_d9,mvn_d9_ind,mvn_d9_dat
  common mvn_da,mvn_da_ind,mvn_da_dat
  common mvn_db,mvn_db_ind,mvn_db_dat

  apid=['2a','c0','c2','c4','c6','c8',$
        'ca','cc','cd','ce','cf','d0',$
        'd1','d2','d3','d4','d6','d7',$
        'd8','d9','da','db']
  nn_apid=n_elements(apid)


  ;-------------------------------------------------------------------------
  ;Load magnetometer data (mostly taken from Dave's mvn_mag_load_ql.pro)
  ;time -> unix time
  ;b[0] -> mag x in mag coordinates
  ;b[1] -> mag y in mag coordinates
  ;b[2] -> mag z in mag coordinates
  trange=timerange()
  if (size(trange,/type) eq 0) then begin
     print,"You must specify a file name or time range."
     return
  endif
  tmin = min(time_double(trange), max=tmax)
  path = 'maven/data/sci/mag/l1_sav/YYYY/MM/mvn_mag_ql_*_YYYYMMDD_v??_r??.sav'
  file = mvn_pfp_file_retrieve(path,/daily_names,trange=[tmin,tmax])
  nfiles = n_elements(file)

  finfo = file_info(file)
  indx = where(finfo.exists, nfiles, comp=jndx, ncomp=n)
  for j=0,(n-1) do print,"File not found: ",file[jndx[j]]
  if (nfiles eq 0) then return
  file = file[indx]
  
  restore, file[0]
  npts = n_elements(data.time.year)
  tstr = replicate(time_struct(0D), npts)
  doy_to_month_date, data.time.year, data.time.doy, month, date
  tstr.year = data.time.year
  tstr.month = month
  tstr.date = date
  tstr.hour = data.time.hour
  tstr.min = data.time.min
  tstr.sec = data.time.sec
  tstr.fsec = double(data.time.msec)/1000D
  tstr.doy = data.time.doy
  time = time_double(tstr)
  magf = fltarr(npts,3)
  magf[*,0] = data.ob_bpl.x
  magf[*,1] = data.ob_bpl.y
  magf[*,2] = data.ob_bpl.z

  for i=1,(nfiles-1) do begin
     restore, file[i]
     
     npts = n_elements(data.time.year)
     tstr = replicate(time_struct(0D), npts)

     doy_to_month_date, data.time.year, data.time.doy, month, date
    
     tstr.year = data.time.year
     tstr.month = month
     tstr.date = date
     tstr.hour = data.time.hour
     tstr.min = data.time.min
     tstr.sec = data.time.sec
     tstr.fsec = data.time.msec/1000D
     tstr.doy = data.time.doy
     time = [temporary(time), time_double(tstr)]

     magfs = magf
     mpts = n_elements(magfs[*,0])

     magf = fltarr(mpts+npts,3)
     magf[0L:(mpts-1L),*] = temporary(magfs)
     magf[mpts:*,0] = data.ob_bpl.x
     magf[mpts:*,1] = data.ob_bpl.y
     magf[mpts:*,2] = data.ob_bpl.z
     
  endfor



  ;----------------------------------------------------------
  ;Trim data to requested time range
  if (size(tmin,/type) eq 5) then begin
    indx = where((time ge tmin) and (time le tmax), count)
    if (count gt 0L) then begin
      time = time[indx]
      magf = magf[indx,*]
   endif else begin
      print,"No MAG data within requested time range."
      return
   endelse
  endif


  ;-------------------------------------------------------------------------
  ;Smooth using a 4 second bin
  bb=magf*0.D
  bb[*,0]=smooth_in_time(magf[*,0],time,4)
  bb[*,1]=smooth_in_time(magf[*,1],time,4)
  bb[*,2]=smooth_in_time(magf[*,2],time,4)
  magf=bb


  ;-------------------------------------------------------------------------
  ;Davin's SPICE Routines to convert from mag to sta (frame of reference). 
  mk = mvn_spice_kernels(/all,/load,trange=trange)
  utc=time_string(time)
  for api=0, nn_apid-1 do begin
     temp=execute('nn1=size(mvn_'+apid[api]+'_dat,/type)')
     if nn1 ne 0 then begin
        temp=execute('tags=tag_names(mvn_'+apid[api]+'_dat)')
        pp=where(tags eq 'POS_SC_MSO' or $
                 tags eq 'MAGF',cc)
        if cc eq 2 then begin
           temp=execute('utc=time_string(mvn_'+apid[api]+'_dat.time)')
           nn=n_elements(utc)
           apid_time=time_double(utc)
           xx=interpol(magf[*,0],time,apid_time)
           yy=interpol(magf[*,1],time,apid_time)
           zz=interpol(magf[*,2],time,apid_time)
           vec=transpose([[xx],[yy],[zz]])
           newvec=spice_vector_rotate(vec,utc,$
                                      'MAVEN_SPACECRAFT',$
                                      'MAVEN_STATIC',$
                                      check_objects='MAVEN_SPACECRAFT')
           vec=transpose(newvec)
           if keyword_set(stacom) then begin
              temp=execute('mvn_'+apid[api]+'_dat.magf[*,0]=vec[*,0]')
              temp=execute('mvn_'+apid[api]+'_dat.magf[*,1]=vec[*,1]')
              temp=execute('mvn_'+apid[api]+'_dat.magf[*,2]=vec[*,2]')
           endif
           if apid[api] eq 'c6' then begin
              time_sta_c6=apid_time
              magf_sta_c6=vec
              cspice_recsph, transpose(magf_sta_c6), r, phi, theta
           endif
        endif
     endif
  endfor
  
  
  ;-------------------------------------------------------------------------
  ;Clear kernels
  cspice_kclear


  ;-------------------------------------------------------------------------
  ;Tplot  
  var = 'mvn_mag1_sta_phi'
  store_data,var,data={x:time, y:phi, v:[0], labels:['phi'], $
                       labflag:1}, limits = {SPICE_FRAME:'MAVEN_STATIC', $
                       SPICE_MASTER_FRAME:'MAVEN_SPACECRAFT'}

  var = 'mvn_mag1_sta_theta'
  store_data,var,data={x:time, y:theta, v:[0], labels:['theta'], $
                       labflag:1}, limits = {SPICE_FRAME:'MAVEN_STATIC', $
                       SPICE_MASTER_FRAME:'MAVEN_SPACECRAFT'}

  var = 'mvn_mag1_pl_full'
  store_data,var,data={x:time, y:magf, v:[0,1,2], labels:['X','Y','Z'], $
                       labflag:1}, limits = {SPICE_FRAME:'MAVEN_SPACECRAFT', $
                       SPICE_MASTER_FRAME:'MAVEN_SPACECRAFT'}

  var = 'mvn_mag1_sta_ql'
  store_data,var,data={x:time_sta_c6, y:magf_sta_c6, v:[0,1,2], labels:['X','Y','Z'], $
                       labflag:1}, limits = {SPICE_FRAME:'MAVEN_STATIC', $
                       SPICE_MASTER_FRAME:'MAVEN_SPACECRAFT'}


  


end


