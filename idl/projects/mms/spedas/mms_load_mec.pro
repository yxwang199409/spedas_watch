;+
; PROCEDURE:
;         mms_load_mec
;
; PURPOSE:
;         Load the attitude/ephermis data from the LANL MEC files
;
; KEYWORDS:
;         trange: time range of interest
;         probe: value for MMS SC #
;         varformat:    should be a string (wildcards accepted) that will match the CDF variables
;                       that should be loaded into tplot variables
;
; EXAMPLES:
;
;
; OUTPUT:
;
;
; NOTES:
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-10-28 16:22:34 -0700 (Wed, 28 Oct 2015) $
;$LastChangedRevision: 19180 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_mec.pro $
;-

pro mms_load_mec, trange = trange, probes = probes, datatype = datatype, $
    level = level, data_rate = data_rate, $
    local_data_dir = local_data_dir, source = source, $
    get_support_data = get_support_data, $
    tplotnames = tplotnames, no_color_setup = no_color_setup, $
    time_clip = time_clip, no_update = no_update, suffix = suffix, varformat = varformat

    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(datatype) then datatype = 'ephts04d'
    if undefined(level) then level = 'l2'
    if undefined(suffix) then suffix = ''
    if undefined(data_rate) then data_rate = 'srvy'

    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'mec', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update, suffix = suffix, varformat = varformat

    ; turn the right ascension and declination of the L vector into separate tplot variables
    ; this is for passing to dmpa2gse
    for probe_idx = 0, n_elements(probes)-1 do begin
        if tnames('mms'+strcompress(string(probes[probe_idx]), /rem)+'_mec_ang_mom_vec') ne '' then begin
            split_vec, 'mms'+strcompress(string(probes[probe_idx]), /rem)+'_mec_ang_mom_vec', $
                names_out=ras_dec_vars
            copy_data, ras_dec_vars[0], 'mms'+strcompress(string(probes[probe_idx]), /rem)+'_defatt_spinras'
            copy_data, ras_dec_vars[1], 'mms'+strcompress(string(probes[probe_idx]), /rem)+'_defatt_spindec'
        endif
    endfor
end