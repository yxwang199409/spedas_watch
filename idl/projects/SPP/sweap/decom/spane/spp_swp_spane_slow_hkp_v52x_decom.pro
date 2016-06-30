;;---------------------------------------
;; Slow Housekeeping

;EM1 and EM2
;--------------------------
;ADC 0: Ch 0 = Ground
;ADC 0: Ch 1 = Ground
;ADC 0: Ch 2 = MCP_VMON
;ADC 0: Ch 3 = MCP_IMON
;ADC 0: Ch 4 = RAW_HV_VMON
;ADC 0: Ch 5 = RAW_HV_IMON
;ADC 0: Ch 6 = HEMI_VMON
;ADC 0: Ch 7 = Ground
;
;ADC 1: Ch 0 = DEF1_VMON
;ADC 1: Ch 1 = DEF2_VMON
;ADC 1: Ch 2 = SPOILER_VMON
;ADC 1: Ch 3 = TEMP_PCB
;ADC 1: Ch 4 = TEMP_FPGA
;ADC 1: Ch 5 = TEMP_EASIC
;ADC 1: Ch 6 = Ground
;ADC 1: Ch 7 = Ground
;
;EM3
;--------------------------
;ADC 0: Ch 0 = MCP_VMON
;ADC 0: Ch 1 = MCP_IMON
;ADC 0: Ch 2 = RAW_HV_VMON
;ADC 0: Ch 3 = RAW_HV_IMON
;ADC 0: Ch 4 = HEMI_VMON
;ADC 0: Ch 5 = Ground
;ADC 0: Ch 6 = Ground
;ADC 0: Ch 7 = Ground
;
;ADC 1: Ch 0 = DEF1_VMON
;ADC 1: Ch 1 = DEF2_VMON
;ADC 1: Ch 2 = SPOILER_VMON
;ADC 1: Ch 3 = TEMP_PCB
;ADC 1: Ch 4 = TEMP_FPGA
;ADC 1: Ch 5 = TEMP_EASIC
;ADC 1: Ch 6 = Ground
;ADC 1: Ch 7 = Ground
;




function spp_swp_spane_slow_hkp_v52x_decom,ccsds , ptp_header=ptp_header, apdat=apdat

  b = ccsds.data
  ;print, 'SIZE[B]', size(b)
  ;  psize = 69  ; REV  16
  ;  psize =81   ; REV 19
  ;  psize =89   ; REV 26?
;  psize = 101                   ; REV 29
;  psize = 97                    ;  REV 27
;  psize = 105                   ; REV ??
;  psize = 113                   ; REV ???????
;  psize = 117                   ; REV 3B
;  psize = 133                   ; rev 3d
;  psize = 145                   ; rev 49 & 4b  fixed to allow for both EM2 and EM3
  psize = 149                   ; rev 52 & 54

  if n_elements(b) ne psize+7 then begin
    dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
    return,0
  endif



chksum1 = swap_endian(/swap_if_little_endian, uint( b,152 ) )
bschk = b[0:151]

uint_array = swap_endian(/swap_if_little_endian,  uint(bschk,0,n_elements(bschk)/2 ) )
chksum2 = total(/preserve,   uint_array )
ulong_array = swap_endian(/swap_if_little_endian, ulong(bschk,0,n_elements(bschk)/4) )
chksum3 = total(/preserve, ulong_array)
chksum3 = ((chksum3 and 'ffff'x)  + ishft(chksum3,-16) ) and 'ffff'x

if debug(4) then begin
  hexprint,uint_array
  printdat,/hex,chksum1
  printdat,/hex,chksum2
  printdat,/hex,chksum3
  printdat,chksum1 - chksum3 
endif

 ; EM2 = 1
  EM3 = 1
  EM2 = ~EM3
  if EM2 then begin
    ;ADC 0: Ch 0 = Ground
    ;ADC 0: Ch 1 = Ground
    ;ADC 0: Ch 2 = MCP_VMON
    ;ADC 0: Ch 3 = MCP_IMON
    ;ADC 0: Ch 4 = RAW_HV_VMON
    ;ADC 0: Ch 5 = RAW_HV_IMON
    ;ADC 0: Ch 6 = HEMI_VMON
    ;ADC 0: Ch 7 = Ground
    MCP_VMON_CH = 2  *4 + 52
    MCP_IMON_CH = 3 *4 + 52
    RAW_HV_VMON_CH = 4 *4 + 52
    RAW_HV_IMON_CH = 5 *4 + 52
    HEMI_VMON_CH = 6 *4 + 52
  endif

  if EM3 then begin
    ;ADC 0: Ch 0 = MCP_VMON
    ;ADC 0: Ch 1 = MCP_IMON
    ;ADC 0: Ch 2 = RAW_HV_VMON
    ;ADC 0: Ch 3 = RAW_HV_IMON
    ;ADC 0: Ch 4 = HEMI_VMON
    ;ADC 0: Ch 5 = Ground
    ;ADC 0: Ch 6 = Ground
    ;ADC 0: Ch 7 = Ground
    MCP_VMON_CH = 0 *4 + 52
    MCP_IMON_CH = 1 *4 + 52
    RAW_HV_VMON_CH = 2 *4 + 52
    RAW_HV_IMON_CH = 3 *4 + 52
    HEMI_VMON_CH = 4 *4 + 52
  endif


  

  sf0 = ccsds.data[11] and 3
  if sf0 ne 0 then dprint,dlevel=4, 'Odd time at: ',time_string(ccsds.time)

;  ref = 5.29 ; Volts   (EM is 5 volt reference,  FM will be 4 volt reference)
  ref = 4.   ; Volts   (EM is 5 volt reference,  FM will be 4 volt reference)

  rio_scale = .002444
  
  temp_par = spp_swp_therm_temp()

  temp_par_8bit       = temp_par
  temp_par_8bit.xmax  = 255
  temp_par_10bit      = temp_par
  temp_par_10bit.xmax = 1023
  temp_par_12bit      = temp_par
  temp_par_12bit.xmax = 4095


  MON_LVPS_TEMP =   func(swap_endian(/swap_if_little_endian,  fix(b,24 ) ), param = temp_par_12bit)
  MON_ANAL_TEMP =   func(swap_endian(/swap_if_little_endian,  fix(b,42 ) ), param = temp_par_12bit)
  MON_PCB_TEMP=     func(swap_endian(/swap_if_little_endian,  fix(b,66 ) ), param = temp_par_12bit)
  MON_FPGA_TEMP=    func(swap_endian(/swap_if_little_endian,  fix(b,70 ) ), param = temp_par_12bit)
  MON_ASIC_TEMP=    func(swap_endian(/swap_if_little_endian,  fix(b,74 ) ), param = temp_par_12bit)
  
  ADCarray = [swap_endian(/swap_if_little_endian,  fix(b,MCP_VMON_CH ) ), $
  swap_endian(/swap_if_little_endian,  fix(b,54 ) ),$
  swap_endian(/swap_if_little_endian,  fix(b,MCP_IMON_CH ) ),$
  swap_endian(/swap_if_little_endian,  fix(b,58 ) ),$
  swap_endian(/swap_if_little_endian,  fix(b,RAW_HV_VMON_CH ) ),$
  swap_endian(/swap_if_little_endian,  fix(b,62 ) ),$
  swap_endian(/swap_if_little_endian,  fix(b,RAW_HV_IMON_CH ) ),$
  swap_endian(/swap_if_little_endian,  fix(b,66 ) ),$
  swap_endian(/swap_if_little_endian,  fix(b,HEMI_VMON_CH ) ),$
  swap_endian(/swap_if_little_endian,  fix(b,70 ) ),$
  swap_endian(/swap_if_little_endian,  fix(b,72 ) ),$
  swap_endian(/swap_if_little_endian,  fix(b,74 ) ),$
  swap_endian(/swap_if_little_endian,  fix(b,76 ) ),$
  swap_endian(/swap_if_little_endian,  fix(b,78 ) ),$
  swap_endian(/swap_if_little_endian,  fix(b,80 ) ),$
  swap_endian(/swap_if_little_endian,  fix(b,82 ) )]
  
  
  spae = { $
    time:           ccsds.time, $
    dtime:          ccsds.dtime/ccsds.dseq_cntr, $
    met:            ccsds.met,  $
    delay_time:     ptp_header.ptp_time - ccsds.time, $
    seq_cntr:       ccsds.seq_cntr, $
    dseq_cntr:      ccsds.dseq_cntr  < 15, $
    HDR_12:         b[12], $
    HDR_13:         b[13], $
    HDR_14:         b[14], $
    HDR_15:         b[15], $
    HDR_16:         b[16], $
    HDR_17:         b[17], $
    HDR_18:         b[18], $
    HDR_19:         b[19], $

    RIO_20:         swap_endian(/swap_if_little_endian,  fix(b,20 ) ),$
    RIO_21:         swap_endian(/swap_if_little_endian,  fix(b,22 ) ),$
    RIO_LVPS_TEMP:  MON_LVPS_TEMP,$ ;swap_endian(/swap_if_little_endian,  fix(b,24 ) ),$
    RIO_22VA:       swap_endian(/swap_if_little_endian,  fix(b,26 ) ),$
    RIO_1p5VD:      swap_endian(/swap_if_little_endian,  fix(b,28 ) ),$
    RIO_3p3VDA:     swap_endian(/swap_if_little_endian,  fix(b,30 ) ),$
    RIO_3p3VD:      swap_endian(/swap_if_little_endian,  fix(b,32 ) ),$
    RIO_M8Va:       swap_endian(/swap_if_little_endian,  fix(b,34 ) ),$
    RIO_M5VA:       swap_endian(/swap_if_little_endian,  fix(b,36 ) ),$
    RIO_P85A:       swap_endian(/swap_if_little_endian,  fix(b,38 ) ),$
    RIO_P5VA:       swap_endian(/swap_if_little_endian,  fix(b,40 ) ),$
    RIO_ANAL_TEMP:  MON_ANAL_TEMP,$ ;swap_endian(/swap_if_little_endian,  fix(b,42 ) ),$
    RIO_3p3I:       swap_endian(/swap_if_little_endian,  fix(b,44 ) ),$
    RIO_1p5I:       swap_endian(/swap_if_little_endian,  fix(b,46 ) ),$
    RIO_P5IA:       swap_endian(/swap_if_little_endian,  fix(b,48 ) ),$
    RIO_M5IA:       swap_endian(/swap_if_little_endian,  fix(b,50 ) ),$

    adc_VMON_MCP:   swap_endian(/swap_if_little_endian,  fix(b,MCP_VMON_CH ) ) * ref/4095. , $
    adc_VMON_DEF1:  swap_endian(/swap_if_little_endian,  fix(b,54 ) )          * ref*1000./4095. , $
    adc_IMON_MCP:   swap_endian(/swap_if_little_endian,  fix(b,MCP_IMON_CH ) ) * ref/4095. , $
    adc_VMON_DEF2:  swap_endian(/swap_if_little_endian,  fix(b,58 ) )          * ref*1000./4095. , $
    adc_VMON_RAW:   swap_endian(/swap_if_little_endian,  fix(b,RAW_HV_VMON_CH ) ) * ref*752.88/4095. , $
    adc_VMON_SPL:   swap_endian(/swap_if_little_endian,  fix(b,62 ) )              * ref*20.12/4095. , $
    adc_IMON_RAW:   swap_endian(/swap_if_little_endian,  fix(b,RAW_HV_IMON_CH ) ) * ref*1000./40.2/4095. , $
    adc_PCBT:       MON_PCB_TEMP,$ ;swap_endian(/swap_if_little_endian,  fix(b,66 ) )             * ref/4095. , $
    adc_HEMIV:      swap_endian(/swap_if_little_endian,  fix(b,HEMI_VMON_CH ) )   * ref*1271./4095. , $
    adc_FPGAT:      MON_FPGA_TEMP,$ ;swap_endian(/swap_if_little_endian,  fix(b,70 ) ) * ref/4095. , $
    adc_ch10:       swap_endian(/swap_if_little_endian,  fix(b,72 ) ) * ref*1000./40.2/4095. , $
    adc_ASICT:      MON_ASIC_TEMP,$ ;swap_endian(/swap_if_little_endian,  fix(b,74 ) ) * ref/4095. , $
    adc_ch12:       swap_endian(/swap_if_little_endian,  fix(b,76 ) ) * ref*1000./4095. , $
    adc_ch13:       swap_endian(/swap_if_little_endian,  fix(b,78 ) ) * ref/4095. , $
    adc_ch14:       swap_endian(/swap_if_little_endian,  fix(b,80 ) ) * ref/4095. , $
    adc_ch15:       swap_endian(/swap_if_little_endian,  fix(b,82 ) ) * ref/4095. , $
    cmd_ignd:       b[84]    , $
    reset_cntr:     b[85]    , $
    BRD_ID:         b[86]    , $
    REVNUM:         b[87]* 1., $
    CMD_ERRS:       b[88]    , $
    cmd_ukn:        b[89]    , $
    CMD_REC:        swap_endian(/swap_if_little_endian, uint( b,90  ) ) and 'ffff'x , $
    raw_dac:        swap_endian(/swap_if_little_endian, uint( b,92  ) ) and 'ffff'x , $
    hv_conf_flag:   b[94]  , $
    ACTSTAT_FLAG:   b[95]  , $
    mcp_dac:        swap_endian(/swap_if_little_endian, uint( b,96  ) ) and 'ffff'x , $
    mdump_addr:     swap_endian(/swap_if_little_endian, uint( b,98  ) ) and 'ffff'x , $
    peak_cmd_val:   b[100],$
    peak_meas:      b[101],$
    cycle_cnt:      swap_endian(/swap_if_little_endian, uint( b,102 ) ) and 'ffff'x , $
    peak_ch_mask:   swap_endian(/swap_if_little_endian, uint( b,104 ) ) and 'ffff'x , $
    lut_peak_sel:   b[106],$
    peak_step:      b[107],$
    fhkp_set:       b[108],$
    ppulse_set_sumsample:     b[109],$
    stim_step:      b[110],$
    stim_mode:      b[111],$
    timeout_cvr:    b[112],$
    timeout_atn:    b[113],$
    timeout_rlx:    swap_endian(/swap_if_little_endian, uint( b,114 ) ) and 'ffff'x , $
    csum_pilut4:    b[116],$
    csum_pilut3:    b[117],$
    csum_pilut2:    b[118],$
    csum_pilut1:    b[119],$
    easic_dac:      swap_endian(/swap_if_little_endian, uint( b,120 ) ) and 'ffff'x , $
    tcmds_rcvd:     b[122],$
    act_overide:    b[123],$
    atn_rlx_t:      swap_endian(/swap_if_little_endian, uint( b,124 ) ) and 'ffff'x , $
    act_cvr_t:      swap_endian(/swap_if_little_endian, uint( b,126 ) ) and 'ffff'x , $
    act_ati_t:      swap_endian(/swap_if_little_endian, uint( b,128 ) ) and 'ffff'x , $
    act_ato_t:      swap_endian(/swap_if_little_endian, uint( b,130 ) ) and 'ffff'x , $
    ppulse_mask:    swap_endian(/swap_if_little_endian, uint( b,132 ) ) and 'ffff'x , $
    act_err_code:   b[134],$
    csum_tab_load:  b[135],$
    max_cnt:        swap_endian(/swap_if_little_endian, uint( b,136 ) ) and 'ffff'x , $
    peak_cnt:       swap_endian(/swap_if_little_endian, uint( b,138 ) ) and 'ffff'x , $
    arch_sumcnt:    swap_endian(/swap_if_little_endian, uint( b,140 ) ) and 'ffff'x , $
    srvy_sumcnt:    swap_endian(/swap_if_little_endian, uint( b,142 ) ) and 'ffff'x , $
    peak_period_act_cldn: swap_endian(/swap_if_little_endian, uint( b, 144 ) ) and 'ffff'x, $
    sample_sum:     b[146], $
    warm_reset:     b[147], $
    mram_wr_addr:   swap_endian(/swap_if_little_endian, uint( b,148 ) ) and 'ffff'x , $
    mram_wr_addr_hi:b[150], $
    clks_per_nys:   b[151], $
;    pkt_csum:       swap_endian(/swap_if_little_endian, uint( b,152 ) ) and 'ffff'x , $
    pkt_csum_diff:  chksum1 - chksum3, $
    edba:           swap_endian(/swap_if_little_endian, uint( b,154 ) ) and 'ffff'x , $
    GAP:            ccsds.gap, $
    all_ADC:        ADCarray}



  return,spae

end

