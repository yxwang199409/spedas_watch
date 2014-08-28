;+
;PROCEDURE: thm_crib_part_getspec
;
;  ***** A copy and paste crib *****
;
;PURPOSE:
;  A crib showing how to create energy and angular spectrograms using
;  THM_PART_GETSPEC.
;
;DETAILS
;  THM_PART_GETSPEC is a wrapper that takes user input and creates tplot
;  variables containing energy and/or angular spectra of ESA and SST data. The
;  tplot variables created end in 'en_eflux' for energy spectra and 'an_eflux'
;  plus a suffix corresponding to the type of angular spectrum specified by
;  the ANGLE keyword for angular spectra by default. The user can select a
;  range of probe(s), PROBE, and time range, TRANGE, of interest. The energy
;  range of interest, ERANGE, is specified in eV. The user can also choose to
;  create tplot variable for one or more data types, DATA_TYPE. The phi, PHI,
;  and theta, THETA, ranges of interest, specified in DSL coordinates, can also
;  be input, by the user. SUFFIX specifies a string that will be added to the
;  *an_eflux*' tplot variables.
;
;  If the phi range is greater than 360 degrees, then the phi bins at the
;  beginning of the phi range are added and wrapped around the end of phi
;  range. For example, if phi=[0,420], the phi bins corresponding to 0-60
;  degrees are appended to the top of the plot.
;
;  The START_ANGLE keyword specifies the start of the y-axis (phi). This is
;  useful to center the spectra plot on the y-axis at a particular phi angle.
;  If this keyword is not set, the y-axis starts at the first angle input to
;  the PHI keyword.
;
;  Use the ENERGY and ANGLE keywords to specify whether to create tplot
;  variables for energy and/or angular spectra. The ANGLE keyword is also used
;  to specify the type of angular spectrum created (e.g. phi, theta, pa, gyro).
;  If neither of ENERGY and ANGLE keywords are specified, then both are turned
;  on and the angular spectrum type defaults to phi.
;
;  When set, the AUTOPLOT keyword enables to the tplot variables to be
;  automatically plotted using some simple code located at the end of
;  THM_PART_GETSPEC. The tplot variables created are properly formatted by
;  THM_PART_MOMENTS2 and THM_PART_GETSPEC whether or not AUTOPLOT is set.
;  Setting AUTOPLOT will also create a default tplot title containing the
;  theta, phi, and energy ranges used to create the plot.
;
;  After reading in the user's input, THM_PART_GETSPEC then calls THM_LOAD_SST
;  and/or THM_LOAD_ESA_PKT to load the particle data.  THM_PART_MOMENTS2 is
;  then called to format the spectra data based on the user's input and create
;  the tplot variables.  THM_PART_MOMENTS2 calls THM_PART_GETANBINS in order to
;  determine which energy/angle bins should be turned on/off. If there's a mode
;  change, THM_PART_MOMENTS2 will re-call THM_PART_GETANBINS to account for any
;  changes in the mode's anglemap.
;
;  Pitch angle (ANGLE='pa') and gyrovelocity (ANGLE='gyro') spectra are generated
;  by gridding a globe in a field-aligned coordinate (FAC) system at regular
;  intervals along pitch (latitude) and gyrovelocity (longitude) as specified by
;  the REGRID keyword. These FAC angle bins are then rotated back into the
;  native DSL coordinates of the particle distribution data. The flux assigned
;  to a given FAC angle bin is determined by native angle bin to which the center
;  of FAC angle bin has been rotated. So if a FAC angle bin center is rotated
;  into the 88th angle bin of the probe's particle distribution data, the flux
;  for that FAC angle bin is the same as the flux in angle bin 88 of the
;  particle distribution data. This rotation occurs for each time sample of the
;  probe's particle data.
;
;  The size of the FAC system grid is specified with the REGRID = [m,n], a two-
;  element array in which the first element of the array specifies the number
;  of grid elements in the gyrovelocity (longitudinal) direction while the second
;  element sets he number of grid elements in the pitch (latitudinal)
;  direction.  Increasing the number of elements in the FAC system grid will
;  increase the accuracy of the pitch angle and gyrovelocity angle spectra as it
;  decreases the degree to which the FAC bins overlap into one or more native
;  distribution angle bin. Suitable numbers for m and n are numbers like 2^k.
;  So far, k=2-6 has been tested and work. Other numbers will work provided
;  180/n and 360/m are rational.
;
;  The PITCH and GYRO keywords set the angle range of interest for pitch angle
;  and gyrovelocity spectra plots similarly to the THETA and PHI keywords.
;  Setting PHI and THETA will affect pitch angle and gyrovelocity plot, but the
;  PITCH and GYRO keywords will be ignored when the ANGLE keyword is set to
;  'PHI' or 'THETA'. Energy spectra, generated by using the /ENERGY keyword, will
;  also be affected by PITCH and GYRO settings. 
;
;  The OTHER_DIM keyword specifies the second axis for the field aligned
;  coordinate system, necessary when plotting pitch angle or gyrovelocity spectra.
;  See THM_FAC_MATRIX_MAKE for more info. If the keyword is not set in
;  THM_PART_GETSPEC, OTHER_DIM defaults to 'mphigeo'.
;
;  Also, when calculating pitch angle and/or gyrovelocity spectra
;  THM_FAC_MATRIX_MAKE might require the data be de-gapped in order to
;  calculate the rotation matrix. If so, the /degap keyword and tdegap keywords
;  can passed in the call to THM_PART_GETSPEC.  See TDEGAP and
;  THM_FAC_MATRIX_MAKE for more info.
;
;  The /NORMALIZE keyword will normalize the flux for each time sample in a
;  spectra plot to values between 0 and 1.
;  
;  BADBINS2MASK is a 0-1 array that will be mask SST bins with a NaN to
;  eliminate artifacts such as sun contamination. The array should have the same
;  number of elements as the number of angle bins for a given data type. A 0
;  indicates that will be masked with a NaN. This is basically the output from
;  the bins argument of EDIT3DBINS.
;  
;  The DATAGAP is very useful when you want to overlay burst mode spectra plots
;  over full mode spectra. Set the DATAGAP keyword to a number of seconds that
;  is less than the time gap of the burst data, but greater than the sample
;  interval of the underlying full mode data.  This way the time gaps between
;  the burst mode data won't be interpolated by SPECPLOT and cover up the full
;  mode data between the burst mode data. 
;
;
;NOTES:
;	- All angles are in DSL coordinates
;	- All datatypes are now valid
;   - Theta input must satisfy: -90 < theta[0] < theta[1] < 90
;   - Phi input must be specified in ascending order in degrees
;     (e.g. [270, 450] or [-90, 90] to specify the 'daylight' hemisphere in DSL
;     coordinates)
;   - Incorporates improvements contained in v1.2
;
;CREATED BY:  Bryan Kerr
;VERSION: 1.2
;  $LastChangedBy: pcruce $
;  $LastChangedDate: 2013-09-09 17:20:39 -0700 (Mon, 09 Sep 2013) $
;  $LastChangedRevision: 13005 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/deprecated/thm_crib_part_getspec.pro $
;-


; thm_crib_part_getspec_01
; Example of plotting the angular phi spectrum in phi for 2 days of data
; beginning 12:30pm, June 17, 2007 for probes D and E, for peif and peef data
; for energies between 15 and 40 keV, for all thetas, and for all phi angles.
; Setting the start_angle to -35 degrees sets up tplot variable so that the phi
; angles are plotted from -35 to 325 degrees.

del_data, '*'
thm_part_getspec, probe=['d','e'], trange=['07-06-17/12:30','07-06-19/12:30'], $
                  theta=[-90,90], phi=[0,360], erange=[15000,40000], $
                  data_type=['peif','peef'], start_angle=-35, angle='phi',$
                  an_tnames=an_tnames
             
 tplot,an_tnames
                  




; thm_crib_part_getspec_02
; Example of plotting the angular phi spectrum in phi for 2 days of data beginning
; 12:30pm, June 17, 2007 for probes A and B, for the psif and psef data types
; for all energies between 100 and 1000 eV, a theta angle between -45 and +45
; degrees, and for all phi angles with an additional 90 degrees wrapped to the
; top of the plot.

del_data, '*'
thm_part_getspec, probe=['a', 'b'], trange=['07-06-17/12:30','07-06-19/12:30'], $
                  theta=[-45,45], phi=[0,450], erange=[5e4, 1e6], $
                  data_type=['psif','psef'], angle='phi',$
                  an_tnames=an_tnames,method_clean='automatic'

tplot,an_tnames



; thm_crib_part_getspec_03
; Example of plotting the energy spectrum for 1.5 hours of data beginning
; 10:30am, March 23, 2007 for probes A and E, for the peif, psif, peef, and psef
; data types for all energies for all theta angles, and for dayside phi angles.

; Alternatively, the 'dayside' angles can also be specified as phi=[270,450].


del_data, '*'
thm_part_getspec, probe=['a','e'], trange=['07-03-23/10:30','07-03-23/12'], $
                  theta=[-90,90], phi=[-90,90], $
                  data_type=['peif', 'psif', 'peef', 'psef'], $
                  /energy,en_tnames=en_tnames
                  
tplot,en_tnames




; thm_crib_part_getspec_04
; Example of plotting the angular phi spectrum for 1.5 hours of data beginning
; 10:30am, March 23, 2007 for probes A and E, for the peib, psif, peeb, and psef
; data types for the energy range between 10 and 100 keV, for all theta angles,
; and for all phi angles. A start_angle for phi of 180 degrees is specified to
; center the plot at phi = 360. A suffix, '_march23', is added to all tplot
; variables.

; This example also shows how to create your own plot without using the AUTOPLOT
; keyword.

del_data, '*'
thm_part_getspec, probe=['a','e'], trange=['07-03-23/10:30','07-03-23/12'], $
                  theta=[-90,90], phi=[0,360], start_angle = 180, $
                  data_type=['peib', 'psif', 'peeb', 'psef'], $
                  erange=[10000, 100000], suffix='_march23', angle='phi'

tplot,'th*an_eflux_phi_march23'




; thm_crib_part_getspec_05
; Example plotting full energy and phi angular spectra for full, reduced, and
; burst iESA data
del_data, '*'
thm_part_getspec, probe=['e'], trange=['07-03-23/11:13','07-03-23/12'], $
                  theta=[-90,90], phi=[0,360], start_angle=180, $
                  data_type=['peif','peib','peir'], erange=[0, 100000], $
                  /energy, angle='phi' ,an_tnames=an_tnames,en_tnames=en_tnames
                  
tplot,[an_tnames,en_tnames]


; thm_crib_part_getspec_06
; Example plotting full energy and phi angular spectra for SST and ESA
; reduced data.
del_data, '*'
thm_part_getspec, probe=['e'], trange=['07-06-17/9:50','07-06-17/10:50'], $
                  theta=[-90,90], phi=[0,360], $
                  data_type=['psir','pser','peir','peer'], $
                  /energy, angle='phi',an_tnames=an_tnames,$
                  en_tnames=en_tnames

tplot,[an_tnames,en_tnames]


; thm_crib_part_getspec_07
; Example plotting full eESA theta angular spectra for all 5 probes
del_data, '*'
thm_part_getspec, probe=['a','b','c','d','e'], trange=['07-03-23/11:13','07-03-23/12'], $
                  theta=[-90,90], phi=[0,360], data_type=['peif'], $
                  angle='theta',an_tnames=an_tnames
                  
tplot,an_tnames





; thm_crib_part_getspec_08
; Example plotting low-energy eESA pitch angular spectra for all 5 probes.
del_data, '*'
thm_part_getspec, probe=['a','b','c','d','e'], trange=['07-06-03/01:08','07-06-03/04:20'], $
                  data_type=['peef'], erange=[100,300], angle='pa', regrid=[30,20],$
                  an_tnames=an_tnames
                  
tplot,an_tnames

; Note: to calculate the gyrovelocity spectrum, set angle='gyro'





; thm_crib_part_getspec_09
; Create a tplot variable, thc_pser_an_eflux_phi,containing the phi spectrum
; for 6-angle pser data for probe c.
del_data, '*'
thm_part_getspec, probe=['c'], trange=['08-02-12/03:37','08-02-12/03:45'], $
                  data_type='pser', angle='phi'
tplot,'thc_pser_an_eflux_phi'





; thm_crib_part_getspec_10
; Plot low-energy eESA gyrovelocity spectra for phi angles between 270-360 degrees.
del_data, '*'
thm_part_getspec, probe=['c'], trange=['07-06-03/01:08','07-06-03/03:49'], $
                  pitch=[0,180], $
                  gyro=[0,540], $
                  theta=[-90,90], $
                  phi=[270,360], $
                  other_dim='xgse', $
                  data_type=['peef'], $
                  angle='gyro', regrid=[30,20], erange=[100,300],$
                  an_tnames=an_tnames
                  
tplot,an_tnames




; thm_crib_part_getspec_11
; Plot iSST pitch angle spectra for theta angles between -45 and 45 degrees, and
; normalize the data.
; NOTE: normalize keyword is fully deprecated, fairly easy to using 'calc' see thm_crib_calc.pro
; 
;del_data, '*'
;thm_part_getspec, probe=['c'], trange=['08-02-16/04:50','08-02-16/04:53'], $
;                  ;pitch=[0,180], $
;                  ;gyro=[0,360], $
;                  theta=[-45,45], $
;                  ;phi=[160,180], $
;                  other_dim='xgse', $
;                  /normalize, $
;                  data_type=['psif'], $
;                  angle='pa', /autoplot, regrid=[32,16], /degap, dt=3




; thm_crib_part_getspec_12
; This crib shows how to locate sun-contaminated iSST angle bins, and save the
; bin numbers to an array that can be passed to THM_PART_MOMENTS to mask the
; contaminated bins with NaNs. The whole crib can be copied an pasted at once.
;
;NOTE : badbins2mask keyword is fully deprecated.  Using sun_bins=[binlist] for sst_contamination
; See thm_crib_sst_contamination.pro

;del_data, '*'
;if keyword_set(badbins2mask) then tmp=temporary(badbins2mask) ; clear previous version of BADBINS2MASK for EDIT3DBINS
;sc='c' ; specify probe
;; plot the pitch angle distribution with no masking applied
;thm_part_getspec, probe=sc, trange=['08-02-12/03:37','08-02-12/03:45'], $
;                  data_type='psif', angle='pa', regrid=[32,32], /autoplot
;
;edit3dbins,thm_sst_psif(probe=sc, gettime(/c)), badbins2mask
;; Select the time at which you want to plot the SST data distribution by a
;; single left-click of the mouse. A plot of the distribution will then appear.
;; All angle bins should be turned on (unmasked) as indicated by their black bin
;; numbers. Click the middle-mouse button (scroll-wheel) to turn off (mask) one
;; or more angle bins. Sun-contaminated bins should have much higher values
;; relative to non-contaminated bins, usually appearing red. Right-click when
;; finished.
;
;;plot pitch angle distribution with masked SST bins
;thm_part_getspec, probe=sc, trange=['08-02-12/03:37','08-02-12/03:45'], $
;                  data_type='psif', angle='pa', regrid=[32,32], /autoplot, $
;                  badbins2mask=badbins2mask




; thm_crib_part_getspec_13
; Same as above crib except shows how to work eSST data.
;NOTE : badbins2mask keyword is fully deprecated.  Using sun_bins=[binlist] for sst_contamination
; See thm_crib_sst_contamination.pro

;del_data, '*'
;if keyword_set(badbins2mask) then tmp=temporary(badbins2mask) ; clear previous version of BADBINS2MASK for EDIT3DBINS
;sc='b' ; specify probe
;; plot the pitch angle distribution with no masking applied
;thm_part_getspec, probe=sc, trange=['08-02-13/01:00','08-02-13/05:00'], $
;                  data_type='psef', angle='pa', regrid=[32,32], /autoplot
;
;edit3dbins,thm_sst_psef(probe=sc, gettime(/c)), badbins2mask
;; Select the time at which you want to plot the SST data distribution by a
;; single left-click of the mouse. A plot of the distribution will then appear.
;; All angle bins should be turned on (unmasked) as indicated by their black bin
;; numbers. Click the middle-mouse button (scroll-wheel) to turn off (mask) one
;; or more angle bins. Sun-contaminated bins should have much higher values
;; relative to non-contaminated bins, usually appearing red. Right-click when
;; finished.
;
;;plot pitch angle distribution with masked SST bins
;thm_part_getspec, probe=sc, trange=['08-02-13/01:00','08-02-13/05:00'], $
;                  data_type='psef', angle='pa', regrid=[32,32], /autoplot, $
;                  badbins2mask=badbins2mask
;                  



; thm_crib_part_getspec_14
; Shows how to limit energy spectra to a specified pitch and gyrovelocity range
; in mphigeo field aligned coordinate system. Since the REGRID keyword is not
; specified, it defaults to [16,8]. OTHER_DIM defaults to 'mphigeo' when not
; explicitly specified.

del_data, '*'
thm_part_getspec, probe=['a'], trange=['07-03-23/10:30','07-03-23/12'], $
                  data_type=['peif'], pitch=[75,105], gyro=[150,210], $
                  /energy,an_tnames=an_tnames,en_tnames=en_tnames
                  
 tplot,[an_tnames,en_tnames]

                  
                  

; thm_crib_part_getspec_15
; This crib shows how to combine full and burst mode spectra into one plot by
; overlaying the burst mode data on top of the full mode data.
del_data,'*'

; Set DATAGAP keyword to a number of seconds greater than highest full mode
; sample rate in the timspan (~390 sec), but less than the length of the time gap
; between burst segments (~44 minutes)
thm_part_getspec, probe=['a'], trange=['07-03-23/10:30','07-03-23/12:40'], $
                  theta=[-90,90], phi=[0,360], data_type=['peif','peib'], /energy, datagap=390

; Store the data in a tplot psuedovariable.
store_data,'tha_comb',data=['tha_peif_en_eflux','tha_peib_en_eflux']
ylim,'th*comb',5,23000 ; set y-axis limits for spectra plots
zlim,'th*comb',10,3e6 ; set all spectra to same color scale
ylim,'tha*eflux',5,23000 ; set y-axis limits for spectra plots
zlim,'tha*eflux',10,3e6 ; set all spectra to same color scale

tplot,'tha_comb' ; plot only the combined spectra

; Plot the full, burst, and combined spectra in separate panels.
;tplot,['tha_peif_en_eflux','tha_peib_en_eflux','tha_comb'] 

end

