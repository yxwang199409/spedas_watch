
function spice_bod2s,nnn
if size(/type,nnn) eq 7 then name=nnn else cspice_bodc2s,code,name
return,strupcase(name)
end

function spice_bodc2s,code
cspice_bodc2s,code,name
return,name
end


function spice_bods2c,name,found
cspice_bods2c,name,code,found
return,code
end


; Loads kernels only if they are not already loaded
pro spice_kernel_load,kernels,unload=unload,verbose=verbose
  if spice_test() eq 0 then return
  loaded = spice_test('*')
  for i=0L,n_elements(kernels)-1 do begin
     w = where(kernels[i] eq loaded,nw)
     if nw eq 0 then begin
       dprint,verbose=verbose,dlevel=2,'Loading  '+kernels[i]
       cspice_furnsh,kernels[i]
     endif else dprint,verbose=verbose,dlevel=3,'Ignoring '+kernels[i] + ' (already loaded)'
  endfor
end

