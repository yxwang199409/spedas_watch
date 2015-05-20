;+
;FUNCTION:   mvn_swe_getpad
;PURPOSE:
;  Returns a SWEA PAD data structure constructed from L0 data or extracted
;  from L2 data.  This routine automatically determines which data are loaded.
;  Optionally sums the data over a time range, propagating uncertainties.
;
;USAGE:
;  pad = mvn_swe_getpad(time)
;
;INPUTS:
;       time:          An array of times for extracting one or more PAD data structure(s)
;                      from survey data (APID A2).  Can be in any format accepted by
;                      time_double.
;
;KEYWORDS:
;       ARCHIVE:       Get PAD data from archive instead (APID A3).
;
;       BURST:         Synonym for ARCHIVE.
;
;       ALL:           Get all PAD spectra bounded by the earliest and latest times in
;                      the input time array.
;
;       SUM:           If set, then sum all PAD's selected.
;
;       UNITS:         Convert data to these units.  (See mvn_swe_convert_units)
;                      Default = 'eflux'.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-05-18 14:43:14 -0700 (Mon, 18 May 2015) $
; $LastChangedRevision: 17641 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_getpad.pro $
;
;CREATED BY:    David L. Mitchell  03-29-14
;FILE: mvn_swe_getpad.pro
;-
function mvn_swe_getpad, time, archive=archive, all=all, sum=sum, units=units, burst=burst

  @mvn_swe_com

  if (size(time,/type) eq 0) then begin
    print,"You must specify a time."
    return, 0
  endif
  
  time = time_double(time)
  
  if (size(swe_mag1,/type) eq 8) then addmag = 1 else addmag = 0
  if (size(swe_sc_pot,/type) eq 8) then addpot = 1 else addpot = 0
  if (size(units,/type) ne 7) then units = 'eflux'
  if keyword_set(burst) then archive = 1

; First attempt to get extract PAD(s) from L2 data

  if keyword_set(archive) then begin
    if (size(mvn_swe_pad_arc,/type) eq 8) then begin
      if keyword_set(all) then begin
        tmin = min(time, max=tmax, /nan)
        indx = where((mvn_swe_pad_arc.time ge tmin) and (mvn_swe_pad_arc.time le tmax), npts)
        if (npts gt 0L) then time = mvn_swe_pad_arc[indx].time $
                        else print,"No PAD archive data at specified time(s)."        
      endif else npts = n_elements(time)
      
      if (npts gt 0L) then begin
        pad = replicate(swe_pad_struct, npts)
        aflg = 1
      endif
    endif else npts = 0L
  endif else begin
    if (size(mvn_swe_pad,/type) eq 8) then begin
      if keyword_set(all) then begin
        tmin = min(time, max=tmax, /nan)
        indx = where((mvn_swe_pad.time ge tmin) and (mvn_swe_pad.time le tmax), npts)
        if (npts gt 0L) then time = mvn_swe_pad[indx].time $
                        else print,"No PAD survey data at specified time(s)."
      endif else npts = n_elements(time)

      if (npts gt 0L) then begin
        pad = replicate(swe_pad_struct, npts)
        aflg = 0
      endif
    endif else npts = 0L
  endelse

  for n=0L,(npts-1L) do begin
    if (aflg) then begin
      tgap = min(abs(mvn_swe_pad_arc.time - time[n]), i)
      pad[n] = mvn_swe_pad_arc[i]
    endif else begin
      tgap = min(abs(mvn_swe_pad.time - time[n]), i)
      pad[n] = mvn_swe_pad[i]
    endelse

    if (addmag) then begin
      dt = min(abs(pad[n].time - swe_mag1.time),j)
      if (dt lt 1D) then pad[n].magf = swe_mag1[j].magf
    endif

    if (addpot) then begin
      dt = min(abs(pad[n].time - swe_sc_pot.time),j)
      if (dt lt pad[n].delta_t) then pad[n].sc_pot = swe_sc_pot[j].potential $
                                else pad[n].sc_pot = !values.f_nan
    endif
  endfor

  if (npts gt 0L) then begin

; Fill in bookkeeping parameters used by snapshot and diagnostic procedures
; Add magnetic field and spacecraft potential, if available

    mvn_swe_magdir, pad.time, iBaz, jBel, pad.Baz, pad.Bel, /inverse

    fake_pkt = replicate({time:0D, Baz:0., Bel:0., group:0}, npts)
    fake_pkt.time = pad.time
    fake_pkt.Baz = iBaz
    fake_pkt.Bel = jBel
    fake_pkt.group = pad.group

    for i=0L,(npts-1L) do begin
      pam = mvn_swe_padmap(fake_pkt[i])
;     pad[i].pa     = pam.pa     ; obtained from the CDF
;     pad[i].dpa    = pam.dpa    ; obtained from the CDF
      pad[i].pa_min = transpose(pam.pa_min)
      pad[i].pa_max = transpose(pam.pa_max)
      pad[i].theta  = transpose(swe_el[pam.jel,*,pad[i].group])
      pad[i].dtheta = transpose(swe_del[pam.jel,*,pad[i].group])
      pad[i].phi    = replicate(1.,pad[i].nenergy) # swe_az[pam.iaz]
      pad[i].dphi   = replicate(1.,pad[i].nenergy) # swe_daz[pam.iaz]
      pad[i].iaz    = pam.iaz
      pad[i].jel    = pam.jel
      pad[i].k3d    = pam.k3d
    endfor

    pad.domega = (2.*!dtor)*pad.dphi*cos(pad.theta*!dtor)*sin(pad.dtheta*!dtor/2.)

    if (keyword_set(sum) and (npts gt 1)) then pad = mvn_swe_padsum(pad)
    mvn_swe_convert_units, pad, units

    return, pad
  endif

; If necessary (npts = 0), extract PAD(s) from L0 data

  if keyword_set(archive) then begin
    if (size(a3,/type) ne 8) then begin
      print,"No PAD archive data."
      return, 0
    endif
    
    if keyword_set(all) then begin
      tmin = min(time, max=tmax, /nan)
      indx = where((a3.time ge tmin) and (a3.time le tmax), npts)
      if (npts eq 0L) then begin
        print,"No PAD archive data at specified time(s)."
        return, 0
      endif
      time = a3[indx].time
    endif

    npts = n_elements(time)
    pad = replicate(swe_pad_struct, npts)
    pad.data_name = "SWEA PAD Archive"
    pad.apid = 'A3'XB
    
    aflg = 1
  endif else begin
    if (size(a2,/type) ne 8) then begin
      print,"No PAD survey data."
      return, 0
    endif
    
    if keyword_set(all) then begin
      tmin = min(time, max=tmax, /nan)
      indx = where((a2.time ge tmin) and (a2.time le tmax), npts)
      if (npts eq 0L) then begin
        print,"No PAD survey data at specified time(s)."
        return, 0
      endif
      time = a2[indx].time
    endif

    npts = n_elements(time)
    pad = replicate(swe_pad_struct, npts)
    pad.data_name = "SWEA PAD Survey"
    pad.apid = 'A2'XB

    aflg = 0
  endelse

; Locate the PAD data closest to the desired time

  for n=0L,(npts-1L) do begin

    if (aflg) then begin
      tgap = min(abs(a3.time - time[n]), i)
      pkt = a3[i]

      thsk = min(abs(swe_hsk.time - a3[i].time), j)
      if (swe_active_chksum ne swe_chksum[j]) then mvn_swe_calib, chksum=swe_chksum[j]
    endif else begin
      tgap = min(abs(a2.time - time[n]), i)
      pkt = a2[i]

      thsk = min(abs(swe_hsk.time - a2[i].time), j)
      if (swe_active_chksum ne swe_chksum[j]) then mvn_swe_calib, chksum=swe_chksum[j]
    endelse

    pad[n].chksum = swe_active_chksum
 
    dt = 1.95D                            ; measurement span
    pad[n].time = pkt.time + (dt/2D)      ; center time (unix)
    pad[n].met = pkt.met + (dt/2D)        ; center time (met)
    pad[n].end_time = pkt.time + dt       ; end time (unix)
    pad[n].delta_t = swe_dt[pkt.period]   ; cadence

; Integration time per energy/angle bin prior to summing bins
; There are 7 deflection bins for each of 64 energy bins spanning
; 1.95 sec.  The first deflection bin is for settling and is
; discarded.

    pad[n].integ_t = swe_integ_t

; There are 16 anodes (az) X 6 deflections (el).  PAD data use the magnetic
; field to calculate the optimal deflection bin for each of the 16 anode
; bins in order to provide the best pitch angle coverage.  There is no
; summing of angle bins, even at the highest deflections (as in the 3D's).
; So for each energy bin, there is a 16x1 (az, el) array.  The final array
; dimensions are then 64 energies X 16 anodes X 1 deflector bin per anode,
; or 64x16, for short.

    pad[n].dt_arr = 2.^(pkt.group)        ; energy bin summing only

; Pitch angle map

    pam = mvn_swe_padmap(pkt)
    pad[n].pa = transpose(pam.pa)
    pad[n].dpa = transpose(pam.dpa)
    pad[n].pa_min = transpose(pam.pa_min)
    pad[n].pa_max = transpose(pam.pa_max)

; Energy bins are summed according to the group parameter.
; Energy resolution in the standard PAD structure allows for the possibility of
; variation with elevation angle.  SWEA calibrations show that this variation
; is modest (< 1% from +55 to -30 deg, increasing to ~4% at -45 deg).  For
; now, I will not include elevation variation.

    pad[n].group = pkt.group
    energy = swe_swp[*,0] # replicate(1.,16)
    pad[n].energy = energy
    
    pad[n].denergy[0,*] = abs(energy[0,*] - energy[1,*])
    for i=1,62 do pad[n].denergy[i,*] = abs(energy[i-1,*] - energy[i+1,*])/2.
    pad[n].denergy[63,*] = abs(energy[62,*] - energy[63,*])

; Geometric factor.  When using V0, the geometric factor is a function of
; energy.  There is also variation in azimuth and elevation.

    pad[n].gf = swe_gf[*,pam.iaz,pkt.group] * swe_dgf[*,pam.jel,pkt.group]

; Relative MCP efficiency.

    pad[n].eff = swe_mcp_eff[*,pam.iaz,pkt.group]

; Fill in the elevation array (units = deg)

    pad[n].theta = transpose(swe_el[pam.jel,*,pkt.group])
    pad[n].dtheta = transpose(swe_del[pam.jel,*,pkt.group])

; Fill in the azimuth array - no energy dependance (units = deg)

    pad[n].phi = replicate(1.,64) # swe_az[pam.iaz]
    pad[n].dphi = replicate(1.,64) # swe_daz[pam.iaz]

; Calculate solid angles from elevation and azimuth

    pad[n].domega = (2.*!dtor)*pad[n].dphi *    $
                    cos(pad[n].theta*!dtor) *   $
                    sin(pad[n].dtheta*!dtor/2.)

; Fill in the data array, duplicating values as needed  (I have to swap the
; first two dimensions of pkt.data.)
  
    counts = transpose(pkt.data[*,indgen(64)/(2^pkt.group)])
    var = transpose(pkt.var[*,indgen(64)/(2^pkt.group)])

; Calculate the deadtime correction, since the units are conveniently COUNTS.
; This makes it possible to convert back and forth between RATE, COUNTS and 
; other units.

    rate = counts/(swe_integ_t*pad[n].dt_arr)  ; raw count rate
    dtc = 1. - rate*swe_dead

    indx = where(dtc lt swe_min_dtc, count)    ; maximum deadtime correction
    if (count gt 0L) then dtc[indx] = !values.f_nan
    
    pad[n].dtc = dtc                           ; corrected count rate = rate/dtc

; Fill in the magnetic field direction

    pad[n].Baz = pam.Baz
    pad[n].Bel = pam.Bel

; Fill in bin numbers (useful for comparing PAD and 3D data)

    pad[n].iaz = pam.iaz
    pad[n].jel = pam.jel
    pad[n].k3d = pam.k3d

; Insert MAG1 data, if available.  This is distinct from the MAG angles
; included in the PAD packets (A2, A3), which are calculated by flight
; software using a basic calibration.

    if (addmag) then begin
      dt = min(abs(pad[n].time - swe_mag1.time),i)
      if (dt lt 1D) then pad[n].magf = swe_mag1[i].magf
    endif

; Insert spacecraft potential, if available

    if (addpot) then begin
      dt = min(abs(pad[n].time - swe_sc_pot.time),i)
      if (dt lt pad[n].delta_t) then pad[n].sc_pot = swe_sc_pot[i].potential $
                                else pad[n].sc_pot = !values.f_nan
    endif

; Electron rest mass [eV/(km/s)^2]

    pad[n].mass = mass_e

; And last, but not least, the data

    pad[n].data = counts                       ; raw counts
    pad[n].var = var                           ; variance

; Validate the data

    if (tgap gt 1.1D*pad[n].delta_t) then begin
      msg = strtrim(string(round(tgap)),2)
      print,"data gap: ",msg," sec"
    endif

    pad[n].valid = 1B                          ; Yep, it's valid.

  endfor

; Apply cross calibration factor.  A new factor is calculated after each 
; MCP bias adjustment. See mvn_swe_config for these times.  See 
; mvn_swe_calib for the cross calibration factors.

  scale = replicate(swe_crosscal[0], 64, 16, npts)

  for i=1,(n_elements(t_mcp)-1) do begin
    indx = where(pad.time gt t_mcp[i], count)
    if (count gt 0L) then scale[*,*,indx] = swe_crosscal[i]
  endfor
  
  pad.eff /= scale

; Sum the data

  if keyword_set(sum) then pad = mvn_swe_padsum(pad)

; Convert units

  mvn_swe_convert_units, pad, units

  return, pad

end
