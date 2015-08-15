;+
; PROCEDURE:
;         mms_load_data
;         
; PURPOSE:
;         Generic MMS load data routine; typically called from instrument specific 
;           load routines - mms_load_???, i.e., mms_load_fgm, mms_load_fpi, etc.
; 
; KEYWORDS:
;         trange: time range of interest
;         probes: list of probes - values for MMS SC #
;         instrument: instrument, AFG, DFG, etc.
;         datatype: not implemented yet 
;         local_data_dir: local directory to store the CDF files; should be set if 
;             you're on *nix or OSX, the default currently assumes the IDL working directory
;         attitude_data: load L-right ascension and L-declination attitude data
;         login_info: string containing name of a sav file containing a structure named "auth_info",
;             with "username" and "password" tags with your API login information
;         varformat: format of the variable names in the CDF to load; not currently used for HPCA ion data
;         
; 
; OUTPUT:
; 
; 
; EXAMPLE:
;     See the crib sheet mms_load_data_crib.pro for usage examples
; 
; NOTES:
;     1) I expect this routine to change significantly as the MMS data products are 
;         released to the public and feedback comes in from scientists - egrimes@igpp
;
;     2) See the following regarding rules for the use of MMS data:
;         https://lasp.colorado.edu/galaxy/display/mms/MMS+Data+Rights+and+Rules+for+Data+Use
;         
;     3) Updated to use the MMS web services API
;     
;     4) The LASP web services API uses SSL/TLS, which is only supported by IDLnetURL 
;         in IDL 7.1 and later. 
;         
;     5) CDF version 3.6 is required to correctly handle the 2015 leap second.  CDF versions before 3.6
;         will give incorrect time tags for data loaded after June 30, 2015 due to this issue.
;         
;     6) The local paths should be set to mirror the SDC directory structure to avoid
;         downloading data more than once
;         
;     7) Warning about datatypes and paths:
;           -- many of the MMS instruments contain datatype details in their path names; for these CDFs
;           to be stored in the correct location locally (i.e., mirroring the SDC directory structure)
;           these datatypes must be passed to this routine by a higher level routine via the "datatype"
;           keyword. If the datatype keyword isn't passed, or datatype "*" is passed, the directory names
;           won't currently match the SDC. We can fix this by defining what "*" is for datatypes 
;           (by a list of all datatypes) in the instrument specific load routine, and passing those to this one.
;           
;               Example for HPCA: mms1/hpca/srvy/l1b/moments/2015/07/
;               
;               "moments" is the datatype. without passing datatype=["moments", ..], the data are stored locally in:
;                                 mms1/hpca/srvy/l1b/2015/07/
;               
;      8) When looking for data availability, look for the CDFs at:
;               https://lasp.colorado.edu/mms/sdc/about/browse/
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-08-13 13:33:31 -0700 (Thu, 13 Aug 2015) $
;$LastChangedRevision: 18487 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/mms_load_data.pro $
;-

pro mms_load_data, trange = trange, probes = probes, datatypes = datatypes_in, $
                  levels = levels, instrument = instrument, data_rates = data_rates, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, login_info = login_info, $
                  tplotnames = tplotnames, varformat = varformat
                  
    mms_init, remote_data_dir = remote_data_dir, local_data_dir = local_data_dir
    
    if undefined(source) then source = !mms

    if undefined(probes) then probes = ['1'] ; default to MMS 1
    if undefined(levels) then levels = 'ql' ; default to quick look
    if undefined(instrument) then instrument = 'dfg'
    if undefined(data_rates) then data_rates = 'srvy'

    ;ensure datatypes are explicitly set for simplicity 
    if undefined(datatypes_in) || in_set('*',datatypes_in) then begin
        mms_load_options, instrument, rate=data_rates, level=levels, datatype=datatypes
    endif else begin
        datatypes = datatypes_in
    endelse

    if undefined(local_data_dir) then local_data_dir = !mms.local_data_dir
    if undefined(varformat) then varformat = '*'
    if ~undefined(trange) && n_elements(trange) eq 2 $
      then tr = timerange(trange) $
      else tr = timerange()

    response_code = spd_check_internet_connection()

    ;combine these flags for now, if we're not downloading files then there is
    ;no reason to contact the server unless mms_get_local_files is unreliable
    no_download = !mms.no_download or !mms.no_server or (response_code ne 200)

    ; only prompt the user if they're going to download data
    if no_download eq 0 then begin
        status = mms_login_lasp(login_info = login_info)
        if status ne 1 then no_download = 1
    endif
    
    ;clear so new names are not appended to existsing array
    undefine, tplotnames

    ;loop over probe, rate, level, and datatype
    ;omitting some tabbing to keep format reasonable
    for probe_idx = 0, n_elements(probes)-1 do begin
    for rate_idx = 0, n_elements(data_rates)-1 do begin
    for level_idx = 0, n_elements(levels)-1 do begin
    for datatype_idx = 0, n_elements(datatypes)-1 do begin
        ;options for this iteration
        probe = 'mms' + strcompress(string(probes[probe_idx]), /rem)
        data_rate = data_rates[rate_idx]
        level = levels[level_idx]
        datatype = datatypes[datatype_idx]

        daily_names = file_dailynames(file_format='/YYYY/MM', trange=tr, /unique, times=times)
        
        ; updated to match the path at SDC; this path includes data type for 
        ; the following instruments: EDP, DSP, EPD-EIS, FEEPS, FIELDS, HPCA, SCM (as of 7/23/2015)
        sdc_path = instrument + '/' + data_rate + '/' + level
        sdc_path = datatype ne '' ? sdc_path + '/' + datatype + daily_names : sdc_path + daily_names

        ;ensure no descriptor is used if instrument doesn't use datatypes
        if datatype eq '' then undefine, descriptor else descriptor = datatype

        for name_idx = 0, n_elements(sdc_path)-1 do begin
            day_string = time_string(tr[0], tformat='YYYY-MM-DD') 
            ; note, -1 second so we don't download the data for the next day accidently
            end_string = time_string(tr[1]-1., tformat='YYYY-MM-DD-hh-mm-ss')
            
            month_directory = sdc_path[name_idx]
            
            ;get file info from remote server
            ;if the server is contacted then a string array or empty string will be returned
            ;depending on whether files were found, if there is a connection error the 
            ;neturl response code is returned instead
            if ~keyword_set(no_download) then begin
                data_file = mms_get_science_file_info(sc_id=probe, instrument_id=instrument, $
                        data_rate_mode=data_rate, data_level=level, start_date=day_string, $
                        end_date=end_string, descriptor=descriptor)
            endif
            
            ;if a list of remote files was retrieved then compare remote and local files
            if is_string(data_file) then begin
              
                remote_file_info = mms_get_filename_size(data_file)
                
                if ~is_struct(remote_file_info) then begin
                    dprint, dlevel = 0, 'Error getting the information on remote files'
                    return
                endif
    
                filename = remote_file_info.filename
                num_filenames = n_elements(filename)
                
                file_dir = strlowcase(local_data_dir + probe + '/' + month_directory)
                
                for file_idx = 0, num_filenames-1 do begin
                    same_file = mms_check_file_exists(remote_file_info[file_idx], file_dir = file_dir)
                    
                    if same_file eq 0 then begin
                        dprint, dlevel = 0, 'Downloading ' + filename[file_idx] + ' to ' + file_dir
                        status = get_mms_science_file(filename=filename[file_idx], local_dir=file_dir)
                        
                        if status eq 0 then append_array, files, file_dir + '/' + filename[file_idx]
                    endif else begin
                        dprint, dlevel = 0, 'Loading local file ' + file_dir + '/' + filename[file_idx]
                        append_array, files, file_dir + '/' + filename[file_idx]
                    endelse
                endfor
            
            ;if no remote list was retrieved then search locally   
            endif else begin
                dprint, dlevel = 2, 'No remote files found for: '+ $
                        probe+' '+instrument+' '+data_rate+' '+level+' '+datatype
                
                local_files = mms_get_local_files(probe=probe, instrument=instrument, $
                        data_rate=data_rate, level=level, datatype=datatype, trange=time_double([day_string, end_string]))

                if is_string(local_files) then begin
                    append_array, files, local_files
                endif else begin
                    dprint, dlevel = 0, 'Error, no data files found for this time.'
                    continue
                endelse
            endelse       
            
            ; sort the data files in time (this is required by 
            ; HPCA (at least) due to multiple files per day
            ; the intention is to order in time before passing
            ; to cdf2tplot
            files = files[bsort(files)]
        endfor

        if ~undefined(files) then begin
            ; kludge for HPCA ion data to avoid reinventing wheels
            if instrument eq 'hpca' and datatype eq 'ion' then begin
                mms_sitl_open_hpca_basic_cdf_jburch_skv_egrimes, files, measurement_id = [5, 5, 5], $
                    sc_id = probe, fov=[0, 180], species=[1, 3, 4], tplotnames = loaded_tnames
            endif else cdf2tplot, files, tplotnames = loaded_tnames, varformat=varformat, /all
        endif
        if ~undefined(loaded_tnames) then append_array, tplotnames, loaded_tnames
        
        ; forget about the daily files for this probe
        undefine, files
        undefine, loaded_tnames

    ;end loops over probe, rate, leve, and datatype
    endfor
    endfor
    endfor
    endfor

    ; just in case multiple datatypes loaded identical variables
    ; (this occurs with hpca moments & logicals)
    if ~undefined(tplotnames) then tplotnames = spd_uniq(tplotnames)

    ; time clip the data
    if ~undefined(tr) && ~undefined(tplotnames) then begin
        if (n_elements(tr) eq 2) and (tplotnames[0] ne '') then begin
            time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
        endif
    endif
end