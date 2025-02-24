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

#load modules
module load cdo
module load netcdf
module load nco

dir='/lustre/nobackup/WUR/ESG/zhou111/Data/Climate_Forcing/WFDE5'

getSum () {

	input_file="${dir}/Prec_daily_1981-2019.nc"
	output_file_annual="${dir}/Prec_Annual_1981-2019.nc"
	output_file_monthly="${dir}/Prec_Monthly_1981-2019.nc"
    
	cdo -ymonsum -selyear,1981/2019 $input_file $output_file_monthly # Monthly sum for each year
    cdo -yearsum -selyear,1981/2019 $input_file $output_file_annual # Annual sum for each year
    echo "Sum value for meteo data has been calculated"
}

getMean() {
    
	input_file="${dir}/Tair_daily_1981-2019.nc"
	output_file_annual="${dir}/Tair_Annual_1981-2019.nc"
	output_file_monthly="${dir}/Tair_Monthly_1981-2019.nc"
    
    cdo -ymonmean -selyear,1981/2019 $input_file $output_file_monthly # Monthly mean for each year
    cdo -yearmean -selyear,1981/2019 $input_file $output_file_annual # Annual sum for each year
	echo "Mean value for meteo data has been calculated"
}

getSum
getMean