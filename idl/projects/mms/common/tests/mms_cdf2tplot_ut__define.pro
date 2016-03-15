;+
;
; Unit tests for mms_cdf2tplot
;
;
; NOTES: 
;     valid times for unit tests involving /center keyword 
;     taken from v2.1.0 of the FPI CDFs, 3/10/2016
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-03-14 13:00:53 -0700 (Mon, 14 Mar 2016) $
; $LastChangedRevision: 20442 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_cdf2tplot_ut__define.pro $
;-

; Test number_records
function mms_cdf2tplot_ut::test_num_records
  mms_load_mec, trange=['2016-01-21', '2016-01-22'], level='l2', cdf_records=1
  get_data, 'mms1_mec_r_gsm', data=d
  assert, n_elements(d.X) eq 1, 'Problem with number_records keyword'
  return, 1
end

;  Test varformat
function mms_cdf2tplot_ut::test_varformat
  del_data, '*'
  mms_load_edi, trange=['2016-01-21', '2016-01-22'], level='l2', varformat='*_edi_e_gsm_srvy_l2'
  assert, ~is_array(tnames()) && n_elements(tnames()) eq 1, 'Problem with varformat!'
  return, 1
end

; CDF with single data point
; regression test for bug reported by Naritoshi Kitamura, 2/22/16
function mms_cdf2tplot_ut::test_single_data_point
  mms_load_fpi,trange=['2015-09-11/10:00:00','2015-09-11/11:00:00'],probes='1',level='l2',data_rate='brst',datatype=['dis-moms'],suffix='_singlepoint'
  assert, is_array(tnames('*_singlepoint')), 'Problem with CDF containing single data point'
  return, 1
end

; DELTA_PLUS_VAR/DELTA_MINUS_VAR for L2 FPI Burst (shifted)
function mms_cdf2tplot_ut::test_fpi_burst_shifted
  mms_load_fpi, trange=['2016-01-21', '2016-01-22'], datatype='des-moms', probe=3, data_rate='brst', /center, suffix='_shifted'
  get_data, 'mms3_des_numberdensity_dbcs_brst_shifted', data=d
  valid_times_shifted = ['20160121/01:06:24.024', '20160121/01:06:24.054', '20160121/01:06:24.084', '20160121/01:06:24.114']
  for vi = 0, n_elements(valid_times_shifted)-1 do begin
    assert, time_string(d.X[vi], tformat='YYYYMMDD/hh:mm:ss.fff') eq valid_times_shifted[vi], 'Problem with the FPI L2 burst shifted data'
  endfor
  return, 1
end

; DELTA_PLUS_VAR/DELTA_MINUS_VAR for L2 FPI Burst (unshifted)
function mms_cdf2tplot_ut::test_fpi_burst_unshifted
  mms_load_fpi, trange=['2016-01-21', '2016-01-22'], datatype='des-moms', probe=3, data_rate='brst'
  get_data, 'mms3_des_numberdensity_dbcs_brst', data=d
  valid_times_noshift = ['20160121/01:06:24.009', '20160121/01:06:24.039', '20160121/01:06:24.069', '20160121/01:06:24.099']
  for vi = 0, n_elements(valid_times_noshift)-1 do begin
    assert, time_string(d.X[vi], tformat='YYYYMMDD/hh:mm:ss.fff') eq valid_times_noshift[vi], 'Problem with the FPI L2 burst unshifted data'
  endfor
  return, 1
end

; DELTA_PLUS_VAR/DELTA_MINUS_VAR for L2 FPI FS (shifted)
function mms_cdf2tplot_ut::test_fpi_fs_shifted
  mms_load_fpi, trange=['2016-01-21', '2016-01-22'], datatype='des-moms', probe=3, data_rate='fast', /center, suffix='_shifted'
  get_data, 'mms3_des_energyspectr_my_fast_shifted', data=d
  valid_times_shifted = ['20160121/00:00:03.068', '20160121/00:00:07.568', '20160121/00:00:12.068', '20160121/00:00:16.568']
  for vi = 0, n_elements(valid_times_noshift)-1 do begin
    assert, time_string(d.X[vi], tformat='YYYYMMDD/hh:mm:ss.fff') eq valid_times_shifted[vi], 'Problem with FPI L2 FS shifted data'
  endfor
  return, 1
end

; DELTA_PLUS_VAR/DELTA_MINUS_VAR for L2 FPI FS (unshifted)
function mms_cdf2tplot_ut::test_fpi_fs_unshifted
  mms_load_fpi, trange=['2016-01-21', '2016-01-22'], datatype='des-moms', probe=3, data_rate='fast'
  get_data, 'mms3_des_energyspectr_my_fast', data=d
  valid_times_noshift = ['20160121/00:00:00.818', '20160121/00:00:05.318', '20160121/00:00:09.818', '20160121/00:00:14.318']
  for vi = 0, n_elements(valid_times_noshift)-1 do begin
    assert, time_string(d.X[vi], tformat='YYYYMMDD/hh:mm:ss.fff') eq valid_times_noshift[vi], 'Problem with FPI L2 FS unshifted data' 
  endfor
  return, 1
end

; DELTA_PLUS_VAR/DELTA_MINUS_VAR for L2 HPCA 'srvy' (unshifted)
function mms_cdf2tplot_ut::test_hpca_srvy_unshifted
  mms_load_hpca, level='l2', trange=['2015-09-15', '2015-09-16'], probe=1
  get_data, 'mms1_hpca_hplus_number_density', data=d
  valid_times_noshift = ['20150915/00:00:13.233', '20150915/00:01:23.231', '20150915/00:02:33.230', '20150915/00:03:43.229']
  for vi = 0, n_elements(valid_times_noshift)-1 do begin
    assert, time_string(d.X[vi], tformat='YYYYMMDD/hh:mm:ss.fff') eq valid_times_noshift[vi], 'Problem with HPCA L2 srvy unshifted data' 
  endfor
  return, 1
end

; DELTA_PLUS_VAR/DELTA_MINUS_VAR for L2 HPCA 'srvy' (shifted)
function mms_cdf2tplot_ut::test_hpca_srvy_shifted
  mms_load_hpca, level='l2', trange=['2015-09-15', '2015-09-16'], probe=1, /center, suffix='_shifted'
  get_data, 'mms1_hpca_hplus_number_density_shifted', data=d
  valid_times_shifted = ['20150915/00:00:18.232', '20150915/00:01:28.231', '20150915/00:02:38.229', '20150915/00:03:48.228']
  for vi = 0, n_elements(valid_times_shifted)-1 do begin
    assert, time_string(d.X[vi], tformat='YYYYMMDD/hh:mm:ss.fff') eq valid_times_shifted[vi], 'Problem with HPCA L2 srvy shifted data'
  endfor
  return, 1
end

pro mms_cdf2tplot_ut::setup
  ; do some setup for the tests
end

pro mms_cdf2tplot_ut__define
  compile_opt strictarr

  define = { mms_cdf2tplot_ut, inherits MGutTestCase }
end