;+
; PROCEDURE:
;         mms_eis_pad_spinavg
;
; PURPOSE:
;         Calculates spin-averaged PADs for the EIS instrument
;
; KEYWORDS:
;         probes:       Probe # to calculate the spin averaged PAD for
;                       if no probe is specified the default is probe '1'
;         datatype:     EIS data types include ['extof' (default), 'phxtof', 'electronenergy', 'combined'].
;                       'combined' is only for use on combined phxtof and extof variables created by
;                       mms_eis_combine_proton_pad.pro
;         data_rate:    instrument data rates for EIS are: ['brst','srvy' (default)].
;         data_units:   desired units for data. Options are ['flux' (default), 'cps', 'counts'].
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         species:      species (should be: proton (default), oxygen, alpha, or electron)
;         scopes:       string array of telescopes to be included in PAD ('0'-'5')
;
; OUTPUT:
; 
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-11-20 09:33:17 -0800 (Mon, 20 Nov 2017) $
;$LastChangedRevision: 24314 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/eis/mms_eis_pad_spinavg.pro $
;
; REVISION HISTORY:
;       + 2016-01-26, I. Cohen      : added scopes keyword and scope_suffix definition to allow for distinction between single telescope PADs (reflects change in mms_eis_pad.pro)
;       + 2016-04-29 egrimes        : fixed issues with the suffix keyword     
;       + 2017-05-15 egrimes        : removed call to congrid, added the "extend_y_edges" option to the output;
;                                     this change makes the results produced by this routine consistent with the
;                                     non-spin averaged PAD
;       + 2017-11-17, I. Cohen      : updated to accept changes to mms_eis_pad.pro, introduced 'combined' datatype;
;                                     changed probe keyword to probes     
;       + 2017-11-20, E. Grimes     : a few minor bug fixes caught by the test suite                      
;-

pro mms_eis_pad_spinavg, probes=probes, species = species, data_units = data_units, $
  datatype = datatype, energy = energy, size_pabin = size_pabin, data_rate = data_rate, $
  suffix = suffix, scopes = scopes
  ;
  compile_opt idl2
  if not KEYWORD_SET(probes) then probes='1' else probes = strcompress(string(probes), /rem)
  if not KEYWORD_SET(datatype) then datatype = 'extof'
  if not KEYWORD_SET(data_units) then data_units = 'flux'
  if not KEYWORD_SET(species) then species = 'proton'
  if not KEYWORD_SET(suffix) then suffix_in = '' else suffix_in = suffix
  if not KEYWORD_SET(energy) then energy = [0, 1000]
  if not KEYWORD_SET(size_pabin) then size_pabin = 15
  if not KEYWORD_SET(data_rate) then data_rate = 'srvy'
  if not KEYWORD_SET(scopes) then scopes = ['0','1','2','3','4','5']
  ;
  en_range_string = strcompress(string(energy[0]), /rem) + '-' + strcompress(string(energy[1]), /rem) + 'keV'
  units_label = data_units eq 'cps' ? '1/s': '1/(cm!U2!N-sr-s-keV)'
  ;
  if (data_rate eq 'brst') then prefix = 'mms'+probes+'_epd_eis_brst_' else prefix = 'mms'+probes+'_epd_eis_'
  if (n_elements(scopes) eq 1) then scope_suffix = '_t'+scopes+suffix_in else if (n_elements(scopes) eq 6) then scope_suffix = '_omni'+suffix_in
  ;
  ; get the spin #s associated with each measurement
  if (datatype eq 'combined') then get_data, prefix + 'extof_spin'+suffix_in, data=spin_nums $
    else get_data, prefix + datatype + '_spin'+suffix_in, data=spin_nums
  ;
  ; find where the spins start
  spin_starts = uniq(spin_nums.Y)
  pad_name = prefix + datatype + '_' + en_range_string + '_' + species + '_' + data_units + scope_suffix + '_pad'
  ;
  get_data, pad_name, data=pad_data, dlimits=pad_dl
  ;
  if ~is_struct(pad_data) then begin
    ;stop
    dprint, dlevel = 0, 'Error, variable containing valid PAD data missing.'
    return
  endif
  ;
  spin_sum_flux = dblarr(n_elements(spin_starts), n_elements(pad_data.Y[0, *]))
  spin_times = dblarr(n_elements(spin_starts))
  ;
  current_start = 0
  ; loop through the spins for this telescope
  for spin_idx = 0, n_elements(spin_starts)-1 do begin
    ; loop over energies
    spin_sum_flux[spin_idx, *] = average(pad_data.Y[where(spin_nums.y eq spin_nums.y[spin_starts[spin_idx]]), *], 1, /nan)
    spin_times[spin_idx] = pad_data.X[current_start]
    current_start = spin_starts[spin_idx]+1
  endfor
  ;
  newname = prefix+datatype+'_'+en_range_string+'_'+species+'_'+data_units+scope_suffix+'_pad_spin'
  ;
  ; the following is because of prefix becoming a single element array in some cases
  if is_array(newname) then newname = newname[0] 
  ;
  n_pabins = 180./size_pabin
  new_bins = 180.*indgen(n_pabins+1)/n_pabins
  new_pa_label = 180.*indgen(n_pabins)/n_pabins+size_pabin/2.
  ;
  store_data, newname, data={x: spin_times, y: spin_sum_flux, v: new_pa_label}, dlimits=flux_dl
  ;
  options, newname, spec=1, ystyle=1, ztitle=units_label, ytitle='MMS'+probes+' EIS '+species, ysubtitle=en_range_string+'!CPAD (deg)', minzlog=.01
  zlim, newname, 0, 0, 1
  ylim, newname, 1., 180.
  options, newname, 'extend_y_edges', 1
  ;
  tdegap, newname, /overwrite
end