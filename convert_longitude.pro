PRO convert_longitude,gloatt,gloatt_val,var_names_cf,$
                      lon_cf,miss_arr,data

;-Get longitude array
lon_ind=where(strmatch(var_names_cf,lon_cf,/fold_case) eq 1,val)
if val eq 0 then stop
lon=data.(lon_ind)

   ;-Get type of variable and missing value
dbl_test=ISA(lon[0], 'Double')
flt_test=ISA(lon[0], 'Float')
if dbl_test then lon_missval=double((miss_arr[lon_ind])[0])
if flt_test then lon_missval=float((miss_arr[lon_ind])[0])
if (dbl_test eq 0) and (flt_test eq 0) then $ 
   lon_missval=str2num((miss_arr[lon_ind])[0])

bad_lon=where(lon eq lon_missval or $
              lon ge 9.0e30 or $
              lon le -777.0, badvals)
lon_tmp=lon
if badvals ge 1 then lon_tmp[bad_lon]=!VALUES.F_NAN

print,'Min,max longitude =    ',min(lon_tmp,/nan),max(lon_tmp,/nan)

;-Check longitude array is -180 to 180 degrees
if (max(lon_tmp,/nan) gt 180.) and (max(lon_tmp,/nan) le 360.) then begin

   ;-Convert longitude array to -180 to 180 if it's 0 to 360
   lon_new = ((lon_tmp + 180) MOD 360) - 180

   print,'Min,max longitude new =',min(lon_new,/nan),max(lon_new,/nan)

   ;-Calculate new min and max longitude and insert into attributes
   gloatt_val[where(gloatt[*] eq 'Lon_Min')]=min(lon_new,/nan)
   gloatt_val[where(gloatt[*] eq 'Lon_Max')]=max(lon_new,/nan)

   ;-Insert missing values back into new longitude array
   if badvals ge 1 then lon_new[bad_lon]=lon_missval

   ;-Insert new longitude back into data structure
   data.(lon_ind)=lon_new
;stop
endif

;-HIPPO data
if (min(lon_tmp,/nan) lt -180.) and (min(lon_tmp,/nan) ge -360.) then begin

   ;-Convert longitude array to -180 to 180 if it's -360 to 0
   lon_new = ((lon_tmp - 180) MOD (-360)) + 180 ;HIPPO data

   print,'Min,max longitude new =',min(lon_new,/nan),max(lon_new,/nan)

   ;-Calculate new min and max longitude and insert into attributes
   gloatt_val[where(gloatt[*] eq 'Lon_Min')]=min(lon_new,/nan)
   gloatt_val[where(gloatt[*] eq 'Lon_Max')]=max(lon_new,/nan)

   ;-Insert missing values back into new longitude array
   if badvals ge 1 then lon_new[bad_lon]=lon_missval

   ;-Insert new longitude back into data structure
   data.(lon_ind)=lon_new
;stop
endif

end
