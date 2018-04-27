PRO update_posvar_names_cfcompliant,gloatt,gloatt_val,platform,var_names,$
                                    time_cf,lat_cf,lon_cf,alt_cf,rh_cf,$
                                    palt_cf,temp_cf,pres_cf,dpres_cf,$
                                    time_varname,var_names_cf

timevar_str=['*JDAY*','*UTC*','*tim*']
latvar_str=['*lat*']            ;,'*latitude*']
lonvar_str=['*lon*']            ;,'longitude*']
altvar_str=['*alt*','GGALT_NTL']
tempvar_str=['ATX','*temp*','AT_3051','TAT_DI_R','T_STAT','St_Air_Tm*','TS']
rhvar_str=['*rh*','RH','*HUMIDITY*','RH_DLH_WATER','RELHUM','Rel_Hum*']
altpvar_str=['*alt*p*','p*alt*','FMS_ALT_PRES_'] ;,'ALTITUDE_PRESSURE']
presvar_str=['PSXC','*pres*','pre','*stat*pres*','BP_915',$
             'STATICPRS','PS_RVSM','P_STAT','Stat_Pr','PSTATIC','PSMB']
dpresvar_str=['*QCXC*']

timematch=where(strupcase(var_names[*]) eq strupcase(time_varname[0]),tval)
var_names_cf[timematch]=time_cf

if platform eq 'Aircraft' then begin
   alt_varname=gloatt_val[where(gloatt[*] eq 'Vertical_Coordinate')]
   altmatch=where(strupcase(var_names[*]) eq strupcase(alt_varname[0]),alval)
   ;-Test if alt is pressure alt or not
   test_palt=0
   for i=0,n_elements(altpvar_str)-1 do begin
      temp=strmatch(alt_varname,altpvar_str[i],/fold_case)
      if temp gt 0 then test_palt=temp
   endfor
   if strupcase(alt_varname[0]) eq 'ALTITUDE_GPS' then test_palt=0
   if test_palt eq 1 then var_names_cf[altmatch]=palt_cf $
   else var_names_cf[altmatch]=alt_cf

   ;-Reset alt name in attributes to CF name
   gloatt_val[where(gloatt[*] eq 'Vertical_Coordinate')]=STRUPCASE(var_names_cf[altmatch]) 

   if var_names_cf[altmatch] ne palt_cf then begin
      for i=0,n_elements(altpvar_str)-1 do begin
         apmatch=where(strmatch(var_names[*],altpvar_str[i],/fold_case) eq 1,apval)
         if apval eq 2 then begin
            var_names_cf[apmatch[1]]=palt_cf
            goto,skipap
         endif
         if apval eq 1 then begin
            var_names_cf[apmatch]=palt_cf
            goto,skipap
         endif
      endfor
      print, 'Error: No pressure altitude variable'
skipap:
   endif
endif

if (platform eq 'Aircraft') or (platform eq 'Ship') then begin
   lat_varname=gloatt_val[where(gloatt[*] eq 'Latitude_Coordinate')]
   latmatch=where(strupcase(var_names[*]) eq strupcase(lat_varname[0]),ltval)
   var_names_cf[latmatch]=lat_cf
   lon_varname=gloatt_val[where(gloatt[*] eq 'Longitude_Coordinate')]
   lonmatch=where(strupcase(var_names[*]) eq strupcase(lon_varname[0]),lnval)
   var_names_cf[lonmatch]=lon_cf
   ;-Reset Lon / Lat names in attributes to CF names
   gloatt_val[where(gloatt[*] eq 'Latitude_Coordinate')] =STRUPCASE(lat_cf)
   gloatt_val[where(gloatt[*] eq 'Longitude_Coordinate')]=STRUPCASE(lon_cf)
endif

for i=0,n_elements(rhvar_str)-1 do begin
   rhmatch=where(strmatch(var_names[*],rhvar_str[i],/fold_case) eq 1,rhval)
   if rhval eq 1 then begin
      var_names_cf[rhmatch]=rh_cf
      goto,skiprh
   endif
endfor
print, 'Error: No RH variable'
skiprh:
for i=0,n_elements(tempvar_str)-1 do begin
   tpmatch=where(strmatch(var_names[*],tempvar_str[i],/fold_case) eq 1 and $
                 ;;stop CCN_temp_unstable_flag begin converted to "air_temperature":
                 strmatch(var_names[*],'*CCN_temp*',/fold_case) eq 0,tpval);flag  
   if tpval eq 1 then begin
      var_names_cf[tpmatch]=temp_cf
      goto,skiptp
   endif
   if tpval eq 2 then begin
      tpmatch2=where(strmatch(var_names[tpmatch],$
                              '*numflag*'+tempvar_str[i],/fold_case) eq 1,tpval2)
      if tpval2 eq 1 then var_names_cf[tpmatch[tpmatch2]]='numflag_'+temp_cf
      tpmatch3=where(strmatch(var_names[tpmatch],$
                              '*numflag*'+tempvar_str[i],/fold_case) eq 0,tpval3)
      if tpval3 eq 1 then var_names_cf[tpmatch[tpmatch3]]=temp_cf
      goto,skiptp
   endif
endfor
print, 'Error: No temperature variable'
skiptp:
for i=0,n_elements(presvar_str)-1 do begin
   prmatch=where((strmatch(var_names[*],presvar_str[i],/fold_case) eq 1) and $
                 (strmatch(var_names[*],altpvar_str[0],/fold_case) eq 0) and $
                 (strmatch(var_names[*],altpvar_str[1],/fold_case) eq 0),prval)
   if prval eq 2 then begin
      ;empty=where(var_names_cf[prmatch] eq '')
      ;var_names_cf[prmatch[empty]]=pres_cf

      prmatch2=where(strmatch(var_names[prmatch],$
                              'numflag'+presvar_str[i],/fold_case) eq 1,prval2)
      if prval2 eq 1 then var_names_cf[prmatch[prmatch2]]='numflag_'+pres_cf
      prmatch3=where(strmatch(var_names[prmatch],$
                              'numflag'+presvar_str[i],/fold_case) eq 0,prval3)
      if prval3 eq 1 then var_names_cf[prmatch[prmatch3]]=pres_cf
      goto,skippr
   endif
   if prval eq 1 then begin
      var_names_cf[prmatch]=pres_cf
      goto,skippr
   endif
endfor
print, 'Error: No pressure variable'
skippr:
for i=0,n_elements(dpresvar_str)-1 do begin
   dprmatch=where(strmatch(var_names[*],dpresvar_str[i],/fold_case) eq 1,dprval)
   if dprval eq 2 then begin
      var_names_cf[dprmatch[0]]=dpres_cf
      goto,skipdpr
   endif
   if dprval eq 1 then begin
      var_names_cf[dprmatch]=dpres_cf
      goto,skipdpr
   endif
endfor
;print, 'Error: No dynamic pressure variable'
skipdpr:
;;bpmatch=where(strmatch(var_names[*],'BP_915',/fold_case) eq 1,bpval)
;;if bpval eq 1 then var_names_cf[bpmatch]='BAROMETRIC PRESSURE


end

;----------------------------------------------------------------------------------------------
PRO match_varnames_standardnames,file_vars,spec_arr,var_names_cf

;;I'm sure there is a more efficient way of doing this!

;***Time***
vn=where(STRMATCH(file_vars,'*TIME*',/FOLD_CASE) EQ 1,vnval)
if vnval gt 1 then begin
   vn=where(STRMATCH(file_vars,'TIMEEND',/FOLD_CASE) EQ 1,vnval)
   if vnval eq 1 then var_names_cf[vn]='TIME_END'
   vn=where(STRMATCH(file_vars,'END_TIME',/FOLD_CASE) EQ 1,vnval)
   if vnval eq 1 then var_names_cf[vn]='TIME_END'
   vn=where(STRMATCH(file_vars,'Time_E',/FOLD_CASE) EQ 1,vnval)
   if vnval eq 1 then var_names_cf[vn]='TIME_END'
   vn=where(STRMATCH(file_vars,'Time_S',/FOLD_CASE) EQ 1,vnval)
   if vnval eq 1 then var_names_cf[vn]='TIME_START'
   vn=where(STRMATCH(file_vars,'Time_M',/FOLD_CASE) EQ 1,vnval)
   if vnval eq 1 then var_names_cf[vn]='TIME'  
endif
vn=where(STRMATCH(file_vars,'STOP_UTC',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='TIME_END'
vn=where(STRMATCH(file_vars,'MID_UTC',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='TIME_MID'

;;**Number conc**
vn=where(STRMATCH(file_vars,'NONVOLN10',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N10_NONVOL'
vn=where(STRMATCH(file_vars,'totalCNgt5nm_CPC1',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N5'
vn=where(STRMATCH(file_vars,'totalCNgt14nm_CPC2',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N14'
vn=where(STRMATCH(file_vars,'nonvolCNgt10nm_CPCA3',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N10_NONVOL'
vn=where(STRMATCH(file_vars,'CN_5_NUMBER',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N5'
vn=where(STRMATCH(file_vars,'CN>4_NM',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N4'
vn=where(STRMATCH(file_vars,'UNHEATED_CN>14_NM',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N14'
vn=where(STRMATCH(file_vars,'HEATED_CN>14_NM',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N14_NONVOL'
vn=where(STRMATCH(file_vars,'CN>3NM',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N3'
vn=where(STRMATCH(file_vars,'CNGT3NM',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N3'
vn=where(STRMATCH(file_vars,'CN>10NM',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N10'
vn=where(STRMATCH(file_vars,'NGT50NM',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N50'
vn=where(STRMATCH(file_vars,'NGT70NM',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N70'

;;also need to convert Ntot**;;could be N8,N10...
;vn=where(STRMATCH(file_vars,'NSUB',/FOLD_CASE) EQ 1,vnval) ;;Clarke data TOO RISKY: could be N8TO750, N10TO750, N150TO750
;if vnval eq 1 then var_names_cf[vn]='N10TO750'

vn=where(STRMATCH(file_vars,'NCOA',/FOLD_CASE) EQ 1,vnval) ;;Clarke data ***risky***
if vnval eq 1 then var_names_cf[vn]='N750'
vn=where(STRMATCH(file_vars,'CNGT10NM',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N10'
vn=where(STRMATCH(file_vars,'CN>10NM_NONVOL',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N10_NONVOL'
vn=where(STRMATCH(file_vars,'CNGT10NM_NONVOL',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N10_NONVOL'
vn=where(STRMATCH(file_vars,'NONVOLN10',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N10_NONVOL'
vn=where(STRMATCH(file_vars,'CPC3025',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N3' 
vn=where(STRMATCH(file_vars,'CPC3010',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N10'
vn=where(STRMATCH(file_vars,'CPC3010_DIL_FLAG',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N10_DIL_FLAG'
vn=where(STRMATCH(file_vars,'UCN_3025',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N3'
vn=where(STRMATCH(file_vars,'CNC_CONC',/FOLD_CASE) EQ 1,vnval);;CPC, FAAM
if vnval eq 1 then var_names_cf[vn]='N3'
vn=where(STRMATCH(file_vars,'CNC_FLAG',/FOLD_CASE) EQ 1,vnval);;CPC FLAG, FAAM
if vnval eq 1 then var_names_cf[vn]='N3_FLAG'
vn=where(STRMATCH(file_vars,'N_CPC_1',/FOLD_CASE) EQ 1,vnval);;CPC, AMF stations ***RISKY***
if vnval eq 1 then var_names_cf[vn]='N10'
vn=where(STRMATCH(file_vars,'total_CN',/FOLD_CASE) EQ 1,vnval);;CPC, AMAZE ***risky***
if vnval eq 1 then var_names_cf[vn]='N20'
vn=where(STRMATCH(file_vars,'UF_AEROSOL',/FOLD_CASE) EQ 1,vnval);;CPC, PEMTropicsA ***risky***
if vnval eq 1 then var_names_cf[vn]='N4'
vn=where(STRMATCH(file_vars,'F_AER_UNH',/FOLD_CASE) EQ 1,vnval);;CPC, PEMTropicsA
if vnval eq 1 then var_names_cf[vn]='N15'
vn=where(STRMATCH(file_vars,'F_AER_H',/FOLD_CASE) EQ 1,vnval);;CPC, PEMTropicsA
if vnval eq 1 then var_names_cf[vn]='N15_NONVOL'
vn=where(STRMATCH(file_vars,'PN_TOTAL_PARTICLES_STP',/FOLD_CASE) EQ 1,vnval);;PCASP, PEMTropicsB
if vnval eq 1 then var_names_cf[vn]='N100_STP'
vn=where(STRMATCH(file_vars,'PN_TOTAL_PARTICLES_AMBIENT',/FOLD_CASE) EQ 1,vnval);;PCASP, PEMTropicsB
if vnval eq 1 then var_names_cf[vn]='N100_AMB'
vn=where(STRMATCH(file_vars,'INTEGN_DMOB_PSL_SMPS_LARGE',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N10TO340'
vn=where(STRMATCH(file_vars,'DMA_50C_number_0.007<_Dp<_0.1um',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N7TO100'
vn=where(STRMATCH(file_vars,'OPC_50C_number_0.1<_Dp<_20.0um',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N100'
vn=where(STRMATCH(file_vars,'Number_dry_.1-.75',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N100TO750'
vn=where(STRMATCH(file_vars,'Number_.75-2',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N750TO2000'
vn=where(STRMATCH(file_vars,'Number_2-5',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N2000TO5000'
vn=where(STRMATCH(file_vars,'Number_5-20',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='N5000'


;;**Size distribution**
vn=where(STRMATCH(file_vars,'CN_size_distribution',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NSD'
vn=where(STRMATCH(file_vars,'CCN_SIZE_DISTRIBUTION',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CCN_NSD'
vn=where(STRMATCH(file_vars,'SIZE_DISTRIBUTION',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NSD'
vn=where(STRMATCH(file_vars,'Bin_Diam',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='DP_MID'
vn=where(STRMATCH(file_vars,'MIDPT_DIAM',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='DP_MID'
vn=where(STRMATCH(file_vars,'MID_DIAM',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='DP_MID'
vn=where(STRMATCH(file_vars,'CON_M',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NSD'
vn=where(STRMATCH(file_vars,'CON',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]=spec_arr[0]
vn=where(STRMATCH(file_vars,'DP',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='DP_MID'
vn=where(STRMATCH(file_vars,'DP_M',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='DP_MID_RT'
vn=where(STRMATCH(file_vars,'DP_REF',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='DP_EDGE'
vn=where(STRMATCH(file_vars,'DP_B',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='DP_EDGE'
vn=where(STRMATCH(file_vars,'NUMDIST',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NSD'
vn=where(STRMATCH(file_vars,'NUMDIST_DMA_300C',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NSD_DMA_NONVOL'
vn=where(STRMATCH(file_vars,'NUMDIST_DMA_OPC',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NSD_DMA_OPC'

;;**SP2**
vn=where(STRMATCH(file_vars,'INCAND_N',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_NUM'
vn=where(STRMATCH(file_vars,'INCAND_S',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_NUM_SC'
vn=where(STRMATCH(file_vars,'INCAND_MASS',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_MASS'
vn=where(STRMATCH(file_vars,'INCAND_MASS_S',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_MASS_SC'
vn=where(STRMATCH(file_vars,'INCAND_N_M',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_NSD'
vn=where(STRMATCH(file_vars,'INCAND_MASS_M',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_MSD'
vn=where(STRMATCH(file_vars,'CNCIND',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_NUM'
vn=where(STRMATCH(file_vars,'INCANDNUM',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_NUM'
vn=where(STRMATCH(file_vars,'MASSIND',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_MASS'
vn=where(STRMATCH(file_vars,'INCANDMASS',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_MASS'
vn=where(STRMATCH(file_vars,'cncNoInd',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='SCAT_NUM'
vn=where(STRMATCH(file_vars,'ScatNum',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='SCAT_NUM'
vn=where(STRMATCH(file_vars,'massNoInd',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='SCAT_MASS'
vn=where(STRMATCH(file_vars,'ScatMass',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='SCAT_MASS'
vn=where(STRMATCH(file_vars,'BC_ng_m3',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_MASS'
vn=where(STRMATCH(file_vars,'BC_ng_kg',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_MMR'
vn=where(STRMATCH(file_vars,'BC',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_MASS'
vn=where(STRMATCH(file_vars,'MASSCONC_RBC',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_MASS'
vn=where(STRMATCH(file_vars,'MASSCONC_RBC_STP',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_MASS_STP'
vn=where(STRMATCH(file_vars,'BlackCarbonMassConcentration',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_MASS'
vn=where(STRMATCH(file_vars,'BC_M',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_MASS'
vn=where(STRMATCH(file_vars,'INCMASS',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_MASS'
vn=where(STRMATCH(file_vars,'INCNUM',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_NUM'
vn=where(STRMATCH(file_vars,'INCMASS5',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_MASS_5'
vn=where(STRMATCH(file_vars,'INCMASS15',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_MASS_15'
vn=where(STRMATCH(file_vars,'INCNUM5',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_NUM_5'
vn=where(STRMATCH(file_vars,'INCNUM15',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='BC_NUM_15'

;;**CATIONS/ANIONS**
vn=where(STRMATCH(file_vars,'SO4_1950',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='SO4_PM1'
vn=where(STRMATCH(file_vars,'NO3_1947',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NO3_PM1'
vn=where(STRMATCH(file_vars,'CL_1944',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CHL_PM1'
vn=where(STRMATCH(file_vars,'NSSSO4_1953',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NSSSO4_PM1'
vn=where(STRMATCH(file_vars,'NH4_1923',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NH4_PM1'
vn=where(STRMATCH(file_vars,'NA_1920',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NA_PM1'
vn=where(STRMATCH(file_vars,'SO4_1952',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='SO4_PM10'
vn=where(STRMATCH(file_vars,'NO3_1949',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NO3_PM10'
vn=where(STRMATCH(file_vars,'CL_1946',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CHL_PM10'
vn=where(STRMATCH(file_vars,'NSSSO4_1955',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NSSSO4_PM10'
vn=where(STRMATCH(file_vars,'NH4_1925',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NH4_PM10'
vn=where(STRMATCH(file_vars,'NA_1922',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NA_PM10'

vn=where(STRMATCH(file_vars,'SULFATE',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='SO4'
vn=where(STRMATCH(file_vars,'NITRATE',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NO3'
vn=where(STRMATCH(file_vars,'CHLORIDE',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CHL'
vn=where(STRMATCH(file_vars,'AMMONIUM',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NH4'
vn=where(STRMATCH(file_vars,'SODIUM',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NA'


;;**Mass concentration**
vn=where(STRMATCH(file_vars,'SUBEC',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='EC_PM1'
vn=where(STRMATCH(file_vars,'SUBOC',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='OC_PM1'
vn=where(STRMATCH(file_vars,'SUB_2_5_EC',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='EC_PM2p5'
vn=where(STRMATCH(file_vars,'SUB_2_5_OC',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='OC_PM2p5'
vn=where(STRMATCH(file_vars,'PM_2_5',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='PM2p5'
vn=where(STRMATCH(file_vars,'PM_12_5',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='PM12P5'
vn=where(STRMATCH(file_vars,'PM25_conc',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='PM2p5'
vn=where(STRMATCH(file_vars,'pm25_mass',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='PM2p5'

print,var_names_cf[vn]


vn=where(STRMATCH(file_vars,'SUBMASS',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='PM1'
vn=where(STRMATCH(file_vars,'SUPMASS',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='PM1TO10'

;;**AMS**
vn=where(STRMATCH(file_vars,'SULFATE_LT_1UM_AMS',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='SO4'
vn=where(STRMATCH(file_vars,'ORG_LT_1UM_AMS',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='ORG'
vn=where(STRMATCH(file_vars,'NITRATE_LT_1UM_AMS',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NO3'
vn=where(STRMATCH(file_vars,'AMMONIUM_LT_1UM_AMS',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NH4'
vn=where(STRMATCH(file_vars,'CHLORIDE_LT_1UM_AMS',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CHL'
vn=where(STRMATCH(file_vars,'AMS_SO4',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='SO4'
vn=where(STRMATCH(file_vars,'AMS_ORG',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='ORG'
vn=where(STRMATCH(file_vars,'AMS_NO3',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NO3'
vn=where(STRMATCH(file_vars,'AMS_NH4',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NH4'
vn=where(STRMATCH(file_vars,'AMS_CHL',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CHL'
vn=where(STRMATCH(file_vars,'AMS_SO4_all',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='SO4'
vn=where(STRMATCH(file_vars,'AMS_Org_all',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='ORG'
vn=where(STRMATCH(file_vars,'AMS_NO3_all',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NO3'
vn=where(STRMATCH(file_vars,'AMS_NH4_all',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NH4'
vn=where(STRMATCH(file_vars,'AMS_Chl_all',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CHL'
vn=where(STRMATCH(file_vars,'Sulfate-lt-1um_AMS-60s',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='SO4'
vn=where(STRMATCH(file_vars,'Org-lt-1um_AMS-60s',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='ORG'
vn=where(STRMATCH(file_vars,'Nitrate-lt-1um_AMS-60s',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NO3'
vn=where(STRMATCH(file_vars,'Ammonium-lt-1um_AMS-60s',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NH4'
vn=where(STRMATCH(file_vars,'Chloride-lt-1um_AMS-60s',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CHL'
vn=where(STRMATCH(file_vars,'AMSSO4',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='SO4'
vn=where(STRMATCH(file_vars,'AMSORG',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='ORG'
vn=where(STRMATCH(file_vars,'AMSNO3',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NO3'
vn=where(STRMATCH(file_vars,'AMSNH4',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NH4'
vn=where(STRMATCH(file_vars,'AMSCHL',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CHL'
vn=where(STRMATCH(file_vars,'ORGANIC_MASS',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='ORG'
vn=where(STRMATCH(file_vars,'SULPHATE_TOTAL',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='SO4'
vn=where(STRMATCH(file_vars,'SUB25SO4',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='SO4'
vn=where(STRMATCH(file_vars,'SUB25NO3',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NO3'
vn=where(STRMATCH(file_vars,'SUB25NH4',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='NH4'

;;**CCN**
vn=where(STRMATCH(file_vars,'CCN_below0_08',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CCN_LT0P08'
vn=where(STRMATCH(file_vars,'CCN_over0_65',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CCN_GT0P65'
vn=where(STRMATCH(file_vars,'CCNlt0_3',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CCN_LT0P3'
vn=where(STRMATCH(file_vars,'CCNgt0_8',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CCN_GT0P8'
vn=where(STRMATCH(file_vars,'CCN0_02*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_02', '_0P02')
vn=where(STRMATCH(file_vars,'CCN0_08*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_08', '_0P08')
vn=where(STRMATCH(file_vars,'CCN0_2*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_2', '_0P2')
vn=where(STRMATCH(file_vars,'CCN0_6*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_6', '_0P6')
vn=where(STRMATCH(file_vars,'CCN0_04',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CCN_0P04'
vn=where(STRMATCH(file_vars,'CCNtot*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('tot', '')
vn=where(STRMATCH(file_vars,'CCN0_08to0_23',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CCN_0P08to0P23'
vn=where(STRMATCH(file_vars,'CCN0_23to0_43',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CCN_0P23to0P43'
vn=where(STRMATCH(file_vars,'CCN0_43to0_65',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CCN_0P43to0P65'
vn=where(STRMATCH(file_vars,'CCN0_08to0_13',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CCN_0P08to0P13'
vn=where(STRMATCH(file_vars,'CCN0_13to0_18',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CCN_0P13to0P18'
vn=where(STRMATCH(file_vars,'CCN0_18to0_23',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='CCN_0P18to0P23'
vn=where(STRMATCH(file_vars,'SSc_percent',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='SS'

;; vn=where(STRMATCH(file_vars,'',/FOLD_CASE) EQ 1,vnval)
;; if vnval eq 1 then var_names_cf[vn]=''
;vn=where(STRMATCH(file_vars,'CCN0_2',/FOLD_CASE) EQ 1,vnval)
;if vnval eq 1 then var_names_cf[vn]='CCN_0P2' ;CCN0_2_inverted ;CCN0_2_measured
;vn=where(STRMATCH(file_vars,'CCN0_08',/FOLD_CASE) EQ 1,vnval)
;if vnval eq 1 then var_names_cf[vn]='CCN_0P08' ;CCN0_08_measured ;CCN0_08_inverted
;vn=where(STRMATCH(file_vars,'CCN0_02',/FOLD_CASE) EQ 1,vnval)
;if vnval eq 1 then var_names_cf[vn]='CCN_0P02'
;vn=where(STRMATCH(file_vars,'CCN0_02_measured',/FOLD_CASE) EQ 1,vnval)
;if vnval eq 1 then var_names_cf[vn]='CCN_0P02_measured';CCN0_02_inverted
;vn=where(STRMATCH(file_vars,'CCN0_6',/FOLD_CASE) EQ 1,vnval)
;if vnval eq 1 then var_names_cf[vn]='CCN_0P6' ;CCN0_6_measured ;CCN0_6_inverted
;vn=where(STRMATCH(file_vars,'CCNtot',/FOLD_CASE) EQ 1,vnval)
;if vnval eq 1 then var_names_cf[vn]='CCN' ;CCNtot_measured ;CCNtot_inverted

;;Below conditions could be simplified to reduce number of lines of code
vn=where(STRMATCH(file_vars,'*0_06*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_06', '0P06')
vn=where(STRMATCH(file_vars,'*0_09*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_09', '0P09')
vn=where(STRMATCH(file_vars,'*0_11*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_11', '0P11')
vn=where(STRMATCH(file_vars,'*0_16*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_16', '0P16')
vn=where(STRMATCH(file_vars,'*0_17*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_17', '0P17')
vn=where(STRMATCH(file_vars,'*0_18*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_18', '0P18')
vn=where(STRMATCH(file_vars,'*0_28*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_28', '0P28')
vn=where(STRMATCH(file_vars,'*0_29*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_29', '0P29')
vn=where(STRMATCH(file_vars,'*0_30*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_30', '0P30')
vn=where(STRMATCH(file_vars,'*0_32*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_32', '0P32')
vn=where(STRMATCH(file_vars,'*0_35*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_35', '0P35')
vn=where(STRMATCH(file_vars,'*0_37*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_37', '0P37')
vn=where(STRMATCH(file_vars,'*0_47*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_47', '0P47')
vn=where(STRMATCH(file_vars,'*0_48*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_48', '0P48')
vn=where(STRMATCH(file_vars,'*0_50*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_50', '0P50')
vn=where(STRMATCH(file_vars,'*0_56*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_56', '0P56')
vn=where(STRMATCH(file_vars,'*0_63*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_63', '0P63')
vn=where(STRMATCH(file_vars,'*0_65*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_65', '0P65')
vn=where(STRMATCH(file_vars,'*0_73*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_73', '0P73')
vn=where(STRMATCH(file_vars,'*0_74*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_74', '0P74')
vn=where(STRMATCH(file_vars,'*0_80*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_80', '0P80')
vn=where(STRMATCH(file_vars,'*0_91*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_91', '0P91')
vn=where(STRMATCH(file_vars,'*0_94*',/FOLD_CASE) EQ 1,vnval)
if vnval ge 1 then var_names_cf[vn] = var_names_cf[vn].Replace('0_94', '0P94')


;vn=where(STRMATCH(file_vars,'NUM',/FOLD_CASE) EQ 1,vnval)
;if vnval ge 1 then var_names_cf[vn] = 'num'
;vn=where(STRMATCH(file_vars,'ORG',/FOLD_CASE) EQ 1,vnval)
;if vnval ge 1 then var_names_cf[vn] = 'org'
;vn=where(STRMATCH(file_vars,'SO4',/FOLD_CASE) EQ 1,vnval)
;if vnval ge 1 then var_names_cf[vn] = STRLOWCASE('SO4')



;**Position variables (not identified previously**
vn=where(STRMATCH(file_vars,'LAT*',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='LATITUDE'
vn=where(STRMATCH(file_vars,'LONGT*',/FOLD_CASE) EQ 1,vnval)
if vnval eq 1 then var_names_cf[vn]='LONGITUDE'


print,"End of match"

print,"file_vars = ",file_vars
print,"spec_arr = ",spec_arr
print,"var_names_cf = ",var_names_cf

;var_names_cf = STRLOWCASE(var_names_cf)
;print,"var_names_cf = ",var_names_cf

print,"***************"
print,""
end
;----------------------------------------------------------------------------------------------
