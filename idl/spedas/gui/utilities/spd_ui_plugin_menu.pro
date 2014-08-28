;+
;Procedure:
;  spd_ui_plugin_menu
;
;
;Purpose:
;  Searches for and adds plugin items to the GUI plugin menu.
;
;
;Calling Sequence:
;  spd_ui_plugin_menu, menu_id
;
;
;Input:
;  menu_id: Widget ID of the parent menu into which plugin buttons will be placed.
;
;
;Output:
;
;
;Notes:
;
;  In Development...
;
;
;
;$LastChangedBy:  $
;$LastChangedDate:  $
;$LastChangedRevision:  $
;$URL:  $
;
;-

pro spd_ui_plugin_menu, menu_id

    compile_opt idl2, hidden


;  ;error catch block in case of incorrect setup
;  ;todo: this should be removed or updated when development is complete
;  err=0
;  catch, err
;  if err ne 0 then begin
;    catch, /cancel
;    help, /last_message ;, output=err_msg
;    ok = error_message('An unknown error occured while populating the Plugins menu.', $
;                       /noname, /center, title='Plugin Menu Error')
;    return
;  endif
  

  ;template for reading config file
  ascii_temp = { VERSION: 1.0, $
                 DATASTART: 0, $
                 DELIMITER: 44b, $
                 MISSINGVALUE: '', $
                 COMMENTSYMBOL: ";", $
                 FIELDCOUNT: 3, $
                 FIELDTYPES: [7, 7, 7], $
                 FIELDNAMES: ['item', 'location', 'procedure'], $
                 FIELDLOCATIONS: [0, 10, 27], $
                 FIELDGROUPS: [0, 1, 2] $
                 }

  ;----------------------------------------------------
  ; Read config file into struct
  ;----------------------------------------------------
  
  getresourcepath, configPath
  
  plugins = read_ascii(configPath+'spd_ui_plugin_config.txt', template=ascii_temp, count=nitems)
  
  if nitems lt 1 then begin
    dummy = widget_button(menu_id, value='None', sens=0)
;    dprint, dlevel=2, 'No plugins found in config file.'
    return
  endif
  
  
  ;----------------------------------------------------
  ; Loop over plugins
  ;----------------------------------------------------

  for i=0, nitems-1 do begin
    
    name = strtrim(plugins.item[i],2)
    location = strtrim(strsplit(plugins.location[i], '|', /extract),2)
    procedure = strlowcase( strtrim(plugins.procedure[i],2) )
    
    ;warn user?
    if name eq '' then continue
    if procedure eq '' then continue

    ;create struct to store plugin name and data
    plugin = { name: name, $
               procedure: procedure, $
               data: ptr_new() $
               }

    ;----------------------------------------------------
    ; Loop over menu structure
    ;----------------------------------------------------
    
    node = menu_id
    
    for j=0, n_elements(location)-1 do begin
      
      ;ignore blank entries
      if location[j] eq '' then continue
      
      ;get children of current menu node
      children = widget_info(node, /all_children)

      ;if children exist then see if sub-node also exists
      if children[0] ne 0 then begin
        
        ;check unames
        unames = widget_info(children, /uname)
  
        idx = where(unames eq location[j], nidx)
        
        ;if match is found then select it and continue
        if nidx eq 1 then begin
          node = children[idx]
          continue
        endif
        
      endif
      
      ;if no matching child is found then create a new menu node
      new_node = widget_button(node, value=location[j], uname=location[j], /menu)
      
      ;select new node and continue
      node = new_node
      
    endfor
    
    ;----------------------------------------------------
    ; Add button to the current node
    ;----------------------------------------------------
    button = widget_button(node, value=name, uval=plugin, uname='GUI_PLUGIN')
    
  endfor
  
  if ~widget_valid(button) then begin
    dummy = widget_button(menu_id, value='None', sens=0)
    dprint, dlevel=2, 'GUI plugins not configured correctly.'
    return
  endif

end
