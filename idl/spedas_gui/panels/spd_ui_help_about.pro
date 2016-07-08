;+
;
;NAME:
; spd_ui_help_about
;
;PURPOSE:
; A widget to display About information (SPEDAS Version)
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2016-07-07 14:52:57 -0700 (Thu, 07 Jul 2016) $
;$LastChangedRevision: 21436 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/panels/spd_ui_help_about.pro $
;-


Pro spd_ui_help_about_event, ev
    plugin_mission = ''
    widget_control, ev.id, get_uvalue=uval
  
  ; check if this event was generated by a button on the about plugins menu
  uval_arr = strsplit(uval, ':', /extract)
  uval = uval_arr[0]
  if n_elements(uval_arr) eq 3 then begin
    plugin_mission = uval_arr[1]
    plugin_about_file = uval_arr[2]
  endif

  case uval of
    'ABOUT': begin
        GETRESOURCEPATH, path ; start at the resources folder
        plugin_about_path = path+ PATH_SEP() + PATH_SEP(/PARENT_DIRECTORY)+ PATH_SEP() + PATH_SEP(/PARENT_DIRECTORY) + PATH_SEP() +  'projects'+ PATH_SEP() + strlowcase(plugin_mission) +PATH_SEP() 
        if ~file_test(plugin_about_path, /directory) then plugin_about_path = path + PATH_SEP() + 'terms_of_use' + PATH_SEP()
        xdisplayfile, plugin_about_path + strlowcase(plugin_about_file), done_button='CLOSE', height=50, /modal, title='About ' + plugin_mission
    end    
    'SPEDASWEB' : begin
      spd_ui_open_url, 'http://spedas.org/'
    end
    'QUIT' : begin
      widget_control, ev.top, /destroy
    end
  endcase

end

Pro spd_ui_help_about, gui_id, historywin
  ;aboutlabel should show the SPEDAS version and some other info (perhaps build date, web site URL, etc)
  aboutString= ' SPEDAS 2.00 beta 1 '  +  string(10B) + string(10B) $
    + ' Space Physics Environment Data Analysis Software ' $
    + string(10B) + string(10B) + ' May 2016 ' + string(10B) $
    + string(10B) + string(10B) + string(10B) $
    + ' For support or bug reports, contact: THEMIS_Science_Support@ssl.berkeley.edu '

  aboutBase = widget_base(/col, title = 'About', /modal, Group_Leader=gui_id)
  aboutLabel = widget_label(aboutBase, value=aboutString, /align_center, XSIZE=500, YSIZE=150, UNITS=0)
  spedasButton = widget_button(aboutBase, value = ' Go to http://spedas.org/ ', uvalue= 'SPEDASWEB', /align_center, scr_xsize = 300)
  aboutPluginButtons = widget_button(aboutBase, value='About SPEDAS Plugins...', uvalue='ABOUTPLUGINS', /align_center, scr_xsize=300, /menu)
  
  widget_control, gui_id, get_uvalue=info
  about_plugins = info.pluginManager->getAboutPlugins()

  if is_struct(about_plugins) then begin
    ; add the items to the about plugins menu
      about_plugins_menu = lonarr(n_elements(about_plugins))
      for i=0, n_elements(about_plugins)-1 do $
          about_plugins_menu[i] = widget_button(aboutPluginButtons, $
            value=about_plugins[i].mission_name, uvalue='ABOUT:' $
            +about_plugins[i].mission_name+':'+about_plugins[i].text_file)
  endif else begin
    ; disable if there weren't any plugins loaded
    widget_control, aboutPluginButtons, sensitive = 0
  endelse
  
  aboutLabel = widget_label(aboutBase, value=' ', /align_center, XSIZE=500, YSIZE=20, UNITS=0)
  exitButton = widget_button(aboutBase, value = ' Close ', uvalue= 'QUIT', /align_center, scr_xsize = 150)

  widget_control, aboutBase, /realize
  xmanager, 'spd_ui_help_about', aboutBase, /no_block
end
