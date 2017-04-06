;+
;PROCEDURE:
;  spd_cdf_compress
;
;PURPOSE:
;  Compresses a cdf file using the CDF utility cdfconvert
;
;PARAMETERS:
;  file_in: (string) Input cdf file. Full path.
;
;KEYWORDS:
;  file_out: (string) Output cdf file. Full path. Optional if replace=1. 
;  replace: if set, replace original file (file_out is ignored)
;  cdfconvert: (string) Full path to cdfconvert executable
;  cdfparams: (string) Parameters for cdfconvert
;  cdf_tmp_dir: (string) Directory for temp files
;  cdf_compress_error: (string) Returns error
;
;OUTPUT:
;  A compressed cdf file
;
;NOTES:
;  The default (optimal) options used with cdfconvert are available only with CDF 3.6.1 and later.
;  
;EXAMPLE:
;  spd_cdf_compress, '/data/tha_l2_fgm_20110101_v01.cdf', '/data/tha_l2_fgm_20110101_v01_temp.cdf', replace=1, cdf_compress_error=cdf_compress_error
;  on windows:
;  spd_cdf_compress, 'c:\temp\in.cdf', 'c:\temp\out.cdf', cdfconvert='C:\CDF Distribution\cdf36_1-dist\bin\cdfconvert.exe', replace=1, cdf_compress_error=cdf_compress_error
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2017-04-05 17:09:29 -0700 (Wed, 05 Apr 2017) $
;$LastChangedRevision: 23123 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_cdf_compress.pro $
;
;-

pro spd_cdf_compress, file_in, file_out=file_out, replace=replace, cdfconvert=cdfconvert, cdfparams=cdfparams, cdf_tmp_dir=cdf_tmp_dir, cdf_compress_error=cdf_compress_error

  ; check input
  cdf_compress_error = ""
  
  if ~keyword_set(replace) || replace eq 0 then replace=0 else replace=1
  
  if ~keyword_set(file_in) then begin
    msg = 'Error: No input cdf file given. Exiting.'
    dprint,  msg
    cdf_compress_error=msg
    return
  endif else begin
    if ~file_test(file_in, /regular) then begin
      msg = 'Error: Input file not found. Exiting. file_in: ' + file_in
      dprint,  msg
      cdf_compress_error=msg
      return
    endif
  endelse
  
  if ~keyword_set(cdf_tmp_dir) then begin
    cdf_temp = '/mydisks/home/thmsoc/' 
    if file_test(cdf_temp, /directory) then begin
      cdf_tmp_dir=cdf_temp
    endif else begin ;if /mydisks/home/thmsoc/ doesn't exist, use the server CDF_TMP dir
      cdf_temp = GETENV('CDF_TMP')
      if file_test(cdf_temp, /directory) then begin
        cdf_tmp_dir = cdf_temp 
      endif
    endelse
  endif
  if ~file_test(cdf_tmp_dir, /directory) then begin
    cdf_tmp_dir = file_dirname(file_in)
  endif
  if strmid(cdf_tmp_dir, 0, /reverse_offset) ne path_sep() then begin
    cdf_tmp_dir = cdf_tmp_dir + path_sep()
  endif
  
  ; if replace is set, then we don't need a file_out
  if (replace eq 1) then begin
     ; file_out = cdf_tmp_dir + file_basename(file_in) + '_temp.cdf'
     file_out = file_in
  endif
   
  if ~keyword_set(file_out) then begin
    msg = 'Error: No output cdf file given. Exiting.'
    dprint,  msg
    cdf_compress_error=msg
    return
  endif

  if ~keyword_set(cdfconvert) then cdfconvert='/usr/local/pkg/cdf-3.6.3_CentOS-6.8/bin/cdfconvert*'
  if ~keyword_set(cdfparams) then cdfparams='-delete -blockingfactor optimal -compressnonepoch -compression "cdf:none"'

  if ~file_test(cdfconvert, /regular) then begin
    msg = 'Error: File cdfconvert not found. Exiting. cdfconvert: ' + cdfconvert
    dprint,  msg
    cdf_compress_error=msg
    return
  endif

  ; compress file
  if !version.os_family eq 'Windows' then begin 
    cmd = 'cdfconvert'  
  endif else begin
    cmd = cdfconvert
  endelse   
  cmd = cmd + ' "' + file_in + '" "' + file_out + '" ' + cdfparams
  print, cmd
  spawn, cmd, cdfmsg 
  dprint, cdfmsg

  if ~file_test(file_out, /regular) then begin
    msg = 'Error: Compression failed. Exiting. file_in: ' + file_in
    dprint, msg
    cdf_compress_error=msg
    return
  endif

  ; replace original file
  if (replace eq 1) then begin
    ; file_move, file_out, file_in, /overwrite, /verbose
    msg = 'Compressed file replaced the uncompressed file. file_in: ' + file_in
    dprint,  msg
  endif else begin
    msg = 'Compressed file was created. file_out: ' + file_out
    dprint,  msg    
  endelse

end