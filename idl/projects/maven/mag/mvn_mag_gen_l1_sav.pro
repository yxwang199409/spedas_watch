;+
;This procedure will creat IDL save files from STS files.  It is only intended to be run from a batch job
;-

pro mvn_mag_gen_l1_sav,trange=trange0,load=load,summary=summary,init=init,timestamp=timestamp,verbose=verbose

if keyword_set(init) then begin
  trange0 = [time_double('2013-12-5'), systime(1) ]
  if init lt 0 then trange0 = [time_double('2014-9-22'), systime(1) ]
endif else trange0 = timerange(trange0)

;filename example:  http://sprg.ssl.berkeley.edu/data/maven/data/sci/mag/l1/2014/10/mvn_mag_ql_2014d290pl_20141017_v00_r01.sts

STS_fileformat =  'maven/data/sci/mag/l1/YYYY/MM/mvn_mag_ql_YYYYdDOYpl_YYYYMMDD_v??_r??.sts' 
sav_fileformat =  'maven/data/sci/mag/l1/sav/$RES/YYYY/MM/mvn_mag_l1_pl_$RES_YYYYMMDD.sav'
;   pathformat =  'maven/data/sci/mag/l1/sav/$RES/YYYY/MM/mvn_mag_l1_pl_$RES_YYYYMMDD.sav'


L1fmt = str_sub(sav_fileformat, '$RES', 'full')

res = 86400L
trange = res* double(round( (timerange((trange0+ [ 0,res-1]) /res)) ))         ; round to days
nd = round( (trange[1]-trange[0]) /res) 

if n_elements(load) eq 0 then load =1

for i=0L,nd-1 do begin
  tr = trange[0] + [i,i+1] * res
  prereq_files=''

  mag_l1_files = mvn_pfp_file_retrieve(STS_fileformat,trange=tr,/daily_names)
  mag_l1_file = mag_l1_files[0]
  
  if file_test(mag_l1_file,/regular) eq 0 then continue

  append_array,prereq_files,mag_l1_file

  sav_filename = mvn_pfp_file_retrieve(L1fmt,/daily,trange=tr[0],source=source,verbose=verbose,create_dir=1)

  prereq_info = file_info(prereq_files)
  prereq_timestamp = max([prereq_info.mtime, prereq_info.ctime])
  
  target_info = file_info(sav_filename)
  target_timestamp =  target_info.mtime 

  if prereq_timestamp lt target_timestamp then continue    ; skip if L1 does not need to be regenerated
  dprint,dlevel=1,verbose=verbose,'Generating L1 file: '+sav_filename
  timestamp= systime(1)    ; trigger regeneration of long term plots
  data = mvn_mag_l1_sts_read(mag_l1_file,header=header)
  
  dependents = file_checksum(mag_l1_file,/add_mtime)
  
;  prereq_info = file_checksum(prereq_files,/add_mtime)
  save,file=sav_filename,data,dependents,header,description='Preliminary MAG Data - Not to be used for science purposes. Read header for more info'

endfor
  
end


