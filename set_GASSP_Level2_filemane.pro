PRO set_GASSP_Level2_filename,project,gloatt,gloatt_val,filename

;;-Standardised filename for Level 2:
;;Variable_Instrument_Project[Database]_PlatformType_PlatformName[StationName]_Startdate_Enddate.nc,
;;dates in format yyyymmdd_hhmmss to be human readable

vartmp=strtrim(gloatt_val[where(gloatt eq 'Species_Short_Name')],2)
variable=strjoin(strsplit(vartmp,'|',/extract),'_')

insttmp=strtrim(gloatt_val[where(gloatt eq 'Instrument')],2)
instrument=strjoin(strsplit(insttmp,'|',/extract),'_')

platform=strtrim(gloatt_val[where(gloatt eq 'Platform')],2)
plattmp=strsplit(strtrim(gloatt_val[where(gloatt eq 'Platform_Name')],2),'|',/extract)
platfmname=strjoin(strsplit(plattmp[0],' ',/extract),'_')

starttime=strtrim(gloatt_val[where(gloatt[*] eq 'Time_Coverage_Start')],2)
endtime  =strtrim(gloatt_val[where(gloatt[*] eq 'Time_Coverage_End'  )],2)
starttmp=strsplit(starttime,' ',/extract,COUNT=nstr)
endtmp=strsplit(endtime,' ',/extract,COUNT=nstr2)
if nstr ge 2 then startdate=strjoin(strsplit(starttmp[0],':',/extract),'')+'_'+$
                            strjoin(strsplit(starttmp[1],':',/extract),'')
if nstr2 ge 2 then enddate=strjoin(strsplit(endtmp[0],':',/extract),'')+'_'+$
                           strjoin(strsplit(endtmp[1],':',/extract),'')
if nstr  eq 1 then startdate=strjoin(strsplit(starttmp[0],':',/extract),'')
if nstr2 ge 1 then enddate=strjoin(strsplit(endtmp[0],':',/extract),'')

filename=variable+'_'+instrument+'_'+project+'_'+platform+$
         '_'+platfmname+'_'+startdate+'_'+enddate+'.nc'

end
