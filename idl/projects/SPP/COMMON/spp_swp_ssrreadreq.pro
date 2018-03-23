pro spp_swp_ssrreadreq,times

n= n_elements(times)
if n and 1 then message ,'Must be odd'


n2 = n/2
tt = reform(times,2,n2)
for i=0,n2-1 do begin
    blocknums = data_cut('spp_swem_dhkp_SW_SSRWRADDR',tt[*,i])
    startblock = blocknums[0]
    deltablock = blocknums[1]-blocknums[0] > 1
    apmask  =  replicate('ffffffff'x,4)
    apmask1  = 'FFFFffff'x
    apmask2  = 'FFFFffff'x
    apmask3  = 'FFFFffff'x
;    print,startblock,deltablock,APMASK0,APMASK1,APMASK2,APMASK3,format='("cmd.sw_ssrreadreq(",i6,i5,Z4,Z4,Z4,Z4,")")'
    print,startblock,deltablock,APMASK,time_string(tt[*,i]),  $
      format='(%"cmd.SW_SSRREADREQ(%d,%d,0x%8X,0x%8X,0x%8X,0x%8x)  # from: %s  to: %s ")'
endfor


end


