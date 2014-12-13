;+
;NAME:
; spd_qf_list__define
;
;PURPOSE:
; Defines an object for quality flag lists
;
;CALLING SEQUENCE:
; qf = Obj_New("spd_qf_list", t_start=t_start, t_end=t_end, qf_bits=qf_bits)
;
;INPUT:
; none
;
;KEYWORDS:
; t_start
; t_end
; qf_bits
;
;OUTPUT:
; quality flag list object reference
;
;METHODS:
; qf_merge(qf)  returns an spd_qf_list which is a merge of self with qf
; qf_time_slice(tstart, tend)   returns an spd_qf_list for times between tstart and tend
; get_qf(t)     returns the quality flag for scalar time t
; qf_print()    prints the values of the three arrays
;
;NOTES:
; 1. Quality flags qf_bits for semiclosed time intervals [t_start, t_end) with t_start<t_end and qf_bits>0
; 2. qf_bits = 0 is ignored since it is assumed to be the default
; 3. t_start = t_end is not possible
; 4. Adding two quality flags (bitwise OR) is handled by qf_add() and qf_total()
;
;EXAMPLES:
; x = obj_new('SPD_QF_LIST', t_start=[1262304000.0], t_end=[1263081600.0], qf_bits=[1])
; y = obj_new('SPD_QF_LIST', t_start=[1262649600.0,1263513600.0], t_end=[1263513600.0,1264377600.0], qf_bits=[2,3])
; z = x.qf_merge(y)
; test = z.qf_print()
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2014-12-10 16:47:06 -0800 (Wed, 10 Dec 2014) $
;$LastChangedRevision: 16448 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas/gui/objects/spd_qf_list__define.pro $
;-----------------------------------------------------------------------------------


function spd_qf_list::init, t_start=t_start, t_end=t_end, qf_bits=qf_bits
  self.t_start = ptr_new(t_start)
  self.t_end = ptr_new(t_end)
  self.qf_bits = ptr_new(qf_bits)
  return, 1
end

function spd_qf_list::qf_time_slice, tstart, tend
  ; returns a quality flag list object for times between tstart and tend
  result = obj_new("spd_qf_list")
  self = self.qf_sort()
  t1 = self.t_start()
  t2 = self.t_end()
  qf_bits = self.qf_bits()
  count = self.count()

  if (n_elements(t1) lt 1) then return, result
  last = t2[count-1]
  if ((tstart ge tend) or (tend le t1[0]) or (tstart ge last)) then return, result

  ids1 = max(where(tstart ge t1))
  ids2 = min(where(tstart le t2))
  ide1 = max(where(tend ge t1))
  ide2 = min(where(tend le t2))

  if (ids1 lt 1) then ids1 = 0
  if (ids2 lt 1) then ids2 = 0
  if (ide1 lt 1) then ide1 = 0
  if (ide2 lt 1) then ide2 = 0

  if (ids1 eq ids2) then begin
    t1[ids1] = tstart
  endif
  if (ide1 eq ide2) then begin
    t2[ide2] = tend
  endif

  result = obj_new('SPD_QF_LIST', t_start=t1[ids2:ide2], t_end=t2[ids2:ide2], qf_bits=qf_bits[ids2:ide2])

  return, result
end

function spd_qf_list::qf_merge, qf
  ; merges self with qf
  ; should be called as z = x.merge(y)
  result = obj_new("spd_qf_list")

  if (self.count() eq 0) then begin
    return, qf
  endif else if (qf.count() eq 0) then begin
    return, self
  endif

  if ((self.qf_check() eq 0) or (qf.qf_check() eq 0)) then begin
    dprint, 'Quality flag error: Number of start and end times do not match.', dlevel=1
    return, result
  endif

  t = [self.t_start(), qf.t_start(), self.t_end(), qf.t_end()]
  t = t(sort(t))

  t1 = [t[0]]
  t2 = [t[1]]
  qfb = [self.get_qf(t[0])]
  for i = 1, n_elements(t)-2  do begin
    nt1 = t[i]
    nt2 = t[i+1]
    qf1 = self.get_qf(t[i])
    qf2 = qf.get_qf(t[i])
    nqfb = self.qf_add(qf1, qf2)

    if ((nqfb gt 0) and (nt1 ne nt2)) then begin
      if ((qfb[n_elements(qfb)-1] eq nqfb) and (t2[n_elements(t2)-1] eq nt1)) then begin
        t2[n_elements(t2)-1] = nt2
      endif else begin
        t1 = [t1, nt1]
        t2 = [t2, nt2]
        qfb = [qfb, nqfb]
      endelse
    endif
  endfor

  result = obj_new('SPD_QF_LIST', t_start=t1, t_end=t2, qf_bits=qfb)
  return, result
end

function spd_qf_list::get_qf, t
  ; get qualify flag for time t
  ; time t is assumed to be scalar time
  t1 = self.t_start()
  t2 = self.t_end()
  qf_bits = self.qf_bits()
  idx = where((t ge t1) and (t lt t2))
  if idx[0] eq -1 then begin
    result = 0
  endif else begin
    result = self.qf_total(qf_bits[idx])
  endelse

  return, result
end

function spd_qf_list::qf_check
  ; checks self for consistency
  result = 1
  count = self.count()
  if (count gt 0) then begin
    t_start = self.t_start()
    t_end = self.t_end()
    for i=0, count-1 do begin
      if t_start[i] gt t_end[i] then result = 0
    endfor
  endif else result = 0

  return, result
end

function spd_qf_list::qf_total, qf_bits
  ; add an array of quality flags
  result = 0
  if (n_elements(qf_bits) eq 0) then begin
    result = 0
  endif else begin
    result = qf_bits[0]
    for i=1, n_elements(qf_bits) - 1 do begin
      result = self.qf_add(result, qf_bits[i])
    endfor
  endelse
  return, result
end

function spd_qf_list::qf_add, qf_bits1, qf_bits2
  ; add two quality flags, bitwise OR
  result = qf_bits1 OR qf_bits2
  return, result
end

function spd_qf_list::qf_sort
  ; sorts self

  if (self.count() eq 0) then return, 0

  ; sort for t_start
  t_start = self.t_start()
  t_end = self.t_end()
  qf_bits = self.qf_bits()

  idx = sort(t_start)
  self.t_start = ptr_new(t_start[idx])
  self.t_end = ptr_new(t_end[idx])
  self.qf_bits = ptr_new(qf_bits[idx])

  ; now sort for t_end
  t_start = self.t_start()
  t_end = self.t_end()
  self_bits = self.qf_bits()
  new_t_end = t_end
  new_qf_bits = qf_bits

  for i=1, self.count()-1 do begin
    if t_start[i] eq t_start[i-1] then begin
      idx = where(t_start eq t_start[i])
      idx1 = sort(t_end[idx])
      new_t_end[idx] = t_end[idx[idx1]]
      new_qf_bits[idx] = qf_bits[idx[idx1]]
      i = max(idx)
    endif
  endfor
  self.t_end = ptr_new(new_t_end)
  self.qf_bits = ptr_new(new_qf_bits)

  return, self
end

function spd_qf_list::qf_print
  print, self.t_start()
  print, self.t_end()
  print, self.qf_bits()
  return, 1
end

function spd_qf_list::count
  ; find how many elements are in self
  ; if there are problems, returns 0
  count = 0
  if (*self.t_start ne !NULL) then begin
    if (n_elements(self.t_start()) eq n_elements(self.t_end())) then begin
      if (n_elements(self.t_start()) eq n_elements(self.qf_bits())) then begin
        count = n_elements(self.t_start())
      endif else begin
        dprint, 'Quality flag error: Number of start times do not match with number of quality flags.', dlevel=1
      endelse
    endif else begin
      dprint, 'Quality flag error: Number of start and end times do not match.', dlevel=1
    endelse
  endif
  return, count
end

function spd_qf_list::t_start
  return, *self.t_start
end

function spd_qf_list::t_end
  return, *self.t_end
end

function spd_qf_list::qf_bits
  return, *self.qf_bits
end

pro spd_qf_list__define
  struct = {SPD_QF_LIST,      $
    t_start:  ptr_new(),      $; start time, double precision Unix times, 0.0D
    t_end:    ptr_new(),      $; end time, double precision Unix times, 0.0D
    qf_bits:  ptr_new()       $; quality flag, 32-bit unsigned integer, 0UL
  }
end