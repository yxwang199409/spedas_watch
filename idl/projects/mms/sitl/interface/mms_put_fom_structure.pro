pro mms_put_fom_structure, new_fomstr, old_fomstr, local_dir, error_flags, $
                           orange_warning_flags, yellow_warning_flags, $
                           error_msg, orange_warning_msg, yellow_warning_msg, $
                           error_times, orange_warning_times, yellow_warning_times, $
                           error_indices, orange_warning_indices, yellow_warning_indices, $
                           problem_status, warning_override = warning_override
                           
; Check the fom structure
mms_check_fom_structure, new_fomstr, old_fomstr, error_flags, orange_warning_flags, $
  yellow_warning_flags, error_msg, orange_warning_msg, yellow_warning_msg, $
  error_times, orange_warning_times, yellow_warning_times, $
  error_indices, orange_warning_indices, yellow_warning_indices          
                           
loc_errors = where(error_flags gt 0, count_errors)
loc_orange_warnings = where(orange_warning_flags gt 0, count_orange)
loc_yellow_warnings = where(yellow_warning_flags gt 0, count_yellow)


if (count_errors eq 0) then begin
  if ((count_yellow eq 0) and (count_orange eq 0)) or keyword_set(warning_override) then begin
     
    fomstr = new_fomstr
    ;savefile = local_dir + 'sitl_selections_' + current_date + '.sav'
    timestamps_temp = new_fomstr.timestamps
    str_element, new_fomstr, 'timestamps', /delete
    str_element, new_fomstr, 'timestamps', ulong(timestamps_temp), /add
    
    ;Get the time of sitl submission
    temptime = systime(/utc)
    mostr = strmid(temptime, 4, 3)
    monew = ''
    case mostr of
      'Jan': monew = '01'
      'Feb': monew = '02'
      'Mar': monew = '03'
      'Apr': monew = '04'
      'May': monew = '05'
      'Jun': monew = '06'
      'Jul': monew = '07'
      'Aug': monew = '08'
      'Sep': monew = '09'
      'Oct': monew = '10'
      'Nov': monew = '11'
      'Dec': monew = '12'
     endcase
  
    daystr = strmid(temptime, 8, 2)
    hrstr = strmid(temptime, 11, 2)
    minstr = strmid(temptime, 14, 2)
    secstr = strmid(temptime, 17, 2)
    yearstr = strmid(temptime, 20, 4)
    
    day_val = fix(daystr)
        
    if day_val lt 10 then begin
      daystr = '0'+string(day_val, format = '(I1)')
    endif else begin
      daystr = string(day_val, format = '(I2)')
    endelse
  
    savefile = local_dir + 'sitl_selections_' + yearstr + '-' + monew + $
               '-' + daystr + '-' + hrstr + '-' + minstr + '-' + secstr + '.sav'
  
    print, savefile
    
    save, fomstr, filename = savefile
    problem_status = 0
    
    sub_status = submit_mms_sitl_selections(savefile)
  endif else begin
    problem_status = 1
  endelse
endif else begin
  problem_status = 1
endelse

end 