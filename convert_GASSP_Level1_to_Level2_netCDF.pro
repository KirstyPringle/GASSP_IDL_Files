;-----MAIN PROCEDURE---------------------------------------------------------------------------

;;IDL code written by Carly Reddington to convert GASSP Level 1 data
;;files to GASSP Level 2 file format. 
;;***Make sure that the "Processed_file_list.txt" file is up-to-date
;;(to produce this file, run the IDL code:
;;Processing_code/count_number_processed_GASSP_files.pro)*****

;; Updated for version vn2.3

projarr=['CARIBIC','TRACEP','TRACEA','IMPROVE','A-PAD','SOS','ITCT2004','ITCT2002','TEXAQS2006','TROMPEX','GoAmazon',$
         'SEAC4RS','MAMM','HolmeMoss','HIPPO','RONOCO','BORTAS','AMMA','COPS','Chilbolton','RHaMBLe',$
         'MIRAGE','PEMTropicsB','PEMTropicsA','PASE','ACE1','ACE2','ACEASIA','VOCALS','INTEX-A','INDOEX','ARCTAS',$
         'CLACE6','OP3','EUCAARI','Weybourne','AEGEAN-GAME','ACCACIA','COPE','CAST','CARRIBA',$
         'Melpitz','A-FORCE','CALNEX','NACHTT','Polarstern','EM25','APPRAISE','Bird_Island',$
         'CAREBeijing','PRIDE_PRD','AMAZE-08','WACS2014','WACS2012','UBWOS2012','UBWOS2013',$
         'TEXAQS2000','RITS94','RITS93','NEAQS2004','NEAQS2002','AEROINDO99',$
         'NAURU99','MAGE92','INTEX-B','ICEALOT','EUSAAR','Environment_Canada',$
         'DYNAMO','DC3','ARCPAC2008','AMS_GlobalDatabase','DISCOVERAQ','AOE2001','AOE1996',$
         'PEMWestB','PEMWestA','AMF_stations','EBAS_ACTRIS'] 

;;projarr=['VOCALS']
;;projarr=['IMPROVE','A-PAD','EBAS_ACTRIS']
;;projarr=['IMPROVE']
;projarr=['AMF_stations']

;projarr=['EBAS_ACTRIS']
;projarr=['AMS_GlobalDatabase']

;;;seg fault on 17196, /nfs/a107/ear3clsr/GASSP/Processed_data/AMF_stations/EasternNorthAtlantic/CCN.enaaosccn100C1.a1.20140112.000000.nc

;;****'EBAS_ACTRIS',,****STILL TO PROCESS "NSD" DATA TO LEVEL 1!!!!!!****
;;EBAS_ACTRIS/pm2_5 files are: 826,1323

;;path='/nfs/see-fs-02_users/earkpr/arch4/DataVisualisation/GASSP/GASSP_Level_2_Data'
;outdir='/nfs/see-fs-02_users/earkpr/arch4/DataVisualisation/GASSP/GASSP_Level_2_Data/'
outdir='/nfs/see-fs-02_users/earkpr/arch4/DataVisualisation/GASSP/GASSP_Level_2_Data_V1/'

print,outdir

; Take a copy of all files in cwd and copy to path for reference.  Pipe git revision number to file.
SPAWN,'rm GIT_REVISION_Number.dat'
SPAWN,'git log --stat > GIT_REVISION_Number.dat'
SPAWN,'ls' 
SPAWN,'tar -cvzf GASSP_IDL_Files.tar *'
SPAWN,'mv GASSP_IDL_Files.tar /nfs/see-fs-02_users/earkpr/arch4/DataVisualisation/GASSP/GASSP_Level_2_Data_V1/.'
 
;path='/nfs/a201/earnadr/GASSP/working_code/'
;;file=path+'Processed_file_list_latest.txt'
;file='Processed_file_list_latest.txt'
file='Processed_file_list_latest.txt'
;file='Processed_file_list_latest_EBASNumber.csv'
openr,lun,file,/get_lun
header=''
readf,lun,header
filearr=strarr(file_lines(file)-1)

readf,lun,filearr
close,lun & free_lun,lun
nfiles=file_lines(file)-1

print,'filearr =',filearr

;time_cf='Time'
;lat_cf='Latitude'
;lon_cf='Longitude'
;alt_cf='Altitude'
;rh_cf ='Relative_humidity'
;palt_cf='Pressure_altitude';?? barometric_altitude
;temp_cf='Air_temperature'
;pres_cf='Air_pressure'
;dpres_cf='Dynamic_pressure'

time_cf='time'
lat_cf='latitude'
lon_cf='longitude'
alt_cf='altitude'
rh_cf ='relative_humidity'
palt_cf='pressure_altitude';?? barometric_altitude
temp_cf='air_temperature'
pres_cf='air_pressure'
dpres_cf='dynamic_pressure'



;;outdir='/nfs/a158/earnadr/GASSP/Level_2_test/'

;NADR - open a file to write variable names to
;OPENW,lunvar,'/nfs/a158/earnadr/GASSP/Level_2_test/vars1.txt',/get_lun
OPENW,lunvar,'/nfs/see-fs-02_users/earkpr/arch4/DataVisualisation/GASSP/Nigel_Code/Level2/vars1.txt',/get_lun

for i=0L,nfiles-1 do begin
;for i=49910,49910 do begin

   print,' i = ', i
   print,'filearr = ',filearr[i]

   if i eq 17196 then goto,skip_file

   str_arr=strsplit(filearr[i],'/',/extract)
   print,"str_arr  = ",str_arr

   proj=str_arr[5]
   str=WHERE(STRMATCH(projarr,proj,/FOLD_CASE) EQ 1,matchvals)
   project=projarr[str]
   if proj eq 'EBAS_ACTRIS'  then proj='EBAS_ACTRIS/'+str_arr[6]
   if proj eq 'AMF_stations' then proj='AMF_stations/'+str_arr[6]
  
   if matchvals ge 1 then begin ;goto, skip_file;

    filename=filearr[i]
    print,''
    print, filename+',  '+strtrim(i,2)
    fileout=str_arr[6]
    if proj eq 'EBAS_ACTRIS/'+str_arr[6] then fileout=str_arr[7]
    if proj eq 'AMF_stations/'+str_arr[6] then fileout=str_arr[7]
    ;print, fileout

     read_netCDF, filename, data, attributes, status, dim_name, dim_size, $
       gloatt, gloatt_val, varatts, varatts_val, nvaratts
    print, tag_names(data)
    help,data,/structure
    help, data.(0)
    ;help, data.time

    ntime=n_elements(data.(0))
    num_att=n_elements(globatts)
    num_var=n_elements(varatts[*,0])
    num_varatts=max(nvaratts)+2 ;max nvaratts ;;;;;;;;;;;;;NADR added in +2 to account for new atts used for NUM upper and lower diams;;;;;;;;;
    var_names=tag_names(data)
    var_names_cf=strarr(num_var)
	

    ;-Use global and variable attributes to get file info
    time_varname=gloatt_val[where(gloatt[*] eq 'Time_Coordinate')]
    platform    =strtrim (gloatt_val[where(gloatt[*] eq 'Platform')],2)
    spec_arr    =strsplit(gloatt_val[where(gloatt[*] eq 'Species_Short_Name')],'| ',/extract)
    vartag=where(gloatt[*] eq 'File_Var_Name',nvartag)
    if nvartag eq 1 then file_vars=strsplit(gloatt_val[vartag],'| ',/extract)$
    else file_vars=strsplit(gloatt_val[where(gloatt[*] eq 'Output_Variable')],'| ',/extract)

    ;Test for 2D variable names:
    var2D=where(gloatt[*] eq 'Output_Variable_2D',nvar2D) 
    if nvar2D ge 1 then begin
       var2Ds=strsplit(gloatt_val[var2D],'| ',/extract)
       file_vars=[file_vars,var2Ds[0]]
    endif

    nspec=n_elements(spec_arr)
    unit_arr=strarr(num_var)
    for ivar=0,num_var-1 do unit_arr[ivar]=reform(varatts_val[ivar,where(varatts[ivar,*] eq 'units')])
    miss_arr=reform(varatts_val[where(varatts eq 'missing_value')])


    ;KP_Comment:  For station data re-name missing_value to _Fillvalue for cf-compliance
    ;  Just for Station, or all data?   if(platform eq 'Station')then varatts[where(varatts eq 'missing_value')]='_FillValue'
    varatts[where(varatts eq 'missing_value')]='TEMPORARY_FillValue'
    varatts[where(varatts eq '_FillValue')]='TEMPORARY_Fillvalue'    ; Note, change to lower case v.  Edit using nco later.

    if (var_names[0] eq 'JDAY') or (var_names[1] eq 'JDAY') then stop;;goto,skip_file ;************************************

    print,'Variable names specified:',file_vars
    print,'Variable names NetCDF:   ',var_names
    print,'Variable units:',unit_arr
    print,'Species short names:', spec_arr

      
    update_posvar_names_cfcompliant,gloatt,gloatt_val,platform,var_names,$
                                    time_cf,lat_cf,lon_cf,alt_cf,rh_cf,$
                                    palt_cf,temp_cf,pres_cf,dpres_cf,$
                                    time_varname,var_names_cf


    ;;Convert var_names to lower case
    ;var_names = STRLOWCASE(var_names)
    ;print,'VAR_NAMES = ',var_names
 
    ;-Replace variable names with species short names
    variables=where(var_names_cf eq '',varvals)
    if varvals eq nspec then begin
       var_names_cf[variables]=spec_arr
       match_varnames_standardnames,file_vars,spec_arr,var_names_cf
    endif else begin
       print,''
       print, 'Error: Number of species not equal to nvariables'
       if n_elements(file_vars) eq num_var then begin
          print, 'Using variable names: ',file_vars[variables]
          var_names_cf[variables]=file_vars[variables]
          match_varnames_standardnames,file_vars,spec_arr,var_names_cf
       endif
       if (n_elements(file_vars) ne num_var) $
          or (proj eq 'TRACEA') then begin
          print, 'Using NetCDF names: ',var_names[variables]
          var_names_cf[variables]=var_names[variables]
          match_varnames_standardnames,var_names,spec_arr,var_names_cf
       endif
    endelse
    ;print, 'Final variable names: ',var_names_cf
    ;var_names_cf = STRLOWCASE(var_names_cf)
    ;print, 'Final variable names: ',var_names_cf
    ;print, ''
    ;print,'CF-compliant variable names: ',var_names_cf
    
    ;-Rename dimensions to CF names
    for idim=0,n_elements(dim_name)-1 do begin
       dim=where(strmatch(var_names,dim_name[idim],/fold_case) eq 1,dimval)
       if dimval eq 1 then dim_name[idim]=var_names_cf[dim]
    endfor
    print,'CF-compliant dimension names: ',dim_name

    ;-Standardise time stamp
    print,'BEF standardise_timestamp'
    ;print,'gloatt = ',gloatt
    ;;;print,'gloatt_val = ',gloatt_val
    ;print,'var_names_cf = ',var_names_cf
    ;print,'time_cf = ',time_cf
    ;
    standardise_timestamp,gloatt,gloatt_val,var_names_cf,time_cf,$
                          unit_arr,miss_arr,data,time_new,timeend,timestart

    ;print,'time_new =',time_new
    ;print,'timeend =',timeend
    ;print,'timestart=',timestart
    ;print,'AFT standardise_timestamp'
    ;print,'gloatt =',gloatt
    ;print,'gloatt_val = ',gloatt_val
    ;print,'var_names_cf = ',var_names_cf
    ;print,' time_cf = ',time_cf
    ;print,' unit_arr = ',unit_arr
    ;print,' miss_arr = ',miss_arr
    ;print,' data = ',data

    ; EBAS_ACTRIS has time_end as a 1D array, not needed.
    ; Set time_end units from the variable units, and time_end value from the time_new array
    if(projarr[str] eq 'EBAS_ACTRIS')then begin
       timeend = time_new[-1]
       timestart = time_new[0] 
       unit_arr[1] = unit_arr[0]
       ;;print,'timeend = ',timeend,' timestart = ', timestart
    endif

    ; AMS_GlobalDatabase files have zero as missing data attribute value, should be nan or NaN.
    if(projarr[str] eq 'AMS_GlobalDatabase')then begin
       print,'var_names_cf = ',var_names_cf
       print,'miss_arr = ',miss_arr

       for index=0,n_elements(miss_arr)-1 do begin
           print,'in loop index = ',index,miss_arr[index]
           miss_arr[index] = 'NaN'
           print,'in loop after = ',index,miss_arr[index]
           print,''
       endfor
       print,'AFT miss_arr = ',miss_arr
    endif


    ;-Convert altitude variable to metres
    if Platform eq 'Aircraft' then $
       convert_altinfeet_to_altinmetres,gloatt,gloatt_val,var_names_cf,$
                                        alt_cf,palt_cf,unit_arr,data

    ;-Convert longitude variable to -180 to 180 degrees
    if Platform eq 'Aircraft' or Platform eq 'Ship' then $
       convert_longitude,gloatt,gloatt_val,var_names_cf,$
                         lon_cf,miss_arr,data

    ;-Standardised unit strings
    print,"bef standardise_unit_strings"
    standardise_unit_strings,unit_arr,var_names_cf
    print,"aft standardise_unit_strings"
    print,'AFT1 miss_arr = ',miss_arr

    print,"bef Replace units with new units"
    ;-Replace units with new units
    for ivar=0,num_var-1 do varatts_val[ivar,where(varatts[ivar,*] eq 'units')]=unit_arr[ivar]
    print,"aft Replace units with new units"

    ;-Get info to create data structure        
    print,"AAA"
    print,'AFT2 miss_arr = ',miss_arr
    var_ptr=PTRARR(num_var)
    for ivar=0,num_var-1 do begin

       ;Insert time variable separately to ensure it is 'long' data type
       if strmatch(var_names_cf[ivar],'Time*',/fold_case) eq 1 then begin
          if strmatch(var_names_cf[ivar],'Time*',/fold_case) eq 1 then $
             var_ptr[ivar] = PTR_NEW( reform(time_new) )
          if strmatch(var_names_cf[ivar],'Time_End',/fold_case) eq 1 then $ 
             var_ptr[ivar] = PTR_NEW( reform(timeend) )
          if strmatch(var_names_cf[ivar],'Time_Start',/fold_case) eq 1 then $ 
             var_ptr[ivar] = PTR_NEW( reform(timestart) )
       endif else $
          var_ptr[ivar] = PTR_NEW( reform(data.(ivar)) )
    endfor

    ;-Create structure to contain selected variables for netCDF file 
    for ivar=0,num_var-1 do begin
       temp=strjoin(strsplit(var_names_cf[ivar],'-',/extract),'_')
       ;print,temp
       if strmatch(temp,'*<*') eq 1 then temp=STRJOIN(STRSPLIT(temp,'<', /EXTRACT), 'lt')
       if strmatch(temp,'*>*') eq 1 then temp=STRJOIN(STRSPLIT(temp,'>', /EXTRACT), 'gt')
       if strmatch(temp,'*.*') eq 1 then temp=STRJOIN(STRSPLIT(temp,'.', /EXTRACT), 'p')
       var_names_cf[ivar]=temp
       ;print,var_names_cf[ivar]
       ;print, var_names_cf[ivar]
       if ivar eq 0 then ss = CREATE_STRUCT( var_names_cf[ivar], *(var_ptr[ivar]) )
       if ivar ge 1 then ss = CREATE_STRUCT( ss, var_names_cf[ivar], *(var_ptr[ivar]) )
       ;print,tag_names(ss)
    endfor
    
    ;-Add variable attribute to store original variable names
    varatts_new=strarr(num_var,num_varatts+1)
    varatts_val_new=varatts_new
    if n_elements(file_vars) eq num_var then varname_orig=file_vars $
    else varname_orig=var_names
    for ivar=0,num_var-1 do begin
       if nvaratts[ivar] gt 0 then begin
          varatts_new[ivar,0:nvaratts[ivar]-1]=varatts[ivar,0:nvaratts[ivar]-1]
          varatts_new[ivar,nvaratts[ivar]]='original_name'
          varatts_val_new[ivar,0:nvaratts[ivar]-1]=varatts_val[ivar,0:nvaratts[ivar]-1]
          varatts_val_new[ivar,nvaratts[ivar]]=varname_orig[ivar] ;var_names[ivar]
       endif else begin
          varatts_new[ivar,0]='original_name'
          varatts_val_new[ivar,0]=varname_orig[ivar]
       endelse 
    endfor
    nvaratts_new=nvaratts+1

    ;-Standardised GASSP & Software version tags
    gasspv=where(strmatch(gloatt[*],'Gassp_version',/fold_case) eq 1) ;'GASSP_Version'
    gloatt[gasspv]='GASSP_Version'
    gloatt_val[gasspv]='2.2'
    gloatt_val[where(gloatt[*] eq 'Software_Version')]='Level1_to_Level2_IDL'

    ;-Replace "Unknown" data tag fields with "NULL"
    field2replace=where(strmatch(gloatt_val,'unknown',/fold_case) eq 1,nfields)
    if nfields ge 1 then gloatt_val[field2replace]='NULL'

    ;-Standardise GASSP Level 2 filename
    ;set_GASSP_Level2_filename,project,gloatt,gloatt_val,filename_new
    ;fileproc=outdir+proj+'/'+filename_new
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;NADR EDITS START;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;Create the directory needed to store output file
	file_mkdir, outdir+proj, /NOEXPAND_PATH



	;========Select variable(s) to be written to netcdf file==============
	
	;read in lookup table which defines variable types
	OPENR,luntype,'vars_vocals_test3.csv',/get_lun
	
	read_type=''
	type_count=0
	
	;Count number of lines in file
	WHILE ~ EOF(luntype) DO BEGIN
	
		READF,luntype,read_type
		type_count=type_count+1
	ENDWHILE
	CLOSE,luntype
	FREE_LUN,luntype
	var_all = strarr(type_count-1)
	class_all = strarr(type_count-1)
	var_code_all = intarr(type_count-1)
	dep_stat_all = strarr(type_count-1)
	dep_var_all = strarr(type_count-1)
	
	
	;Read in variable name/class/code
	OPENR,luntype,'vars_vocals_test3.csv',/get_lun
	
	type_count=0
	
	WHILE ~ EOF(luntype) DO BEGIN
	
		READF,luntype,read_type
		CASE type_count OF
		0:
		ELSE: BEGIN
		
			tmp=strsplit(read_type,',',/extract)
			var_all(type_count-1)=tmp(0)
			class_all(type_count-1)=tmp(1)
			var_code_all(type_count-1)=fix(tmp(2))
			dep_stat_all(type_count-1)=tmp(3)
			dep_var_all(type_count-1)=tmp(4)
			
			END
		ENDCASE
		
		type_count=type_count+1
		
	ENDWHILE
	
	CLOSE,luntype
	FREE_LUN,luntype
	
	;Match up variables in this file with the full variable list to get variable names, classes and codes
	var=strarr(n_tags(ss))
	class=strarr(n_tags(ss))
	var_code=intarr(n_tags(ss))
	dep_stat=strarr(n_tags(ss))
	dep_var=strarr(n_tags(ss))
	
	ss_tags=tag_names(ss)
	
	FOR tt=0,n_tags(ss)-1 DO BEGIN
	
		;Test for missing variable in lookup table

                ;print,"STRUPCASE(var_all) ",STRUPCASE(var_all)
                ;print,"ss_tags(tt)",ss_tags(tt)
                ;print,"tt = ",tt
		var_test=where(STRUPCASE(var_all) eq ss_tags(tt))
		
		CASE var_test(0) OF
		-1: BEGIN
		
				print, 'Variable not in lookup table - '+ss_tags(tt)
				print, 'Current file - '+filename
				STOP
		
			END
		ELSE: BEGIN
	
				var(tt)=var_all(where(STRUPCASE(var_all) eq ss_tags(tt)))
				class(tt)=class_all(where(STRUPCASE(var_all) eq ss_tags(tt)))
				var_code(tt)=var_code_all(where(STRUPCASE(var_all) eq ss_tags(tt)))
				dep_var(tt)=dep_var_all(where(STRUPCASE(var_all) eq ss_tags(tt)))
				dep_stat(tt)=dep_stat_all(where(STRUPCASE(var_all) eq ss_tags(tt)))
				
			END
		ENDCASE
	
	ENDFOR
	
	;Get ancillary variables that need to be written to every file such as Time etc (code = 1)
	anc_var_inds=where(var_code eq 1)
	anc_var_names=var(anc_var_inds)
	
	;Get variables that need to be written to seperate files (code = 2)
	var_write_inds=where(var_code eq 2)
	var_write_names=var(var_write_inds)
	var_write_class=class(var_write_inds)
	dep_stat_write=dep_stat(where(var_code eq 2))
	dep_var_write=dep_var(where(var_code eq 2))
;	dep_var_inds=where(var_code eq 3)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;Code for cut offs;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;Figure out cuttoff values for NUM and/or NSD variables
	cut_low_tmp=gloatt_val(where(gloatt eq 'Cutoff_Low_Diameter'))
	;cut_low=fltarr(n_elements(cut_low_tmp))
	cut_low_tmp=strsplit(cut_low_tmp,'|',/extract)
	cutsl=where(var_code eq 2)
	cut_low=fltarr(n_elements(cutsl))
	cut_low_unit=strarr(n_elements(cut_low_tmp))
	
	CASE n_elements(cut_low_tmp) OF
	1: BEGIN
			CASE cut_low_tmp(0) OF
			'NULL': cut_low(*) = 0.
			' ': cut_low(*) = 0.
			'  ': cut_low(*) = 0.
			ELSE: BEGIN
							
					;remove ~,<,> if present
					cc=strpos(cut_low_tmp,'~')
					cut_low_tmp=cut_low_tmp.remove(cc,0)
					cc=strpos(cut_low_tmp,'<')
					cut_low_tmp=cut_low_tmp.remove(cc,0)
					cc=strpos(cut_low_tmp,'>')
					cut_low_tmp=cut_low_tmp.remove(cc,0)
					
					cut_low(*)=float(cut_low_tmp(0))
					
					;Deal with units
					
					cl_tmp=strsplit(cut_low_tmp,' ',/extract)
					
					CASE n_elements(cl_tmp) OF
					1: cut_low(*)=float(cut_low_tmp(0))
					ELSE: BEGIN		
					
							IF (cl_tmp(1) eq 'um') THEN cut_low=cut_low*1000. ELSE cut_low(*)=float(cl_tmp(0))
							
				
						END
					ENDCASE
					
					
				END
			ENDCASE
		
	
		END
		
	ELSE: BEGIN

			FOR ch = 0, n_elements(cut_low_tmp)-1 DO BEGIN
				CASE cut_low_tmp(ch) OF
				'NULL': cut_low(ch) = 0.
				' ': cut_low(ch) = 0.
				'  ': cut_low(ch) = 0.
				ELSE: BEGIN
				
						;remove ~,<,> if present
						cc=strpos(cut_low_tmp(ch),'~')
						cut_low_tmp(ch)=cut_low_tmp(ch).remove(cc,0)
						cc=strpos(cut_low_tmp(ch),'<')
						cut_low_tmp(ch)=cut_low_tmp(ch).remove(cc,0)
						cc=strpos(cut_low_tmp(ch),'>')
						cut_low_tmp(ch)=cut_low_tmp(ch).remove(cc,0)
					
						;need to deal with units
						cl_tmp=strsplit(cut_low_tmp(ch),' ',/extract)
					
					
						CASE n_elements(cl_tmp) OF
						1: BEGIN
				
								IF (cut_low_tmp(ch) eq '  ' OR cut_low_tmp(ch) eq ' ' OR cut_low_tmp(ch) eq 'NULL') THEN cut_low(ch)=0. ELSE cut_low(ch)=float(cut_low_tmp(ch))
					
							END
						ELSE: BEGIN
				
								cut_low_unit(ch)=cl_tmp(1)
					
								IF (cl_tmp(1) eq 'um') THEN cut_low(ch)=1000.*float(cl_tmp(0)) ELSE cut_low(ch)=float(cl_tmp(0))
				
							END
						ENDCASE
					END
				ENDCASE
			END
		END
	ENDCASE
	
	cut_high_tmp=gloatt_val(where(gloatt eq 'Cutoff_High_Diameter'))
	cut_high_tmp=strsplit(cut_high_tmp,'|',/extract)
	cutsh=where(var_code eq 2)
	cut_high=fltarr(n_elements(cutsh))
	
	
	CASE n_elements(cut_high_tmp) OF
	1: BEGIN
			CASE cut_high_tmp(0) OF
			'NULL': cut_high(*) = !values.f_infinity
			' ': cut_high(*) = !values.f_infinity
			'  ': cut_high(*) = !values.f_infinity
			ELSE: BEGIN
			
					;remove ~,<,> if present
					cc=strpos(cut_high_tmp,'~')
					cut_high_tmp=cut_high_tmp.remove(cc,0)
					cc=strpos(cut_high_tmp,'<')
					cut_high_tmp=cut_high_tmp.remove(cc,0)
					cc=strpos(cut_high_tmp,'>')
					cut_high_tmp=cut_high_tmp.remove(cc,0)
			
					;Deal with units
					ch_tmp=strsplit(cut_high_tmp,' ',/extract)
					
					CASE n_elements(ch_tmp) OF
					1: cut_high(*)=float(cut_high_tmp(0))
					ELSE: BEGIN
					
							IF (ch_tmp(1) eq 'um') THEN cut_high(*)=1000.*float(ch_tmp(0)) ELSE cut_high(*)=float(ch_tmp(0))
				
						END
					ENDCASE
			
							
					
				END
			ENDCASE
		
	
		END
	
	ELSE: BEGIN
			
				;cut_high=fltarr(n_elements(cut_high_tmp))
				;cut_high_unit=strarr(n_elements(cut_high_tmp))
				
				;Temporary fix for files with no variables to write;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				CASE cutsh(0) OF
				-1: cut_high(*)=!values.f_infinity
				ELSE: BEGIN
			
					;Need to deal with changes in units if present
					FOR ch = 0,n_elements(cut_high_tmp)-1 DO BEGIN
			
						;remove ~,<,> if present
						cc=strpos(cut_high_tmp(ch),'~')
						cut_high_tmp(ch)=cut_high_tmp(ch).remove(cc,0)
						cc=strpos(cut_high_tmp(ch),'<')
						cut_high_tmp(ch)=cut_high_tmp(ch).remove(cc,0)
						cc=strpos(cut_high_tmp(ch),'>')
						cut_high_tmp(ch)=cut_high_tmp(ch).remove(cc,0)
					
						ch_tmp=strsplit(cut_high_tmp(ch),' ',/extract)
					
					
						CASE n_elements(ch_tmp) OF
						1: BEGIN
				
								IF (cut_high_tmp(ch) eq '  ' OR cut_high_tmp(ch) eq ' ' OR cut_high_tmp(ch) eq 'NULL') THEN cut_high(ch)=!values.f_infinity ELSE cut_high(ch)=float(cut_high_tmp(ch))
					
				
								;cut_high(where(cut_high_tmp eq ' '))=!values.f_infinity
								;cut_high(where(cut_high_tmp ne ' '))=fix(cut_high_tmp(where(cut_high_tmp ne ' ')))
				
							END
						ELSE: BEGIN
				
								;cut_high_unit(ch)=ch_tmp(1)
					
								IF (ch_tmp(1) eq 'um') THEN cut_high(ch)=1000.*float(ch_tmp(0)) ELSE cut_high(ch)=float(ch_tmp(0))
				
							END
						ENDCASE
			
			
					END
					END
				ENDCASE

			END
	ENDCASE
	
	;update attributes for variables to include cutt offs
	cuts=where(var_code eq 2)
	
	
	nvaratts_old=nvaratts_new
	nvaratts_new(cuts)=nvaratts_old(cuts)+2
	
	
		FOR n = 0,n_elements(cuts)-1 DO BEGIN
	
			varatts_new(cuts(n),nvaratts_new(cuts(n))-2)='lower_diam'
			varatts_val_new(cuts(n),nvaratts_new(cuts(n))-2)=strcompress(cut_low(n),/remove_all)
		
			varatts_new(cuts(n),nvaratts_new(cuts(n))-1)='upper_diam'
			varatts_val_new(cuts(n),nvaratts_new(cuts(n))-1)=strcompress(cut_high(n),/remove_all)
	
		END


;;;;;;;;;;;END of cut offs code;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
	;Loop round variables to create a file for each
	
	FOR xx =0, n_elements(var_write_inds)-1 DO BEGIN
	
		;Need to recreate the variables that the writing code requires containing only the variable to be written to this particular file
		tmp1="ss2=CREATE_STRUCT('"+anc_var_names(0)+"',ss."+anc_var_names(0)+")"
		tmp2=EXECUTE(tmp1)

		FOR xxx=1,n_elements(anc_var_names)-1 DO BEGIN
		
			tmp1="ss2=CREATE_STRUCT(ss2,'"+anc_var_names(xxx)+"',ss."+anc_var_names(xxx)+")"
			tmp2=EXECUTE(tmp1)
		
		END
		
		;If dealing with a NUM measurement replace the variable name with 'NUM' in the new file
		CASE var_write_class(xx) OF
		'NUM':BEGIN
		
				tmp1="ss2=CREATE_STRUCT(ss2,'"+var_write_class(xx)+"',ss."+var_write_names(xx)+")"
				tmp2=EXECUTE(tmp1)
		
			END
		ELSE: BEGIN
		
				tmp1="ss2=CREATE_STRUCT(ss2,'"+var_write_names(xx)+"',ss."+var_write_names(xx)+")"
				tmp2=EXECUTE(tmp1)
			END
		ENDCASE
		
		
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Deal with dependant variables;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		;Check for dependant variable(s) that need to be written to file
		
		CASE dep_stat_write(xx) OF
		'N': BEGIN
		
				num_var2=n_elements(anc_var_names)+1
				nvaratts_new2=[nvaratts_new(anc_var_inds),nvaratts_new(var_write_inds(xx))]
				zz=size(varatts_new)
				varatts_new2=strarr(n_elements(anc_var_names)+1, zz(2))
		
				FOR xxx=0,n_elements(anc_var_names)-1 DO varatts_new2(xxx,*)=varatts_new(anc_var_inds(xxx),*)
				varatts_new2(n_elements(anc_var_names),*)=varatts_new(var_write_inds(xx),*)
				
				varatts_val_new2=strarr(n_elements(anc_var_names)+1, zz(2))
		
				FOR xxx=0,n_elements(anc_var_names)-1 DO varatts_val_new2(xxx,*)=varatts_val_new(anc_var_inds(xxx),*)
				varatts_val_new2(n_elements(anc_var_names),*)=varatts_val_new(var_write_inds(xx),*)
				
			END
			
		ELSE: BEGIN
				
				dep_write=strsplit(dep_var_write(xx),';',/extract)
				dep_ind=intarr(n_elements(dep_write))
				
				FOR dw=0, n_elements(dep_write)-1 DO dep_ind(dw)=where(var eq dep_write(dw))
				
				CASE dep_ind(0) OF
				-1: BEGIN
				
						num_var2=n_elements(anc_var_names)+1
						nvaratts_new2=[nvaratts_new(anc_var_inds),nvaratts_new(var_write_inds(xx))]
						zz=size(varatts_new)
						varatts_new2=strarr(n_elements(anc_var_names)+1, zz(2))
		
						FOR xxx=0,n_elements(anc_var_names)-1 DO varatts_new2(xxx,*)=varatts_new(anc_var_inds(xxx),*)
						varatts_new2(n_elements(anc_var_names),*)=varatts_new(var_write_inds(xx),*)
				
						varatts_val_new2=strarr(n_elements(anc_var_names)+1, zz(2))
		
						FOR xxx=0,n_elements(anc_var_names)-1 DO varatts_val_new2(xxx,*)=varatts_val_new(anc_var_inds(xxx),*)
						varatts_val_new2(n_elements(anc_var_names),*)=varatts_val_new(var_write_inds(xx),*)

					END
				ELSE: BEGIN
				
						FOR dw=0, n_elements(dep_write)-1 DO BEGIN
				
					
							tmp1="ss2=CREATE_STRUCT(ss2,'"+dep_write(dw)+"',ss."+dep_write(dw)+")"
							tmp2=EXECUTE(tmp1)
							dep_ind(dw)=where(var eq dep_write(dw))
					
						END
				
						num_var2=n_elements(anc_var_names)+1+n_elements(dep_write)
						nvaratts_new2=[nvaratts_new(anc_var_inds),nvaratts_new(var_write_inds(xx)), nvaratts_new(dep_ind)]
						zz=size(varatts_new)
						varatts_new2=strarr(n_elements(anc_var_names)+1+n_elements(dep_write), zz(2))
		
						FOR xxx=0,n_elements(anc_var_names)-1 DO varatts_new2(xxx,*)=varatts_new(anc_var_inds(xxx),*)
						varatts_new2(n_elements(anc_var_names),*)=varatts_new(var_write_inds(xx),*)
						FOR dw=0, n_elements(dep_write)-1 DO varatts_new2(n_elements(anc_var_names)+dw+1,*)=varatts_new(dep_ind(dw),*)
		
						varatts_val_new2=strarr(n_elements(anc_var_names)+1+n_elements(dep_write), zz(2))
		
						FOR xxx=0,n_elements(anc_var_names)-1 DO varatts_val_new2(xxx,*)=varatts_val_new(anc_var_inds(xxx),*)
						varatts_val_new2(n_elements(anc_var_names),*)=varatts_val_new(var_write_inds(xx),*)
						FOR dw=0, n_elements(dep_write)-1 DO varatts_val_new2(n_elements(anc_var_names)+dw+1,*)=varatts_val_new(dep_ind(dw),*)
					END
				ENDCASE
				
			END
		ENDCASE
		
		
		;Create filename used for output file
		
		tmp3=strsplit(fileout,'.',/extract)
	
		fileout2=tmp3(0)
		
		FOR ff = 1,n_elements(tmp3)-2 do fileout2=fileout2+'.'+tmp3(ff)
		
		insttmp=strtrim(gloatt_val[where(gloatt eq 'Instrument')],2)
		instrument=strjoin(strsplit(insttmp,'|',/extract),'_')

		platform=strtrim(gloatt_val[where(gloatt eq 'Platform')],2)
		plattmp=strsplit(strtrim(gloatt_val[where(gloatt eq 'Platform_Name')],2),'|',/extract)
		
		FOR kk=0,4 DO BEGIN
			cc=strpos(plattmp,'/')
		
			CASE cc(0) OF
			-1:
			ELSE:plattmp=plattmp.remove(cc,cc+1)
			ENDCASE
	
		
			cc=strpos(instrument,'/')
		
			CASE cc(0) OF
			-1:
			ELSE:instrument=instrument.remove(cc,cc+1)
			ENDCASE
		
		END
		
		platfmname=strjoin(strsplit(plattmp[0],' ',/extract),'_')
		
		;cc=strpos(platfmname,'/')
		
		;CASE cc(0) OF
		;-1:
		;ELSE:platfmname=platfmname.remove(cc,cc+1)
		;ENDCASE

		starttime=strtrim(gloatt_val[where(gloatt[*] eq 'Time_Coverage_Start')],2)
		endtime  =strtrim(gloatt_val[where(gloatt[*] eq 'Time_Coverage_End'  )],2)
		starttmp=strsplit(starttime,' ',/extract,COUNT=nstr)
		endtmp=strsplit(endtime,' ',/extract,COUNT=nstr2)
		if nstr ge 2 then startdate=strjoin(strsplit(starttmp[0],':',/extract),'')+'_'+strjoin(strsplit(starttmp[1],':',/extract),'')
		if nstr2 ge 2 then enddate=strjoin(strsplit(endtmp[0],':',/extract),'')+'_'+strjoin(strsplit(endtmp[1],':',/extract),'')
		if nstr  eq 1 then startdate=strjoin(strsplit(starttmp[0],':',/extract),'')
		if nstr2 ge 1 then enddate=strjoin(strsplit(endtmp[0],':',/extract),'')

		;filename=variable+'_'+instrument+'_'+project+'_'+platform+'_'+platfmname+'_'+startdate+'_'+enddate+'.nc'
		
		;fileout2=var_write_class(xx)+'_'+var_write_names(xx)+'_'+fileout2+'.nc'
	
		fileout2=var_write_class(xx)+'_'+var_write_names(xx)+'_'+instrument+'_'+project+'_'+platform+'_'+platfmname+'_'+startdate+'_'+enddate+'.nc'
	
		fileproc=outdir+proj+'/'+fileout2.compress()
	
		;Use existing write_netCDF procedure to do writing

		;print, 'tag_names(ss2) = ',tag_names(ss2)

                ; Add in missing standard_name attributes

                ; Check if the air_pressure variable exists
		variable_names = tag_names(ss2)

                print,''
                print,''
                print,''
                print,"BEF PRESS variable_names ",variable_names
                print,size(varatts_val_new2)
                for index=0,n_elements(varatts_val_new2)-1 do begin
                   print,"varatts_val_new2 index", index,'varatts_new2=',varatts_new2[index],' vals=', varatts_val_new2[index]
                endfor

                air_pres_index = WHERE(STRMATCH(variable_names, STRUPCASE('air_pressure'), /FOLD_CASE) EQ 1)
                if(air_pres_index gt 0) then begin
                    ; Check if air_pressure already has a standard_name attribute
                    n_atts = nvaratts_new2[air_pres_index]
                    standard_name_pres_index = WHERE(STRMATCH(varatts_new2[air_pres_index,0:n_atts-1], 'standard_name', /FOLD_CASE) EQ 1)
                    if( standard_name_pres_index eq -1)then begin

                        ; increase size of varatts_new2 array by 1 for standard_name
                        ; make a new larger array varatts_temp, then set varatts_new2=varatts_temp
                        zz=size(varatts_new2)
                        varatts_temp = strarr([zz[0],zz[1]+1])
                        varatts_temp = varatts_new2
                        varatts_new2=strarr([zz[0],zz[1]+1])
                        varatts_new2=varatts_temp

                        nvaratts_new2[air_pres_index] = nvaratts_new2[air_pres_index]+1
                        varatts_new2[air_pres_index,n_atts] = "standard_name"
                        varatts_val_new2[air_pres_index,n_atts] = "air_pressure"

                   endif
                endif

                air_temp_index = WHERE(STRMATCH(variable_names, STRUPCASE('air_temperature'), /FOLD_CASE) EQ 1)
                if(air_temp_index gt 0) then begin
                    ; Check if air_temperature already has a standard_name attribute
                    n_atts = nvaratts_new2[air_temp_index]
                    print,'n_atts = ',n_atts
                    standard_name_temp_index = WHERE(STRMATCH(varatts_new2[air_temp_index,0:n_atts-1], 'standard_name', /FOLD_CASE) EQ 1)
                    if( standard_name_temp_index eq -1)then begin

                        ; increase size of varatts_new2 array by 1 for standard_name
                        ; make a new larger array varatts_temp, then set varatts_new2=varatts_temp
                        zz=size(varatts_new2)
                        varatts_temp = strarr([zz[0],zz[1]+1])
                        varatts_temp = varatts_new2
                        varatts_new2=strarr([zz[0],zz[1]+1])
                        varatts_new2=varatts_temp

                        nvaratts_new2[air_temp_index] = nvaratts_new2[air_temp_index]+1
                        varatts_new2[air_temp_index,n_atts] = "standard_name"
                        varatts_val_new2[air_temp_index,n_atts] = "air_temperature"
                        
                    endif
                endif


                rh_index = WHERE(STRMATCH(variable_names, STRUPCASE('relative_humidity'), /FOLD_CASE) EQ 1)
                if(rh_index gt 0) then begin
                    ; Check if relative_humidity already has a standard_name attribute
                    n_atts = nvaratts_new2[rh_index]
                    standard_name_rh_index = WHERE(STRMATCH(varatts_new2[rh_index,0:n_atts-1], 'standard_name', /FOLD_CASE) EQ 1)
                    if( standard_name_rh_index eq -1)then begin
                        ; increase size of varatts_new2 array by 1 for standard_name
                        ; make a new larger array varatts_temp, then set varatts_new2=varatts_temp
                        zz=size(varatts_new2)
                        varatts_temp = strarr([zz[0],zz[1]+1])
                        varatts_temp = varatts_new2
                        varatts_new2=strarr([zz[0],zz[1]+1])
                        varatts_new2=varatts_temp

                        nvaratts_new2[rh_index] = nvaratts_new2[rh_index]+1
                        varatts_new2[rh_index,n_atts] = "standard_name"
                        varatts_val_new2[rh_index,n_atts] = "relative_humidity"
                    endif
                endif

                print,"AFT PRESS variable_names ",variable_names
                print,size(varatts_val_new2)
                for index=0,n_elements(varatts_val_new2)-1 do begin
                   print,"varatts_val_new2 index", index,'varatts_new2=',varatts_new2[index],' vals=', varatts_val_new2[index]
                endfor
                print,''
                print,''
                print,''

		write_netCDF, ss2, fileproc, gloatt, gloatt_val, $
		          num_var2, nvaratts_new2, varatts_new2, varatts_val_new2, $
		          status, dim_name, dim_size, /clobber
		
		print,'***********************************************************************************************************'
		print,'Created netCDF file: ',fileproc
		print,'***********************************************************************************************************'
		print, ''
	
		PRINTF,lunvar,fileproc
		FOR xy=0,n_elements(var_names_cf)-1 DO printf,lunvar,var_names_cf(xy)
		PRINTF,lunvar,'============================================================='
	ENDFOR
;stop
skip_file:
 endif

;stop
endfor ;nfiles
print,"GGG"

CLOSE,lunvar

;;;;;;;;;;;;;;;;;;;;;;;;;;;NADR END;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;*******NetCDF Error Codes*******
;;% NCDF_CONTROL: Attempt to take the file out of define mode (ENDEF) failed. (NC_ERROR=-45)
;;It's likely that the type of missing value does not match the
;;variable type (i.e. float, double, integer etc.) -> need to go to
;;line 452 and edit cases (note case of double -> default is float).
;;% NCDF_CONTROL: Attempt to take the file out of define mode (ENDEF) failed. (NC_ERROR=-62)
;;File being created is too big (>16G), needs splitting up into
;;smaller chunks.
;;http://www.nco.ncep.noaa.gov/pmb/codes/nwprod/sorc/rtofs_archv2netCDF.fd/netcdf.inc


;;http://www.stsci.edu/~valenti/idl/struct_replace_field.pro

END
