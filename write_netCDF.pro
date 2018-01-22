;------------------------------------------------------------------------------------------
;+
; NAME:
;	write_netCDF.pro
;
; PURPOSE:
;	Write netCDF file given a structure variable
;
; CATEGORY:
;	All levels of processing
;
; CALLING SEQUENCE:  
;	write_netCDF, data, filename, status, path=dir_path, att_file=att_filename, /clobber
;
; INPUTS:
;	data = structure variable of input data
;	filename = filename for new netCDF file
;	path = optional directory path for the attributes definition file
;	att_file = optional filename for the attributes definition file
;	clobber = optional option for creating netCDF file
;			clobber means any old file will be destroyed
;
;	An external *.att file is used to define attributes (where * = "data" structure name)
;
; OUTPUTS:  
;	status = result status: 0 = OK_STATUS, -1 = BAD_PARAMS, -2 = BAD_FILE,
;			-3 = BAD_FILE_DATA, -4 = FILE_ALREADY_OPENED
;
;	A netCDF file is created and written.
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;	Check for valid input parameters
;	Open the netCDF file
;	Use the structure's tag names for defining the variable names in the netCDF.
;	Use the structure name and optional 'path' variable for the Attributes filename
;		OR use the optional 'att_file' parameter for this filename
;	If this Attributes definition file exists, then transfer those attributes into the netCDF file
;		OR else don't write any attributes to the netCDF file.
;	Once netCDF variables and attributes are defined, then write the structure's data to netCDF file
;	Close the netCDF file
;
;	NetCDF IDL Procedures / Process:
;	1. NCDF_CREATE: Call this procedure to begin creating a new file. The new file is put into define mode.
;	2. NCDF_DIMDEF: Create dimensions for the file.
; 	3. NCDF_VARDEF: Define the variables to be used in the file.
;	4. NCDF_ATTPUT: Optionally, use attributes to describe the data.  Global attributes also allowed.
;	4. NCDF_CONTROL, /ENDEF: Leave define mode and enter data mode.
;	5. NCDF_VARPUT: Write the appropriate data to the netCDF file.
;	6. NCDF_CLOSE: Close the file.
;
; MODIFICATION HISTORY:
;	9/20/99		Tom Woods		Original release code, Version 1.00
;
;+

pro write_netCDF, data, filename, tagname_arr, tagrspn_arr, num_var2, $
                  var_natts, varatt, varatt_val, status, dim_name, dim_size, clobber=clobber

print, 'Writing data to GASSP Level 2 netCDF file'
;print, tag_names(data)
;
;	Generic "status" values
;
OK_STATUS = 0
BAD_PARAMS = -1
BAD_FILE = -2
BAD_FILE_DATA = -3
FILE_ALREADY_OPENED = -4

debug_mode = 0		; set to >= 1 if want to debug this procedure
					; set to 2 if want to debug and force directory to special Woods Mac directory

;
;	check for valid parameters
;
status = BAD_PARAMS
if (n_params(0) lt 1) then begin
	print, 'USAGE: write_netCDF, data, filename, status, path=dir_path, att_file=att_filename, /clobber'
	return
endif
dsize = size(data)
if (dsize[0] ne 1) or (dsize[2] ne 8) then begin
	print, 'ERROR: write_netCDF requires the data to be a structure array'
	return
endif
if (n_params(0) lt 2) then begin
	filename = ''
	read, 'Enter filename for the new netCDF file : ', filename
	if (strlen(filename) lt 1) then return
endif
dir_path = ''
att_filename = tag_names( data, /structure_name ) + '.att'
if keyword_set(path) then dir_path = path
if keyword_set(att_file) then att_filename = att_file
att_filename = dir_path + att_filename

;
;	Do initial survery of variables and nested structures
;	to verify limitation on dimensions of arrays and nested structures
;	
;	LIMITATIONS:  4 dimensions on arrays and 4 nested structures
;
;	Use internal name structure for tracking any nested structures
;
temp_def = { name : ' ', isVar : 0B, tag_index : 0L, var_size : lonarr(10), nest_level : 0, $
	struct_index : lonarr(4), dim_index : lonarr(16), var_ptr : ptr_new() }
var_def = temp_def

;
;	define first structure entry into "var_def" for the "data" structure
;
var_def[0].name = tag_names( data, /structure_name )
var_def[0].isVar = 0
var_def[0].tag_index = 0
var_def[0].var_size = size( data )
var_def[0].nest_level = 0
temp_index = lonarr(4)
var_def[0].struct_index = temp_index
temp_dim = lonarr(16) - 1
var_def[0].dim_index = temp_dim
var_def[0].var_ptr = ptr_new(data[0])

next_var = 1
level_index = lonarr(5)
level_index[0] = 1
extra_var = n_tags( data )
nest_level = 0

;help,data,/structure


while (extra_var gt 0) and (nest_level le 4) do begin
	;
	; each level of nested structures are appended to var_def
	;
	var_def = [ var_def, replicate( temp_def, extra_var ) ]
	if (nest_level gt 0) then j_start = level_index[nest_level-1] else j_start = 0
	j_end = level_index[nest_level] - 1
	extra_var = 0	
	for j=j_start, j_end do begin
		;
		; only process structure definitions
		;
		if ( var_def[j].isVar eq 0 ) then begin
			theData = *(var_def[j].var_ptr)
			tnames = tag_names( theData )
                        ;print, tnames
			temp_index = var_def[j].struct_index
			k_total = n_tags( theData ) - 1
			for k= 0, k_total do begin
				theVar = theData[0].(k)
				theName = ''
				nn = var_def[j].nest_level
				if ( nn gt 0 ) then begin
					theName = var_def[ var_def[j].struct_index[nn-1] ].name + '.'
				endif
				theName = theName + tnames[k]
				var_def[next_var].name = theName
				var_def[next_var].isVar = 1
				var_def[next_var].tag_index = k
				var_def[next_var].nest_level = nest_level
				var_def[next_var].struct_index = temp_index
				var_def[next_var].dim_index = temp_dim
				tempsize = size( theVar )
				if (tempsize[0] gt 4) then begin
					print, 'ERROR:  write_netCDF  has a limitation of 4 dimensions for its variables'
					print, 'ABORTING....'
					; NCDF_CONTROL, fid, /ABORT
					return
				endif
				var_def[next_var].var_size = tempsize
				var_def[next_var].var_ptr = ptr_new( theVar )
				;
				;	if structure, then need to set it up special
				;
				if (tempsize[tempsize[0]+1] eq 8) then begin
					var_def[next_var].isVar = 0
					var_def[next_var].nest_level = nest_level + 1
					var_def[next_var].struct_index[nest_level] = next_var
					extra_var = extra_var + n_tags( theVar[0] )
				endif
				next_var = next_var + 1
			endfor
		endif
	endfor
	;
	;	get ready for next level of nested structures
	;
	nest_level = nest_level + 1
	level_index[nest_level] = next_var
endwhile

num_var = next_var		; the maximum number of variables for netCDF file (size of var_def)
if (num_var ne n_elements(var_def)) then begin
	print, 'WARNING: write_netCDF has error in pre-parsing for variable definitions'
endif

if (extra_var gt 0) then begin
	print, 'ERROR:  write_netCDF  has a limitation of 4 nested structures for its variables'
	print, 'ABORTING....'
	; NCDF_CONTROL, fid, /ABORT
	return
endif

;if (debug_mode gt 0) then stop, 'Check out "var_def" structure results...'

;
;	Open the netCDF file - option to CLOBBER any existing file
;
status = BAD_FILE
if keyword_set(clobber) then fid = NCDF_CREATE( filename, /CLOBBER ) $
else fid = NCDF_CREATE( filename, /NOCLOBBER )
status = OK_STATUS

;
;	Define the netCDF dimensions
;	Use the size() function to make dimensions
;	Define the dimension of the structure itself as UNLIMITED (in case want to append to this file)
;
ndimmax=n_elements(dim_size)
for idim=0,ndimmax-1 do begin
   var_dim = NCDF_DIMDEF( fid, STRUPCASE(dim_name[idim]), dim_size[idim] );;dim_name[idim]
   if strmatch(dim_name[idim],'flag_length',/fold_case) eq 1 then $
   str_did=var_dim ;need string length for AMF station files
   if idim eq 0 then dim_id=var_dim $
   else dim_id=[dim_id,var_dim]
endfor

; if (debug_mode gt 0) then stop, 'Check out the var_def.dim_index[]...'

if (debug_mode gt 0) then begin
   print, ' '
   print, 'Number of structures / variables = ', num_var
   print, ' '
   print, 'Defining dimensions and variables...'
   print, '    Index   Dimensions   Data-Type   Name'
   print, '    -----   ----------   ---------   ----'
endif
;
;	Now define the netCDF variables
;	Use the structure's tag names for defining the variable names in the netCDF
;
first_var=0
for k=0,num_var-1 do begin
	;
	;  only process real variables (not structure definitions)
	;
   if (var_def[k].isVar ne 0) then begin
      var_size = var_def[k].var_size
      data_type = var_size[ var_size[0] + 1 ]
      var_ndim = var_def[k].var_size[0]

      if var_ndim eq 0 then var_ndim=1 ;***FUDGE***
      
      if (debug_mode gt 0) then print, k, var_ndim, data_type, '   ', var_def[k].name
      ;
      ;-Get size of dimensions in variable
      for idim=0,var_ndim-1 do begin
         if idim eq 0 then var_dims=var_def[k].var_size[idim+1] $
         else var_dims=[var_dims,var_def[k].var_size[idim+1]]
      endfor
      index=0
      for idim=0,var_ndim-1 do begin
         ;-Find which dim_size the var_dims correspond to (store index)
         var_dim_id=where(dim_size eq var_dims[idim],nvals)

         ;-Check for multiple matches of dimensions
         if nvals gt 1 then begin
            vardim_match=where(strmatch(dim_name[var_dim_id],$
                                        var_def[k].name,/fold_case) eq 1,nmatchvals)
            ;;If dimension and variable name match then set that dimension
            if nmatchvals eq 1 then var_dim_id=var_dim_id[vardim_match] $
            else begin
               ;;-For AOE1996 data file: DMPS_INT_AOE1996_960723.dat.nc
               if strmatch(var_def[k].name,'LATITUDE') eq 1 or $
                  strmatch(var_def[k].name,'LONGITUDE') eq 1 or $
                  strmatch(var_def[k].name,'N5') eq 1 then $
                     var_dim_id=var_dim_id[where(strmatch(dim_name[var_dim_id],$
                                                          'time',/fold_case) eq 1,nmatchvals)] $
               else var_dim_id=var_dim_id[index];For ARM AMF station data
               index++
            endelse
            ;print,dim_name[var_dim_id],var_def[k].name,var_dim_id,nmatchvals
         endif
         
         ;-Define the dimensions of the variable in terms 
         ;-of NCDF_DIMDEF (using dim_id array) and make dimnsions array
         if idim eq 0 then the_dim=dim_id[var_dim_id] $
         else the_dim=[the_dim,dim_id[var_dim_id]]
         ;print, var_def[k].name, idim, var_dims[idim], dim_size[var_dim_id], data_type
      endfor
      ;
      ;	now make variable in a big case statement now for different data type
      ;
      case data_type of 
         1:	var_defid = NCDF_VARDEF( fid, var_def[k].name, the_dim, /BYTE )
         2:	var_defid = NCDF_VARDEF( fid, var_def[k].name, the_dim, /SHORT )
         3:	var_defid = NCDF_VARDEF( fid, var_def[k].name, the_dim, /LONG )
         4:	var_defid = NCDF_VARDEF( fid, var_def[k].name, the_dim, /FLOAT )
         5:	var_defid = NCDF_VARDEF( fid, var_def[k].name, the_dim, /DOUBLE )
         7:	var_defid = NCDF_VARDEF( fid, var_def[k].name, [str_did, the_dim], /CHAR )
         12:	var_defid = NCDF_VARDEF( fid, var_def[k].name, the_dim, /SHORT )
         13:	var_defid = NCDF_VARDEF( fid, var_def[k].name, the_dim, /LONG )
         14:	var_defid = NCDF_VARDEF( fid, var_def[k].name, the_dim, /LONG) ;DOUBLE);UINT64 )       
         else: begin
            print, 'WARNING: write_netCDF error in variable type, assuming float'
            var_defid = NCDF_VARDEF( fid, var_def[k].name, the_dim ) ; assume it is /FLOAT ???
         end
      endcase
      if (first_var eq 0) then var_id = replicate( var_defid, num_var )
      first_var = 1
      var_id[k] = var_defid
    endif 
endfor

;if (debug_mode gt 0) then stop, 'Check out the "var_id"...'

;
;	Use the structure name and optional 'path' variable for the Attributes filename
;		OR use the optional 'att_file' parameter for this filename
;	If this Attributes definition file exists, then transfer those attributes into the netCDF file
;		OR else don't write any attributes to the netCDF file.
;

ntags=n_elements(tagname_arr)
for itag=0,ntags-1 do begin
   if tagname_arr[itag] eq 'File_N_Var' then goto,skiptag
   if tagname_arr[itag] eq 'File_Var_Name' then goto,skiptag
   if tagname_arr[itag] eq 'Output_Variable' then goto,skiptag
   if tagname_arr[itag] eq 'Output_Variable_2D' then goto,skiptag
   if tagname_arr[itag] eq 'Output_Variable_2D_Units' then goto,skiptag
   if tagname_arr[itag] eq 'Output_Variable_2D_Missing' then goto,skiptag
   if tagname_arr[itag] eq 'Time_Stamp_Info' then goto,skiptag
   ncdf_attput,fid,/global,/char,tagname_arr[itag],tagrspn_arr[itag]
   ;print,'Inserting tag: ',tagname_arr[itag]+' = '+tagrspn_arr[itag]
   skiptag:
endfor
for k=0,num_var2-1 do begin
    for jj=0,var_natts[k]-1 do begin

       ;;if (varatt[k,jj] eq 'units') or (varatt[k,jj] eq 'missing_value') or $
       ;; ;;;****NOT ONLY THESE VARIABLE ATTRIBUTES***
       ;;   (varatt[k,jj] eq 'long_name') then begin
          if (varatt[k,jj] eq 'missing_value') or $
             (varatt[k,jj] eq '_FillValue') or $
             (varatt[k,jj] eq 'scale_factor') or $
             (varatt[k,jj] eq 'add_offset') or $
             (varatt[k,jj] eq 'ASTG') or $
             (varatt[k,jj] eq 'SFCT') or $
             (varatt[k,jj] eq 'SampledRate') or $
             (varatt[k,jj] eq 'OutputRate') or $
             (varatt[k,jj] eq 'VectorLength')  or $
             (varatt[k,jj] eq 'valid_min')  or $
             (varatt[k,jj] eq 'valid_max')  or $
             (varatt[k,jj] eq 'DespikeSlope')  or $
             (varatt[k,jj] eq 'scale') then begin
             if FINITE(varatt_val[k,jj]) eq 1 then begin
                varatt_val_temp=STR2NUM((varatt_val[k,jj]),TYPE=attype)
                THE_CASE:
                CASE attype OF
                   7 : NCDF_ATTPUT, fid, k, varatt[k,jj], varatt_val[k,jj]
                   5 : NCDF_ATTPUT, fid, k, varatt[k,jj], varatt_val_temp, /FLOAT;/DOUBLE;
                   4 : NCDF_ATTPUT, fid, k, varatt[k,jj], varatt_val_temp, /FLOAT ;value=float(temp)
                   3 : NCDF_ATTPUT, fid, k, varatt[k,jj], varatt_val_temp, /LONG  ;value=long(temp)
                   ;;KP_Comment: cf-complance wants a  float  2 : NCDF_ATTPUT, fid, k, varatt[k,jj], varatt_val_temp, /LONG  ;value=fix(temp)
                   2 : NCDF_ATTPUT, fid, k, varatt[k,jj], varatt_val_temp, /FLOAT  ;value=fix(temp)
                   1 : NCDF_ATTPUT, fid, k, varatt[k,jj], varatt_val_temp, /LONG  ;value=byte(temp)
                   else: NCDF_ATTPUT, fid, k, varatt[k,jj], varatt_val_temp
                ENDCASE
             endif else begin
                NCDF_ATTPUT, fid, k, varatt[k,jj], !Values.F_NAN
             endelse 
          endif else begin
             varatt_val_temp=varatt_val[k,jj]
             if varatt_val_temp ne '' then NCDF_ATTPUT, fid, k, varatt[k,jj], varatt_val_temp
          endelse
          ;print, 'Inserting variable attribute: ',k,'  '+varatt[k,jj]+' = ', varatt_val[k,jj]
       ;;endif
    endfor
 endfor

;stop

on_ioerror, NULL

;
;	Once netCDF variables and attributes are defined, then write the structure's data to netCDF file
;
NCDF_CONTROL, fid, /ENDEF;exit define mode

for k=0,num_var-1 do begin
	;
	;  only process real variables (not structure definitions)
	;
	if (var_def[k].isVar ne 0) then begin
		ti = var_def[k].struct_index
		k_ti = var_def[k].tag_index
		ti_0 = var_def[ti[0]].tag_index
		ti_1 = var_def[ti[1]].tag_index
		ti_2 = var_def[ti[2]].tag_index
		ti_3 = var_def[ti[3]].tag_index

                case  var_def[k].nest_level of
			0 :        theData = data.(k_ti)
			1 : theData = data.(ti_0).(k_ti)
			2 : theData = data.(ti_0).(ti_1).(k_ti)
			3 : theData = data.(ti_0).(ti_1).(ti_2).(k_ti)
			4 : theData = data.(ti_0).(ti_1).(ti_2).(ti_3).(k_ti)
		else : begin
			print, 'WARNING: write_netCDF has error in parsing data for writing'
			theData = 0.0
			end
		endcase
                NCDF_VARPUT, fid, var_id[k], theData
                ;help, thedata
                ;print, max(thedata)
	endif
endfor
;
;	Close the netCDF file
;
NCDF_CLOSE, fid

;
;	clean up pointer heap before leaving
;
num_var_def = n_elements( var_def )
for k=0,num_var_def-1 do begin
	if ( ptr_valid( var_def[k].var_ptr ) ) then ptr_free, var_def[k].var_ptr
endfor


return
end
;-----------------------------------------------------------------------------------
