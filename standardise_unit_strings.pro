PRO standardise_unit_strings,unit_arr,var_names_cf

units2change=$
   ['/cm3','/cm^3','1/cm^3','1/cm3','cm^-3','#/cm3','#cm-3','particles/cm^3','parts/cc','#/cm^3','1/cm3@stp','1/cm^3_STP',$
    'per std cc','particle cm-3 at 1atm, 0C','parts/cc','count/cm^3','cm3',$
    'um3/cm3','um^3/cm^3','um3cm-3','micrometers^3/cm^3','um3/cm3@ambient','um^3/scc','um3 cm-3 at 1atm, 0C','um3cm-3',$
    'um2/cm3','um^2/cm^3','um2cm-3','micrometers^2/cm^3','um2/cm3@ambient','um^2/scc','um2cm-3',$
    'ug/m^3','ug/m3','mg/m3','ugC/m3','ugstdm-3','µg / m3','ug/sm^3',$
    'ng/m^3','ng/m3','ngstdm-3','ng m-3 at 1atm, 0C','ngm-3', 'ng sm^-3', $
    'ng/kg',$
    'N degree','degree N','degree_N','Deg_N','degN',$
    'E degree','degree E','degree_E','Deg_E','degE',$
    'degK','degree_K','degree_K, CAPS','degree_k caps','K',  $
    'degC','degree_C','degrees C','degree C','Celcius','deg_C','C',$
    'pct','percent','%, CAPS',$
    'mb','mbar','hPa, CAPS','Mb',$
    'meters','micrometers',$
    'km, POS',$
    'unitless','no units',' ','#',$;check this last one!
    'm/s', 'Seconds since 1970-01-01, 00:00:00 UTC', 'Seconds since 1970-01-01, 00:00:00 UTC']                      


stdunits=$
   ['cm-3','cm-3','cm-3','cm-3','cm-3','cm-3','cm-3','cm-3','cm-3','cm-3','cm-3 stp','cm-3 stp',$
    'cm-3 stp','cm-3 stp','cm-3','cm-3','cm-3',$
    'um3 cm-3','um3 cm-3','um3 cm-3','um3 cm-3','um3 cm-3 ambient','um3 cm-3 stp','um3 cm-3 stp','um3 cm-3',$
    'um2 cm-3','um2 cm-3','um2 cm-3','um2 cm-3','um2 cm-3 ambient','um2 cm-3 stp','um2 cm-3',$
    'ug m-3','ug m-3','ug m-3','ugC m-3','ug m-3 stp','ug m-3','ug m-3 stp',$  ;;ugs m-3??
    'ng m-3','ng m-3','ng m-3 stp','ng m-3 stp','ng m-3','ng m-3',$
    'ng kg-1',$
    'degrees_north','degrees_north','degrees_north','degrees_north','degrees_north',$
    'degrees_east','degrees_east','degrees_east','degrees_east','degrees_east',$
    'Kelvin','Kelvin','Kelvin','Kelvin','Kelvin',$
    'Celcius','Celcius','Celcius','Celcius','Celcius','Celcius','Celcius',$
    '%','%','%',$
    'hPa','hPa','hPa','hPa',$
    'm','um',$
    'km',$
;;    'none','none','none','none',$
    '','','','',$
    'm s-1', 'Seconds since 1970-01-01 00:00:00',  'Seconds since 1970-01-01 00:00:00']

;help,units2change,stdunits
if n_elements(units2change) ne n_elements(stdunits) then stop,'****Unit array dimensions do not match****'

unspecunit=['deg','degs','degrees','degree, POS']

for u=0,n_elements(unit_arr)-1 do begin

   unitmatch=where(strmatch(units2change,unit_arr[u],/fold_case) eq 1,val)
   if val eq 1 then begin
;      print,'Old unit:',unit_arr[u]
      unit_arr[u]=stdunits[unitmatch]
;      print,'New unit:',unit_arr[u]
   endif
   if val eq 0 then begin

      ;-Replace general lat/lon units (deg, degs, etc.)
      unitmatch2=where(strmatch(unspecunit,unit_arr[u],/fold_case) eq 1,val2)
      if val2 eq 1 then begin
         print,'Old unit:',unit_arr[u]
         ;;how do you replace: 'deg', 'degs', 'degrees'
         ;;if it's used for both lon and lat --> need to put a check in
         if strmatch(var_names_cf[u],'longitude',/fold_case) eq 1 then $
            unit_arr[u]='degree_east'
         if strmatch(var_names_cf[u],'latitude',/fold_case) eq 1 then $
            unit_arr[u]='degree_north'
         print,'New unit:',unit_arr[u]
      endif else print,'Retaining original unit:',unit_arr[u]
   endif

   ;-Check for encoding errors (assume corresponds to 'mu' symbol)
   if ((byte(unit_arr[u]))[0] eq 181) and $
      (STRMID(unit_arr[u], 1, 1) eq 'm') then begin
      print,'Encoding error, changing to "um"'
      ;byte(STRMID(unit_arr[u], 0, 1))
      unit_arr[u]='um'
   endif

   ;-Check for upper case metres
   if strmatch(unit_arr[u],'M') eq 1 then unit_arr[u]='m'

endfor

;stop

;Need to add in unit conversions: km, degC ;*************
;Celcius,deg_C,C

end
