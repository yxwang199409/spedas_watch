;+
; Procedure:
;         mms_part_slice2d
;
; Purpose:
;         This is a wrapper around spd_slice2d that loads required
;         support data, creates the slice and plots the slice
;
; Keywords:
;         probe: MMS s/c # to create the 2D slice for
;         instrument: fpi or hpca
;         species: depends on instrument:
;             FPI: 'e' for electrons, 'i' for ions
;             HPCA: 'hplus' for H+, 'oplus' for O+, 'heplus' for He+, 'heplusplus', for He++
;         level: level of the data you'd like to plot
;         data_rate: data rate of the distribution data you'd like to plot
;         time: time of the 2D slice
;         trange: two-element time range over which data will be averaged (optional, ignored if 'time' is specified)
;         spdf: load the data from the SPDF instead of the LASP SDC
;         output: returns the computed slice
;         units: units of the slice (default is df_cm - other options include 'df_km', 'flux', 'eflux')
;
; Notes:
;         This routine always centers the distribution/moments data
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-05-07 08:01:20 -0700 (Mon, 07 May 2018) $
;$LastChangedRevision: 25174 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_part_slice2d.pro $
;-

pro mms_part_slice2d, time=time, probe=probe, level=level, data_rate=data_rate, species=species, instrument=instrument, $
                      trange=trange, subtract_bulk=subtract_bulk, spdf=spdf, rotation=rotation, output=output, $
                      units=units, _extra=_extra

    start_time = systime(/seconds)
  
    if undefined(time) then begin
      if ~keyword_set(trange) then begin
        trange = timerange()
      endif else trange = timerange(trange)
    endif else trange = time_double(time)+[-60, 60]

    if undefined(instrument) then instrument = 'fpi' else instrument = strlowcase(instrument)
    if undefined(species) then begin
      if instrument eq 'fpi' then species = 'e'
      if instrument eq 'hpca' then species = 'hplus'
    endif
    if undefined(data_rate) then begin
      if instrument eq 'fpi' then data_rate = 'fast'
      if instrument eq 'hpca' then data_rate = 'srvy'
    endif
    if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
    if undefined(rotation) then rotation = 'xy'
    
    if ~in_set(rotation, ['xy', 'yz', 'xz']) then load_support = 1b else load_support = 0b
    if keyword_set(subtract_bulk) then load_support = 1b ; need support data for bulk velocity subtraction as well
    
    if load_support then mms_load_fgm, trange=trange, probe=probe, spdf=spdf
    bname = 'mms'+probe+'_fgm_b_gse_srvy_l2_bvec'
    
    if instrument eq 'fpi' then begin
      name = 'mms'+probe+'_d'+species+'s_dist_'+data_rate
      vname = 'mms'+probe+'_d'+species+'s_bulkv_gse_'+data_rate
      mms_load_fpi, datatype='d'+species+'s-dist', data_rate=data_rate, /center, level=level, probe=probe, trange=trange, spdf=spdf
      if load_support then mms_load_fpi, datatype='d'+species+'s-moms', data_rate=data_rate, /center, level=level, probe=probe, trange=trange, spdf=spdf
    endif else if instrument eq 'hpca' then begin
      name = 'mms'+probe+'_hpca_'+species+'_phase_space_density'
      vname = 'mms'+probe+'_hpca_'+species+'_ion_bulk_velocity'
      mms_load_hpca, datatype='ion', data_rate=data_rate, /center, level=level, probe=probe, trange=trange, spdf=spdf
      if load_support then mms_load_hpca, datatype='moments', data_rate=data_rate, /center, level=level, probe=probe, trange=trange, spdf=spdf
    endif else begin
      dprint, dlevel=0, 'Error, unknown instrument; valid options are: fpi, hpca'
      return
    endelse
    
    dist = mms_get_dist(name, trange=trange, /structure)
    
    if keyword_set(units) then begin
      for dist_idx=0, n_elements(dist)-1 do begin
        mms_convert_flux_units, dist[dist_idx], units=units, output=dist_tmp
        append_array, dist_out, dist_tmp
      endfor
    endif else dist_out = dist

    if ~undefined(time) then undefine, trange
    
    slice = spd_slice2d(dist_out, time=time, trange=trange, rotation=rotation, mag_data=bname, vel_data=vname, _extra=_extra)
    
    spd_slice2d_plot, slice, _extra=_extra
    output=slice
end