;+
;
; Unit tests for mms_load_fgm
;
; Requires both the SPEDAS QA folder (not distributed with SPEDAS) and mgunit
; in the local path
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-03-16 12:16:42 -0700 (Wed, 16 Mar 2016) $
; $LastChangedRevision: 20477 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_load_fgm_ut__define.pro $
;-


function mms_load_fgm_ut::test_load
    mms_load_fgm, probe=1, level='l2'
    assert, spd_data_exists('mms1_fgm_b_dmpa_srvy_l2 mms1_fgm_b_gse_srvy_l2 mms1_fgm_b_gsm_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading L2 FGM data'
    return, 1
end

function mms_load_fgm_ut::test_load_largeL2
    mms_load_fgm, probe=1, level='L2'
    assert, spd_data_exists('mms1_fgm_b_dmpa_srvy_l2 mms1_fgm_b_gse_srvy_l2 mms1_fgm_b_gsm_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading L2 FGM data'
    return, 1
end

function mms_load_fgm_ut::test_load_no_split
    mms_load_fgm, probe=1, level='l2', /no_split
    assert, ~spd_data_exists('mms1_fgm_b_dmpa_srvy_l2_bvec mms1_fgm_b_gsm_srvy_l2_bvec', '2015-12-15', '2015-12-16'), 'Problem with /no_split_vars keyword'
    return, 1
end

function mms_load_fgm_ut::test_multi_probe
    mms_load_fgm, probes=[1, 2, 3, 4], level='l2'
    assert, spd_data_exists('mms1_fgm_b_gsm_srvy_l2_bvec mms2_fgm_b_gsm_srvy_l2_bvec mms3_fgm_b_gsm_srvy_l2_bvec mms4_fgm_b_gsm_srvy_l2_bvec', '2015-12-15', '2015-12-16'), 'Problem loading FGM data for multiple spacecraft'
    return, 1
end

function mms_load_fgm_ut::test_multi_probe_mixed_type
    mms_load_fgm, probes=['1', 2, 3, '4']
    assert, spd_data_exists('mms1_fgm_b_gsm_srvy_l2_bvec mms2_fgm_b_gsm_srvy_l2_bvec mms3_fgm_b_gsm_srvy_l2_bvec mms4_fgm_b_gsm_srvy_l2_bvec', '2015-12-15', '2015-12-16'), 'Problem loading FGM data for multiple spacecraft'
    return, 1
end

function mms_load_fgm_ut::test_load_spdf
    mms_load_fgm, level='l2', probe=1, /spdf
    assert, spd_data_exists('mms1_fgm_b_dmpa_srvy_l2 mms1_fgm_b_gse_srvy_l2 mms1_fgm_b_gsm_srvy_l2', '2015-12-15', '2015-12-16'), 'Problem loading L2 FGM data from SPDF'
    return, 1
end

function mms_load_fgm_ut::test_load_brst
  mms_load_fgm, probe=1, level='l2', data_rate='brst'
  assert, spd_data_exists('mms1_fgm_b_dmpa_brst_l2 mms1_fgm_b_gse_brst_l2 mms1_fgm_b_gsm_brst_l2', '2015-12-15', '2015-12-16'), 'Problem loading L2 FGM data'
  return, 1
end

function mms_load_fgm_ut::test_load_brst_caps
  mms_load_fgm, probe=1, level='l2', data_rate='BRST'
  assert, spd_data_exists('mms1_fgm_b_dmpa_brst_l2_bvec mms1_fgm_b_gse_brst_l2_bvec mms1_fgm_b_gsm_brst_l2_bvec', '2015-12-15', '2015-12-16'), 'Problem loading L2 FGM data'
  return, 1
end

function mms_load_fgm_ut::test_load_brst_spdf
  mms_load_fgm, level='l2', data_rate='brst', probe=1, /spdf
  assert, spd_data_exists('mms1_fgm_b_dmpa_brst_l2 mms1_fgm_b_gse_brst_l2 mms1_fgm_b_gsm_brst_l2', '2015-12-15', '2015-12-16'), 'Problem loading L2 burst FGM data from SPDF'
  return, 1
end

function mms_load_fgm_ut::test_load_brst_spdf_caps
    mms_load_fgm, probe=1, level='l2', data_rate='BRST', /spdf
    assert, spd_data_exists('mms1_fgm_b_dmpa_brst_l2_bvec mms1_fgm_b_gse_brst_l2_bvec mms1_fgm_b_gsm_brst_l2_bvec', '2015-12-15', '2015-12-16'), 'Problem loading L2 FGM data'
    return, 1
end

function mms_load_fgm_ut::test_load_suffix
    mms_load_fgm, level='l2', probe=3, suffix='_suffixtest'
    assert, spd_data_exists('mms3_fgm_b_gsm_srvy_l2_bvec_suffixtest mms3_fgm_b_dmpa_srvy_l2_suffixtest', '2015-12-15', '2015-12-16'), 'Problem with L2 FGM suffix test'
    return, 1
end

function mms_load_fgm_ut::test_load_coords
    mms_load_fgm, level='l2', probe=2
    assert, cotrans_get_coord('mms2_fgm_b_gsm_srvy_l2_bvec') eq 'gsm', 'Problem with coordinate system in L2 FGM data'
    assert, cotrans_get_coord('mms2_fgm_b_gse_srvy_l2_bvec') eq 'gse', 'Problem with coordinate system in L2 FGM data'
    assert, cotrans_get_coord('mms2_fgm_b_dmpa_srvy_l2_bvec') eq 'dmpa', 'Problem with coordinate system in L2 FGM data'
    return, 1
end

function mms_load_fgm_ut::test_trange
    mms_load_fgm, trange=['2015-12-10', '2015-12-20'], level='l2', probe=1
    assert, spd_data_exists('mms1_fgm_b_dmpa_srvy_l2_bvec', '2015-12-11', '2015-12-20'), 'Problem with trange keyword while loading FGM data'
    return, 1
end

pro mms_load_fgm_ut::setup
    del_data, '*'
    timespan, '2015-12-15', 1, /day
end
pro mms_load_fgm_ut__define

    define = { mms_load_fgm_ut, inherits MGutTestCase }
end