;+
; PROCEDURE:
;         mms_load_fgm_crib
;         
; PURPOSE:
;         Crib sheet showing how to load and plot MMS FGM data
; 
;   
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-05-03 08:52:33 -0700 (Tue, 03 May 2016) $
; $LastChangedRevision: 21000 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/basic/mms_load_fgm_crib.pro $
;-

; load MMS FGM data for MMS 1 and MMS 2
mms_load_fgm, probes=[1, 2], trange=['2016-01-20', '2016-01-21']

; set the left and right margins for the plots
tplot_options, 'xmargin', [15,10]

; plot the data in GSM coordinates for MMS-2
tplot, 'mms2_fgm_b_gsm_srvy_l2_bvec'

; plot dashed line at zero
timebar, 0.0, /databar, varname='mms2_fgm_b_gsm_srvy_l2_bvec', linestyle=2
stop

; zoom in
tlimit, '2016-01-20/03:00', '2016-01-20/04:00'
stop

; list all the variables loaded into tplot variables
tplot_names

; load the FGM data, along with the ephemeris data stored in the FGM files
mms_load_fgm, probes=3, trange=['2016-01-20', '2016-01-21'], /get_fgm_ephemeris

; plot the FGM data, along with position in GSM coordinates
tplot, ['mms3_fgm_b_gsm_srvy_l2_bvec', 'mms3_fgm_r_gsm_srvy_l2_vec']
stop

; delete the data from previous loads
del_data, '*'

; load the FGM data without splitting the variables
mms_load_fgm, probe=1, trange=['2016-01-20', '2016-01-21'], /get_fgm_ephemeris, /no_split_vars

; since the variables aren't split, they can't be used by routines
; in SPEDAS that expect vectors to be stored as vectors
tplot, ['mms1_fgm_b_gsm_srvy_l2', 'mms1_fgm_r_gsm_srvy_l2']


end