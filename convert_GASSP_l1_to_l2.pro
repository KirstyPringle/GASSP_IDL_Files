;-----MAIN PROCEDURE---------------------------------------------------------------------------

;;IDL code written by Carly Reddington to convert GASSP Level 1 data
;;files to GASSP Level 2 file format. 
;;***Make sure that the "Processed_file_list.txt" file is up-to-date
;;(to produce this file, run the IDL code:
;;Processing_code/count_number_processed_GASSP_files.pro)*****


projarr=['CARIBIC','TRACEP','TRACEA','IMPROVE','A-PAD','SOS','ITCT2004','ITCT2002','TEXAQS2006','TROMPEX','GoAmazon',$
         'SEAC4RS','MAMM','HolmeMoss','HIPPO','RONOCO','BORTAS','AMMA','COPS','Chilbolton','RHaMBLe',$
         'MIRAGE','PEMTropicsB','PEMTropicsA','PASE','ACE1','ACE2','ACEASIA','VOCALS','INTEX-A','INDOEX','ARCTAS',$
         'CLACE6','OP3','EUCAARI','Weybourne','AEGEAN-GAME','ACCACIA','COPE','CAST','CARRIBA',$
         'Melpitz','A-FORCE','CALNEX','NACHTT','Polarstern','EM25','APPRAISE','Bird_Island',$
         'CAREBeijing','PRIDE_PRD','AMAZE-08','WACS2014','WACS2012','UBWOS2012','UBWOS2013',$
         'TEXAQS2000','RITS94','RITS93','NEAQS2004','NEAQS2002','AEROINDO99',$
         'NAURU99','MAGE92','INTEX-B','ICEALOT','EUSAAR','Environment_Canada',$
         'DYNAMO','DC3','ARCPAC2008','AMS_GlobalDatabase','DISCOVERAQ','AOE2001','AOE1996',$
         'PEMWestB','PEMWestA','AMF_stations'] 

projarr=['EBAS_ACTRIS']

;;'EBAS_ACTRIS'

;;;seg fault on 17196, /nfs/a107/ear3clsr/GASSP/Processed_data/AMF_stations/EasternNorthAtlantic/CCN.enaaosccn100C1.a1.20140112.000000.nc

;;****'EBAS_ACTRIS',,****STILL TO PROCESS "NSD" DATA TO LEVEL 1!!!!!!****
;;EBAS_ACTRIS/pm2_5 files are: 826,1323

path='/nfs/a201/earnadr/GASSP/working_code/'
file=path+'Processed_file_list_testing_VOCALS_CPC.txt'
openr,lun,file,/get_lun
header=''
readf,lun,header
filearr=strarr(file_lines(file)-1)
readf,lun,filearr
close,lun & free_lun,lun
nfiles=file_lines(file)-1

time_cf='Time'
lat_cf='Latitude'
lon_cf='Longitude'
alt_cf='Altitude'
rh_cf ='Relative_humidity'
palt_cf='Pressure_altitude';?? barometric_altitude
temp_cf='Air_temperature'
pres_cf='Air_pressure'
dpres_cf='Dynamic_pressure'

outdir='/nfs/a158/earnadr/GASSP/Level_2/'

openw,lunvar,'/nfs/a158/earnadr/GASSP/Level_2/vars1.txt',/get_lun

for i=0L,nfiles-1 do begin
;for i=49910,49910 do begin

   if i eq 17196 then goto,skip_file

   str_arr=strsplit(filearr[i],'/',/extract)
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
    ;help,data,/structure
    ;help, data.(0)
    ;help, data.time

    ntime=n_elements(data.(0))
    num_att=n_elements(globatts)
    num_var=n_elements(varatts[*,0])
    num_varatts=max(nvaratts) ;max nvaratts
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

    if (var_names[0] eq 'JDAY') or (var_names[1] eq 'JDAY') then stop;;goto,skip_file ;************************************

    print,'Variable names specified:',file_vars
    print,'Variable names NetCDF:   ',var_names
    print,'Variable units:',unit_arr
    print,'Species short names:', spec_arr
      
    update_posvar_names_cfcompliant,gloatt,gloatt_val,platform,var_names,$
                                    time_cf,lat_cf,lon_cf,alt_cf,rh_cf,$
                                    palt_cf,temp_cf,pres_cf,dpres_cf,$
                                    time_varname,var_names_cf
 
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
    print, 'Final variable names: ',var_names_cf
    print, ''
    print,'CF-compliant variable names: ',var_names_cf
    
    ;-Rename dimensions to CF names
    for idim=0,n_elements(dim_name)-1 do begin
       dim=where(strmatch(var_names,dim_name[idim],/fold_case) eq 1,dimval)
       if dimval eq 1 then dim_name[idim]=var_names_cf[dim]
    endfor
    print,'CF-compliant dimension names: ',dim_name

    ;-Standardise time stamp
    standardise_timestamp,gloatt,gloatt_val,var_names_cf,time_cf,$
                          unit_arr,miss_arr,data,time_new,timeend,timestart

    
    ;-Convert altitude variable to metres
    if Platform eq 'Aircraft' then $
       convert_altinfeet_to_altinmetres,gloatt,gloatt_val,var_names_cf,$
                                        alt_cf,palt_cf,unit_arr,data

    ;-Convert longitude variable to -180 to 180 degrees
    if Platform eq 'Aircraft' or Platform eq 'Ship' then $
       convert_longitude,gloatt,gloatt_val,var_names_cf,$
                         lon_cf,miss_arr,data

    ;-Standardised unit strings
    standardise_unit_strings,unit_arr,var_names_cf

    ;-Replace units with new units
    for ivar=0,num_var-1 do varatts_val[ivar,where(varatts[ivar,*] eq 'units')]=unit_arr[ivar]

    ;-Get info to create data structure        
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
    gloatt_val[gasspv]='2.0'
    gloatt_val[where(gloatt[*] eq 'Software_Version')]='Level1_to_Level2_IDL'

    ;-Replace "Unknown" data tag fields with "NULL"
    field2replace=where(strmatch(gloatt_val,'unknown',/fold_case) eq 1,nfields)
    if nfields ge 1 then gloatt_val[field2replace]='NULL'

    ;-Standardise GASSP Level 2 filename
    ;set_GASSP_Level2_filename,project,gloatt,gloatt_val,filename_new
    ;fileproc=outdir+proj+'/'+filename_new
	
	file_mkdir, outdir+proj, /NOEXPAND_PATH

    fileproc=outdir+proj+'/'+fileout

    write_netCDF, ss, fileproc, gloatt, gloatt_val, $
                  num_var, nvaratts_new, varatts_new, varatts_val_new, $
                  status, dim_name, dim_size, /clobber
    print, tag_names(ss)
  
    print,'***********************************************************************************************************'
    print,'Created netCDF file: ',fileproc
    print,'***********************************************************************************************************'
    print, ''
	
	printf,lunvar,fileproc
	FOR xx=0,n_elements(var_names_cf)-1 DO printf,lunvar,var_names_cf(xx)
	printf,lunvar,'============================================================='
;stop
skip_file:
 endif

;stop
endfor ;nfiles

close,lunvar
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
