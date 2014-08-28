;+ 
;NAME:
;
; spd_gui_init
;
;PURPOSE:
;the very beginnings of global configuration info
;for spd_gui
;
;CALLING SEQUENCE:
; spedas_gui_new_init
;
;INPUT:
; none
;
;OUTPUT:
; none
;
;HISTORY:
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/utilities/spd_gui_init.pro $
;-----------------------------------------------------------------------------------

pro spd_gui_init

  defsysv,'!SPD_GUI',exists=i
  if ~i then begin
    defsysv,'!SPD_GUI',{renderer:1B,$  ;OS specific rendering options should go here
                            guiId:0L,  $ ; the widget id of the main gui, needed as an input to command line.
                            drawObject:obj_new(),$ ;draw object, so that command line can interface with gui
                            windowStorage:obj_new(),$ ; window_storage object, so that command line can interface with gui
                            loadedData:obj_new(), $ ; loaded_data object, so that command line can interface with gui
                            windowMenus:obj_new(), $ ; the window menu object, so that the command line can update the gui window menu
                            historyWin:obj_new(), $ ; the history window object, so that we can log the tplot_gui
                            templatePath:'',$; add the the template path if user specifies one
                            oplot_calls:ptr_new(0) };kluge for spd_ui_overplot to prevent overwriting user data, uses an incrementing counter
                          
  endif

  out = thm_read_config()

  if is_struct(out) && in_set('renderer',strlowcase(tag_names(out))) then begin
    !spd_gui.renderer = long(out.renderer)
  endif
  if is_struct(out) && in_set('templatepath',strlowcase(tag_names(out))) then begin
    !spd_gui.templatePath = out.templatePath
  endif

end
