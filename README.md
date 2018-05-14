# GASSP_IDL_Files

Files used to process data collected during the Global Aerosol Science and Synthesis Project (GASSP) from mixed data formats to netCDF format with standard attribute naming.

The GASSP database identifies three levels of data processing:

Level 0 : The raw data from data providers 
Level 1 : The same data saved in netCDF format 
Level 2 : The data saved in a netCDF format, plus names changed to ensure standard naming and additional attributes added. 

The code held within this repository converts Level 1 GASSP data to Level 2, this includes re-naming to GASSP standard names, and adding attribute information. It is written in Interactive Data Language (IDL).

The IDL proceedure relies on a file called Processed_file_list.txt which contains a list of the files that have been converted to Level 1 format. 

Summary of convert_GASSP_Level1_to_Level2_netCDF.pro 

Script to convert all Level 1 data to Level 2 format (other scripts in this directory convert Level 0 to Level 1).

Reads files from Processed_file_list.txt, specifying which projects to process using “projarr” array.

Uses “read_netCDF” and “write_netCDF” procedures modified from original code (downloaded from the web) to deal with GASSP data files.

“update_posvar_names_cfcompliant” procedure attempts to convert position variable names to CF-compliant names automatically.

“match_varnames_standardnames” procedure attempts to match non-standard aerosol variable names and convert these to the ‘standardised’ names (need to keep adding to this list manually).

“standardise_timestamp” procedure converts primary time variable in file to a standardised time stamp.

“standardise_unit_strings” procedure attempts to match non-standard unit strings and convert these to standardised (not all CF-compliant) unit strings (need to keep adding to this list manually).

Code then creates a new data structure including standardised time variable and all other variables in file (replacing symbols in variable names that are not accepted by IDL data structures).

Additional variable and global attributes are added then the new data structure is written to netCDF.



*Guide to the vars_vocals_test3.csv file.*

The vars_vocals_test3.csv file is used to split the variables into different netCDF files so that each variable is in a seperate file.

It is a table with 5 headings: Var Name,Class,Code,Depend?,Dep var

Var Name:  Variable name as written in the Level 1 data. 

Class = Can be either one of the varialbe classes (NUM = Numnber, NSD = Number size dist, COMP = Composition, CCN = CCN,  BC = Black Carbon) or DEP which means it's a dependent variable, and only makes sense in the context of a variable (e.g. CCN_StDev) or ANC = Ancillary data (e.g. temp, pressure) or OTH = Other for data we don't want to process.  

Code = Either 1 or 2.  1 = Don't make a new netCDF file, 2 = Do make a new netCDF file for this variable.  e.g. ANC and DEP should have code = 1,  Key variables should have code = 2.  Other codes? e.g. 4?

Depend?  = Either Y (yes) or N (no).  Put Y if the vara

Dep var = Name of the dependant varaible as written in the Level 1 file (not after it has been renamed to cf_var)

I don't *think* this file is case sensitive.




