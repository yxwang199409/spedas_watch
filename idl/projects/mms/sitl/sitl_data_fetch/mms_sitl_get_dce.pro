; This program will fetch the 2D DCE data for the SITL from the SDC
; 
; Use coord = 'pgse' for pseudo-gse
; Use coord = 'dsl' for DSL

pro mms_sitl_get_dce, start_date, end_date, cache_dir, sdp_status, sc_id=sc_id, coord=coord, no_update = no_update, reload = reload

  sdp_status = 0
  
  level = 'sitl'
  mode = 'fast'
  
  on_error, 2
  if keyword_set(no_update) and keyword_set(reload) then message, 'ERROR: Keywords /no_update and /reload are ' + $
    'conflicting and should never be used simultaneously.'
  
  ; See if spacecraft id is set
  if ~keyword_set(sc_id) then begin
    print, 'Spacecraft ID not set, defaulting to mms1.'
    sc_id = 'mms1'
  endif else begin
    sc_id=strlowcase(sc_id) ; this turns any data type to a string
    if sc_id ne 'mms1' and sc_id ne 'mms2' and sc_id ne 'mms3' and sc_id ne 'mms4' then begin
      message,"Invalid spacecraft id. Using default spacecraft mms1.",/continue
      sc_id='mms1'
    endif
  endelse
  
  ; See if coord is set
  if ~keyword_set(coord) then begin
    print, 'Vector basis not set, defaulting to pgse'
    coord = 'pgse'
  endif else begin
    sc_id=strlowcase(coord) ; this turns any data type to a string
    if sc_id ne 'pgse' and sc_id ne 'dsl' then begin
      message,"Invalid vector basis. Using default system pgse.",/continue
      coord='pgse'
    endif
  endelse
  
  ;----------------------------------------------------------------------------------------------------------
  ; Get the data
  ;----------------------------------------------------------------------------------------------------------
  
  if keyword_set(no_update) then begin
    mms_data_fetch, local_flist, cache_dir, start_date, end_date, login_flag, sc_id=sc_id, $
      instrument_id='sdp', mode=mode, $
      level=level, optional_descriptor = 'dce', /no_update
  endif else begin
    if keyword_set(reload) then begin
      mms_data_fetch, local_flist, cache_dir, start_date, end_date, login_flag, sc_id=sc_id, $
        instrument_id='sdp', optional_descriptor = 'dce', mode=mode, $
        level=level, /reload
    endif else begin
      mms_data_fetch, local_flist, cache_dir, start_date, end_date, login_flag, sc_id=sc_id, $
        instrument_id='sdp', optional_descriptor = 'dce', mode=mode, $
        level=level
    endelse
  endelse
  
  ;
  ;if n_elements(local_flist) eq 1 and strlen(local_flist(0)) eq 0 then begin
  ;  login_flag = 1
  ;endif
  
  ; Now we need to do one of two things:
  ; If the communication to the server fails, or no data on server, we need to check for local data
  ; If the communication worked, we need to open the flist
  
  ; First lets handle failure of the server
  
  
  file_flag = 0
  if login_flag eq 1 then begin
    print, 'Unable to locate files on the SDC server, checking local cache...'
    mms_check_local_cache, local_flist, cache_dir, start_date, end_date, file_flag, $
      mode, 'sdp', level, sc_id, optional_descriptor = 'dce'
  endif
  
  if login_flag eq 0 or file_flag eq 0 then begin
    ; We can safely verify that there is some data file to open, so lets do it
    
    
    files_open = local_flist
    
    ; Now we can open the files and create tplot variables
    ; First, we open the initial file
    
    efield_struct = mms_sitl_open_sdp_dce_sitl_cdf(files_open(0), coord)
    times = efield_struct.x
    e_field = efield_struct.y
    sdpvarname = efield_struct.varname
    
    if n_elements(files_open) gt 1 then begin
      for i = 1, n_elements(files_open)-1 do begin
        temp_struct = mms_sitl_open_sdp_dce_sitl_cdf(files_open(i), coord)
        times = [times, temp_struct.x]
        e_field = [e_field, temp_struct.y]
      endfor
    endif
    
    store_data, sdpvarname, data = {x: times, y:e_field}
    
    ;
    
  endif else begin
    sdp_status = 1
    print, 'No E-field data available locally or at SDC or invalid query!'
  endelse
  
  
  
end