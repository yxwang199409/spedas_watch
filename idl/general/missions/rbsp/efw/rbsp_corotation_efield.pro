;+
; NAME: rbsp_corotation_efield
;
; PURPOSE: Determine the co-rotation electric field for RBSP. Saves as tplot variable
;		
;
; INPUT: probe -> 'a' or 'b'
;		 date  -> ex '2012-10-13'
;
; KEYWORDS: no_spice_load -> don't load SPICE kernels
;
;
; NOTES: 1) I've tested this with the hires mag data as well as lowres 4-sec data.
;		 The lowres data work just as well. 
;		 2) uses accurate 1-min cadence spinaxis pointing direction
;
; HISTORY:
;   2013-07-08: Adapted by Aaron Breneman from program by Scott Thaller, University of Minnesota
;
;
; VERSION:
; $LastChangedBy: kersten $
; $LastChangedDate: 2013-11-26 08:34:58 -0800 (Tue, 26 Nov 2013) $
; $LastChangedRevision: 13591 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_corotation_efield.pro $
;
;-



pro rbsp_corotation_efield,probe,date,no_spice_load=no_spice_load


;Initializing stuff...
;	rbsp_efw_init
;	!rbsp_efw.user_agent = ''
	timespan,date

;Load SPICE if required
	if ~keyword_set(no_spice_load) then rbsp_load_spice_predict
	if ~keyword_set(no_spice_load) then rbsp_load_spice_kernels


;Get the spinphase variable. 
	rbsp_load_state,probe=probe,/no_spice_load,datatype=['pos','vel','spinper','spinphase','mat_dsc','Lvec']
	get_data,'rbsp'+probe+'_Lvec',data=lvec


;Load spice for position and velocity data
	rbsp_load_spice_state,probe=probe,coord='gse',/no_spice_load
	

;Get spin-axis pointing direction once/minute
	time2=time_double(date) ; first get unix time double for beginning of day

	;number of time chunks throughout day
	ntimes = 1440.  ;1440 = once/min
	time3 = time_string(time2 + 60.*indgen(ntimes))

	strput,time3,'T',10 ; convert TPLOT time string 'yyyy-mm-dd/hh:mm:ss.msec' to ISO 'yyyy-mm-ddThh:mm:ss.msec'
	cspice_str2et,time3,et2 ; convert ISO time string to SPICE ET

	cspice_pxform,'RBSP'+strupcase(probe)+'_SCIENCE','GSE',et2,pxform

	wsc=dblarr(3,ntimes)
	wsc[2,*]=1d
	wsc_GSE=dblarr(3,ntimes)

	for qq=0l,ntimes-1 do wsc_GSE[*,qq] = pxform[*,*,qq] ## wsc[*,qq]



;Load EMFISIS data (first try to load L3, if no L3 then load quicklook)
	rbsp_load_emfisis,probe=probe,coord='gse',cadence='4sec',level='l3'
	get_data,'rbsp'+probe+'_emfisis_l3_4sec_gse_Mag',data=Bmag
	
	if ~is_struct(Bmag) then begin
		rbsp_load_emfisis,probe=probe,/quicklook

		;no need to have data at very high res
		rbsp_downsample,'rbsp'+probe+'_emfisis_quicklook_Mag',1/11.8,suffix='_tmp'

		rbsp_uvw_to_mgse,probe,'rbsp'+probe+'_emfisis_quicklook_Mag_tmp',/no_spice_load


		get_data,'rbsp'+probe+'_emfisis_quicklook_Mag_tmp_mgse',data=Bmag
		wsc_gsetmp = [[interpol(wsc_GSE[0,*],time_double(time3),Bmag.x)],$
					[interpol(wsc_GSE[1,*],time_double(time3),Bmag.x)],$
					[interpol(wsc_GSE[2,*],time_double(time3),Bmag.x)]]

		rbsp_mgse2gse,'rbsp'+probe+'_emfisis_quicklook_Mag_tmp_mgse',wsc_gsetmp,probe=probe,/no_spice_load,newname='rbsp'+probe+'_emfisis_quicklook_Mag_gse'

		copy_data,'rbsp'+probe+'_emfisis_quicklook_Mag_gse','bfield_data'

	endif else copy_data,'rbsp'+probe+'_emfisis_l3_4sec_gse_Mag','bfield_data'
	


	if ~is_struct(Bmag) then begin
		print,'NO MAG DATA LOADED.....RETURNING'
		return
	endif




;Find corotation electric field

	;use GEI (Geocentric Equitorial Inertial) coordinates
	cotrans,'rbsp'+probe+'_state_pos_gse','rbsp'+probe+'_state_pos_gei',/GSE2GEI

	get_data,'rbsp'+probe+'_state_pos_gei',data=gei_pos

	if ~is_struct(gei_pos) then begin
		print,'NO POSITION DATA LOADED.....RETURNING'
		return
	endif

	gei_pos_times = gei_pos.x
	gei_pos       = gei_pos.y

	xgei = gei_pos[*,0]
	ygei = gei_pos[*,1]
	zgei = gei_pos[*,2]

	Omega_E = (2*!Pi)/(24.0*3600.0) ;Earth's rotation angular frequency

	Vel_coro = fltarr(n_elements(xgei),3) ;set up array for velocity of corotating frame at RBSP location 

	;V=Omega X position  (rigid body rotation) 
	Vel_coro[*,0] = -ygei*Omega_E  
	Vel_coro[*,1] = xgei*Omega_E
	Vel_coro[*,2] = 0.0



;Transform magnetic field into GEI coordinates
	cotrans,'bfield_data','bfield_data_gei',/GSE2GEI,/ignore_dlimits


	get_data,'bfield_data_gei',data=Bgei
	mag_times=Bgei.x
	Bgei = Bgei.y

	Vel_coro=interp(Vel_coro,gei_pos_times,mag_times,/no_extrap)

	store_data,'rbsp'+probe+'_state_vel_coro_gei',data={x:mag_times,y:Vel_coro}

	E_coro=fltarr(n_elements(mag_times),3)
	for xx=0L,n_elements(mag_times)-1 do E_coro[xx,*]=-crossp(Vel_coro[xx,*],Bgei[xx,*])/1000.0 

	store_data,'rbsp'+probe+'_E_coro_gei',data={x:mag_times,y:E_coro},dlim={colors:[2,4,6],lables:['Ex','Ey','Ez']}


;Transform corotational E and V in GEI into GSE and MGSE

	cotrans,'rbsp'+probe+'_E_coro_gei','rbsp'+probe+'_E_coro_gse',/GEI2GSE
	cotrans,'rbsp'+probe+'_state_vel_coro_gei','rbsp'+probe+'_state_vel_coro_gse',/GEI2GSE
	get_data,'rbsp'+probe+'_E_coro_gse',data=Ecoro

	if ~is_struct(Ecoro) then begin
		print,'NO CO-ROTATION EFIELD DATA LOADED'
		return
	endif



	;put the pointing direction on the same timestamps as the Efield data
	wsc_GSE2 = [[interpol(wsc_GSE[0,*],time_double(time3),Ecoro.x)],$
				[interpol(wsc_GSE[1,*],time_double(time3),Ecoro.x)],$
				[interpol(wsc_GSE[2,*],time_double(time3),Ecoro.x)]]
	if is_struct(Ecoro) then rbsp_gse2mgse,'rbsp'+probe+'_E_coro_gse',reform(wsc_GSE2),newname='rbsp'+probe+'_E_coro_mgse'
	if is_struct(Ecoro) then rbsp_gse2mgse,'rbsp'+probe+'_state_vel_coro_gse',reform(wsc_GSE2),newname='rbsp'+probe+'_state_vel_coro_mgse'



	get_data,'rbsp'+probe+'_E_coro_mgse',data=Ecorot
	options,'rbsp'+probe+'_E_coro_mgse','colors',[2,4,6]
	options,'rbsp'+probe+'_E_coro_mgse','labels',['Ex','Ey','Ez']

	get_data,'rbsp'+probe+'_state_vel_coro_mgse',data=Vcorot
	options,'rbsp'+probe+'_state_vel_coro_mgse','colors',[2,4,6]
	options,'rbsp'+probe+'_state_vel_coro_mgse','labels',['Vx','Vy','Vz']

	message,"Done with rbsp_corotation_efield...",/continue

end