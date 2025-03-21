#!/bin/bash
#-----------------------------Mail address-----------------------------
#SBATCH --mail-user=yixuan.zhou@wur.nl
#SBATCH --mail-type=END,FAIL
#-----------------------------Output files-----------------------------
#SBATCH --output=HPCReport/output_%j.txt
#SBATCH --error=HPCReport/error_output_%j.txt

#-----------------------------Required resources-----------------------
#SBATCH --time=600
#SBATCH --mem=250000

#-----------------------------Functions in this script-----------------
# 1. "Get" functions: 
#    1) Merge multiple .nc files;
#    2) Extract certain time periods;
#    3) Transform the unit of the raw data to what is required for model input
# 2. CorrectUnitD:
#    1) Correct the unit description of processed .nc files;
# 3. correctCoord:
#    1) Correct the coordinates of .nc files.

#load modules
module load cdo
module load netcdf
module load nco

getSWdown () {
	
	input_name='/lustre/nobackup/WUR/ESG/zhou111/Data/Raw/Climate/WFDE5/SWdown/SWdown_tot.nc'
    process_dir='/lustre/nobackup/WUR/ESG/zhou111/Data/Processed/Climate/WFDE5'
    output_name='/lustre/nobackup/WUR/ESG/zhou111/Data/Climate_Forcing/WFDE5/SWdown_daily_1981-2019.nc'


    # Select certain years from the merged file
	cdo selyear,1981/2019 $input_name $process_dir/'merged_SWdown_1981-2019.nc' 	

    # Unit transformation: Convert from W/m2 to KJ m-2 day-1
	cdo mulc,86.400 $process_dir/'merged_SWdown_1981-2019.nc' $process_dir/'SWdown_1981-2019.nc' 
    cdo -invertlat $process_dir/'SWdown_1981-2019.nc'  $process_dir/'SWdown_1981-2019_invertlat.nc'

    cdo setattribute,SWdown@unit="KJ m-2 day-1" $process_dir/'SWdown_1981-2019_invertlat.nc' $output_name
			
}

getSWdown