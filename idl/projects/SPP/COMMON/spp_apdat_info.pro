



pro spp_apdat_info,apids,name=name,verbose=verbose,$
                  clear=clear,$
                  reset=reset,$
                  apdats = apdats, $
                  save_flag=save_flag,$
                  nonzero=nonzero,  $
                  all = all, $
                  finish=finish,$
                  tname=tname,$
                  save_tags=save_tags,$
                  rt_tags=rt_tags,$
                  routine=routine,$
                  apid_obj_name = apid_obj_name, $
                  print=print, $
                  rt_flag=rt_flag

  common spp_apdat_info_com, all_apdat, misc1

  if keyword_set(reset) then begin   ; not recommended!
    obj_free,all_apdat    ; this might not be required in IDL8.x and above
    all_apdat=!null
    return
  endif

  if ~keyword_set(all_apdat) then all_apdat = replicate( obj_new() , 2^11 )

  if n_elements(apids) eq 0 then apids = where(all_apdat,/null)
  
  default_apid_obj_name =  'spp_gen_apdat'

  for i=0,n_elements(apids)-1 do begin
    apid = apids[i]
    if ~obj_valid(all_apdat[apid])  || (isa(/string,apid_obj_name) && (typename(all_apdat[apid]) ne strupcase(apid_obj_name) ) )  then begin
      dprint,verbose=verbose,dlevel=3,'Initializing APID: ',apid        ; potential memory leak here - old version should be destroyed
      all_apdat[apid] = obj_new( isa(/string,apid_obj_name) ? apid_obj_name : default_apid_obj_name, apid)       
    endif
    apdat = all_apdat[apid]
    if n_elements(name)       ne 0 then apdat.name = name
    if n_elements(routine)    ne 0 then apdat.routine=routine
    if n_elements(rt_flag)    ne 0 then apdat.rt_flag = rt_flag
    if n_elements(rt_tags)    ne 0 then apdat.rt_tags = rt_tags
    if n_elements(tname)      ne 0 then apdat.tname = tname
    if n_elements(save_flag)  ne 0 then apdat.save_flag = save_flag
    if n_elements(save_tags)  ne 0 then apdat.save_tags = save_tags
    if ~keyword_set(all)  &&  (apdat.npkts eq 0) then continue
    if keyword_set(finish) then    apdat.finish
    if keyword_set(clear)  then    apdat.clear
    if keyword_set(print)  then    apdat.print
  endfor

  apdats=all_apdat[apids]
  
end

