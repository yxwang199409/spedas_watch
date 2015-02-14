;+
;NAME:
; mvn_lpw_anc_clear_spice_kernels
;PURPOSE:
; Clears spice kernels, and unsets the 'kernel verified' flag in the
; mvn_spc_met_to_unixtime so that mvn_spc_met_to_unixtime doesn't crash
;CALLING SEQUENCE:
; mvn_lpw_anc_clear_spice_kernels
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-02-12 11:10:10 -0800 (Thu, 12 Feb 2015) $
; $LastChangedRevision: 16968 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/lpw/mvn_lpw_anc_clear_spice_kernels.pro $
;-
Pro mvn_lpw_anc_clear_spice_kernels

  common mvn_spc_met_to_unixtime_com, cor_clkdrift, icy_installed  , kernel_verified, time_verified, sclk,tls

  cspice_kclear                 ;unload spice kernels
  undefine, kernel_verified

Return
End
