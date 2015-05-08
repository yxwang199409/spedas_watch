

;This routine will replace coordinate plot labels only in the dlimits,
;If the coordinate name is clearly delineated, so that it will not accidentally modify substrings that look like coordinate names  
pro spd_cotrans_update_dlimits,out_name,in_coord,out_coord

  get_data, out_name, dlimit = dl
  
  if ~is_struct(dl) then return
  
  if in_set(strlowcase(tag_names(dl)),'ytitle') then begin
    type1 = stregex(dl.ytitle,'[^a-zA-Z]'+in_coord+'[^a-zA-Z]',/fold_case)
    type2 = stregex(dl.ytitle,'^'+in_coord+'[^a-zA-Z]',/fold_case)
    type3 = stregex(dl.ytitle,'[^a-zA-Z]'+in_coord+'$',/fold_case)
    type4 = stregex(dl.ytitle,'^'+in_coord+'$',/fold_case)
    if type1 ne -1 then begin
      dl.ytitle = strmid(dl.ytitle,0,type1+1) + out_coord + strmid(dl.ytitle,type1+strlen(in_coord)+1,strlen(dl.ytitle)-(type1+strlen(in_coord)+1))
    endif else if type2 ne -1 then begin
      dl.ytitle = out_coord + strmid(dl.ytitle,strlen(in_coord),strlen(dl.ytitle)-strlen(in_coord))
    endif else if type3 ne -1 then begin
      dl.ytitle = strmid(dl.ytitle,0,type3+1) + out_coord
    endif else if type4 ne -1 then begin
      dl.ytitle = out_coord
    endif else begin
      return
    endelse
    store_data,out_name,dlimit=dl
  endif

  if in_set(strlowcase(tag_names(dl)),'ysubtitle') then begin
    type1 = stregex(dl.ysubtitle,'[^a-zA-Z]'+in_coord+'[^a-zA-Z]',/fold_case)
    type2 = stregex(dl.ysubtitle,'^'+in_coord+'[^a-zA-Z]',/fold_case)
    type3 = stregex(dl.ysubtitle,'[^a-zA-Z]'+in_coord+'$',/fold_case)
    type4 = stregex(dl.ysubtitle,'^'+in_coord+'$',/fold_case)
    if type1 ne -1 then begin
      dl.ysubtitle = strmid(dl.ysubtitle,0,type1+1) + out_coord + strmid(dl.ysubtitle,type1+strlen(in_coord)+1,strlen(dl.ysubtitle)-(type1+strlen(in_coord)+1))
    endif else if type2 ne -1 then begin
      dl.ysubtitle = out_coord + strmid(dl.ysubtitle,strlen(in_coord),strlen(dl.ysubtitle)-strlen(in_coord))
    endif else if type3 ne -1 then begin
      dl.ysubtitle = strmid(dl.ysubtitle,0,type3+1) + out_coord
    endif else if type4 ne -1 then begin
      dl.ysubtitle = out_coord
    endif else begin
      return
    endelse
    store_data,out_name,dlimit=dl
  endif

  if in_set(strlowcase(tag_names(dl)),'labels') then begin
    nl = n_elements(dl.labels)
    for k = 0, nl-1 do begin
      type1 = stregex(dl.labels[k], '[^a-zA-Z]'+in_coord+'[^a-zA-Z]', /fold_case)
      type2 = stregex(dl.labels[k], '^'+in_coord+'[^a-zA-Z]', /fold_case)
      type3 = stregex(dl.labels[k], '[^a-zA-Z]'+in_coord+'$', /fold_case)
      type4 = stregex(dl.labels[k], '^'+in_coord+'$', /fold_case)
      if type1 ne -1 then begin
        dl.labels[k] = strmid(dl.labels[k], 0, type1+1) + out_coord + strmid(dl.labels[k], type1+strlen(in_coord)+1, strlen(dl.labels[k])-(type1+strlen(in_coord)+1))
      endif else if type2 ne -1 then begin
        dl.labels[k] = out_coord + strmid(dl.labels[k], strlen(in_coord), strlen(dl.labels[k])-strlen(in_coord))
      endif else if type3 ne -1 then begin
        dl.labels[k] = strmid(dl.labels[k], 0, type3+1) + out_coord
      endif else if type4 ne -1 then begin
        dl.labels[k] = out_coord
      endif else begin
        return
      endelse
      store_data, out_name, dlimit = dl
    endfor
  endif

end

;This routine will replace coordinate plot labels only in the limits,
;If the coordinate name is clearly delineated, so that it will not accidentally modify substrings that look like coordinate names  
pro spd_cotrans_update_limits,out_name,in_coord,out_coord

  get_data, out_name, limit = al
  
  if ~is_struct(al) then return
  
  if in_set(strlowcase(tag_names(al)),'labels') then begin
    nl = n_elements(al.labels)
    for k = 0, nl-1 do begin
      type1 = stregex(al.labels[k], '[^a-zA-Z]'+in_coord+'[^a-zA-Z]', /fold_case)
      type2 = stregex(al.labels[k], '^'+in_coord+'[^a-zA-Z]', /fold_case)
      type3 = stregex(al.labels[k], '[^a-zA-Z]'+in_coord+'$', /fold_case)
      type4 = stregex(al.labels[k], '^'+in_coord+'$', /fold_case)
      if type1 ne -1 then begin
        al.labels[k] = strmid(al.labels[k], 0, type1+1) + out_coord + strmid(al.labels[k], type1+strlen(in_coord)+1, strlen(al.labels[k])-(type1+strlen(in_coord)+1))
      endif else if type2 ne -1 then begin
        al.labels[k] = out_coord + strmid(al.labels[k], strlen(in_coord), strlen(al.labels[k])-strlen(in_coord))
      endif else if type3 ne -1 then begin
        al.labels[k] = strmid(al.labels[k], 0, type3+1) + out_coord
      endif else if type4 ne -1 then begin
        al.labels[k] = out_coord
      endif else begin
        return
      endelse
      store_data, out_name, limit = al
    endfor
  endif

end

; if the data is of type 'vel' this is an invalid coordinate transform, warn user
pro spd_cotrans_check_valid_transform, in_name, in_coord, out_coord
    get_data, in_name, dlimit = dl
    if is_struct(dl) && in_set(strlowcase(tag_names(dl)),'data_att') && $
        in_set(strlowcase(tag_names(dl.data_att)),'st_type') && $ 
        strlowcase(dl.data_att.st_type) eq 'vel' then begin
        dprint, 'Warning: Transforming '+in_name+' from '+strupcase(in_coord)+' to '+strupcase(out_coord)+' coordinates can produce invalid results'
    endif
end


;+
;Purpose:
;  Helps simplify transformation logic code using a recursive formulation.
;  Rather than specifying the set of transformations for each combination of
;  in_coord & out_coord, this routine will perform only the nearest transformation
;  then make a recursive call to itself, with each call performing one additional
;  step in the chain.  This makes it so only neighboring coordinate transforms need be
;  specified.
;
;The set of transformations forms the following graph:
;  GSE<->GEI<->GEO<->MAG
;  GSE<->GSM<->SM
;
;-
pro spd_cotrans_transform_helper,in_name,out_name,in_coord,out_coord, $
                      ignore_dlimits=ignore_dlimits
                      
  compile_opt hidden

  ;case select below modified to increase simplicity and maintainability.
  ;#1 Identity transform separated.
  ;#2 Recursive calls to spd_cotrans prevents duplicated code. 
  if in_coord eq out_coord then begin
    if in_name ne out_name then copy_data,in_name,out_name 
  endif else begin
    case in_coord of

      'gse': switch out_coord of
        'sm':
        'gsm': begin
          cotrans, in_name, out_name, /gse2gsm,ignore_dlimits=ignore_dlimits
          recursive_in_coord='gsm'
          break
        end
        'agsm': begin
          ; using a rotation angle of 4 degrees when transforming to aGSM coordinates in the GUI
          gse2agsm, in_name, out_name, rotation_angle = 4.0
          recursive_in_coord='agsm'
          break
        end
        else: begin
          ; if the data is of type 'vel' this is an invalid coordinate transform, warn user
          spd_cotrans_check_valid_transform, in_name, in_coord, out_coord
          cotrans, in_name,out_name,/gse2gei, ignore_dlimits=ignore_dlimits
          recursive_in_coord='gei'
        end
      endswitch
      'agsm': begin
        agsm2gse, in_name, out_name, rotation_angle = 4.0
        recursive_in_coord='gse'
        break
      end
      'sm': begin
         cotrans, in_name,out_name,/sm2gsm, ignore_dlimits=ignore_dlimits
         recursive_in_coord='gsm'
      end
      'gsm': switch out_coord of
        'sm': begin
          cotrans, in_name,out_name,/gsm2sm, ignore_dlimits=ignore_dlimits
          recursive_in_coord='sm'
          break
        end
        else: begin
          cotrans, in_name,out_name,/gsm2gse, ignore_dlimits=ignore_dlimits
          recursive_in_coord='gse'
        end
      endswitch
      'gei': switch out_coord of
        'geo': begin
          ; if the data is of type 'vel' this is an invalid coordinate transform, warn user
          spd_cotrans_check_valid_transform, in_name, in_coord, out_coord
          cotrans,in_name,out_name,/gei2geo,ignore_dlimits=ignore_dlimits
          recursive_in_coord='geo'
          break
        end
        'mag': begin
          ; if the data is of type 'vel' this is an invalid coordinate transform, warn user
          spd_cotrans_check_valid_transform, in_name, in_coord, out_coord
          cotrans,in_name,out_name,/gei2geo,ignore_dlimits=ignore_dlimits
          recursive_in_coord='geo'
          break
        end
        else: begin
          ; if the data is of type 'vel' this is an invalid coordinate transform, warn user
          spd_cotrans_check_valid_transform, in_name, in_coord, out_coord
          cotrans,in_name,out_name,/gei2gse,ignore_dlimits=ignore_dlimits
          recursive_in_coord='gse'
        end
      endswitch
      'geo': switch out_coord of
        'mag': begin
          ;geo2mag,in_name,out_name
          cotrans,in_name,out_name,/geo2mag,ignore_dlimits=ignore_dlimits
          recursive_in_coord='mag'            
          break
        end
        else: begin
          ; if the data is of type 'vel' this is an invalid coordinate transform, warn user
          spd_cotrans_check_valid_transform, in_name, in_coord, out_coord
          cotrans,in_name,out_name,/geo2gei,ignore_dlimits=ignore_dlimits
          recursive_in_coord='gei'
          break
        end
      endswitch 
      'mag': begin
          cotrans,in_name,out_name,/mag2geo,ignore_dlimits=ignore_dlimits
          ;mag2geo,in_name,out_name
          recursive_in_coord='geo'
      end
      else: begin
        dprint,"spd_cotrans: does not know how to transform "+in_coord+" to " + out_coord
        recursive_in_coord=out_coord
      end
    endcase
    spd_cotrans_transform_helper,out_name,out_name,recursive_in_coord,out_coord, $
                      ignore_dlimits=ignore_dlimits 
  endelse          
                      
end




;+
;Procedure:
;  spd_cotrans
;
;Purpose:
;  Transform between various THEMIS and geophysical coordinate systems
;
;Calling Sequence:
;  spd_cotrans, input_name [,output_name] 
;
;Arguments:
; input_name: String or string array of input tplot variable(s).  Standard tplot
;             wildcards may be used to specify multiple variables.
; output_name (optional) String or string array of output tplot variable names.
;             Number of output names must match number of input names once 
;             wildcards are considered.
;
;Keywords:
;  in_coord:  String specifying the coordinate system of the input(s).
;             This keyword is optional if the dlimits.data_att.coord_sys attribute
;             is present for the tplot variable, and if present, it must match
;             the value of that attribute (see cotrans_set_coord, cotrans_get_coord).
;               e.g. 'gse', 'gsm', 'sm', 'gei','geo', 'mag'
;  out_coord:  String specifying the desitnation coordinate system.
;                e.g. 'gse', 'gsm', 'sm', 'gei','geo', 'mag' 
;  in_suffix:  Suffix of input variable name.  This specifies the portion of
;              the input variable's name that will be replace with the output
;              suffix.  If specified, the name effective input name will be
;              input_name + in_suffix
;  out_suffix:  Suffix appended to the output name.  If in_suffix is present or
;               the input coordinates are part of the input variable's name then
;               they will be replaced with out_suffix.
;           
;  out_vars: return a list of the names of any transformed variables
;
;  valid_names:  return valid coordinate system names in named varibles supplied to
;                in_coord and/or out_coord keywords.
;  ignore_dlimits: set this keyword to true so that an error will not
;                  be produced if the internal label of the coordinate system clashed
;                  with the user provided coordinate system.
;  no_update_labels: Set this keyword if you want the routine to not update the labels automatically
;
;Notes:
;  This procedure was forked from thm_cotrans.
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-05-01 10:37:34 -0700 (Fri, 01 May 2015) $
;$LastChangedRevision: 17466 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/utilities/cotrans/spd_cotrans.pro $
;
;-
pro spd_cotrans, input_name, output_name, $

                 in_coord=in_coord, $
                 out_coord=out_coord, $

                 in_suffix=in_suf, $
                 out_suffix=out_suf, $

                 out_vars=out_vars, $

                 valid_names=valid_names, $
                 ignore_dlimits=ignore_dlimits,$
                 verbose=verbose, $
                 no_update_labels=no_update_labels


compile_opt idl2, hidden


;if verbose keyword is defined, override !themis.verbose
;vb = size(verbose, /type) ne 0 ? verbose : !spedas.verbose
vb = size(verbose, /type) ne 0 ? verbose : !themis.verbose

;get valid coordinates
coordSysObj = obj_new('spd_ui_coordinate_systems')
vcoord = coordSysObj->makeCoordSysList()
obj_destroy, coordSysObj

;print usage if requested (vestigial)
if keyword_set(valid_names) then begin
  in_coord = vcoord
  out_coord = vcoord
  if keyword_set(vb) then begin
    dprint, dlevel=0, string(strjoin(vcoord, ','), format = '( "Valid coords:",X,A,".")')
  endif
  return
endif


;Validate in_coord and out_coord
;--------------------------------
if not keyword_set(out_coord) and keyword_set(out_suf) then begin
  out_coord=strmid(out_suf,2,3,/reverse)
  if stregex(out_coord,'sm',/boolean) && ~stregex(out_coord,'gsm',/boolean) then begin
    out_coord = 'sm'
  endif
endif
 
if not keyword_set(out_coord) then begin
  dprint, dlevel=1, 'Must specify out_coord or out_suffix'
  return
endif else begin
  out_coord = ssl_check_valid_name(strlowcase(out_coord), vcoord)
endelse

if not keyword_set(out_coord) then return

if n_elements(out_coord) gt 1 then begin
  dprint, dlevel=1, 'Can only specify one out_coord'
  return
endif

if ~keyword_set(in_coord) && keyword_set(in_suf) then begin 
  in_coord=strmid(in_suf,2,3,/reverse)
  if stregex(in_coord,'sm',/boolean) && ~stregex(in_coord,'gsm',/boolean) then begin
    in_coord = 'sm'
  endif
endif

if keyword_set(in_coord) then begin
  in_coord = ssl_check_valid_name(strlowcase(in_coord), vcoord)
  if not keyword_set(in_coord) then return
  if n_elements(in_coord) gt 1 then begin
    dprint, dlevel=1, 'Can only specify one in_coord'
    return
  endif
endif


;Validate names
;--------------------------------
if not keyword_set(in_suf) then in_suf = ''
if not keyword_set(out_suf) then out_suf = ''

; allow for globbing on the input parameters
in_names = tnames(input_name+in_suf, n)
if n eq 0 then begin
  dprint, dlevel=1, 'No match: '+input_name+in_suf
  return
endif

;generate output names if not provided
if n_params() eq 1 || n_elements(in_names) ne n_elements(output_name) then begin
  if n_params() eq 2 then dprint, dlevel=1, 'WARNING: Ignoring out_names'
  base_len = in_suf ne '' ? strpos(in_names,in_suf,/reverse_search):strlen(in_names) 
  out_names = in_names
  for j = 0, n-1 do begin
    out_names[j] = strmid(in_names[j],0,base_len[j])+out_suf
  endfor
endif else begin
  out_names = output_name + out_suf
endelse

;throw error because it's probably the program's fault?
if n_elements(in_names) ne n_elements(out_names) then begin
  message, 'SPD_COTRANS: number of input variables does not match number of output variables'
endif


;Resolve discrepancies between in_coord keyword, and data_att.coord_sys
;--------------------------------
in_coords = strarr(n_elements(in_names))
for i = 0,n_elements(in_names)-1 do begin

  data_in_coord = cotrans_get_coord(in_names[i])
  
  if ~keyword_set(in_coord) || strmatch(in_coord, 'unknown') then begin
    in_coords[i] = data_in_coord
  endif else if strmatch(data_in_coord,'unknown') then begin
    in_coords[i] = in_coord
  endif else if data_in_coord ne in_coord then begin
    in_coords[i] = 'conflict'
  endif else begin
    in_coords[i] = in_coord
  endelse

endfor


;Loop over input variables
;--------------------------------
for i = 0, n_elements(in_names)-1 do begin
  
  in_nam = in_names[i]
  out_nam = out_names[i]

  ;check that data is present
  get_data, in_nam, data=in, dl=in_dl
  if size(in, /type) ne 8 then begin
    dprint, dlevel=1, 'Input tplot variable '+in_nam+' has no data'
    continue
  endif

  ;check that data is a 3-vector
  sizein=size(in.y)
  if sizein[0] ne 2 or sizein[2] ne 3 then begin
    dprint, dlevel=1, 'Input tplot variable '+in_nam+' is not a 3-vector. Skipping'
    continue
  endif

  in_c = in_coords[i]

  ;verify input coordinates match variable's metadata
  if in_c eq 'conflict' then begin
    dprint, dlevel=1, 'Argument input coordinate system and data coordinate system of "' + in_nam + '" do not match. Skipping.'
    continue
  endif else if in_c eq 'unknown' then begin
    dprint, dlevel=1, 'Tplot variable "' + in_nam + '" has unknown input coordinate system. Skipping'
    continue
  endif

  dprint, dlevel=2, 'Transforming '+in_nam+' ('+in_c+') to '+out_coord
  
  ;perform the transformation
  ;--------------------------------
  spd_cotrans_transform_helper,in_nam,out_nam,in_c,out_coord, $
                      ignore_dlimits=ignore_dlimits   
  
  ;aggregate transformed variables
  name_list = array_concat(out_nam,name_list)

  ;update labels in limits and dlimits structures  
  if ~keyword_set(no_update_labels) then begin
    spd_cotrans_update_dlimits,out_nam,in_c,out_coord
    spd_cotrans_update_limits,out_nam,in_c,out_coord
  endif

endfor

if arg_present(out_vars) && n_elements(name_list) gt 0 then begin
  out_vars = name_list
endif

end