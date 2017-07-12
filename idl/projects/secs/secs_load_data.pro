;+
; Procedure: secs_load_data
; 
; Keywords: 
;             trange:        time range of interest
;             datatype:      type of secs data to be loaded. Valid data types are: secs or SEC
;             suffix:        String to append to the end of the loaded tplot variables
;             prefix:        String to append to the beginning of the loaded tplot variables
;             /downloadonly: Download the file but don't read it  
;             /noupdate:     Don't download if file exists (not implemented yet)
;             /nodownload:   Don't download - use only local files
;             verbose:       controls amount of error/information messages displayed 
;             /get_stations: get list of stations used to generate this data
; 
; NOTE: 
; - Can only handle time ranges that don't overlap a day
; - Need to  No Update and No clobber
; - Need to correctly handle time clip
; - Add all standard tplot options
; - If no files downloaded notify user
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-02-13 15:32:14 -0800 (Mon, 13 Feb 2017) $
; $LastChangedRevision: 22769 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/secs/secs_load_data.pro $
;-
 
pro secs_load_data, trange = trange, datatype = datatype, suffix = suffix, prefix = prefix, $
                    downloadonly = downloadonly, noupdate = noupdate, nodownload = nodownload, $
                    verbose = verbose, get_stations = get_stations
                    
    compile_opt idl2
    
    ; handle possible server errors
    catch, errstats
    if errstats ne 0 then begin
        dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
        catch, /cancel
        return
    endif

    ; initialize variables and parameters
    defsysv, '!secs', exists=exists
    if not(exists) then secs_init
    if undefined(suffix) then suffix = ''
    if undefined(prefix) then prefix = ''
    if not keyword_set(datatype) then datatype = '*'   
    if datatype[0] EQ '*' then datatype = ['eics', 'seca']
    dirtype = strupcase(strmid(datatype,0,3))
    if not keyword_set(source) then source = !secs
    if (keyword_set(trange) && n_elements(trange) eq 2) $
      then tr = timerange(trange) $
      else tr = timerange()

    tn_list_before = tnames('*')
      
    ; extract date information
    tstart = time_string(tr[0])
    yr_start = strmid(time_string(tr[0]),0,4)
    mo_start = strmid(time_string(tr[0]),5,2)
    day_start = strmid(time_string(tr[0]),8,2)
 
    dur = (time_struct(tr[1])).sod - (time_struct(tr[0])).sod
    if dur EQ 0 then nfiles = 1 else nfiles = long(dur/10)
    dates = time_string(tr[0]+long(findgen(nfiles)*10)) 
    idx = strpos(dates[0], '/')     
    dates_str = strmid(dates,idx+1,2)+strmid(dates,idx+4,2)+strmid(dates,idx+7,2)
   
    for j = 0, n_elements(datatype)-1 do begin
    
        remote_path = source.remote_data_dir+dirtype[j]+'S/'+yr_start+'/'+mo_start+'/'+day_start+'/'   
        local_path = source.local_data_dir+dirtype[j]+'S\'+yr_start+'\'+mo_start+'\'+day_start+'\'
        filenames = dirtype[j]+'S'+yr_start+mo_start+day_start+'_'+dates_str+'.dat'

        local_files = local_path + filenames
        found_files = file_search(local_files, count=ncnt)
        
        if keyword_set(nodownload) then begin
            ; check for local files
            if ncnt LT 1 then begin
              dprint, dlevel = 0, ' No local files were found in: ' + local_path
              return
            endif
            if n_elements(found_files) LT n_elements(local_files) then begin
              ; update files var
              dprint, dlevel = 0, 'Not all local files were found in: '+local_path
              dprint, dlevel = 0, 'Loading files there were found.'
            endif
        endif else begin
            if keyword_set(noupdate) then begin
              if ncnt GT 0 then begin 
                 for k=0,n_elements(filenames)-1 do begin
                    idx = where(found_files eq local_files[k],fcnt)
                    stop
                    if fcnt LT 1 then append_array, update_files, filenames[k]
                 endfor
                 stop
                 if ~undefined(update_files) && update_files[0] NE '' then $
                    files = spd_download(remote_file=update_files, remote_path=remote_path, $
                                         local_path = local_path)                 
              endif 
            endif else begin
              files = spd_download(remote_file=filenames, remote_path=remote_path, $
                                   local_path = local_path)
            endelse
        endelse
         
        if keyword_set(downloadonly) then continue

        ; can only read files that have been downloaded
        files = file_search(local_files, count=ncnt)
        if ncnt EQ 0 then continue

        case datatype[j] of
          ; Equivalent Ionospheric Currents
          'eics': eic_ascii2tplot, files, prefix=prefix, suffix=suffix, verbose=verbose, tplotnames=tplotnames
          ; Current Magnitudes
          'seca': sec_ascii2tplot, files, prefix=prefix, suffix=suffix, verbose=verbose, tplotnames=tplotnames
          else: dprint, dlevel = 0, 'Unknown data type!'
        endcase

        ; load magnetometer stations
        ;if keyword_set(get_stations) then get_station_names
       
    endfor

    ; make sure some tplot variables were loaded
    tn_list_after = tnames('*')
    new_tnames = ssl_set_complement([tn_list_before], [tn_list_after])
    
    ; check that some data was loaded
;    if n_elements(new_tnames) eq 1 && is_num(new_tnames) then begin
;        dprint, dlevel = 1, 'No new tplot variables were created.'
;        return
;    endif
        
end
