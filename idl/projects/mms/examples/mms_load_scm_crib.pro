;+
; MMS SCM crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; Note:
; 1) Due to calibration processing L2 SCM data are set to 0 at the edges of each continous period of waveform
; 2) In srvy mode, onboard SCM calibration sequences have been removed from L2 SCM srvy data and appear as data gap    
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-02-29 12:21:35 -0800 (Mon, 29 Feb 2016) $
; $LastChangedRevision: 20262 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_scm_crib.pro $
;-

;;    ============================
;; 1) Select date and time interval
;;    ============================


date = '2016-01-16/00:00:00'

timespan,date,1,/day

;;    =====================
;; 2) Select probe and mode
;;    =====================

;; Select SATNAME ('1','2','3', or '4')
satname = '4'

;; Select data rate ('srvy' or 'burst')
scm_data_rate = 'brst';'srvy'

;; Select mode ('scsrvy' for survey data rate (both slow and fast have 32 S/s), 
;                'scb' (8192 S/s) or 'schb' (16384 S/s) for burst data rate)
scm_mode = 'scb';'scsrvy'

scm_name = 'mms'+satname+'_scm_acb_gse_'+scm_mode+'_'+scm_data_rate+'_l2'

;; To impose by hand t1 and t2 :
starting_date =strmid(date,0,10)
;scsrvy
;starting_time='00:00:00.0'
;ending_time  ='24:00:00.0'
;scb
starting_time='00:13:00.0'
ending_time  ='00:20:00.0'

trange = [starting_date+'/'+starting_time, $
    starting_date+'/'+ending_time]

mms_load_scm, trange=trange, probes=satname, level='l2', data_rate=scm_data_rate, datatype=scm_mode, tplotnames=tplotnames

options, scm_name, colors=[2, 4, 6]
options, scm_name, labels=['X', 'Y', 'Z']
options, scm_name, labflag=-1


window, 0, ysize=650
tplot_options, 'xmargin', [15, 15]
tplot_options,title= 'MMS'+satname+' '+ scm_data_rate+' period, '+scm_mode +' SCM data in GSE frame'

; plot the SCM data
tplot, scm_name
tlimit,trange

;; zoom into a time in the afternoon
;;tlimit, ['2015-08-02/16:00', '2015-08-02/18:00']

; calculate the dynamic power spectra without overlapping nshiftpoints=nboxpoints
if scm_mode eq 'scb' then nboxpoints_input = 8192 else nboxpoints_input = 512

tdpwrspc, scm_name, nboxpoints=nboxpoints_input,nshiftpoints=nboxpoints_input,bin=1

if scm_mode eq 'scsrvy' then Fmin = 0.5
if scm_mode eq 'scsrvy' then Fmax = 16.
if scm_mode eq 'scb'    then Fmin = 1.
if scm_mode eq 'scb'    then Fmax = 4096.
if scm_mode eq 'schb'   then Fmin = 32.
if scm_mode eq 'schb'   then Fmax = 8192.

options, scm_name+'_?_dpwrspc', 'ytitle', 'MMS'+satname+' '+scm_mode
options, scm_name+'_x_dpwrspc', 'ysubtitle', 'dynamic power!CX!C[Hz]'
options, scm_name+'_y_dpwrspc', 'ysubtitle', 'dynamic power!CY!C[Hz]'
options, scm_name+'_z_dpwrspc', 'ysubtitle', 'dynamic power!CZ!C[Hz]'
options, scm_name+'_?_dpwrspc', 'ztitle', '[nT!U2!N/Hz]

ylim, scm_name+'_?_dpwrspc',Fmin,Fmax,1
 
tplot, [scm_name, scm_name+'_?_dpwrspc']

end