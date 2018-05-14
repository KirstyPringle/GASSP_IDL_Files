.compile STR2NUM
.compile read_netcdf
.compile convert_altinfeet_to_altinmetres
.compile convert_longitude
.compile set_GASSP_Level2_filemane
.compile standardise_timestamp
.compile standardise_unit_strings
.compile update_posvar_names_cfcompliant
.compile write_netCDF
.r convert_GASSP_Level1_to_Level2_netCDF.pro
$bash nco_script.sh

