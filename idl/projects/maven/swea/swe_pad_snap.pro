;+
;PROCEDURE:   swe_pad_snap
;PURPOSE:
;  Plots PAD snapshots in a separate window for times selected with the cursor in
;  a tplot window.  Hold down the left mouse button and slide for a movie effect.
;  A PAD snapshot is an pitch angle X energy spectrogram at the selected time.
;  Optionally, keyword ENERGY can be used to plot a PAD in histogram mode for a 
;  single energy.
;
;USAGE:
;  swe_pad_snap
;
;INPUTS:
;
;KEYWORDS:
;       ENERGY:        Energy (eV) to use for the histogram plot.
;
;       UNITS:         Plot PAD data in these units.
;
;       PAD:           Named variable to hold a PAD structure at the last time
;                      selected.
;
;       DDD:           If set, compare with the nearest 3D spectrum.
;
;       CENTER:        Specify the center azimuth for 3D plots.  Only works when DDD
;                      is set.
;
;       SUM:           If set, use cursor to specify time ranges for averaging.
;
;       SMO:           Number of energy bins to smooth over.
;
;       NORM:          At each energy step, normalize the distribution to the mean.
;
;       POT:           Overplot an estimate of the spacecraft potential.  Must run
;                      mvn_swe_sc_pot first.
;
;       SCP:           Temporarily override any other estimates of the spacecraft
;                      potential and force it to be this value.
;
;       SHIFTPOT:      Correct for the spacecraft potential.  Spectra are shifted from
;                      the spacecraft frame to the plasma frame.
;
;       LABEL:         If set, label the anode and deflection bin numbers.
;
;       KEEPWINS:      If set, then don't close the snapshot window(s) on exit.
;
;       ARCHIVE:       If set, show snapshots of archive data.
;
;       BURST:         Synonym for ARCHIVE.
;
;       DIR:           If set, show some useful information with
;                      respect to the observed vector magnetic field
;                      in the MSO and LGEO(local geographic coordinate). 
;
;       MASK_SC:       Mask PA bins that are blocked by the spacecraft.
;                      Default = 1 (yes).
;
;       SPEC:          Plot energy spectra for parallel, anti-parallel, and
;                      90-degree pitch angle populations.  The value of this 
;                      keyword is the pitch angle width (deg) that is used
;                      to separate the populations:
;
;                        parallel      : 0 to SPEC degrees
;                        middle        : SPEC to (180 - SPEC) degrees
;                        anti-parallel : (180 - SPEC) to 180 degrees
;
;                      Pitch angle bins must be entirely contained within
;                      one of these ranges to be included.
;
;                      Any value of SPEC < 30 deg is taken to be 30 deg.
;
;        NOMID:        When using keyword SPEC, do not plot the energy spectrum
;                      for the middle range of pitch angles.  Plot only the 
;                      spectra for parallel and anti-parallel populations.
;
;        PLOTLIMS:     Plot dashed lines at the limits of the pitch angle
;                      coverage.
;
;        PEP:          Plot vertical dashed lines at the nominal photoelectron
;                      energy peaks at 23 and 27 eV (due to ionization of CO2
;                      and O by 304-Angstrom He-II line).
;
;        RESAMPLE:     Two independent pitch angle distributions are measured 
;                      for each PAD data structure.  This keyword averages them
;                      together and plots the result.
;
;        UNCERTAINTY:  If set, show the relative uncertainty of the resampled PAD.
;
;        HIRES:        Use 32-Hz MAG data to map pitch angle with high time 
;                      resolution within a 2-second SWEA measurement cycle.  A
;                      separate pitch angle map is determined for each of the
;                      64 energy steps.  You must first load 32-Hz MAG data for 
;                      this keyword to be effective.  Please read warnings in 
;                      mvn_swe_padmap_32Hz.pro.
;
;        FBDATA:       Tplot variable name that contains the 32-Hz MAG data.
;                      Default = 'mvn_B_full'.
;
;        WINDOW:       Window number for the first snapshot window.  Additional 
;                      snapshot windows are in numerical sequence.  If not set,
;                      then all snapshot window numbers are generated automatically.
;
;        ADIABATIC:    Calculate and display the adiabatic condition:
;
;                        (1/B)*(dB/dx)*Rg << 1
;
;                      which is the fractional change in the magnetic field over
;                      one gyroradius.  Only works when HIRES is set.
;
;        POPEN:        Set this to the name of a postscript file for output.
;        
;        INDSPEC:      To plot out the energy spectrum for each PA bins
;        
;        TWOPOT:       Allow input a two-element array to allow shifting different
;                      potentials on parallel and anti-parallel directions
;        
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2016-09-19 17:00:04 -0700 (Mon, 19 Sep 2016) $
; $LastChangedRevision: 21865 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_pad_snap.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;-
pro swe_pad_snap, keepwins=keepwins, archive=archive, energy=energy, $
                  units=units, pad=pad, ddd=ddd, zrange=zrange, sum=sum, $
                  label=label, smo=smo, dir=dir, mask_sc=mask_sc, $
                  abins=abins, dbins=dbins, obins=obins, burst=burst, $
                  pot=pot, scp=scp, spec=spec, plotlims=plotlims, norm=norm, $
                  center=center, pep=pep, resample=resample, hires=hires, $
                  fbdata=fbdata, window=window, adiabatic=adiabatic, $
                  nomid=nomid, uncertainty=uncertainty, nospec90=nospec90, $
                  shiftpot=shiftpot,popen=popen, indspec=indspec, twopot=twopot

  @mvn_swe_com
  @swe_snap_common

  if keyword_set(archive) then aflg = 1 else aflg = 0
  if keyword_set(burst) then aflg = 1
  if (size(units,/type) ne 7) then units = 'eflux'
  if keyword_set(energy) then sflg = 1 else sflg = 0
  if keyword_set(keepwins) then kflg = 0 else kflg = 1
  if not keyword_set(zrange) then zrange = 0
  if keyword_set(ddd) then dflg = 1 else dflg = 0
  if keyword_set(resample) then begin
    rflg = 1
    if (resample gt 1) then dotwo = 0 else dotwo = 1
  endif else begin
    rflg = 0
    dotwo = 1
  endelse
  if keyword_set(hires) then hflg = 1 else hflg = 0
  if (size(fbdata, /type) eq 0) then fbdata = 'mvn_B_full'
  if keyword_set(adiabatic) then begin
    mflg = 1
    get_data, 'dBdRg', index=idbdr
    if (idbdr eq 0) then mvn_swe_eparam
  endif else mflg = 0
  if keyword_set(uncertainty) then begin
     uflg = 1
     rflg = 1
  endif else uflg = 0
  if (size(center,/type) eq 0) then center = 0
  if keyword_set(pep) then pflg = 1 else pflg = 0
  if keyword_set(sum) then begin
    npts = 2
    doall = 1
  endif else begin
    npts = 1
    doall = 0
  endelse
  if not keyword_set(smo) then smo = 1
  if keyword_set(norm) then nflg = 1 else nflg = 0
  if keyword_set(pot) then dopot = 1 else dopot = 0
  if (size(scp,/type) eq 0) then scp = !values.f_nan else scp = float(scp[0])
  if keyword_set(shiftpot) then begin
    spflg = 1
    xrange = [1.,5000.]
  endif else begin
    spflg = 0
    xrange = [3.,5000.]
  endelse
  if keyword_set(label) then begin
    dolab = 1
    abin = string(indgen(16),format='(i2.2)')
    dbin = string(indgen(6),format='(i1)')
  endif else dolab = 0
  if keyword_set(plotlims) then plot_pa_lims = 1 else plot_pa_lims = 0
  if keyword_set(nomid) then domid = 0 else domid = 1
  
  if (n_elements(abins) ne 16) then abins = replicate(1B, 16)
  if (n_elements(dbins) ne  6) then dbins = replicate(1B, 6)
  if (n_elements(obins) ne 96) then begin
    obins = replicate(1B, 96, 2)
    obins[*,0] = reform(abins # dbins, 96)
    obins[*,1] = obins[*,0]
  endif else obins = byte(obins # [1B,1B])
  if (size(mask_sc,/type) eq 0) then mask_sc = 1
  if keyword_set(mask_sc) then obins = swe_sc_mask * obins
  if (size(spec,/type) ne 0) then begin
    dospec = 1
    swidth = (float(abs(spec)) > 30.)*!dtor
  endif else begin
    dospec = 0
    swidth = 30.*!dtor
  endelse
  
  if keyword_set(indspec) then doind=1 else doind=0
  
  if (size(popen,/type) eq 7) then begin
      psflg = 1
      psname = popen[0]
      csize1 = 1.2
      csize2 = 1.0
  endif else begin
      psflg = 0
      csize1 = 1.2
      csize2 = 1.4
  endelse

  case n_elements(center) of
    0 : begin
          lon0 = 180.
          lat0 = 0.
        end
    1 : begin
          lon0 = center[0]
          lat0 = 0.
        end
    else : begin
             lon0 = center[0]
             lat0 = center[1]
           end
  endcase

  case strupcase(units) of
    'COUNTS' : drange = [1e0, 1e5]
    'RATE'   : drange = [1e1, 1e6]
    'CRATE'  : drange = [1e1, 1e6]
    'FLUX'   : drange = [1e1, 3e8]
    'EFLUX'  : drange = [1e4, 3e9]
    'E2FLUX' : drange = [1e6, 1e11]
    'DF'     : drange = [1e-18, 1e-8]
    else     : drange = [0,0]
  endcase
  
  case strupcase(units) of
    'COUNTS' : ytitle = 'Raw Counts'
    'RATE'   : ytitle = 'Raw Count Rate'
    'CRATE'  : ytitle = 'Count Rate'
    'EFLUX'  : ytitle = 'Energy Flux (eV/cm2-s-ster-eV)'
    'E2FLUX' : ytitle = 'Energy Flux (eV/cm2-s-ster)'
    'FLUX'   : ytitle = 'Flux (1/cm2-s-ster-eV)'
    'DF'     : ytitle = 'Dist. Function (1/cm3-(km/s)3)'
    else     : ytitle = 'Unknown Units'
  endcase

  get_data,'alt',data=alt
  if (size(alt,/type) eq 8) then begin
    doalt = 1
    get_data,'sza',data=sza
    get_data,'lon',data=lon
    get_data,'lat',data=lat
    get_data,'sza',data=sza
  endif else doalt = 0

; Put up snapshot window(s)

  tplot_options, get_opt=topt
  str_element, topt, 'window', value=Twin, success=ok
  if (not ok) then Twin = !d.window

  if (size(window,/type) gt 0) then begin
     wnum = window  ; snapshot window numbers determined by user
     free = 0
  endif else begin
     wnum = 0       ; snapshot window numbers determined by IDL
     free = 1
     wstat = 0
  endelse
  if (size(Dopt,/type) ne 8) then swe_snap_layout, 0
  IF keyword_set(dir) THEN wdy = 0.125*Nopt.ysize ELSE wdy = 0.
  if ~(free) then wstat = execute("wset, wnum")
  if wstat eq 0 then window, wnum, free=free, xsize=Popt.xsize, ysize=Popt.ysize, xpos=Popt.xpos, ypos=Popt.ypos
  Pwin = !d.window
  wnum += 1

  if (sflg) then begin
    if ~(free) then wstat = execute("wset, wnum")
    if wstat eq 0 then window, wnum, free=free, xsize=Nopt.xsize, ysize=Nopt.ysize + wdy, xpos=Nopt.xpos, ypos=Nopt.ypos
    Nwin = !d.window
    wnum += 1
  endif
  
  if (dflg) then begin
    if ~(free) then wstat = execute("wset, wnum")
    if wstat eq 0 then window, wnum, free=free, xsize=Copt.xsize, ysize=Copt.ysize, xpos=Copt.xpos, ypos=Copt.ypos
    Cwin = !d.window
    wnum += 1
  endif
  
  if (dospec) then begin
    if ~(free) then wstat = execute("wset, wnum")
    if wstat eq 0 then window, wnum, free=free, xsize=Fopt.xsize, ysize=Fopt.ysize, xpos=Fopt.xpos, ypos=Fopt.ypos
    Ewin = !d.window
    wnum += 1
  endif

  if (rflg or hflg or uflg) then begin
     if ~(free) then wstat = execute("wset, wnum")
     if wstat eq 0 then window, wnum, free=free, xsize=Popt.xsize, ysize=Popt.ysize*0.5*(rflg+hflg+uflg), xpos=Popt.xpos, ypos=Popt.ypos
     Rwin = !d.window
     wnum += 1
  endif

  if (doind) then begin
      if ~(free) then wstat = execute("wset, wnum")
      if wstat eq 0 then window, wnum, free=free, xsize=Fopt.xsize*2, ysize=Fopt.ysize, xpos=Fopt.xpos+1, ypos=Fopt.ypos+1
      Iwin = !d.window
      wnum += 1
  endif

; Set plot options

  limits = {no_interp:1, xlog:1, xrange:xrange, xstyle:1, xtitle:'Energy (eV)', $
            yrange:[0,180], ystyle:1, yticks:6, yminor:3, ytitle:'Pitch Angle (deg)', $
            zlog:1, ztitle:strupcase(units), xmargin:[15,15], charsize:1.4}

  if keyword_set(zrange) then str_element, limits, 'zrange', zrange, /add

; Select the first time, then get the PAD spectrum closest that time

  if size(pad, /type) ne 8 then begin
     print,'Use button 1 to select time; button 3 to quit.'
     
     wset,Twin
     ctime,trange,npoints=npts,/silent
     if (npts gt 1) then cursor,cx,cy,/norm,/up ; make sure mouse button is released
     pdflg = 1
  endif else begin
     trange = 0.5*(pad.time + pad.end_time)
     pdflg = 0
     kflg = 0
  endelse 
  if (size(trange,/type) eq 2) then begin  ; Abort before first time select.
    wdelete,Pwin                           ; Don't keep empty windows.
    if (sflg) then wdelete,Nwin
    if (dospec) then wdelete,Ewin
    if (rflg or hflg) then wdelete,Rwin
    wset,Twin
    return
  endif
  
  if keyword_set(dir) then begin
    get_data,'mvn_B_1sec',index=i
    if (i eq 0) then mvn_mag_load

    get_data,'mvn_B_1sec_iau_mars',data=mag_pc,index=i
    if (i eq 0) then begin
      mvn_mag_geom
      get_data,'mvn_B_1sec_iau_mars',data=mag_pc,index=i
      if (i eq 0) then print,"Can't get MAG data!"
    endif

    get_data,'mvn_B_1sec_maven_mso',data=mag_ss,index=j
    if ((i eq 0) or (j eq 0)) then dir = 0
  endif

  ok = 1
  
  nplot = 0
  
  while (ok) do begin

  
  if (psflg) then popen, psname + string(nplot,format='("_",i2.2)')

; Put up a PAD spectrogram
 
    if ~(psflg) then wset, Pwin
    if (pdflg) then begin
       pad = mvn_swe_getpad(trange,archive=aflg,all=doall,/sum,units=units)
       if (hflg) then pad = mvn_swe_padmap_32hz(pad, fbdata=fbdata, /verbose, maglev=maglev)
    endif
    
    if (size(pad,/type) eq 8) then begin

      if keyword_set(dir) then begin
        dt = min(abs(mag_ss.x - pad.time),i)
        B_mso = reform(mag_ss.y[i,*])

        dt = min(abs(mag_pc.x - pad.time),i)
        B_geo = reform(mag_pc.y[i,*])
        B_azim  = mag_pc.azim[i]
        B_elev  = mag_pc.elev[i]
      endif

      if (size(swe_sc_pot, /type) eq 8) then begin
          pot = swe_sc_pot[nn(swe_sc_pot.time, pad.time)].potential
          if (~finite(pot)) then pot = 0.
      endif else pot = 0.
      if (finite(scp)) then pot = scp  ; override with user-supplied value
      pad.sc_pot = pot
  
      if (spflg) then begin
        mvn_swe_convert_units, pad, 'df'
        pad.energy -= pot
        mvn_swe_convert_units, pad, units
      endif
    
      case strupcase(pad.units_name) of
        'COUNTS' : zlo = 1
        'RATE'   : zlo = 1
        'CRATE'  : zlo = 1
        'FLUX'   : zlo = 1
        'EFLUX'  : zlo = 1e3
        'DF'     : zlo = 1e-18
        else     : zlo = 1
      endcase

      title = string(time_string(pad.time), pad.Baz*!radeg, pad.Bel*!radeg, $
                     format='(a19,5x,"Baz = ",f5.1,3x,"Bel = ",f5.1)')
      str_element,limits,'title',title,/add
      
      if (pad.time gt t_mtx[2]) then boom = 1 else boom = 0
      indx = where(obins[pad.k3d,boom] eq 0B, count)
      if (count gt 0L) then pad.data[*,indx] = !values.f_nan

      x = pad.energy[*,0]
      y = pad.pa*!radeg
      ylo = pad.pa_min*!radeg
      yhi = pad.pa_max*!radeg
      z = smooth(pad.data,[smo,1],/nan)
      
      if (nflg) then begin
        zmean = average(z,2,/nan) # replicate(1.,16)
        z /= (zmean > 1.)
      endif

; Add extra elements to force specplot to show the full pitch angle range

      y1 = fltarr(64,10)
      ylo1 = y1
      yhi1 = y1
      z1 = y1
      y2 = y1
      ylo2 = y1
      yhi2 = y1
      z2 = y1

      for i=0,63 do begin
        indx = sort(reform(y[i,0:7]))
        y1[i,1:8] = y[i,indx]
        z1[i,1:8] = z[i,indx]
        ylo1[i,1:8] = ylo[i,indx]
        yhi1[i,1:8] = yhi[i,indx]
        jndx = sort(reform(y[i,8:15])) + 8
        y2[i,1:8] = y[i,jndx]
        z2[i,1:8] = z[i,jndx]
        ylo2[i,1:8] = ylo[i,jndx]
        yhi2[i,1:8] = yhi[i,jndx]
      endfor
      y1[*,0] = ylo1[*,1]
      y1[*,9] = yhi1[*,8]
      z1[*,0] = z1[*,1]
      z1[*,9] = z1[*,8]

      y2[*,0] = ylo2[*,1]
      y2[*,9] = yhi2[*,8]
      z2[*,0] = z2[*,1]
      z2[*,9] = z2[*,8]

;     str_element,limits,'zrange',success=ok
      ok = 0
      if (not ok) then begin
        zmin = min(z, max=zmax, /nan) > zlo
        if (nflg) then begin
          zmin = 0.3
          zmax = 3.0
          str_element,limits,'zlog',1,/add
          str_element,limits,'ztitle','NORM',/add
          str_element,limits,'zticks',2,/add
          str_element,limits,'ztickname',['0.3','1.0','3.0'],/add
        endif
        str_element,limits,'zrange',[zmin,zmax],/add
      endif

      !p.multi = [0,1,2]
      specplot,x,y1,z1,limits=limits
      if (dopot) then begin
        if (spflg) then oplot,[-pot,-pot],[0,180],line=2,color=6 $
                   else oplot,[pot,pot],[0,180],line=2
      endif
      if (plot_pa_lims) then begin
        oplot,[3,5000],[ylo1[63,1],ylo1[63,1]],line=2
        oplot,[3,5000],[yhi1[63,8],yhi1[63,8]],line=2
      endif
      limits.title = ''
      specplot,x,y2,z2,limits=limits
      if (dopot) then begin
        if (spflg) then oplot,[-pot,-pot],[0,180],line=2,color=6 $
                   else oplot,[pot,pot],[0,180],line=2
      endif
      if (plot_pa_lims) then begin
        oplot,[3,5000],[ylo2[63,1],ylo2[63,1]],line=2
        oplot,[3,5000],[yhi2[63,8],yhi2[63,8]],line=2
      endif
      !p.multi = 0

      if (rflg or hflg or uflg) then begin
         if ~(psflg) then wset, Rwin
         if (rflg + hflg + uflg) gt 1 then !p.multi = [0, 1, rflg+hflg+uflg]
         if (rflg) then begin
            rlim = limits
            if (rflg + hflg + uflg) eq 3 then begin
               ymargin = !y.margin
               str_element, rlim, 'charsize', rlim.charsize * 1.5, /add_replace
               str_element, rlim, 'xmargin', rlim.xmargin / 1.5, /add_replace
               !y.margin /= 1.5
            endif 
            rtime = minmax(trange)
            if rtime[0] eq rtime[1] then rtime = rtime[0]
            mvn_swe_pad_resample, rtime, snap=0, tplot=0, result=rpad, silent=3, hires=hflg, $
                                  fbdata=fbdata, sc_pot=spflg, archive=aflg
            arpad = rpad.avg
            if size(arpad, /n_dimension) eq 3 then arpad = average(arpad, 3)
            if (nflg) then arpad /= rebin(average(arpad, 2, /nan), n_elements(arpad[*, 0]), n_elements(arpad[0, *]), /sample)
            str_element, rlim, 'title', time_string(mean(rpad.time)) + ' (Resampled)', /add_replace
            specplot, average(pad.energy, 2), rpad[0].xax, arpad, lim=rlim

            if (dopot) then begin
              if (spflg) then oplot,[-pot,-pot],[0,180],line=2,color=6 $
                         else oplot,[pot,pot],[0,180],line=2
            endif

            if (uflg) then begin
               urpad = rpad.std
               if size(urpad, /n_dimension) eq 3 then urpad = average(urpad, 3)
               str_element, rlim, 'ztitle', 'Relative Uncertainty', /add_replace
               str_element, rlim, 'zrange', [1.d-2, 1.], /add_replace
               str_element, rlim, 'title', 'Resampled PAD Relative Uncertainty', /add_replace
               specplot, average(pad.energy, 2), rpad[0].xax, urpad/arpad, lim=rlim
               if (dopot) then begin
                 if (spflg) then oplot,[-pot,-pot],[0,180],line=2,color=6 $
                            else oplot,[pot,pot],[0,180],line=2
               endif
            endif 
         endif 
         if (hflg) then begin
            if tag_exist(pad, 'ftime') then begin
               ftime = pad.ftime - time_double(time_string(pad.ftime[0], tformat='YYYY-MM-DD/hh:mm'))
               if (mflg) then begin
                  get_data, 'dBdRg', data=dbdr, index=idbdr
                  if (idbdr ne 0) then begin
                     idx = where(dbdr.x ge pad.time and dbdr.x le pad.end_time, nidx)
                     if nidx gt 0 then begin
                        edbdr = dbdr.v
                        dbdr = average(dbdr.y[idx, *], 1)
                        fdbdr = strarr(3)
                        jdx = where(floor(alog10(dbdr)) ge 0, njdx, complement=kdx, ncomplement=nkdx)
                        if njdx gt 0 then fdbdr[jdx] = '(f0.1)'
                        if nkdx gt 0 then fdbdr[kdx] = '(f0.' + string(abs(floor(alog10(dbdr[kdx]))) + 1, '(i0)') + ')'
                        htit = 'dB/dRg = ' + string(dbdr[0], fdbdr[0]) + ' (' + string(edbdr[0], '(i0)') + ' eV), ' + $
                               string(dbdr[1], fdbdr[1]) + ' (' + string(edbdr[1], '(i0)') + ' eV), ' + $
                               string(dbdr[2], fdbdr[2]) + ' (' + string(edbdr[2], '(i0)') + ' eV)'
                        undefine, jdx, njdx, kdx, nkdx
                        undefine, edbdr, fdbdr
                     endif else htit = ''
                     undefine, idx, nidx
                  endif else htit = ''
                  undefine, dbdr, idbdr
               endif else htit = ''
               box, {xrange: minmax(ftime), xstyle: 1, yrange: [0., 360.], yticks: 4, yminor: 3, ystyle: 9, $
                     xtitle: 'Time (UT) Seconds after ' + time_string(pad.ftime[0], tformat='YYYY-MM-DD/hh:mm'), ytitle: 'Baz (deg)', $
                     charsize: 0.7 * (rflg + uflg + hflg) > 1.4, xmargin: [15, 15] / ((rflg + uflg + hflg)/2. > 1.)}
               ;oplot, minmax(ftime), [180., 180.], lines=1
               oplot, minmax(ftime), replicate(pad.baz*!radeg, 2), lines=1
               oplot, minmax(ftime), replicate(2.*pad.bel*!radeg + 180., 2), color=254, lines=1
               oplot, ftime, pad.fbaz*!radeg, psym=1
               oplot, ftime, 2. * pad.fbel*!radeg + 180., psym=1, color=254
               axis, /yaxis, yrange=[-90., 90.], color=254, ytitle='Bel (deg)', yticks=4, yminor=3, /ystyle, charsize=(0.7 * (rflg + uflg + hflg) > 1.4)
               ;axis, /xaxis, charsize=1.4, xrange=reverse(minmax(pad.energy)), xtitle='Energy [eV]', /xstyle, /xlog
               xyouts, mean(!x.window), mean([!y.window[1], !y.region[1]]), htit, align=.5, charsize=1.4, /normal
            endif 
         endif 
         if (rflg + hflg + uflg) ge 2 then !p.multi = 0
         if size(ymargin, /type) ne 0 then begin
            !y.margin = ymargin
            undefine, ymargin
         endif 
      endif

      if (sflg) then begin
        x = pad.energy[*,0]
        y = pad.pa*!radeg
        z = pad.data

        if ~(psflg) then wset, Nwin
        de = min(abs(energy - x),i)
        energy = x[i]
        ylo = reform(pad.pa_min[i,*])*!radeg
        yhi = reform(pad.pa_max[i,*])*!radeg
        zi = z[i,*]/mean(z[i,*],/nan)

        col = [replicate(2,8), replicate(6,8)]

        plot_io,[-1.],[0.1],psym=3,xtitle='Pitch Angle (deg)',ytitle='Normalized', $
                yrange=[0.1,10.],ystyle=1,xrange=[0,180],xstyle=1,xticks=6,xminor=3, $
                title='', charsize=1.4, $
                pos=[0.140005, 0.124449 - (wdy/4000.), 0.958005, 0.937783 - (wdy/525.)]

        xyouts,140,7.5,string(energy,format='(f6.1," eV")'),charsize=1.4

        for j=0,15 do oplot,[ylo[j],yhi[j]],[zi[j],zi[j]],color=col[j]
        oplot,y[i,0:7],zi[0:7],linestyle=1,color=2
        oplot,y[i,0:7],zi[0:7],psym=4
        oplot,y[i,8:15],zi[8:15],linestyle=1,color=6
        oplot,y[i,8:15],zi[8:15],psym=4
      
        if (dolab) then begin
          alab = abin[pad.iaz]
          dlab = dbin[pad.jel]
          for j=0,7  do xyouts,(ylo[j]+yhi[j])/2.,8.,alab[j],color=2,align=0.5
          for j=0,7  do xyouts,(ylo[j]+yhi[j])/2.,7.,dlab[j],color=2,align=0.5

          for j=8,15 do xyouts,(ylo[j]+yhi[j])/2.,0.15,alab[j],color=6,align=0.5
          for j=8,15 do xyouts,(ylo[j]+yhi[j])/2.,0.13,dlab[j],color=6,align=0.5
        endif

        IF keyword_set(dir) THEN BEGIN
           
          IF B_mso[0] GT 0. THEN append_array, dirname, 'SUN' ELSE append_array, dirname, 'TAIL'
          IF B_elev GT 0. THEN append_array, dirname, 'UP' ELSE append_array, dirname, 'DOWN'
          IF -B_mso[0] GT 0. THEN append_array, dirname, 'SUN' ELSE append_array, dirname, 'TAIL'
          IF -B_elev GT 0. THEN append_array, dirname, 'UP' ELSE append_array, dirname, 'DOWN'
           
          bperp = [B_mso[1], B_mso[2], -B_geo[0], -B_geo[1]]
          FOR j=0, 3 DO $
            IF bperp[j] GT 0. THEN append_array, dircol, 6 ELSE append_array, dircol, 2
          FOR j=0, 3 DO $
            XYOUTS, 17.5+45.*j, 15., dirname[j], color=!p.color, charsize=1.3, /data

          PLOT, [-1., 1.], [-1., 1.], /nodata, pos=[0.285892, 0.874722, 0.39075, 1.], $
                 /noerase, yticks=1, xticks=1, xminor=1, yminor=1, xstyle=5, ystyle=5
          OPLOT, 0.9*COS(FINDGEN(361)*!DTOR), 0.9*SIN(FINDGEN(361)*!DTOR)
          angle = ATAN(B_mso[2], B_mso[1])
          IF B_mso[0] GT 0. THEN dircol = 6 ELSE dircol = 2
          ARROW, 0., 0., 0.7*COS(angle), 0.7*SIN(angle), /data, color=dircol
          XYOUTS, 0., -1.3, 'MSO', /data, alignment=0.5
          XYOUTS, 0., 0.5, 'Z', /data, alignment=0.5
          XYOUTS, 0.6, 0., 'Y', /data, alignment=0.5

          PLOT, [-1., 1.], [-1., 1.], /nodata, pos=[0.708061, 0.874722, 0.812919, 1.], $
                 /noerase, yticks=1, xticks=1, xminor=1, yminor=1, xstyle=5, ystyle=5
          OPLOT, 0.9*COS(FINDGEN(361)*!DTOR), 0.9*SIN(FINDGEN(361)*!DTOR)
          angle = ATAN(-B_geo[1], -B_geo[0])
          IF -B_geo[2] GT 0. THEN dircol = 6 ELSE dircol = 2
          ARROW, 0., 0., 0.7*COS(angle), 0.7*SIN(angle), /data, color=dircol
          XYOUTS, 0., -1.3, 'GEO', /data, alignment=0.5
          XYOUTS, 0., 0.5, 'N', /data, alignment=0.5
          XYOUTS, 0.6, 0., 'E', /data, alignment=0.5
        ENDIF

        if (dflg) then begin
          ddd = mvn_swe_get3d(trange,archive=aflg,all=doall,/sum,units=units)
          indx = where(obins[*,boom] eq 0B, count)
          if (count gt 0L) then ddd.data[*,indx] = !values.f_nan

          de = min(abs(ddd.energy[*,0] - energy),ebin)
          z3d = reform(ddd.data[ebin,pad.k3d])  ; 3D mapped into PAD
          z3d = z3d/mean(z3d,/nan)

          col = [replicate(3,8), replicate(7,8)]

          for j=0,15 do oplot,[ylo[j],yhi[j]],[z3d[j],z3d[j]],color=col[j],line=2

          if ~(psflg) then wset, Cwin
          d_dat = replicate(!values.f_nan,96)
          d_dat[pad.k3d] = reform(z[i,*])       ; PAD mapped into 3D
          ddd.data[ebin+1,*] = d_dat            ; overwrite adjacent energy bin
          ddd.energy[ebin+1,*] = ddd.energy[ebin,*]
          ddd.magf[0] = cos(pad.Baz)*cos(pad.Bel)
          ddd.magf[1] = sin(pad.Baz)*cos(pad.Bel)
          ddd.magf[2] = sin(pad.Bel)
          plot3d_new,ddd,lat0,lon0,ebins=[ebin,ebin+1]
        endif
      endif
            
      if (dospec) then begin
        if ~(psflg) then wset, Ewin
        x = pad.energy[*,0]
        pndx = where(reform(pad.pa_max[63,*]) lt swidth, count)
        if (count gt 0L) then Fp = average(pad.data[*,pndx],2,/nan) $
                         else Fp = replicate(!values.f_nan,64)
        mndx = where(reform(pad.pa_min[63,*]) gt (!pi - swidth), count)
        if (count gt 0L) then Fm = average(pad.data[*,mndx],2,/nan) $
                         else Fm = replicate(!values.f_nan,64)
        zndx = where((reform(pad.pa_max[63,*]) lt (!pi - swidth)) and $
                     (reform(pad.pa_min[63,*]) gt swidth), count)
        if (count gt 0L) then Fz = average(pad.data[*,zndx],2,/nan) $
                         else Fz = replicate(!values.f_nan,64)
        
        if keyword_set(twopot) then begin
            php = Fp/x^2
            x1 = x-twopot[0]
            inE=where(x1 ge 0,cts)
            Fp = php[inE]*x1[inE]^2
            
            php = Fm/x^2
            x2 = x-twopot[1]
            inE=where(x2 ge 0,cts)
            Fm = php[inE]*x2[inE]^2
        endif else begin
            x1=x
            x2=x
        endelse
        
        plot_oo, [0.1,0.1], drange, xrange=[1,5000], yrange=drange, /ysty, $
          xtitle='Energy (eV)', ytitle=ytitle, title=time_string(pad.time), $
          charsize=1.4
        oplot, x1, Fp, psym=10, color=6
        oplot, x2, Fm, psym=10, color=2
        if (domid) then oplot, x, Fz, psym=10, color=4
        if (dopot) then begin
          if (spflg) then oplot,[-pot,-pot],drange,line=2,color=6 $
                     else oplot,[pot,pot],drange,line=2
        endif
        if (pflg) then begin
          oplot,[23.,23.],drange,line=2,color=1
          oplot,[27.,27.],drange,line=2,color=1
          oplot,[60.,60.],drange,line=2,color=1
        endif

        xs = 0.68
        ys = 0.90
        dys = 0.03
        pa_min = round(swidth*!radeg)
        pa_max = 180 - pa_min
        xyouts,xs,ys,string(pa_min, format='("  0 - ",i2)'),charsize=1.2,/norm,color=6
        ys -= dys
        if (domid) then begin
          xyouts,xs,ys,string(pa_min, pa_max, format='(i3," - ",i3)'),charsize=1.2,/norm,color=4
          ys -= dys
        endif
        xyouts,xs,ys,string(pa_max, format='(i3," - 180")'),charsize=1.2,/norm,color=2
        ys -= dys

        if (doalt) then begin
          dt = min(abs(alt.x - pad.time), aref)
          xyouts,xs,ys,string(round(alt.y[aref]), format='("ALT = ",i5)'),charsize=1.2,/norm
          ys -= dys
          xyouts,xs,ys,string(round(sza.y[aref]), format='("SZA = ",i5)'),charsize=1.2,/norm
          ys -= dys
        endif
        
        if (dopot) then begin
          xyouts,xs,ys,string(pot, format='("SCP = ",f5.1)'),charsize=1.2,/norm
          ys -= dys
        endif
        
        if keyword_set(dir) then begin
          if (B_azim lt 0.) then B_azim = (B_azim + 360.) mod 360.
          xyouts,xs,ys,string(round(B_azim), format='("B_az = ",i4)'),charsize=1.2,/norm
          ys -= dys
          xyouts,xs,ys,string(round(B_elev), format='("B_el = ",i4)'),charsize=1.2,/norm          
          ys -= dys
        endif
      endif
    endif
    
    if (doind) then begin
        if ~(psflg) then wset, Iwin
        x = pad.energy[*,0]
        npa = 16;n_elements(pad.energy[0,*])
        pas = reform(pad.pa[63,*])
        inm = where(pas eq min(pas))
        inm = inm[0]
        !p.multi=[0,2,1,0,0]
        
        ;first half of the PAD
        plot_oo, [0.1,0.1], drange, xrange=[1,5000], yrange=drange, /ysty, $
            xtitle='Energy (eV)', ytitle=ytitle, title=time_string(pad.time), $
            charsize=1.4
                    
        xs = 0.36
        ys = 0.90
        dys = 0.03
      
        for ip=0,npa/2-1 do begin
            ipa=ip+inm
            if ipa ge npa then ipa=ipa-npa
            mip=pad.pa_min[63,ipa]*!radeg
            maap=pad.pa_max[63,ipa]*!radeg
            if pad.pa[63,ipa]*!radeg ge 90 then lst=2 else lst=0
            clr=244./(npa/2-1)*ip+10
            oplot,x,pad.data[*,ipa], color=clr, linestyle=lst
            xyouts,xs,ys,string(mip, maap, format='(i3," - ",i3)'),charsize=1.2,/norm,color=clr
            ys -= dys
        endfor
        if (dopot) then begin
            if (finite(scp)) then pot = scp $
            else if (finite(pad.sc_pot)) then pot = pad.sc_pot else pot = 0.
            oplot,[pot,pot],drange,line=2
        endif
        if (pflg) then begin
            oplot,[23.,23.],drange,line=2,color=1
            oplot,[27.,27.],drange,line=2,color=1
            oplot,[60.,60.],drange,line=2,color=1
        endif

        if (doalt) then begin
            dt = min(abs(alt.x - pad.time), aref)
            xyouts,xs,ys,string(round(alt.y[aref]), format='("ALT = ",i5)'),charsize=1.2,/norm
            ys -= dys
            xyouts,xs,ys,string(round(sza.y[aref]), format='("SZA = ",i5)'),charsize=1.2,/norm
            ys -= dys
        endif

        if keyword_set(dir) then begin
            if (B_azim lt 0.) then B_azim = (B_azim + 360.) mod 360.
            xyouts,xs,ys,string(round(B_azim), format='("B_az = ",i4)'),charsize=1.2,/norm
            ys -= dys
            xyouts,xs,ys,string(round(B_elev), format='("B_el = ",i4)'),charsize=1.2,/norm
            ys -= dys
        endif
        
        
        ;second half of the PAD
        plot_oo, [0.1,0.1], drange, xrange=[1,5000], yrange=drange, /ysty, $
            xtitle='Energy (eV)', ytitle=ytitle, title=time_string(pad.time), $
            charsize=1.4

        xs = 0.68
        ys = 0.90
        dys = 0.03

        for ip=0,npa/2-1 do begin
            ipa=ip+npa/2+inm
            if ipa ge npa then ipa=ipa-npa
            mip=pad.pa_min[63,ipa]*!radeg
            maap=pad.pa_max[63,ipa]*!radeg
            if pad.pa[63,ipa]*!radeg ge 90 then lst=2 else lst=0
            clr=254.-244./(npa/2-1)*ip
            oplot,x,pad.data[*,ipa], color=clr, linestyle=lst
            xyouts,xs,ys,string(mip, maap, format='(i3," - ",i3)'),charsize=1.2,/norm,color=clr
            ys -= dys
        endfor
        if (dopot) then begin
            if (finite(scp)) then pot = scp $
            else if (finite(pad.sc_pot)) then pot = pad.sc_pot else pot = 0.
            oplot,[pot,pot],drange,line=2
        endif
        if (pflg) then begin
            oplot,[23.,23.],drange,line=2,color=1
            oplot,[27.,27.],drange,line=2,color=1
            oplot,[60.,60.],drange,line=2,color=1
        endif

        if (doalt) then begin
            dt = min(abs(alt.x - pad.time), aref)
            xyouts,xs,ys,string(round(alt.y[aref]), format='("ALT = ",i5)'),charsize=1.2,/norm
            ys -= dys
            xyouts,xs,ys,string(round(sza.y[aref]), format='("SZA = ",i5)'),charsize=1.2,/norm
            ys -= dys
        endif

        if keyword_set(dir) then begin
            if (B_azim lt 0.) then B_azim = (B_azim + 360.) mod 360.
            xyouts,xs,ys,string(round(B_azim), format='("B_az = ",i4)'),charsize=1.2,/norm
            ys -= dys
            xyouts,xs,ys,string(round(B_elev), format='("B_el = ",i4)'),charsize=1.2,/norm
            ys -= dys
        endif
        
        !p.multi=0
    endif

    if (psflg) then pclose
    nplot++
    
; Get the next button press
    if (pdflg) then begin
       wset,Twin
       ctime,trange,npoints=npts,/silent
       if (npts gt 1) then cursor,cx,cy,/norm,/up ; make sure mouse button is released
       if (size(trange,/type) eq 5) then ok = 1 else ok = 0
    endif else ok = 0
    
  endwhile

  if (kflg) then begin
    wdelete, Pwin
    if (sflg) then wdelete, Nwin
    if (dflg) then wdelete, Cwin
    if (dospec) then wdelete, Ewin
    if (rflg or hflg) then wdelete, Rwin
    if (doind) then wdelete, Iwin
  endif

  wset, Twin

  return

end
