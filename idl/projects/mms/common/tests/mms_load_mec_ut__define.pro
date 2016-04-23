;+
;
; Unit tests for mms_load_mec
;
; Requires both the SPEDAS QA folder (not distributed with SPEDAS) and mgunit
; in the local path
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-04-22 08:37:33 -0700 (Fri, 22 Apr 2016) $
; $LastChangedRevision: 20885 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_mec_ut__define.pro $
;-

;9 mms1_mec_quat_eci_to_smpa
;10 mms1_mec_quat_eci_to_dsl
;11 mms1_mec_quat_eci_to_ssl
;26 mms1_mec_quat_eci_to_gsm
;29 mms1_mec_quat_eci_to_geo
;32 mms1_mec_quat_eci_to_sm
;35 mms1_mec_quat_eci_to_gse
;38 mms1_mec_quat_eci_to_gse2000
function mms_load_mec_ut::test_multi_probe
  mms_load_mec, probe=[1, 2, '3', '4'], level='l2', data_rate='srvy'
  assert, spd_data_exists('mms1_mec_r_gsm mms2_mec_r_gsm mms3_mec_r_gsm mms4_mec_r_gsm', '2016-2-10', '2016-2-11'), $
    'Problem loading multi-probe MEC data'
  return, 1
end

function mms_load_mec_ut::test_load_brst_caps
  mms_load_mec, probe=1, level='L2', data_rate='BrST'
  assert, spd_data_exists('mms1_mec_r_gsm mms1_mec_r_sm', '2016-2-10', '2016-2-11') , $
    'Problem loading MEC brst data with caps'
  return, 1
end

function mms_load_mec_ut::test_load_brst
  mms_load_mec, probe=1, level='l2', data_rate='brst', suffix='_brst'
  assert, spd_data_exists('mms1_mec_r_gsm_brst', '2016-2-10', '2016-2-11'), $
    'Problem loading MEC brst data'
  return, 1
end

function mms_load_mec_ut::test_load_mec_cdf_filenames
  mms_load_mec, probe=1, level='l2', /spdf, suffix='_fromspdf', cdf_filenames=spdf_filenames
  mms_load_mec, probe=1, level='l2', suffix='_fromsdc', cdf_filenames=sdc_filenames
  assert, array_equal(spdf_filenames, sdc_filenames), 'Problem with cdf_filenames keyword (SDC vs. SPDF)'
  return, 1
end

function mms_load_mec_ut::test_load_spdf
  mms_load_mec, probes=[1, 4], /spdf
  assert, spd_data_exists('mms4_mec_r_gsm mms1_mec_r_gsm mms1_defatt_spinras mms4_defatt_spinras', '2016-2-10', '2016-2-11')
  return, 1
end

pro mms_load_mec_ut::setup
  del_data, '*'
  timespan, '2016-2-10', 1, /day
  ; create a connection to the LASP SDC with public access
  mms_load_data, login_info='test_auth_info_pub.sav', instrument='mec'
end

function mms_load_mec_ut::init, _extra=e
  if (~self->MGutTestCase::init(_extra=e)) then return, 0
  ; the following adds code coverage % to the output
  self->addTestingRoutine, ['mms_load_mec', 'mms_mec_fix_metadata']
  return, 1
end

pro mms_load_mec_ut__define

  define = { mms_load_mec_ut, inherits MGutTestCase }
end