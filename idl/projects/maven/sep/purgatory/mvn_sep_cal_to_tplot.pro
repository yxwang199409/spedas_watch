pro mvn_sep_cal_to_tplot,newdat,sepnum=sepnum

@mvn_sep_handler_commonblock.pro

if ~keyword_set(newdat) then begin
  rawdat = sepnum eq 1 ? *sep1_svy.x : *sep2_svy.x
  if 0 then begin
    raw_data=transpose(rawdat.data)
    raw_data=smooth_counts(raw_data)
    rawdat.data=transpose(raw_data)    
  endif
  bkgfile=mvn_pfp_file_retrieve('maven/data/sci/sep/l1/sav/sep2_bkg.sav')
  restore,file=bkgfile,/verb
  ; mvn_sep_spectra_plot,bkg2
  newdat = mvn_sep_get_cal_units(rawdat,background = bkg2)
endif

prefix='mvn_'

  ;
  data = newdat.f_ion_flux
  ;ddata = newdat.f_ion_flux_unc
  ;

  dim = size(/dimen,data)
  r = intarr( dim[0] )
  r[0:2] = 0
  r[3:9] = 0
  r[10:19] = 1
  r[20:*]  = 2
  ;printdat,r
  ;printdat,minmax(r)
  d1 = max(r) +1
  rr = fltarr( d1, dim[0] )
  h = histogram(r,reverse=rev)
  for i=0,d1-1 do if h[i] ne 0 then  rr[i,  Rev[Rev[i] : Rev[i+1]-1] ] =1

  rr = fltarr( d1, dim[0] )
  rr[0,5:12]=1
  rr[1,13:20]=1
  rr[2,21:27]=1


  data = newdat.f_ion_eflux
  ddata = newdat.f_ion_eflux_unc


  bad = data lt .0* ddata
  w = where(bad)
  ;data[w] = !values.f_nan
  store_data,prefix+'sep2F_ion_eflux',newdat.time,transpose(data),transpose(newdat.f_ion_energy),dlim={spec:1,yrange:[10,6000.],ystyle:1,ylog:1,zrange:[100.,1e5],zlog:1,panel_size:2}

  data = newdat.r_ion_eflux
  ddata = newdat.r_ion_eflux_unc
  bad = data lt .0* ddata
  ;w = where(bad)
  data[w] = !values.f_nan
  store_data,prefix+'sep2R_ion_eflux',newdat.time,transpose(data),transpose(newdat.R_ion_energy),dlim={spec:1,yrange:[10,6000.],ystyle:1,ylog:1,zrange:[100.,1e5],zlog:1,panel_size:2}

  data = newdat.f_ion_flux
  ddata = newdat.f_ion_flux_unc
  bad = data lt .0* ddata
  w = where(bad)
  ;data[w] = !values.f_nan
  store_data,prefix+'sep2F_ion_flux',newdat.time,transpose(data),transpose(newdat.f_ion_energy),dlim={spec:1,yrange:[10,6000.],ystyle:1,ylog:1,zrange:[1,1e4],zlog:1,panel_size:2}
  data= rr # data
  ddata= sqrt(rr # (ddata ^2))
  eval0 = newdat[0].f_ion_energy
  eval = (rr # eval0) / total(rr,2)
  store_data,prefix+'sep2F_ion_flux_red',newdat.time,transpose(data),eval,dlim={spec:0,yrange:[.01,1e5],ystyle:1,ylog:1,zrange:[1,1e4],zlog:1,panel_size:2}

  store_data,prefix+'sep2F_ion_eflux_tot',data={x:newdat.time,y:newdat.f_ion_eflux_tot},dlim={ylog:1,yrange:[1e3,1e8]}
  store_data,prefix+'sep2R_ion_eflux_tot',data={x:newdat.time,y:newdat.r_ion_eflux_tot},dlim={ylog:1,yrange:[1e3,1e8]}

  store_data,prefix+'sep2F_ion_flux_tot',data={x:newdat.time,y:newdat.f_ion_flux_tot},dlim={ylog:1,yrange:[10.,1e6]}
  store_data,prefix+'sep2R_ion_flux_tot',data={x:newdat.time,y:newdat.r_ion_flux_tot},dlim={ylog:1,yrange:[10.,1e6]}


  ;print,(eval0* reform(rr[0,*]))
  ;print,(eval0* reform(rr[1,*]))
  ;print,(eval0* reform(rr[2,*]))
  print,eval0[where(rr[0,*])]
  print,eval0[where(rr[1,*])]
  print,eval0[where(rr[2,*])]
end