;+
;NAME:
;rerun_sta_L2gen
;PURPOSE:
;Designed to run from a cronjob, after the original L2 processing,
;reprocesses, using the current L2 files as input.
;CALLING SEQUENCE:
; run_sta_l2gen, noffset_sec = noffset_sec
;INPUT:
; none
;OUTPUT:
; none
;KEYWORDS:
; none
;HISTORY:
; 20-oct-2014, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-07-22 18:41:07 -0700 (Fri, 22 Jul 2016) $
; $LastChangedRevision: 21517 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/l2util/rerun_sta_l2gen.pro $
;-

Pro rerun_sta_l2gen, ndays = ndays

  test_file = file_search('/tmp/STAL2Rlock.txt')
  If(is_string(test_file[0])) Then Begin
     message, /info, 'Lock file /tmp/STAL2Rlock.txt Exists, Returning'
  Endif Else Begin
     test_file = '/tmp/STAL2Rlock.txt'
     file_touch, test_file[0]
;by default, ndays is 7
     If(~keyword_set(ndays)) Then ndays = 7
;Subtract ndays from today
     tt = time_string(systime(/sec)-ndays*86400.0d0)
     days_in = time_string(tt, precision = -3)
     mvn_call_sta_l2gen, days_in = days_in;, /use_l2_files temporarily use L0, jmm, 2016-07-22
     message, /info, 'Removing Lock file /tmp/STAL2Rlock.txt'
     file_delete, test_file[0]
  Endelse

  Return

End

