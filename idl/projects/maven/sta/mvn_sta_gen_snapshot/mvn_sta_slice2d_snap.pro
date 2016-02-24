;+
;
;PROCEDURE:       MVN_STA_SLICE2D_SNAP
;
;PURPOSE:         Plots 2D slice for the times and data type selected by cursor.
;                 Hold down the left mouse button and slide for a movie effect. 
;                 
;INPUTS:          None.
;                 But the specified time (or [tmin, tmax]) is set, it
;                 automatically show the snapshot. In this case, the
;                 cursor does not appear in a tplot window.
;
;CAUTION:         *** !!! ***
;                 The velocity is computed under the assumption that  
;                 all the observed ions are protons (i.e., m/q = 1) as default.
;                 If user wants to show it as the other ion species, such as O+ or O2+, 
;                 user must use the "m_int" keyword like m_int=16 or m_int=32. 
;                 Please see also the usage example #2.
;                 *** !!! ***
;
;KEYWORDS:        All the keywords included in 'slice2d' are acceptable. 
;
;   ARCHIVE:      Returns archive distribution instead of survey.
;
;     BURST:      Synonym for "ARCHIVE".
;   
;    WINDOW:      Specifies window number to plot.
;                 A new window to show is generated as default.
;   
;     BLINE:      Shows magnetic field direction by a black solid line.
;
;       MSO:      Rotates into the MSO coordinates (no effect on 'BV',
;                 'BE', and 'perp' cuts). 
;
;   KEEPWIN:      If set, then don't close the snapshot window on exit.
;
;      MASS:      Selects ion mass/charge range to show. Default is all.
;
;      MMIN:      Defines the minimum ion mass/charge to use.
;
;      MMAX:      Defines the maximum ion mass/charge to use.
;
;     M_INT:      Assumes ion mass/charge. Default = 1.
;
;      APID:      If set, specifies the APID data product to use.
;
;    SC_POT:      Specifies the spacecraft potential.
;
;       VSC:      Corrects for the spacecraft velocity.
;
;  SHOWDATA:      Plos all the data points over the contour (symsize = showdata).
;                 Pluses = Free sky bins, Crosses = Blocked bins.
;
;USAGE EXAMPLES:
;         1.      ; Normal case
;                 ; Uses archive data, and shows the B field direction.
;                 ; Draws the Xmso-Zmso plane slice.
;   
;                 mvn_sta_slice2d_snap, /arc, /bline, /mso, _extra={rot: 'xz'}
;
;         2.      ; Specified time case
;                 ; Selects the time to show.
;
;                 ctime, t ; Clicks once or twice on the tplot window.
;
;                 ; Draws the oxygen ion velocity distribution
;                 ; function in the plane perpendicular to the B field.   
;
;                 mvn_sta_slice2d_snap, t, mass=[12., 20.], m_int=16., _extra={rot: 'perp'} 
;
;         3.      ; Advanced case
;                 ; Uses 'ctime' procedure with "routine" keyword.
;
;                 ctime, routine='mvn_sta_slice2d_snap'
;
;NOTE:            This routine is written partially based on 'mvn_swia_slice2d_snap'
;                 created by Yuki Harada.
;
;CREATED BY:      Takuya Hara on 2015-05-22.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2016-02-23 16:01:49 -0800 (Tue, 23 Feb 2016) $
; $LastChangedRevision: 20116 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_gen_snapshot/mvn_sta_slice2d_snap.pro $
;
;-
PRO mvn_sta_slice2d_snap, var1, var2, archive=archive, window=window, mso=mso, _extra=_extra, $
                          bline=bline, mass=mass, m_int=mq, mmin=mmin, mmax=mmax, apid=id,    $
                          verbose=verbose, keepwin=keepwin, charsize=chsz, sum=sum, burst=burst, $
                          sc_pot=sc_pot, vsc=vsc, showdata=showdata

  IF STRUPCASE(STRMID(!version.os, 0, 3)) EQ 'WIN' THEN lbreak = STRING([13B, 10B]) ELSE lbreak = STRING(10B)
  tplot_options, get_option=topt
  dsize = GET_SCREEN_SIZE()
  IF SIZE(var2, /type) NE 0 THEN BEGIN
     keepwin = 1
     window = topt.window + 1 
  ENDIF 
  IF SIZE(var1, /type) NE 0 AND SIZE(var2, /type) EQ 0 THEN var2 = var1
  IF SIZE(var2, /type) NE 0 THEN trange = time_double(var2)

  IF keyword_set(window) THEN wnum = window ELSE BEGIN
     IF !d.name NE 'PS' THEN BEGIN
        WINDOW, /free, xsize=dsize[0]/2., ysize=dsize[1]*2./3., xpos=0., ypos=0.
        wnum = !d.window
     ENDIF 
  ENDELSE 
  ochsz = !p.charsize
  IF keyword_set(chsz) THEN !p.charsize = chsz
  IF keyword_set(archive) THEN aflg = 1
  IF keyword_set(burst) THEN aflg = 1
  IF SIZE(aflg, /type) EQ 0 THEN aflg = 0
  IF keyword_set(mass) THEN mmin = MIN(mass, max=mmax)
  IF keyword_set(mmin) AND ~keyword_set(mmax) THEN mtit = STRING(mmin, '(F0.1)') + ' < m/q'
  IF keyword_set(mmax) AND ~keyword_set(mmin) THEN mtit = 'm/q < ' + STRING(mmax, '(F0.1)')
  IF keyword_set(mmin) AND  keyword_set(mmax) THEN mtit = STRING(mmin, '(F0.1)') + ' < m/q < ' + STRING(mmax, '(F0.1)')
  IF SIZE(mtit, /type) EQ 0 THEN mtit = 'm/q = all'

  IF SIZE(trange, /type) NE 0 THEN IF N_ELEMENTS(trange) GT 1 THEN sum = 1
  IF keyword_set(sum) THEN npts = 2 ELSE npts = 1

  IF SIZE(var1, /type) EQ 0 THEN $
     dprint, 'Uses button 1 to select time: botton 3 to quit.', dlevel=2, verbose=verbose
  IF SIZE(var2, /type) EQ 0 THEN ctime, trange, npoints=npts, /silent

  status = EXECUTE("c6 = SCOPE_VARFETCH('mvn_c6_dat', common='mvn_c6')")
  IF status EQ 0 THEN BEGIN
     dprint, 'Since APID = c6 data is not available, ' + $
             'it cannot automatically determine the obs. mode at the specified time.', dlevel=1, verbose=verbose
     RETURN
  ENDIF ELSE undefine, status
  
  IF ~keyword_set(id) THEN BEGIN
     mode = c6.mode
     mtime = c6.time
  ENDIF
  func = 'mvn_sta_get'
  IF ~keyword_set(mmin) THEN mmin = 0
  IF ~keyword_set(mmax) THEN mmax = 100.
  
  ok = 1
  WHILE (ok) DO BEGIN
     IF ~keyword_set(id) THEN BEGIN
        idx = nn(mtime, trange)
        emode = mode[idx]
        emode = emode[uniq(emode)]
        IF N_ELEMENTS(emode) EQ 1 THEN BEGIN
           IF MEAN(trange) LT time_double('2015-07-01') THEN BEGIN
              CASE emode OF
                 1: IF (aflg) THEN apid = 'cd' ELSE apid = 'cc'
                 2: IF (aflg) THEN apid = 'cf' ELSE apid = 'ce'
                 3: IF (aflg) THEN apid = 'd1' ELSE apid = 'd0'
                 5: IF (aflg) THEN apid = 'd1' ELSE apid = 'd0'
                 6: IF (aflg) THEN apid = 'd1' ELSE apid = 'd0'
                 ELSE: apid = 'ca'
              ENDCASE
           ENDIF ELSE IF (aflg) THEN apid = 'd1' ELSE apid = 'd0'
        ENDIF ELSE BEGIN
           dprint, 'The specified time range includes multiple APID modes.', dlevel=2, verbose=verbose
           apid = 'ca'
        ENDELSE
        undefine, idx, emode
     ENDIF ELSE apid = id

     IF keyword_set(sum) THEN d = mvn_sta_get(apid, tt=trange) $
     ELSE d = CALL_FUNCTION(func + '_' + apid, trange)
     
     IF d.valid EQ 1 THEN BEGIN
        IF keyword_set(mass) THEN BEGIN
           idx = where(d.mass_arr LT mmin OR d.mass_arr GT mmax, nidx)
           IF nidx GT 0 THEN d.data[idx] = 0.
           IF keyword_set(mq) THEN d.mass *= FLOAT(mq)
        ENDIF
        
        IF keyword_set(mso) THEN BEGIN
           mvn_pfp_cotrans, d, from='MAVEN_STATIC', to='MAVEN_MSO', /overwrite

           IF TOTAL(d.quat_mso) EQ 0. THEN $
              bnew = spice_vector_rotate(d.magf, (d.time+d.end_time)/2.d, 'MAVEN_STATIC', 'MAVEN_MSO', check='MAVEN_SPACECRAFT', verbose=verbose) $
           ELSE bnew = REFORM(quaternion_rotation(d.magf, d.quat_mso, /last_ind))
           str_element, d, 'magf', bnew, /add_replace
        ENDIF 
        
        IF keyword_set(bline) THEN bdir = d.magf/SQRT(TOTAL(d.magf*d.magf))
        d = sum4m(d)
        str_element, d, 'nbins', (d.nbins), /add_replace
        str_element, d, 'nenergy', (d.nenergy), /add_replace
        str_element, d, 'bins', REBIN(TRANSPOSE(d.bins), d.nenergy, d.nbins), /add_replace
        str_element, d, 'bins_sc', REBIN(TRANSPOSE(d.bins_sc), d.nenergy, d.nbins), /add_replace

        IF keyword_set(sc_pot) OR keyword_set(vsc) THEN BEGIN
           IF keyword_set(vsc) THEN BEGIN
              sstat = EXECUTE("v_sc = spice_body_vel('MAVEN', 'MARS', utc=0.5*(d.time + d.end_time), frame='MAVEN_MSO')")
              IF sstat EQ 0 THEN BEGIN
                 mvn_spice_load, /download, verbose=verbose
                 v_sc = spice_body_vel('MAVEN', 'MARS', utc=0.5*(d.time + d.end_time), frame='MAVEN_MSO')
              ENDIF 
              IF SIZE(v_sc, /type) NE 0 THEN BEGIN
                 v_sc = spice_vector_rotate(v_sc, 0.5*(d.time + d.end_time), 'MAVEN_MSO', 'MAVEN_STATIC', verbose=verbose)
                 dprint, dlevel=2, verbose=verbose, $
                         lbreak + '  Correcting f(v) for the spacecraft velocity:' + lbreak + $
                         '  V_sc (km/s) = [   ' + STRING(v_sc, '(3(F0, :, ",   "))') + '].'
              ENDIF 
              undefine, sstat
           ENDIF ELSE v_sc = [0., 0., 0.]

           IF keyword_set(sc_pot) THEN d.sc_pot = sc_pot
           vel = v_4d(d)
           IF keyword_set(sc_pot) THEN d.sc_pot *= -1. ; Trick to apply 'convert_vframe'.
           d = convert_vframe(d, v_sc)                 ; Correcting f(v) for either sc_pot or V_sc.
           badbin = WHERE(~FINITE(d.energy), nbad)
           IF nbad GT 0 THEN d.bins[badbin] = 0
           vel -= v_sc          ; Removing V_sc from the bulk flow.
           undefine, v_sc
        ENDIF ELSE vel = v_3d(d)

        IF !d.name NE 'PS' THEN BEGIN
           wstat = EXECUTE("wset, wnum")
           IF wstat EQ 0 THEN wi, wnum, wsize=[dsize[0]/2., dsize[1]*2./3.] ELSE undefine, wstat
        ENDIF 

        IF keyword_set(showdata) THEN BEGIN
           dummy = d
           dummy.data = FLOAT(d.bins_sc) 
           status = EXECUTE("slice2d, dummy, _extra=_extra, vel=vel, /noplot, datplot=block, /verbose")
           undefine, dummy
        ENDIF
        status = EXECUTE("slice2d, d, _extra=_extra, sundir=bdir, vel=vel, datplot=dpts")
        IF status EQ 1 THEN BEGIN
           XYOUTS, !x.window[0]*1.2, !y.window[0]*1.2, mtit, charsize=!p.charsize, /normal
           IF keyword_set(showdata) THEN BEGIN
              wb = WHERE(block.v LE 0., nwb, complement=wf, ncomplement=nwf)
              IF nwb GT 0 THEN OPLOT, block.x[wb], block.y[wb], psym=7, color=1, symsize=showdata ; blocked bins
              IF nwf GT 0 THEN OPLOT, block.x[wf], block.y[wf], psym=1, symsize=showdata          ; free space bins
              undefine, block, wb, nwb, wf, nwf
           ENDIF 
        ENDIF 
        undefine, status, d, vel, dpts
     ENDIF ELSE dprint, 'Click again.', dlevel=2, verbose=verbose

     IF SIZE(var2, /type) EQ 0 THEN BEGIN
        ctime, trange, npoints=npts, /silent
        IF (SIZE(trange, /type) EQ 5) THEN ok = 1 ELSE ok = 0
     ENDIF ELSE ok = 0
  ENDWHILE 
  IF ~keyword_set(keepwin) THEN IF !d.name NE 'PS' THEN wdelete, wnum
  !p.charsize = ochsz
  RETURN
END 
