PRO convert_altinfeet_to_altinmetres,gloatt,gloatt_val,var_names_cf,$
                                     alt_cf,palt_cf,unit_arr,data

altmin=str2num((gloatt_val[where(gloatt[*] eq 'Vertical_Min')])[0])
altmax=str2num((gloatt_val[where(gloatt[*] eq 'Vertical_Max')])[0])
aind=where(var_names_cf eq alt_cf,valalt)
pind=where(var_names_cf eq palt_cf,valpalt)
if (valalt eq 1) and (valpalt eq 1) then begin
   altind=[aind,pind]
   for a=0,1 do begin
      test_ft=strmatch(unit_arr[altind[a]],'*f*t*',/fold_case)
      if test_ft eq 1 then begin
         alt=data.(altind[a])*0.3048 ;;1 foot = 0.3048 meters
         data.(altind[a])=alt
         unit_arr[altind[a]]='m'
         if a eq 0 then begin
            gloatt_val[where(gloatt[*] eq 'Vertical_Min')]=strtrim(altmin*0.3048,2)
            gloatt_val[where(gloatt[*] eq 'Vertical_Max')]=strtrim(altmax*0.3048,2)
         endif
      endif
   endfor
endif else begin
   if (valalt eq 1) then altind=aind
   if (valalt eq 0) and (valpalt eq 1) then altind=pind
   test_ft=strmatch(unit_arr[altind],'*f*t*',/fold_case)
   if test_ft eq 1 then begin
      alt=data.(altind)*0.3048 ;;1 foot = 0.3048 meters
      data.(altind)=alt
      unit_arr[altind]='m'
      gloatt_val[where(gloatt[*] eq 'Vertical_Min')]=strtrim(altmin*0.3048,2)
      gloatt_val[where(gloatt[*] eq 'Vertical_Max')]=strtrim(altmax*0.3048,2)
   endif
endelse

end
