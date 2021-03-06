
function spp_ptp_header_struct,ptphdr
  ptp_size = swap_endian(uint(ptphdr,0) ,/swap_if_little_endian )
  ptp_code = ptphdr[2]
  ptp_scid = swap_endian(/swap_if_little_endian, uint(ptphdr,3))

  days  = swap_endian(/swap_if_little_endian, uint(ptphdr,5))
  ms    = swap_endian(/swap_if_little_endian, ulong(ptphdr,7))
  us    = swap_endian(/swap_if_little_endian, uint(ptphdr,11))
  utime = (days-4383L) * 86400L + ms/1000d
  if utime lt   1425168000 then utime += us/1d4   ;  correct for error in pre 2015-3-1 files
  ;      if keyword_set(time) then dt = utime-time  else dt = 0
  source   =    ptphdr[13]
  spare    =    ptphdr[14]
  path  = swap_endian(/swap_if_little_endian, uint(ptphdr,15))
  ptp_header ={ptp_size:ptp_size, ptp_code:ptp_code, ptp_scid: ptp_scid, ptp_time:utime, ptp_source:source, ptp_spare:spare, ptp_path:path }
  return,ptp_header
end




pro spp_ptp_lun_read,in_lun,out_lun,info=info

  dwait = 10.
  
  on_ioerror, nextfile
    info.time_received = systime(1)
    msg = time_string(info.time_received,tformat='hh:mm:ss -',local=localtime)
;    in_lun = info.hfp
    out_lun = info.dfp
    buf = bytarr(17)
    remainder = !null
    nbytes = 0
    run_proc = struct_value(info,'run_proc',default=1)
    while file_poll_input(in_lun,timeout=0) && ~eof(in_lun) do begin
      readu,in_lun,buf,transfer_count=nb
      nbytes += nb
      if keyword_set(out_lun) then writeu,out_lun, buf
      ptp_buf = [remainder,buf]
      sz = ptp_buf[0]*256 + ptp_buf[1]
      if (sz lt 17) || (ptp_buf[2] ne 3) || (ptp_buf[3] ne 0) || (ptp_buf[4] ne 'bb'x) then  begin     ;; Lost sync - read one byte at a time
          remainder = ptp_buf[1:*]
          buf = bytarr(1)
          if debug(2) then begin
            dprint,dlevel=2,'Lost sync:',dwait=10
          endif
          continue  
      endif
      ptp_header = spp_ptp_header_struct(ptp_buf)
      ccsds_buf = bytarr(sz - n_elements(ptp_buf))
      readu,in_lun,ccsds_buf,transfer_count=nb
      nbytes += nb
      if keyword_set(out_lun) then writeu,out_lun, ccsds_buf
      
      fst = fstat(in_lun)
      if debug(2) && fst.cur_ptr ne 0 && fst.size ne 0 then begin
        dprint,dwait=dwait,dlevel=2,fst.compress ? '(Compressed) ' : '','File percentage: ' ,(fst.cur_ptr*100.)/fst.size
      endif
      
      if nb ne  sz-17 then begin
        fst = fstat(in_lun)
        dprint,'File read error. Aborting @ ',fst.cur_ptr,' bytes'
        break
      endif
      if debug(5) then begin
        hexprint,dlevel=3,ccsds_buf,nbytes=32
      endif
      if run_proc then   spp_ccsds_pkt_handler,ccsds_buf,ptp_header=ptp_header  

      buf = bytarr(17)
      remainder=!null
    endwhile
    
    if nbytes ne 0 then msg += string(/print,nbytes,([ptp_buf,ccsds_buf])[0:(nbytes < 32)-1],format='(i6 ," bytes: ", 128(" ",Z02))')  $
    else msg+= ' No data available'

    dprint,dlevel=4,msg
    info.msg = msg

    if 0 then begin
      nextfile:
      dprint,!error_state.msg
      dprint,'Skipping file'
    endif
;    dprint,dlevel=2,'Compression: ',float(fp)/fi.size
  
end


