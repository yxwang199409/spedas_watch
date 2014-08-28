;+
;Procedure: tt01
;
;Purpose:  tplot wrapper for the functional interface to the idl
;geopack implementation of the Tsyganenko 2001 and IGRF fields model.
;
;Keywords: 
;          pos_gsm_tvar: the tplot variable storing the position in
;          gsm coordinates
;
;          pdyn(optional): Solar wind pressure(nanoPascals) should either be a
;          string naming a tplot variable or an array or a single
;          value. If a tplot input is used it will be interpolated to
;match the time inputs from the position var. Non-tplot array values
;must match the number of times in the tplot input for pos_gsm_tvar
;
;          dsti(optional): DST index(nanoTeslas)  should either be a
;          string naming a tplot variable or an array or a single
;          value.  If a tplot input is used it will be interpolated to
;match the time inputs from the position var. Non-tplot array values
;must match the number of times in the tplot input for pos_gsm_tvar
;
;         yimf(optional): y component of the interplanetary magnetic field
;         should either be a string naming a tplot variable or an
;         array or a single value.  If a tplot input is used it will
;be interpolated to match the time inputs from the position
;var. Non-tplot array values must match the number of times in the
;tplot input for pos_gsm_tvar
;
;         zimf(optional): z component of the interplanetary magnetic field
;          should either be a string naming a tplot variable or an
;          array or a single value.  If a tplot input is used it will
;be interpolated to match the time inputs from the position
;var. Non-tplot array values must match the number of times in the
;tplot input for pos_gsm_tvar
;
;         g1(optional):  index describes solar wind conditions in the
;         previous hour, should either be a string naming a tplot variable or an
;          array or a single value.   If a tplot input is used it will
;be interpolated to match the time inputs from the position
;var. Non-tplot array values must match the number of times in the
;tplot input for pos_gsm_tvar
;
;         g2(optional): index describes solar wind conditions in the
;         previous hour should either be a string naming a tplot variable or an
;          array or a single value.   If a tplot input is used it will
;be interpolated to match the time inputs from the position
;var. Non-tplot array values must match the number of times in the
;tplot input for pos_gsm_tvar
;
;         parmod(optional): can input the Nx10 parmod array used by the
;         fortran Tsyganenko model.If passed as a raw array it will not be
;         modified or interpolated so be sure its has the correct
;         number of entries. It can also be passed as a tplot variable
;         name in which case it will be interpolated. If values are 
;         passed individually and as par the par values will be overwritten.
;
;          period(optional): the amount of time between recalculations of
;             geodipole tilt in seconds(default: 60)  increase this
;             value to decrease run time
;
;          get_nperiod(optional): Return the number of periods used in the time interval
;
;          newname(optional):the name of the output variable. 
;          (default: pos_gsm_tvar+'_bt01') This option is ignored if
;          globbing is used.
;
;          error(optional): named variable in which to return the
;          error state of this procedure call. 1 = success, 0 = failure
;       
;          get_tilt(optional):  Set this value to a tplot variable name in which the geodipole tilt for each period will be returned
;                     One sample will be returned for each period with time at the center of the period.
;          
;          set_tilt(optional): Set this to a tplot variable name or an array of values containing the dipole tilt that should be used.
;                              If a tplot input is used it will be interpolated to match the time inputs from the position
;                              var. Non-tplot array values must match the number of times in the tplot input for pos_gsm_tvar
;
;          add_tilt(optional): Set this to a tplot variable name or an array of values containing the values to be added to the dipole tilt
;                              that should be used for each period. If a tplot input is used it will be interpolated to match the time inputs from the position
;                            
;          storm(optional): Set this to use the storm-time version of the T01 model
;                              
;
;
; Output: Stores the result of the field model calculations in tplot variables
;          
; Notes: 1, converts from normal gsm to rgsm by dividing vectors by earth's
; radius(6374 km) ie inputs should be in km
;        2. Input must be in GSM coordinates
;        3. Haje Korth's IDL/Geopack DLM must be installed for this
;        procedure to work
;        4. either the variables setting parmod or the variables
;        setting the individual parameter arrays should be set because
;        the defaults aren't scientifically accurate
;        5. model parameters that are input as tplot variables they
;        will be interpolated to match the time values on the input 
;        position
;        6.Find more documentation on the inner workings of the model,
;        any gotchas, and the meaning of the arguments at:
;        http://modelweb.gsfc.nasa.gov/magnetos/data-based/modeling.html
;        -or-
;        http://dysprosium.jhuapl.edu/idl_geopack/
;        7. Definition of G1 and G2 can be found at: 
;        http://modelweb.gsfc.nasa.gov/magnetos/data-based/Paper220.pdf
;        http://modelweb.gsfc.nasa.gov/magnetos/data-based/Paper219.pdf
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-01-15 15:09:40 -0800 (Wed, 15 Jan 2014) $
; $LastChangedRevision: 13909 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/t01/tt01.pro $
;-

;validates input parameters, in_val is the value passed to the main
;function, name string is a name used for error output,pos_name is the
;name of the position tplot variable
;returns -1L on failure

function tt01_valid_param, in_val, name_string, pos_name
  
  COMPILE_OPT HIDDEN, IDL2

  if n_elements(in_val) gt 0 then begin

    ;if in_val is a string, assume in_val is stored in a tplot variable
    if size(in_val, /type) eq 7 then begin
      if tnames(in_val) eq '' then begin
        message, /continue, name_string + ' is of type string but no tplot variable of that name exists'
        return, -1L
      endif
          
      ;make sure there are an appropriate number of pdyn values in the array
      tinterpol_mxn, in_val, pos_name,out=d_verify, error = e

      if e ne 0 then begin
        return, d_verify.y
      endif else begin
        message, /continue, 'error interpolating ' + name_string + ' onto position data'
        return, -1L
      endelse
      
    endif else return, in_val
  endif

  get_data, pos_name, data = d

  return, dblarr(n_elements(d.x))

end

pro tt01, pos_gsm_tvar, pdyn = pdyn,dsti = dsti, yimf = yimf, zimf = zimf,g1=g1,g2=g2, parmod=parmod,period = period,get_nperiod=get_nperiod, newname = newname, error = error,get_tilt=get_tilt,set_tilt=set_tilt,add_tilt=add_tilt, storm=storm

  error = 0

  if not keyword_set(pos_gsm_tvar) then begin
    message, /continue, 'pos_gsm_tvar must be set'
    return
  endif

  var_names = tnames(pos_gsm_tvar)

  if(var_names[0] eq '') then begin
    message, /continue, 'No valid tplot_variables match pos_gsm_tvar'
    return
  endif else if(n_elements(var_names) ne 1) then begin
    message, /continue, 'tt01 only accepts one position tplot variable as input'
    return
  end

  var_name = var_names[0];just in case

  
  if n_elements(parmod) gt 0 then begin

     if size(parmod,/type) eq 7 then begin
        
        if tnames(parmod) eq '' then message,'parmod variable not valid tplot variable'

        
        tinterpol_mxn,parmod,var_name,newname='par_out'

        get_data,'par_out',data=dat
        
        par_temp = dat.y

     endif else par_temp = parmod
     
     if n_elements(pdyn_dat) gt 0 then begin

        pdyn_dat = tt01_valid_param(pdyn, 'pdyn', var_name)

        if(size(pdyn_dat, /n_dim) eq 0 && pdyn_dat[0] eq -1L) then return

     endif else begin

        pdyn_dat = par_temp[*,0]

     endelse

     if n_elements(dsti_dat) gt 0 then begin
      
        dsti_dat = tt01_valid_param(dsti, 'dsti', var_name)
     
        if(size(dsti_dat, /n_dim) eq 0 && dsti_dat[0] eq -1L) then return

     endif else begin
  
        dsti_dat = par_temp[*,1]

     endelse

     if n_elements(yimf_dat) gt 0 then begin
        
        yimf_dat = tt01_valid_param(yimf, 'yimf', var_name)

        if(size(yimf_dat, /n_dim) eq 0 && yimf_dat[0] eq -1L) then return

     endif else begin
  
        yimf_dat = par_temp[*,2]

     endelse

     if n_elements(zimf_dat) gt 0 then begin
        
        zimf_dat = tt01_valid_param(zimf, 'zimf', var_name)

        if(size(zimf_dat, /n_dim) eq 0 && zimf_dat[0] eq -1L) then return

     endif else begin

        zimf_dat = par_temp[*,3]

     endelse

     if n_elements(g1_dat) gt 0 then begin
          
        g1_dat = tt01_valid_param(g1, 'g1', var_name)

        if(size(g1_dat, /n_dim) eq 0 && g1_dat[0] eq -1L) then return

     endif else begin
        
        g1_dat = par_temp[*,4]
       
     endelse

       
     if n_elements(g2_dat) gt 0 then begin 

        g2_dat = tt01_valid_param(g2, 'g2', var_name)

        if(size(g2_dat, /n_dim) eq 0 && g2_dat[0] eq -1L) then return

     endif else begin

        g2_dat = par_temp[*,5]

     endelse

  endif else begin
  
     pdyn_dat = tt01_valid_param(pdyn, 'pdyn', var_name)

     if(size(pdyn_dat, /n_dim) eq 0 && pdyn_dat[0] eq -1L) then return
    
     dsti_dat = tt01_valid_param(dsti, 'dsti', var_name)

     if(size(dsti_dat, /n_dim) eq 0 && dsti_dat[0] eq -1L) then return
  
     yimf_dat = tt01_valid_param(yimf, 'yimf', var_name)

     if(size(yimf_dat, /n_dim) eq 0 && yimf_dat[0] eq -1L) then return
  
     zimf_dat = tt01_valid_param(zimf, 'zimf', var_name)

     if(size(zimf_dat, /n_dim) eq 0 && zimf_dat[0] eq -1L) then return
  
     g1_dat = tt01_valid_param(g1, 'g1', var_name)

     if(size(g1_dat, /n_dim) eq 0 && g1_dat[0] eq -1L) then return
  
     g2_dat = tt01_valid_param(g2, 'g2', var_name)

     if(size(g2_dat, /n_dim) eq 0 && g2_dat[0] eq -1L) then return

  endelse

  get_data, var_name, data = d, dlimits = dl, limits = l

  ;several nested ifs to check this
  ;variable's coordinate system in a
  ;safe way(ie won't reference any struct elements that don't exist)
  if ~is_struct(dl) then begin
    message, /continue, 'dlimits structure not set, make sure input variables are in gsm coordinates or results will be invalid'
    endif else begin
   
   str_element, dl, 'data_att', success = s
   if s eq 0 then begin
      message, /continue, 'dlimits.data_att structure not set, make sure input variables are in gsm coordinates or results will be invalid'
   endif else begin
     str_element, dl.data_att, 'coord_sys', success = s
     if s eq 0 then begin
       message, /continue, 'dlimits.data_att.coord_sys value not set, make sure input variables are in gsm coordinates or results will be invalid'
     endif else if strlowcase(dl.data_att.coord_sys) ne 'gsm' then begin
       message, /continue, 'input variable is in the wrong coordinate system, returning'
       return                ;definitely wrong coordinate system=error
     endif
   endelse
 endelse
 
 if n_elements(add_tilt) gt 0 then begin
   add_tilt_dat = tt01_valid_param(add_tilt, 'add_tilt', var_name)
   if(size(add_tilt, /n_dim) eq 0 && add_tilt_dat[0] eq -1L) then return
 endif
 
 if n_elements(set_tilt) gt 0 then begin
   set_tilt_dat = tt01_valid_param(set_tilt, 'set_tilt', var_name)
   if(size(set_tilt, /n_dim) eq 0 && set_tilt_dat[0] eq -1L) then return
 endif

 ;do the calculation, division converts position into earth radii units
 
 ;various types for various tilt control options
 if n_elements(set_tilt) gt 0 then begin
   mag_array = t01(d.x, d.y/6374, pdyn_dat, dsti_dat, yimf_dat, zimf_dat,g1_dat,g2_dat, period = period,get_nperiod=get_nperiod,get_period_times=period_times_dat,get_tilt=tilt_dat,set_tilt=set_tilt_dat,storm=storm)
 endif else if n_elements(add_tilt) gt 0 then begin
   mag_array = t01(d.x, d.y/6374, pdyn_dat, dsti_dat, yimf_dat, zimf_dat,g1_dat,g2_dat, period = period,get_nperiod=get_nperiod,get_period_times=period_times_dat,get_tilt=tilt_dat,add_tilt=add_tilt_dat,storm=storm)
 endif else begin
   mag_array = t01(d.x, d.y/6374, pdyn_dat, dsti_dat, yimf_dat, zimf_dat,g1_dat,g2_dat, period = period,get_nperiod=get_nperiod,get_period_times=period_times_dat,get_tilt=tilt_dat,storm=storm)
 endelse
 
 if size(mag_array, /n_dim) eq 0 && mag_array[0] eq -1L then begin
   message, /continue, 'Tysganenko model query failed, returning'
   return
 endif

 if is_string(get_tilt) then begin
   store_data,get_tilt,data={x:period_times_dat,y:tilt_dat}
 endif

  ;sometimes v element is present, sometimes not 
  ;if it is around it is stored in output so information is not lost 
  str_element, d, 'v', success = s

  if s eq 1 then $
    d_out = {x:d.x, y:mag_array, v:d.v} $
  else $
    d_out = {x:d.x, y:mag_array}

  if keyword_set(newname) then $
    store_data, newname, data = d_out, dlimits = dl, limits = l $
  else $
    store_data, var_name +'_bt01', data = d_out, dlimits = dl, limits = l

  ;signal success
  error = 1 

  return

end
