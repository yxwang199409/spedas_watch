;+
;NAME:
;   thm_load_gmag_networks
; 
;PURPOSE:   
;   Loads the GMAG networks and stations from file gmag_stations.txt, which recides in the same directory. 
;
;KEYWORDS:
;   gmag_networks: list of gmag networks (gima, carisma, etc)
;   gmag_stations: list of gmag station codes (abk, atha, etc)
;   selected_network: list of selected networks
;   
;EXAMPLES:
;   thm_load_gmag_networks, gmag_networks=gmag_networks, gmag_stations=gmag_stations
;   thm_load_gmag_networks, gmag_networks=gmag_networks, gmag_stations=gmag_stations, selected_network=['gima', 'autumnx']
;
;HISTORY:
; $LastChangedBy: nikos $
; $LastChangedDate: 2015-11-03 14:35:08 -0800 (Tue, 03 Nov 2015) $
; $LastChangedRevision: 19225 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/thm_load_gmag_networks.pro $
;-

; reads a text file and returns lists of gmag networks and stations
pro thm_load_gmag_networks, gmag_networks=gmag_networks, gmag_stations=gmag_stations, selected_network=selected_network

  if ~keyword_set(selected_network) then selected_network=''
    
  station_file = 'gmag_stations.txt'
  rt_info = routine_info('thm_load_gmag_networks',/source)
  filename = file_dirname(rt_info.path) + path_sep() + station_file
  
  result = file_test(filename, /read)
  if result eq 1 then begin
    OPENR, unit, filename, /GET_LUN
    str = ''
    count = 0ll
    WHILE ~ EOF(unit) DO BEGIN
      READF, unit, str
      str = strtrim(str)
      gmags = STRSPLIT( str, "|", count=ct, /extract, /preserve_null)
      if ct eq 4 then begin ; if line is well formed
        if count eq 0 then begin
          ggroups = [gmags[0]] ; group code
          ggroupnames = [gmags[1]] ; group full name
          gstationgroups = [0] ; what station belongs to which group
          gstationcodes = [strtrim(gmags[2])] ; station code
          gstationnames = [strtrim(gmags[3])] ; station full name
        endif else begin
          index = WHERE(ggroups eq gmags[0], icount)
          if icount eq 0 then begin
            ggroups = [ggroups, gmags[0]]
            ggroupnames = [ggroupnames, gmags[1]]
            gstationgroups = [gstationgroups, n_elements(ggroups)-1]
            gstationcodes = [gstationcodes, strtrim(gmags[2])]
            gstationnames = [gstationnames, strtrim(gmags[3])]
          endif else begin
            gstationgroups = [gstationgroups, index]
            gstationcodes = [gstationcodes, strtrim(gmags[2])]
            gstationnames = [gstationnames, strtrim(gmags[3])]
          endelse
        endelse
      endif
      if count eq 0 then str_all = [str] else str_all = [str_all,str]
      count = count + 1
    ENDWHILE
    FREE_LUN, unit
    gmag_networks = ggroupnames
    gmag_stations = gstationcodes
  endif else begin ; static loading if file is not found
    dprint, 'GMAG stations file not found. Static loading of stations. Missing file: ' + filename
    gmag_networks=['AARI','ASI','AUTUMN','AUTUMNX','CARISMA','CGSM','DTU','GIMA','KYOTO','Leirvogur','MACCS','McMAC','NRCan','PENGUIn','SGU','STEP','TGO','Themis AE', $
      'Themis AE (pre 2015)','Themis EPO','Themis GBO','USGS']
    gmag_stations=['abk','akul','amd','amer','amk','and','arct','atha','atu','benn','bett','bfe','bjn','blc','bmls','bou','brw','bsl','cbb','ccnv','cdrt','chbg', $
      'cigo','cmo','crvr','ded','dik','dmh','dnb','dob','don','drby','eagl','ekat','fcc','fhb','frd','frn','fsim','fsj','fsmi','ftn','fykn','fyts','gako','gbay', $
      'gdh','ghb','gill','gjoa','glyn','gua','hlms','homr','hon','hop','hots','hrp','iglo','inuk','inuv','iqa','jck','kako','kapu','kar','kian','kjpk','kuuj','kuv', $
      'larg','lcl','leth','loys','lres','lrg','lrv','lyfd','lyr','mcgr','mea','nain','nal','naq','new','nor','nrd','nrsq','ott','pang','pbk','pcel','pg1','pg2','pg3', $
      'pg4','pgeo','pina','pine','pks','pokr','ptrs','puvr','radi','rank','rbay','redr','rich','rmus','roe','roth','rvk','salu','satx','schf','sco','sept','shu','sit', $
      'sjg','skt','snap','snkq','sol','sor','stf','stfl','stj','svs','swno','talo','tdc','thl','tik','tool','tpas','trap','tro','tuc','ukia','umq','upn','vic','vldr','whit','whs','wrth','ykc','yknf']
    selected_network=''
  endelse

  if (selected_network[0] ne '') then begin
    gmag_stations = ['']
    for i=0, n_elements(selected_network)-1 do begin
      idx = where(strlowcase(strcompress(ggroupnames,/remove_all)) eq strlowcase(strcompress(selected_network[i],/remove_all)), cidx)
      if (cidx gt 0) then begin
        gmag_stations_sel = gstationcodes[where(gstationgroups eq idx[0])]
        gmag_stations = [gmag_stations, gmag_stations_sel]
      endif
    endfor

    uncal_site = ['amk','and','atu','bfe','bjn','dob','dmh','dnb','don','fhb','gdh','ghb','hop','jck','kar','kuv','lyr','nal','naq','nor','nrd','roe','rvk','sco','skt','sol','sor','stf','svs','tdc','thl','tro','umq','upn']
    matching_sites = strfilter(gmag_stations,uncal_site, count=count)
    if(count gt 0) then begin
      dprint, 'Warning: some data may be uncalibrated.'
    endif
  endif

  gmag_stations = strtrim(gmag_stations)
  gmag_stations = gmag_stations[where(gmag_stations ne '' and gmag_stations ne ' ')]
  gmag_stations = gmag_stations[sort(gmag_stations)]
  gmag_stations = gmag_stations[UNIQ(gmag_stations)]

  gmag_networks = strtrim(gmag_networks)
  gmag_networks = gmag_networks[where(gmag_networks ne '' and gmag_networks ne ' ')]
  gmag_networks = gmag_networks[sort(gmag_networks)]

  gmag_networks = gmag_networks[UNIQ(gmag_networks)]
end