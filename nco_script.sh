#!/bin/bash

# K. Pringle.
# Bash script to do some postprocessing to the GASSP data.
# 1) Adds "Time in seconds" to long_name of TIME variable (needed for python processing).
# 2) Changes TEMPORARY_FillValue to _FillValue which can't be done in IDL due to bug

# run with:  bash nco_script.sh

DIR='/nfs/a201/earkpr/DataVisualisation/GASSP/GASSP_Level_2_Data/'

find $DIR -name "*.nc" -print0 | while read -d $'\0' file
do
   echo "$file"
   ncatted -O -a long_name,TIME,c,c,"Time in seconds" $file
   ncrename -O -a .TEMPORARY_FillValue,_FillValue $file
done

