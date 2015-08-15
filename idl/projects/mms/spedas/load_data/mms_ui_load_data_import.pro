;+
;NAME:
;  mms_ui_load_data_import
;
;PURPOSE:
;  This routine acts as a wrapper around the load data 
;      routine for MMS, mms_load_data. It is called by the 
;      SPEDAS plugin mms_ui_load_data, and imports the data
;      loaded by mms_load_data into the SPEDAS GUI
;
;  
;HISTORY:
;
;;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-08-12 18:10:37 -0700 (Wed, 12 Aug 2015) $
;$LastChangedRevision: 18477 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/load_data/mms_ui_load_data_import.pro $
;
;-

pro mms_ui_load_data_import,$
                         loadStruc,$
                         loadedData,$
                         statusBar,$
                         historyWin,$
                         parent_widget_id,$  
                         replay=replay,$
                         overwrite_selections=overwrite_selections
                         

  compile_opt hidden,idl2
  
  ; initialize variables
  loaded = 0
  overwrite_selection=''
  overwrite_count =0
  if ~keyword_set(replay) then begin
    overwrite_selections = ''
  endif
  extra_msg = ''

  ; extract the variables from the load structure
  probes=loadStruc.probes
  instrument=loadStruc.instrument
  timeRange=loadStruc.trange
  rate=loadStruc.rate
  level=loadStruc.level
  datatype=loadStruc.datatype ;only used for state atm
  
  ; need to update for MMS
  mmsmintime = '2015-03-01'
  mmsmaxtime = time_string(systime(/seconds), tformat='YYYY-MM-DD')  

  tn_before = [tnames('*',create_time=cn_before)]

  if instrument eq 'STATE' then begin
     mms_load_state, probes=probes, level=level, datatypes=datatype, trange=timeRange, tplotnames=tplotnames
  endif else if instrument eq 'AFG' or instrument eq 'DFG' then begin
     mms_load_fgm, probes=probes, level=level, trange=timeRange, instrument=instrument, data_rate=rate, tplotnames=tplotnames
  endif else if instrument eq 'FPI' then begin
     mms_load_fpi, probes=probes, level=level, trange=timeRange, data_rate=rate, datatype=datatype, tplotnames=tplotnames
  endif else if instrument eq 'SCM' then begin
     mms_load_scm, probes=probes, level=level, trange=timeRange, data_rate=rate, datatype=datatype, tplotnames=tplotnames
  endif else if instrument eq 'FEEPS' then begin
     mms_load_feeps, probes=probes, level=level, trange=timeRange, data_rate=rate, datatype=datatype, tplotnames=tplotnames
  endif else if instrument eq 'EIS' then begin
     mms_load_eis, probes=probes, level=level, trange=timeRange, data_rate=rate, datatype=datatype, tplotnames=tplotnames
  endif else if instrument eq 'HPCA' then begin
     mms_load_hpca, probes=probes, level=level, trange=timeRange, data_rate=rate, datatype=datatype, tplotnames=tplotnames
     
     ;filter types with too many dimensions so that the user doesn't have to click
     ;through multiple warnings, there must be a better way...
     if is_string(tplotnames) then begin
        search = '(_starts)|(_stops)|(_tensor)|(_ion_pressure$)'
        dummy = where( stregex(tplotnames,search, /bool), ncomp=n_valid, comp=valid_idx)
        tplotnames =  n_valid gt 0 ? tplotnames[valid_idx] : ''
     endif

  endif else begin
     mms_load_data, probes=probes, level=level, trange=timeRange, instrument=instrument, data_rate=rate, tplotnames=tplotnames
  endelse

  ; determine which tplot vars to delete and which ones are the new temporary vars
  spd_ui_cleanup_tplot, tn_before, create_time_before=cn_before, del_vars=to_delete,$
                        new_vars=new_vars
 
  if is_string(tplotnames) then begin
    
    ; loop over loaded data
    for i = 0,n_elements(tplotnames)-1 do begin
      
      ; check if data is already loaded, if so query the user on whether they want to overwrite data
      spd_ui_check_overwrite_data,tplotnames[i],loadedData,parent_widget_id,statusBar,historyWin, $
        overwrite_selection,overwrite_count,replay=replay,overwrite_selections=overwrite_selections
      if strmid(overwrite_selection, 0, 2) eq 'no' then continue
      
      ; this statement adds the variable to the loadedData object
      result = loadedData->add(tplotnames[i],mission='MMS',observatory=probes, $
                               instrument=strupcase(instrument))
        
      ; report errors to the status bar and add them to the history window
      if ~result then begin
        spd_ui_message, 'Error loading: ' + tplotnames[i], sb=statusbar, hw=historywin
        extra_msg = ' - Some variables could not be loaded into the GUI' 
      endif else begin
        loaded = 1
      endelse

    endfor
  endif
    
  ; here's where the temporary tplot variables are removed
  if to_delete[0] ne '' then begin
     store_data,to_delete,/delete
  endif
  
  ; inform the user that the load was successful and add it to the history   
  if loaded eq 1 then begin   
     spd_ui_message, 'MMS Data Loaded Successfully'+extra_msg, sb=statusbar, hw=historywin
  endif else begin
     ; if the time range specified by the user is not within the time range 
     ; of available data for this mission and instrument then inform the user 
     ; The min max times are only valid for definitive data
     if level eq 'def' && time_double(mmsmaxtime) lt time_double(timerange[0]) || $
        time_double(mmsmintime) gt time_double(timerange[1]) then begin
        spd_ui_message, sb=statusbar, hw=historywin, $
           'No MMS Data Loaded, MMS ' + instrument + ' data is only available between ' + mmsmintime + ' and ' + mmsmaxtime
     endif else begin
        spd_ui_message, 'No MMS Data Loaded', sb=statusbar, hw=historywin
     endelse       
  endelse

end
