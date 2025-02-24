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

#--------------------Environment, Operations and Job steps-------------

#load modules
module load cdo
module load netcdf
module load nco

# Path for original input, final output, and processed data that will be deleted.
input_dir="/lustre/nobackup/WUR/ESG/zhou111/Data/Raw/Climate"
output_dir="/lustre/nobackup/WUR/ESG/zhou111/Data/Climate_Forcing/historical"
process_dir="/lustre/nobackup/WUR/ESG/zhou111/Data/Processed/Climate/"

# Input model name
models=('GFDL-ESM4' 'IPSL-CM6A-LR' 'MPI-ESM1-2-HR' 'MRI-ESM2-0' 'UKESM1-0-LL')
# Models that will be used: 'GFDL-ESM4' 'IPSL-CM6A-LR' 'MPI-ESM1-2-HR' 'MRI-ESM2-0' 'UKESM1-0-LL'

# Input StartYear & EndYear of the .nc file that will be created
StartYear=1985
EndYear=2014

# ---------------------------- Tmax & Tmin ---------------------------
getTmaxTmin () {
	
	vars=('tasmax' 'tasmin')
	
	for model in "${models[@]}";
	do
		# Find the input and output directories
		name="${model,,}"
		path1="${input_dir}/historical/${model}/"
		path2="${input_dir}/ssp585/${model}/"
		out="${output_dir}/${model}/"

			
		if [ $model == 'UKESM1-0-LL' ]; then
		input='r1i1p1f2' # The file name of UKESM1 data is different from the others
		else
		input='r1i1p1f1'
		fi
		
		for var in "${vars[@]}";
		do	

			if [ ${var} == 'tasmax' ]; then
				output_name='Org_Tmax'
			else 
			    output_name='Org_Tmin'
			fi

            # Merge all of the data
            tmp1=$path1$name'_'$input'_w5e5_historical_'$var'_landonly_daily_1981_1990.nc'
            tmp2=$path1$name'_'$input'_w5e5_historical_'$var'_landonly_daily_1991_2000.nc' 
			tmp3=$path1$name'_'$input'_w5e5_historical_'$var'_landonly_daily_2001_2010.nc'
            tmp4=$path1$name'_'$input'_w5e5_historical_'$var'_landonly_daily_2011_2014.nc'
            tmp5=$path2$name'_'$input'_w5e5_ssp585_'$var'_landonly_daily_2015_2020.nc'

            # Merge all .nc files
			cdo -O mergetime $tmp1 $tmp2 $tmp3 $tmp4 $tmp5 $process_dir'merged_'$output_name'_'$model'.nc' 
			# Only temperature data is named with their models as the processed temperature need to be used for Vap calculation

            # Select certain years from the merged file
			cdo selyear,${StartYear}/${EndYear} $process_dir/'merged_'$output_name'_'$model'.nc' $process_dir'x1_'$output_name'_'$model'.nc'	

            # Unit transformation: Convert K to celsuis degree
			cdo -invertlat -addc,-273.15 $process_dir'x1_'$output_name'_'$model'.nc' $process_dir${model}'/'$output_name'_daily_'${StartYear}'-'${EndYear}'.nc'
			
		done
	done
}


# ---------------------------- Shortwave radiation -----------------------
getSWdown () {
	
	var='rsds' # Variable name in the naming of the raw data file
	output_name='Org_SWdown'
	
	for model in "${models[@]}";
	do
		# Find the input and output directories
		name="${model,,}"
		path1="${input_dir}/historical/${model}/"
		path2="${input_dir}/ssp585/${model}/"
		out="${output_dir}/${model}/"
			
		if [ $model == 'UKESM1-0-LL' ]; then
		input='r1i1p1f2' # The file name of UKESM1 data is different from the others
		else
		input='r1i1p1f1'
		fi

            # Merge all of the data
            tmp1=$path1$name'_'$input'_w5e5_historical_'$var'_landonly_daily_1981_1990.nc'
            tmp2=$path1$name'_'$input'_w5e5_historical_'$var'_landonly_daily_1991_2000.nc' 
			tmp3=$path1$name'_'$input'_w5e5_historical_'$var'_landonly_daily_2001_2010.nc'
            tmp4=$path1$name'_'$input'_w5e5_historical_'$var'_landonly_daily_2011_2014.nc'
            tmp5=$path2$name'_'$input'_w5e5_ssp585_'$var'_landonly_daily_2015_2020.nc'

            # Merge all .nc files
			cdo -O mergetime $tmp1 $tmp2 $tmp3 $tmp4 $tmp5 $process_dir'merged_'$output_name'.nc'

            # Select certain years from the merged file
			cdo selyear,${StartYear}/${EndYear} $process_dir/'merged_'$output_name'.nc' $process_dir'x1_'$output_name'.nc'	

            # Unit transformation: Convert from W/m2 to KJ m-2 day-1
			cdo mulc,86.400 $process_dir'x1_'$output_name'.nc' $process_dir${model}'/'$output_name'_daily_'${StartYear}'-'${EndYear}'.nc'
			
	done
}

# ---------------------------- Precipitation  -----------------------
# p.s. Here the variable name is Rainf just to match the variable names in wofost
# The variable is actually precipitation (pr) in the original data.
getRainf () {
	
	var='pr' # 
	output_name='Org_Rainf'
	
	for model in "${models[@]}";
	do
		# Find the input and output directories
		name="${model,,}"
		path1="${input_dir}/historical/${model}/"
		path2="${input_dir}/ssp585/${model}/"
		out="${output_dir}/${model}/"
			
		if [ $model == 'UKESM1-0-LL' ]; then
		input='r1i1p1f2' # The file name of UKESM1 data is different from the others
		else
		input='r1i1p1f1'
		fi

            # Merge all of the data
            tmp1=$path1$name'_'$input'_w5e5_historical_'$var'_landonly_daily_1981_1990.nc'
            tmp2=$path1$name'_'$input'_w5e5_historical_'$var'_landonly_daily_1991_2000.nc' 
			tmp3=$path1$name'_'$input'_w5e5_historical_'$var'_landonly_daily_2001_2010.nc'
            tmp4=$path1$name'_'$input'_w5e5_historical_'$var'_landonly_daily_2011_2014.nc'
            tmp5=$path2$name'_'$input'_w5e5_ssp585_'$var'_landonly_daily_2015_2020.nc'

            # Merge all .nc files
			cdo -O mergetime $tmp1 $tmp2 $tmp3 $tmp4 $tmp5 $process_dir'merged_'$output_name'.nc'

            # Select certain years from the merged file
			cdo selyear,${StartYear}/${EndYear} $process_dir/'merged_'$output_name'.nc' $process_dir'x1_'$output_name'.nc'	

            # Unit transformation: Convert from kg m-2 -1 to mm day-1
			cdo mulc,86.400 $process_dir'x1_'$output_name'.nc' $process_dir${model}'/'$output_name'_daily_'${StartYear}'-'${EndYear}'.nc'
			
	done
}

# ---------------------------- Wind speed  -----------------------
getWind () {
	
	var='sfcwind' # 
	output_name='Org_Wind'
	
	for model in "${models[@]}";
	do
		# Find the input and output directories
		name="${model,,}"
		path1="${input_dir}/historical/${model}/"
		path2="${input_dir}/ssp585/${model}/"
		out="${output_dir}/${model}/"
			
		if [ $model == 'UKESM1-0-LL' ]; then
		input='r1i1p1f2' # The file name of UKESM1 data is different from the others
		else
		input='r1i1p1f1'
		fi

            # Merge all of the data
            tmp1=$path1$name'_'$input'_w5e5_historical_'$var'_landonly_daily_1981_1990.nc'
            tmp2=$path1$name'_'$input'_w5e5_historical_'$var'_landonly_daily_1991_2000.nc' 
			tmp3=$path1$name'_'$input'_w5e5_historical_'$var'_landonly_daily_2001_2010.nc'
            tmp4=$path1$name'_'$input'_w5e5_historical_'$var'_landonly_daily_2011_2014.nc'
            tmp5=$path2$name'_'$input'_w5e5_ssp585_'$var'_landonly_daily_2015_2020.nc'

            # Merge all .nc files
			cdo -O mergetime $tmp1 $tmp2 $tmp3 $tmp4 $tmp5 $process_dir'merged_'$output_name'.nc'

            # Select certain years from the merged file
			cdo selyear,${StartYear}/${EndYear} $process_dir/'merged_'$output_name'.nc' $process_dir'x1_'$output_name'.nc'	

            # Unit transformation: From 10 m-height to 2 m
			cdo mulc,0.747 $process_dir'x1_'$output_name'.nc' $process_dir${model}'/'$output_name'_daily_'${StartYear}'-'${EndYear}'.nc'
			
	done
}

# ---------------------------- Vapour pressure  -----------------------
getVap () {
    output_name='Org_Vap'

	for model in "${models[@]}";
	do
		# Find the input and output directories
		path="/lustre/nobackup/WUR/ESG/zhou111/Data/Processed/Climate" # Directory of the processed temperature data
		out="${output_dir}/${model}/"

        # Calculate the saturation vapour pressure: e(T) = 0.6108 * exp [17.27*T/(T+237.3)]
		# In this function, the unit of T is celsuis degree
		
		# Tmax (T - 273.15 as the unit is K for the raw data)		
        cdo addc,-273.15 $path'/x1_Org_Tmax_'${model}'.nc' $path'/Tmax_K_'${model}'.nc'
        cdo addc,237.3 $path'/Tmax_K_'${model}'.nc' $path'/Tmax_plus_'${model}'.nc'
        cdo div $path'/Tmax_K_'${model}'.nc' $path'/Tmax_plus_'${model}'.nc' $path'/Tmax_fraction_'${model}'.nc'
        cdo mulc,17.27 $path'/Tmax_fraction_'${model}'.nc' $path'/Tmax_multiplied_'${model}'.nc'
        cdo exp $path'/Tmax_multiplied_'${model}'.nc' $path'/Tmax_exponential_'${model}'.nc'
        cdo mulc,0.6108 $path'/Tmax_exponential_'${model}'.nc' $path'/Vap_Tmax_'${model}'.nc'
		
		# Tmin (T - 273.15 as the unit is K for the raw data)
        cdo addc,-273.15 $path'/x1_Org_Tmin_'${model}'.nc' $path'/Tmin_K_'${model}'.nc'
        cdo addc,237.3 $path'/Tmin_K_'${model}'.nc' $path'/Tmin_plus_'${model}'.nc'
        cdo div $path'/Tmin_K_'${model}'.nc' $path'/Tmin_plus_'${model}'.nc' $path'/Tmin_fraction_'${model}'.nc'
        cdo mulc,17.27 $path'/Tmin_fraction_'${model}'.nc' $path'/Tmin_multiplied_'${model}'.nc'
        cdo exp $path'/Tmin_multiplied_'${model}'.nc' $path'/Tmin_exponential_'${model}'.nc'
        cdo mulc,0.6108 $path'/Tmin_exponential_'${model}'.nc' $path'/Vap_Tmin_'${model}'.nc'

        # es = [e(Tmax) + e(Tmin)]/2
        cdo -add $path'/Vap_Tmax_'${model}'.nc' $path'/Vap_Tmin_'${model}'.nc' $path'/Vap_Tsum_'${model}'.nc'
        cdo -divc,2 $path'/Vap_Tsum_'${model}'.nc' $process_dir${model}'/'$output_name'_daily_'${StartYear}'-'${EndYear}'.nc'
	done
}


# ---------------- Correct the description of variables ------------------
correctUnit () {

	# Path of the output data
	path1=$process_dir   # For variables that need coordinates transformation
	path2=$output_dir'/' # For variables that do not need coordinates transformation

	for m in "${models[@]}"
	do		
		## Tmax
		# Tranform the name of the variable
		# cdo chvar,tasmax,Tmax $path1$m'/Org_Tmax_daily_'${StartYear}'-'${EndYear}'.nc' $path1$m'/Tmax_daily_VN_Trans.nc'
		# Transform the unit descriptions
		# cdo setattribute,Tmax@unit="celsuis degree" $path1$m'/Tmax_daily_VN_Trans.nc' $path2$m'/Tmax_daily_'${StartYear}'-'${EndYear}'.nc'

		## Tmin
		# Tranform the name of the variable
		# cdo chvar,tasmin,Tmin $path1$m'/Org_Tmin_daily_'${StartYear}'-'${EndYear}'.nc' $path1$m'/Tmin_daily_VN_Trans.nc'
		# Transform the unit descriptions
		cdo setattribute,Tmin@unit="celsuis degree" $path1$m'/Tmin_daily_VN_Trans.nc' $path2$m'/Tmin_daily_'${StartYear}'-'${EndYear}'.nc'

		## Vap
		# Tranform the name of the variable
		# cdo chvar,tasmax,Vap $path1$m'/Org_Vap_daily_'${StartYear}'-'${EndYear}'.nc' $path1$m'/Vap_daily_VN_Trans.nc'
		# Transform the unit descriptions
		# cdo setattribute,Vap@unit="KPa" $path1$m'/Vap_daily_VN_Trans.nc' $path2$m'/Vap_daily_'${StartYear}'-'${EndYear}'.nc'

		## SWdown
		# Tranform the name of the variable
		# cdo chvar,rsds,SWdown $path1$m'/Org_SWdown_daily_'${StartYear}'-'${EndYear}'.nc' $path1$m'/SWdown_daily_VN_Trans.nc'
		# Transform the unit descriptions
		# cdo setattribute,SWdown@unit="KJ m-2 day-1" $path1$m'/SWdown_daily_VN_Trans.nc' $path1$m'/SWdown_daily_'${StartYear}'-'${EndYear}'.nc'

		## Rainf
		# Tranform the name of the variable
		# cdo chvar,pr,Rainf $path1$m'/Org_Rainf_daily_'${StartYear}'-'${EndYear}'.nc' $path1$m'/Rainf_daily_VN_Trans.nc'
		# Transform the unit descriptions
		# cdo setattribute,Rainf@unit="mm" $path1$m'/Rainf_daily_VN_Trans.nc' $path1$m'/Rainf_daily_'${StartYear}'-'${EndYear}'.nc'

		## Wind speed
		# Tranform the name of the variable
		# cdo chvar,sfcwind,Wind $path1$m'/Org_Wind_daily_'${StartYear}'-'${EndYear}'.nc' $path1$m'/Wind_daily_VN_Trans.nc'
		# Transform the unit descriptions
		# cdo setattribute,Wind@long_name="Wind speed at 2m height" $path1$m'/Wind_daily_VN_Trans.nc' $path1$m'/Wind_daily_'${StartYear}'-'${EndYear}'.nc'

	done
}

correctCoord () {

	# Path of the output data
	path1=$process_dir   # For variables that need coordinates transformation
	path2=$output_dir'/' # For variables that do not need coordinates transformation

	for m in "${models[@]}"
	do					
		## SWdown
		cdo -invertlat $path1$m'/SWdown_daily_'${StartYear}'-'${EndYear}'.nc' $path2$m'/SWdown_daily_'${StartYear}'-'${EndYear}'.nc'
		
		## Rainf
		cdo -invertlat $path1$m'/Rainf_daily_'${StartYear}'-'${EndYear}'.nc' $path2$m'/Rainf_daily_'${StartYear}'-'${EndYear}'.nc'
		
		## Wind
		cdo -invertlat $path1$m'/Wind_daily_'${StartYear}'-'${EndYear}'.nc' $path2$m'/Wind_daily_'${StartYear}'-'${EndYear}'.nc'

    done 

}

# Step1 - List of get functions:
# getTmaxTmin
# getSWdown
# getRainf
# getWind

# Step2 - Calculate Vap based on temperature
# getVap

# Step3 - Unit description transformation functions:
# correctUnit

# Step4 - Coordinates transformation:
# correctCoord

# Step 5- Clean up the processed folder
# rm -rf /lustre/nobackup/WUR/ESG/zhou111/Data/Processed/Climate/*