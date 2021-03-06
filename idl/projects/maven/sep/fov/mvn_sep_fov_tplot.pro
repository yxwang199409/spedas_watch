;20180414 Ali
;mvn_sep_fov tplotter
;resdeg: angular resolution for fov fraction calculations

pro mvn_sep_fov_tplot,tplot=tplot,store=store,lowres=lowres,nofrac=nofrac,resdeg=resdeg

  @mvn_sep_fov_common.pro

  if ~keyword_set(mvn_sep_fov) then begin
    dprint,'sep fov data not loaded. Please run mvn_sep_fov first! returning...'
    return
  endif

  if keyword_set(lowres) then lrs='5min_' else lrs=''
  if keyword_set(store) then begin
    pos   =mvn_sep_fov.pos
    rad   =mvn_sep_fov.rad
    pdm   =mvn_sep_fov.pdm
    tal   =mvn_sep_fov.tal
    crh   =mvn_sep_fov.crh
    crl   =mvn_sep_fov.crl
    times =mvn_sep_fov.time
    occsx1=mvn_sep_fov.occsx1

    tag=strlowcase(tag_names(pdm))
    npos=n_tags(pos)
    for ipos=0,npos-1 do begin
      store_data,'mvn_sep_dot_'+tag[ipos],times,transpose(pos.(ipos)),dlim={yrange:[-1,1],constant:0.,colors:'bgr',labels:['SEP1','SEP1y','SEP2'],labflag:-1,ystyle:2}
      store_data,'mvn_rad_'+tag[ipos]+'_(km)',times,rad.(ipos),dlim={ylog:1,colors:'b',labels:tag[ipos],labflag:-1,ystyle:2}
    endfor

    store_data,'mvn_mars_dot_object',data={x:times,y:[[pdm.cm1],[pdm.sx1],[pdm.dem],[pdm.sun],[pdm.mar],[pdm.pho]]},dlim={colors:'cbmrkg',labels:['Crab','Sco X1','Deimos','Sun','Surface','Phobos'],labflag:-1,ystyle:2,constant:0}
    store_data,'mvn_mars_tanalt(km)',data={x:times,y:[[tal.cm1],[tal.sx1],[tal.dem],[tal.sun],[tal.pho]]},dlim={colors:'cbmrg',labels:['Crab','Sco X1','Deimos','Sun','Phobos'],labflag:-1,ystyle:2,constant:0}
    store_data,'mvn_sep_sx1_occultation',data={x:times,y:occsx1},dlim={panel_size:.5,yrange:[0,5],ystyle:2}

    dlim={colors:'rmbkgc',labels:detlab,labflag:-1,ystyle:2,ylog:1}
    store_data,'mvn_sep1_xray_crate',data={x:times,y:transpose(crl[0,*,*])},dlim=dlim
    store_data,'mvn_sep2_xray_crate',data={x:times,y:transpose(crl[1,*,*])},dlim=dlim
    store_data,'mvn_sep1_hibc_crate',data={x:times,y:transpose(crh[0,*,*])},dlim=dlim
    store_data,'mvn_sep2_hibc_crate',data={x:times,y:transpose(crh[1,*,*])},dlim=dlim

    if ~keyword_set(nofrac) then begin
      dprint,'calculating mars shine. this might take a while to complete...'
      fraction=mvn_sep_fov_mars_shine(rmars,(replicate(1.,3)#rad.mar)*pos.mar,pos.sun,resdeg=resdeg,/fov)
      ;   fraction2=mvn_sep_anc_fov_mars_fraction(times,check_objects=['MAVEN_SC_BUS']) ;Rob's routine (slow)
      for isep=0,3 do store_data,'mvn_sep'+(['1f','2f','1r','2r'])[isep]+'_fov_fraction',data={x:times,y:transpose([fraction.mars_surfa[isep,*],fraction.mars_shine[isep,*],fraction.mshine_fov[isep,*]])},dlim={colors:'brm',labels:['Disc','Shine','shfov'],labflag:-1,ystyle:2,ylog:1,yrange:[.01,1]}
    endif
  endif

  if keyword_set(tplot) then begin
    case tplot of
      1: tplot,'mvn_sep??_fov_fraction mvn_sep_dot_sun mvn_sep_dot_sx1 mvn_mars_dot_object mvn_mars_tanalt(km) mvn_sep_sx1_occultation mvn_sep?_xray_crate mvn_sep?_hibc_crate mvn_'+lrs+'SEPS_svy_ATT mvn_SEPS_???_DURATION'
      2: tplot,'mvn_'+lrs+'sep?_?-?_Rate_Energy',/add
    endcase
  endif

end