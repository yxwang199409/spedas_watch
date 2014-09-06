;$Author: nikos $
;$Date: 2014-09-03 15:05:59 -0700 (Wed, 03 Sep 2014) $
;$Header: /home/cdaweb/dev/control/RCS/combined_subtitle.pro,v 1.17 2012/05/15 15:57:21 johnson Exp johnson $
;$Locker: johnson $
;$Revision: 15739 $
;+------------------------------------------------------------------------
; NAME: Combined_SUBTITLE
; PURPOSE: Take a prepared string for both the title and pi line  of the subtitle 
; and properly place them on the plot.
; CALLING SEQUENCE:
;       project_subtitle, a, pi_list, title
; INPUTS:
;       a = variable structure returned from read_mycdf which
;	will be used to determine the project and pi affiliation (only if
;	the pi_list is too short to be believable).
;	title = string to place at the top of the gif.
;       pi_list - line containing combine PI's to go at the bottom of the plot file
; OUTPUTS:
;
; KEYWORD PARAMETERS:
;
; AUTHOR:
;       Tami Kovalick QSS Group Inc.
;
; MODIFICATION HISTORY: Initial version is a greatly modified version of 
; project_subtitle.
;
;
;Copyright 1996-2013 United States Government as represented by the 
;Administrator of the National Aeronautics and Space Administration. 
;All Rights Reserved.
;
;------------------------------------------------------------------
PRO combined_subtitle, a, pi_list, title, ps=ps

; write the title (at the top of the page) to the gif file
web_code='CDAWeb'

if keyword_set(ps) then begin
  ; xyouts,!d.x_size/2,!d.y_size-4*!d.y_ch_size,title,/DEVICE,ALIGNMENT=0.5
endif else begin  
   xyouts,!d.x_size/2,!d.y_size-!d.y_ch_size,title,/DEVICE,ALIGNMENT=0.5,charsize=1.5
endelse

;check if the PI_List provided ends w/ an "and", if so, remove it.
  pos = strpos(pi_list, 'and', /reverse_search) ;find the 1st
  if (pos ge (strlen(pi_list)-4)) then pi_list = strmid(pi_list,0,pos-1)

; Generate the subtitle

  pi = ' ' & s='' & b = tagindex('PROJECT',tag_names(a))
  if (b[0] ne -1) then begin
   if(n_elements(a.PROJECT) eq 1) then begin 
    pr = break_mystring(a.PROJECT,delimiter='>')
   endif else begin
    pr = break_mystring(a.PROJECT[0],delimiter='>')
   endelse
    if (pr[0] eq 'ISTP') then begin
      s = 'Key Parameter and Survey data (labels K0,K1,K2)'
      s = s + ' are preliminary browse data.' + '!C'
    endif ;ISTP case
    s = s + ' Generated by '+ web_code + ' on ' + systime()
  endif ; Global attribute Project is found

if (strlen(pi_list) lt 5) then begin
    b = tagindex('PI_NAME',tag_names(a))
    if (b[0] ne -1) then begin
     if(n_elements(a.PI_NAME) eq 1) then pi = a.PI_NAME
    endif
    b = tagindex('PI_AFFILIATION',tag_names(a))
    if (b[0] ne -1) then begin
      if((n_elements(a.PI_AFFILIATION) eq 1) and (a.PI_AFFILIATION[0] ne "")) then $
         pi = pi + ' at '+ a.PI_AFFILIATION 
    endif
  
    pi = 'Please acknowledge data provider, ' + pi + ' and '+ web_code +' when using these data.'
endif else pi = pi_list + ' and '+ web_code +' when using these data.'


;Determine the size of the characters to be used, based on which
;subtitle will be used - if long make characters smaller

if (s ne '') then begin
  c = 1.0 ; initialize
  if ((!d.x_ch_size * strlen(s)) gt !d.x_size) then begin
    b = float(!d.x_ch_size * strlen(s)) / float(!d.x_size)
;original    c = 1.0 - (b/7.0)
    c = 1.0 - (b/11.0)
  endif


;Determine the length of the PI line and if too long, split it into several lines

;TJK 12/8/2006 new code - needed due to really long info. from THEMIS
pi_len = strlen(pi)
number_of_lines = 0
pi_final = ' '

if (c lt 0.75) then string_len = 160 else string_len = 145

if (pi_len gt string_len) then begin
    pi_tmp = strsplit(pi, ' at ',/extract, /regex)
    ;put the 'at' words back into the strings
    for t = 1, (n_elements(pi_tmp)-1) do pi_tmp[t] = ' at ' + pi_tmp[t]

;Now merge some of the lines back together wherever possible (since we don't
;have a lot of room at the bottom of the plot.

    lines = make_array(n_elements(pi_tmp),/string, value='')
    l_num = 0L
    ds = 1L
    lines[0] = pi_tmp[0]        ; initialize 1st line
    while (ds le (n_elements(pi_tmp)-1)) do begin 
        if ((strlen(lines[l_num]) + strlen(pi_tmp[ds])) le string_len) then begin
            lines[l_num] = lines[l_num] + pi_tmp[ds]
        endif else begin
            l_num = l_num + 1
            lines[l_num] = pi_tmp[ds]
        endelse    
        ds = ds + 1
    endwhile
    ;put the carriage returns inbetween the lines and don't include the blanks
    goodlines = where(lines ne '', g_cnt)
    pi_final = lines(goodlines[0]) ; initialize
    for g = 1, g_cnt-1 do pi_final = pi_final + '!C' + lines(goodlines[g])
    ;print, pi_final
    number_of_lines = g_cnt
endif else begin
  pi_final = pi
  number_of_lines = 1L
endelse

; Write the subtitle into the window
  if (c ge 0.75) then begin
      case number_of_lines of
      6: begin
         if keyword_set(ps) then begin
	     ; RCJ 05/09/2007  Bob opted to leave these out for the moment:
             ;xyouts,!d.x_size/2,49L,pi_final,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
             ;xyouts,!d.x_size/2,4L,s,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
	 endif else begin; y distance below was 49L and 4L.  RCJ
             xyouts,!d.x_size/2,49L,pi_final,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
             xyouts,!d.x_size/2,4L,s,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
         endelse
         end
      5: begin
         if keyword_set(ps) then begin
           ;xyouts,!d.x_size/2,47L,pi_final,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
           ;xyouts,!d.x_size/2,6L,s,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
	 endif else begin; y distance below was 47L and 6L.  RCJ
           xyouts,!d.x_size/2,47L,pi_final,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
           xyouts,!d.x_size/2,6L,s,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
         endelse
         end
      4: begin
         if keyword_set(ps) then begin
           ;xyouts,!d.x_size/2,45L,pi_final,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
           ;xyouts,!d.x_size/2,8L,s,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
	 endif else begin; y distance below was 45L and 8L.  RCJ
           xyouts,!d.x_size/2,45L,pi_final,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
           xyouts,!d.x_size/2,8L,s,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
         endelse
         end
      3: begin
         if keyword_set(ps) then begin
           ;xyouts,!d.x_size/2,42L,pi_final,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
           ;xyouts,!d.x_size/2,10L,s,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
	 endif else begin; y distance below was 42L and 10L.  RCJ
           xyouts,!d.x_size/2,42L,pi_final,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
           xyouts,!d.x_size/2,10L,s,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
         endelse
         end
      2: begin
         if keyword_set(ps) then begin
           ;xyouts,!d.x_size/2,!d.y_ch_size*2.75,pi_final,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
           ;xyouts,!d.x_size/2,!d.y_ch_size,s,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
	 endif else begin; y distance below was 32L and 10L.  RCJ
           xyouts,!d.x_size/2,32L,pi_final,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
           xyouts,!d.x_size/2,10L,s,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
         endelse
         end
      else: begin 
	  if not keyword_set(ps) then begin
	      ; y distance below was 22L and 10L.  RCJ
              ;xyouts,!d.x_size/2,!d.y_ch_size*2.,pi_final,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
              ;xyouts,!d.x_size/2,!d.y_ch_size,s,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
              xyouts,!d.x_size/2,22L,pi_final,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
              xyouts,!d.x_size/2,10L,s,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
          endif
         end
      endcase
  endif 

  if (c lt 0.75) then begin ;TJK added to handle label when
				       ;space is limited
    s = ''
    if (pr[0] eq 'ISTP') then begin
      s = 'Key Parameter and Survey data (labels K0,K1,K2) are '
      s = s + 'preliminary browse data.' + '!C'
    endif

    gen_date = ' Generated by '+ web_code + ' on ' + systime()



      case number_of_lines of
      6: begin
         xyouts,!d.x_size/2,49L,pi_final,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
         xyouts,!d.x_size/2,4L,s,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
         end
      5: begin
         xyouts,!d.x_size/2,47L,pi_final,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
         xyouts,!d.x_size/2,6L,s,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
         end
      4: begin
         xyouts,!d.x_size/2,45L,pi_final,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
         xyouts,!d.x_size/2,8L,s,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
         end
      3: begin
         xyouts,!d.x_size/2,42L,pi_final,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
         xyouts,!d.x_size/2,10L,s,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
         end
      2: begin
         xyouts,!d.x_size/2,32L,pi_final,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
         xyouts,!d.x_size/2,10L,s,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
         end
      else: begin 
            xyouts,!d.x_size/2,22L,pi_final,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
            xyouts,!d.x_size/2,10L,s,/DEVICE,ALIGNMENT=0.5,CHARSIZE=c
            end
      endcase



  endif

endif
end
