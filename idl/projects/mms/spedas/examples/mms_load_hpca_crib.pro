;+
; MMS HPCA crib sheet
; 
; do you have suggestions for this crib sheet? 
;   please send them to egrimes@igpp.ucla.edu
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-08-21 15:18:29 -0700 (Fri, 21 Aug 2015) $
; $LastChangedRevision: 18571 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_hpca_crib.pro $
;-

; set some reasonable margins
tplot_options, 'xmargin', [20, 15]

mms_load_hpca, probes='1', trange=['2015-07-31', '2015-08-01'], datatype='moments'

; there's a gap in the data in the morning of 7/31 ~(0530UT-1330UT)
;tdegap, tnames(), /overwrite

; show H+, O+ and He+ density
tplot, ['mms1_hpca_hplus_number_density', $
        'mms1_hpca_oplus_number_density', $
        'mms1_hpca_heplus_number_density']

window, 1
; show H+, O+ and He+ temperature
tplot, ['mms1_hpca_hplus_scalar_temperature', $
        'mms1_hpca_oplus_scalar_temperature', $
        'mms1_hpca_heplus_scalar_temperature'], window=1
stop

window, 2
tplot_options, 'colors', [2, 4, 6]
; show H+, O+ and He+ flow velocity
tplot, ['mms1_hpca_hplus_ion_bulk_velocity', $
        'mms1_hpca_oplus_ion_bulk_velocity', $
        'mms1_hpca_heplus_ion_bulk_velocity'], window=2
       
stop

mms_load_hpca, probes='1', trange=['2015-07-31', '2015-08-01'], datatype='rf_corr', level='l1b'

rf_corrected = ['mms1_hpca_hplus_RF_corrected', $
                'mms1_hpca_oplus_RF_corrected', $ 
                'mms1_hpca_heplus_RF_corrected', $
                'mms1_hpca_heplusplus_RF_corrected']
        
; show spectra for H+, O+ and He+, He++
window, 3, ysize=600
tplot, rf_corrected, window=3

tlimit, '2015-07-31/11:45', '2015-07-31/13:45'
end