;+
; PROCEDURE:
;         mms_load_fpi
;         
; PURPOSE:
;         Load data from the Fast Plasma Investigation (FPI) onboard MMS
; 
; KEYWORDS:
;         trange: time range of interest
;         probes: list of probes - values for MMS SC #
;         datatype: type of data to load
;         local_data_dir: local directory to store the CDF files
;         no_color_setup: don't setup graphics configuration; use this
;             keyword when you're using this load routine from a
;             terminal without an X server running
; 
; 
; EXAMPLE:
;     See the crib sheet mms_load_fpi_crib.pro for usage examples
; 
; NOTES:
;     Please see the notes in mms_load_data for more information 
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-08-31 08:52:32 -0700 (Mon, 31 Aug 2015) $
;$LastChangedRevision: 18673 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_fpi.pro $
;-

function mms_fpi_angles
    return, [0,6,12,18, $
            24,30,36,42,48,54,60,66,72,78,84,90,96,102, $
            108,114,120,126,132,138,144,150,156,162,168,174] + 3
end

function mms_fpi_energies
    nrg01 = [10.958904109589000, $
       14.051833510123000, $
       18.017679780904700, $
       23.102806082448500, $
       29.623106602709100, $
       37.983630285592900, $
       48.703742960593600, $
       62.449390975440400, $
       80.074470587586500, $
       102.673873031106000, $
       131.651500482625000, $
       168.807478160251000, $
       216.449980276406000, $
       277.538616607854000, $
       355.868287029812000, $
       456.304925279898000, $
       585.087776639255000, $
       750.216987385536000, $
       961.950583542695000, $
       1233.441711847820000, $
       1581.555729113560000, $
       2027.917898564260000, $
       2600.256777307640000, $
       3334.126747794510000, $
       4275.116699001150000, $
       5481.682063277360000, $
       7028.776138409860000, $
       9012.506277013540000, $
       11556.104191359900000, $
       14817.581256189400000, $
       18999.544366165800000, $
       24361.782120892000000]

    nrg02 = [12.409379356009200, $
         15.911676106557200, $
         20.402425395866400, $
         26.160597993969600, $
         33.543898537707400, $
         43.010986574824500, $
         55.149969049070800, $
         70.714934213895700, $
         90.672796505583000, $
         116.263362435927000, $
         149.076348870252000, $
         191.150138159239000, $
         245.098404912620000, $
         314.272480622884000, $
         402.969542425509000, $
         516.699558933000000, $
         662.527576140347000, $
         849.512606615793000, $
         1089.270386303560000, $
         1396.694958070860000, $
         1790.883907640650000, $
         2296.324728683900000, $
         2944.416015503820000, $
         3775.417981638950000, $
         4840.953472956760000, $
         6207.214841191920000, $
         7959.075892786910000, $
         10205.364352263600000, $
         13085.622371919000000, $
         16778.775058872400000, $
         21514.245518836000000, $
         27586.206896551600000]

    energies = (nrg01 + nrg02)/2.
    return, energies
end

pro mms_load_fpi_fix_angles, tplotnames, prefix = prefix
    fpi_angles = mms_fpi_angles()

    spectra_where = strmatch(tplotnames, prefix + '_fpi_?PitchAngDist_*En')

    if n_elements(spectra_where) ne 0 then begin
        for var_idx = 0, n_elements(tplotnames)-1 do begin
            if spectra_where[var_idx] ne 0 then begin
                get_data, tplotnames[var_idx], data=fpi_d, dlimits=dl
                if is_struct(fpi_d) then begin
                    store_data, tplotnames[var_idx], data={x: fpi_d.X, y:fpi_d.Y, v: fpi_angles}, dlimits=dl
                endif
            endif
        endfor
    endif
end
pro mms_load_fpi_fix_spectra, tplotnames, prefix = prefix
    fpi_energies = mms_fpi_energies()

    spectra_where = strmatch(tplotnames, prefix + '_fpi_?EnergySpectr_??')

    if n_elements(spectra_where) ne 0 then begin
        for var_idx = 0, n_elements(tplotnames)-1 do begin
            if spectra_where[var_idx] ne 0 then begin
                get_data, tplotnames[var_idx], data=fpi_d, dlimits=dl
                if is_struct(fpi_d) then begin
                    store_data, tplotnames[var_idx], data={x: fpi_d.X, y:fpi_d.Y, v: fpi_energies}, dlimits=dl
                endif
            endif
        endfor
    endif
end

pro mms_load_fpi, trange = trange, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip

    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = ['3'] ; default to MMS 3
    if undefined(datatype) then datatype = '*' ; grab all data in the CDF
    if undefined(level) then level = 'sitl' 
    if undefined(data_rate) then data_rate = 'fast'
      
    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'fpi', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip

    ; correct the energies in the spectra for each probe
    if ~undefined(tplotnames) && n_elements(tplotnames) ne 0 then begin
        for probe_idx = 0, n_elements(probes)-1 do begin
            mms_load_fpi_fix_spectra, tplotnames, prefix = 'mms'+strcompress(string(probes[probe_idx]), /rem)
            mms_load_fpi_fix_angles, tplotnames, prefix = 'mms'+strcompress(string(probes[probe_idx]), /rem)
        endfor
    endif
end