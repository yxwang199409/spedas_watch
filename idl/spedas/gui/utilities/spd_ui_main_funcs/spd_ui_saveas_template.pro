;+
;
;  Name: SPD_UI_SAVEAS_TEMPLATE
;  
;  Purpose: SAVES a spedas template with a new file name
;  
;  Inputs: The info structure from the main gui
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/utilities/spd_ui_main_funcs/spd_ui_saveas_template.pro $
;-

pro spd_ui_saveas_template,info

  if info.marking ne 0 || info.rubberbanding ne 0 then begin
    return
  endif
  
  info.ctrl = 0

  filestring=info.template_filename
  IF NOT Is_String(filestring) then begin
     xt = Time_String(systime(/sec))
     timeString = Strmid(xt, 0, 4)+Strmid(xt, 5, 2)+Strmid(xt, 8, 2)+$
       '_'+Strmid(xt,11,2)+Strmid(xt,14,2)+Strmid(xt,17,2)
     filestring = 'spedas_template_'+timeString+'.tgt'
  ENDIF
  
  path = file_dirname(filestring)
  
  ;fileName = dialog_pickfile(Title='Save As:', $
  ;     Filter='*.tgt', File = fileString,path=path, /Write, Dialog_Parent=info.master)
  fileName = spd_ui_dialog_pickfile_save_wrapper(Title='Save As:', $
       Filter='*.tgt', File = fileString,path=path, /Write, Dialog_Parent=info.master)
  IF(Is_String(fileName)) THEN BEGIN
     save_spedas_template,template=info.template_object,filename=fileName,$
         statusmsg=statusmsg,statuscode=statuscode
     IF (statuscode LT 0) THEN BEGIN
       ; statuscode -6 means "operation cancelled by user", no
       ; need to pop up another dialog
       IF (statuscode NE -6) THEN dummy=dialog_message(statusmsg,/ERROR,/CENTER, title='Error in GUI')
     ENDIF ELSE BEGIN
       info.template_filename=filename
     ENDELSE
     info.statusBar->Update, statusmsg
     info.historywin->Update,statusmsg
  ENDIF ELSE BEGIN
    info.statusBar->Update, 'Operation Cancelled'
  ENDELSE

end
