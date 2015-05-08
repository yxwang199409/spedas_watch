;+
;PROCEDURE:   mvn_swe_sumplot_long
;PURPOSE:
;  Plots time series summary plots of SWEA SPEC data over arbitrarily long
;  time spans.  The result is stored in a single TPLOT variable.
;
;USAGE:
;  mvn_swe_sumplot_long, trange=trange, orbit=orbit
;
;INPUTS:
;
;KEYWORDS:
;
;       TRANGE:       Time range over which load data.  Must have at least two
;                     elements, in any format accepted by time_double().  If
;                     not specified, then load data using the current timespan.
;
;       ORBIT:        Load data by orbit number (overrides TRANGE and TIMESPAN
;                     methods).
;
;       UNITS:        Units for plotting energy spectra.  Default = 'eflux'.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-05-06 17:35:48 -0700 (Wed, 06 May 2015) $
; $LastChangedRevision: 17495 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sumplot_long.pro $
;
;CREATED BY:    David L. Mitchell  2015-05-06
;-
pro mvn_swe_sumplot_long, trange=trange, orbit=orbit, units=units

  @mvn_swe_com
  
  if keyword_set(orbit) then begin
    imin = min(orbit, max=imax)
    trange = mvn_orbit_num(orbnum=[imin-0.5,imax+0.5])
  endif

  tplot_options, get_opt=topt
  tspan_exists = (max(topt.trange_full) gt time_double('2013-11-18'))
  if ((size(trange,/type) eq 0) and tspan_exists) then trange = topt.trange_full

  if (size(trange,/type) eq 0) then begin
    print,"You must specify a time range or an orbit range, or set a timespan."
    return
  endif
  
  if (size(units,/type) ne 7) then units = 'eflux'
  
  oneday = 86400D
  start_day = time_double(time_string(min(trange), prec=-3))
  stop_day = time_double(time_string(max(trange), prec=-3))
  ndays = floor((stop_day - start_day)/oneday) + 1L
  
  tsp = [start_day, (start_day + oneday)]
  ok = 0
  while (not ok) do begin
    mvn_swe_load_l2, tsp, /spec
    mvn_swe_sumplot, /loadonly
    get_data,'swe_a4',data=spec,index=j
    if (j gt 0) then begin
      x = spec.x
      y = spec.y
      v = spec.v
      ok = 1
    endif else begin
      tsp += oneday
      if (tsp[1] gt stop_day) then begin
        print,"No data within specified time range."
        return
      endif
    endelse
  endwhile
  
  while (tsp[1] lt stop_day) do begin
    tsp += oneday
    mvn_swe_load_l2, tsp, /spec
    store_data,'swe_a4',/delete
    mvn_swe_sumplot, /loadonly
    get_data,'swe_a4',data=spec,index=j
    if (j gt 0) then begin
      x = [temporary(x), spec.x]
      y = [temporary(y), spec.y]
    endif
  endwhile
  
  store_data,'swe_a4',data={x:x, y:y, v:v}
  mvn_swe_clear
  store_data,'dC',/delete
  store_data,'dT',/delete
  store_data,'dC_lab',/delete

  return

end