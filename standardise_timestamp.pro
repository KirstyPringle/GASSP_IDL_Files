PRO standardise_timestamp,gloatt,gloatt_val,var_names_cf,time_cf,$
                          unit_arr,miss_arr,data,time_new,timeend,timestart

tind=where(strmatch(var_names_cf,time_cf,/fold_case) eq 1)
time=data.(tind)
timeend=time
timestart=time
tinfo=strsplit(unit_arr[tind],',- :',/extract)
print, 'Time stamp info: ',tinfo[0]+' '+tinfo[1]+' '+tinfo[2]+'-'+tinfo[3]+'-'+tinfo[4]+','+tinfo[5]+':',tinfo[6]+':'+tinfo[7]
if tinfo[2] ne '1970' then begin
   if tinfo[4] eq '00' then begin
      startdate=JULDAY(tinfo[3],'01',tinfo[2],tinfo[5],tinfo[6],tinfo[7])-1
      caldat,startdate,mntmp,dytmp,yrtmp
      print, startdate,dytmp,mntmp,yrtmp
   endif else startdate=JULDAY(tinfo[3],tinfo[4],tinfo[2],tinfo[5],tinfo[6],tinfo[7])
   ;;Month , Day    , Year   , Hour   , Minute , Second
   jultime = startdate - JULDAY(1,1,1970,0,0,0)
   
   dy_test=strmatch(tinfo[0],'*days*',/fold_case)
   if dy_test eq 1 then begin
      diff=time[1]-time[0]
      if ((size(time,/type) eq 4) or (size(time,/type) eq 5))$ ;FLOAT or DOUBLE
         and (diff lt 1.0) then begin                                      
         time_temp=long64(time*24*60*60) ;-Calculate time in seconds
         ;-Calculate # seconds since 1970-01-01
         if time[0] lt 1.0 then var_time=long64(jultime)* 24LL * 60 * 60 $ ;-Assumes day 1 of year is zero
         else var_time=long64(jultime-1)* 24LL * 60 * 60                   ;-Assumes day 1 of year is one
         ;;**Need to check above when day 1 is
         ;;zero but arrays starts on any other
         ;;day than 1st Jan
         time_new=time_temp+var_time

         ;-Test for end time stamps
         te=where(strmatch(var_names_cf,'TIME_END',/fold_case) eq 1,te_vals)
         if te_vals eq 1 then begin
            timeend_temp=long64(data.(te)*24*60*60) ;-Calculate time in seconds
            timeend=timeend_temp+var_time             
            unit_arr[te]='Seconds since 1970-01-01 00:00:00'
         endif
      endif else begin
         var_time= long64(jultime) ;-Calculate time in days since 1970-01-01
         time_new=(long64(time)+var_time)* 24LL * 60 * 60
      endelse
   endif
   hr_test=strmatch(tinfo[0],'*hours*',/fold_case)
   if hr_test eq 1 then begin
      ;var_time= long64(jultime * 24LL) ;-Calculate time in hours since 1970-01-01
      ;time_new=(long64(time)+var_time)* 60 * 60
      var_time=long64(jultime * 24LL * 60 * 60) ;-Calculate time in seconds since 1970-01-01
      time_sec=time*60.*60.;-Calculate time in seconds
      time_new=long64(time_sec+var_time)
   endif
   min_test=strmatch(tinfo[0],'*minutes*',/fold_case)
   if min_test eq 1 then begin
      var_time= long64(jultime * 24LL * 60) ;-Calculate time in hours since 1970-01-01
      time_new=(long64(time)+var_time)* 60
   endif
   sc_test=strmatch(tinfo[0],'*seconds*',/fold_case)
   if sc_test eq 1 then begin
      var_time= long64(jultime * 24LL * 60 * 60) ;-Calculate time in seconds since 1970-01-01
      time_new= long64(time)+var_time
      
      ;-Test for start/end time stamps
      te=where(strmatch(var_names_cf,'Time_E*',/fold_case) eq 1,te_vals)
      if te_vals eq 1 then begin
         timeend=long64(data.(te))+var_time             
         ;-Check time-stamp for negative values & set to missing value
         neg_te=where(timeend lt (-1.0),neg_vals)
         if neg_vals gt 0 then timeend[neg_te]=str2num((miss_arr[te])[0])
         ;data.(te)=timeend
         unit_arr[te]='Seconds since 1970-01-01 00:00:00'
      endif
      ts=where(strmatch(var_names_cf,'Time_S*',/fold_case) eq 1,ts_vals)
      if ts_vals eq 1 then begin
         timestart=long64(data.(ts))+var_time
         ;-Check time-stamp for negative values & set to missing value
         neg_ts=where(timestart lt (-1.0),neg_vals)
         if neg_vals gt 0 then timestart[neg_ts]=str2num((miss_arr[ts])[0])
         ;data.(ts)=timestart
         unit_arr[ts]='Seconds since 1970-01-01 00:00:00'
      endif
   endif
   if sc_test eq 0 and hr_test  eq 0 and $
      dy_test eq 0 and min_test eq 0 then begin
      print, 'Error: time stamp is not recognised (not seconds, minutes, hours or days)'
      stop                      ;******** 
   endif
   t_unit='Seconds since 1970-01-01 00:00:00'
   unit_arr[tind]=t_unit
       
   ;-Check time-stamp for negative values & set to missing value
   neg_check=where(time lt (-1.0),neg_vals);old time stamp
   if neg_vals gt 0 then begin
      print,'****Time array contains negative values!!****'
      time_new[neg_check]=str2num((miss_arr[tind])[0])
      valid_time=where(time_new ne str2num((miss_arr[tind])[0]))
      ;-Calculate new start/end values of time coverage
      mintime=min(time_new[valid_time]) & maxtime=max(time_new[valid_time])
   endif else begin
      ;-Put missing values into new time array
      miss_check=where(time eq miss_arr[tind],miss_vals)
      if miss_vals gt 0 then begin
         time_new[miss_check]=miss_arr[tind]
         mintime=min(time_new[where(time ne miss_arr[tind])])
         maxtime=max(time_new[where(time ne miss_arr[tind])])
      endif else begin
         ;-Calculate new start/end values of time coverage
         mintime=min(time_new) & maxtime=max(time_new)
      endelse
   endelse

   ;-Reset time-stamp in data structure
   data.(tind)=time_new         ;& help, time_new, var_time
endif else begin
   ;-For time stamps already converted to secs since 1970
   time_new=time
      
   ;-Check if characters are present in time coverages attributes
   att=(gloatt_val[where(gloatt[*] eq 'Time_Coverage_Start')])[0]
   if (strmatch(att,'*-*') eq 1) or (strmatch(att,'*:*') eq 1) $
      or (strmatch(att,'* *') eq 1) then begin
      mintime=min(time)
      maxtime=max(time)
   endif else begin
      ;-Get start/end values of time coverage from attributes
      mintime=gloatt_val[where(gloatt[*] eq 'Time_Coverage_Start')]
      maxtime=gloatt_val[where(gloatt[*] eq 'Time_Coverage_End'  )]
   endelse
endelse

;-Convert seconds since 1970 to meaningful time stamp for attributes 
mon_arr=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
mintimestr = strsplit(SYSTIME(0,mintime,/UTC),' ',/extract) ;;DOW MON DD HH:MM:SS YEAR
mon=string(where(mon_arr eq mintimestr[1])+1,format='(1i2.2)')
mindate=mintimestr[4]+'-'+mon+'-'+string(mintimestr[2],format='(1i2.2)')$
        +' '+mintimestr[3]+' '
maxtimestr = strsplit(SYSTIME(0,maxtime,/UTC),' ',/extract) ;;DOW MON DD HH:MM:SS YEAR
mon=string(where(mon_arr eq maxtimestr[1])+1,format='(1i2.2)')
maxdate=maxtimestr[4]+'-'+mon+'-'+string(maxtimestr[2],format='(1i2.2)')$
        +' '+maxtimestr[3]+' '
print,mindate;,mintimestr
print,maxdate;,maxtimestr

;-Replace time coordinate attributes with new time stamp name and values
gloatt_val[where(gloatt[*] eq 'Time_Coverage_Start')]=strtrim(mindate,2)  
gloatt_val[where(gloatt[*] eq 'Time_Coverage_End'  )]=strtrim(maxdate,2)
gloatt_val[where(gloatt[*] eq 'Time_Coordinate'    )]=STRUPCASE(time_cf)

print,'time_cf'
print,time_cf

;ntime=n_elements(time)
;stop   
end
