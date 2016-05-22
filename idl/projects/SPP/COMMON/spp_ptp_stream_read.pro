
pro spp_ptp_stream_read,buffer,info=info,no_sum=no_sum  ;,time=time
  
  bsize= n_elements(buffer) * (size(/n_dimen,buffer) ne 0)
  time = info.time_received


  common spp_ptp_stream_read_com,last_time,total_bytes,rate_sm
  if ~keyword_set(no_sum) then begin
    if keyword_set(last_time) then begin
      dt = time - last_time
      len = n_elements(buffer)
      total_bytes += len
      if dt gt .1 then begin
        rate = total_bytes/dt
        store_data,'AVG_DATA_RATE2',append=1,time, rate,dlimit={psym:-4}
        total_bytes =0
        last_time = time
      endif
    endif else begin
      last_time = time
      total_bytes = 0
    endelse    
  endif


  ;; Handle remainder of buffer from previous call
  if n_elements( *info.exec_proc_ptr ) ne 0 then begin
     remainder =  *info.exec_proc_ptr
     dprint,dlevel=2,'Using remainder buffer from previous call'
     dprint,dlevel=3,/phelp, remainder
     undefine , *info.exec_proc_ptr
     if bsize gt 0 then  spp_ptp_stream_read, [remainder,buffer],info=info,/no_sum
     return
  endif
  
  p=0L
  while p lt bsize do begin
     if p gt bsize-3 then begin
        dprint,dlevel=1,'Warning PTP stream size can not be read ',p,bsize
        ptp_size = 17  
        ;; (minimum value possible) 
        ;; Dummy value that will trigger end of buffer
     endif else  ptp_size = swap_endian( uint(buffer,p) ,$
                                         /swap_if_little_endian)
     if ptp_size lt 17 then begin
        dprint,dlevel=1,'PTP packet size is too small!'
        dprint,dlevel=1,p,ptp_size,buffer,/phelp
        break
     endif
     ;; Buffer doesn't have complete pkt.
     if p+ptp_size gt bsize then begin 
        dprint,dlevel=2,'Buffer has incomplete packet. Saving ', n_elements(buffer)-p,' bytes for next call.'
        ;dprint,dlevel=1,p,ptp_size,buffer,/phelp
        *info.exec_proc_ptr = buffer[p:*] 
        ;; Store remainder of buffer to be used on the next 
        ;; call to this procedure
        return
        break
     endif
     spp_ptp_pkt_handler,buffer[p:p+ptp_size-1],time=time
     p += ptp_size
  endwhile
  if p ne bsize then dprint,dlevel=1,'Buffer incomplete',p,ptp_size,bsize
  return
end
