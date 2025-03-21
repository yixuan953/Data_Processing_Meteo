#!/bin/bash
#----------------------------- Mail address -----------------------------
#SBATCH --mail-user=yixuan.zhou@wur.nl
#SBATCH --mail-type=END,FAIL
#----------------------------- Output files -----------------------------
#SBATCH --output=HPCReport/output_%j.txt
#SBATCH --error=HPCReport/error_output_%j.txt

#------------------------ Required time and space -----------------------
#SBATCH --time=600
#SBATCH --mem=250000

#-------------------- Environment, Operations and Job steps -------------
#load modules
module load cdo
module load netcdf

# Path for original input, final output
input_dir="/lustre/nobackup/WUR/ESG/zhou111/Data/Climate_Forcing/WFDE5/"
process_dir="/lustre/nobackup/WUR/ESG/zhou111/Data/Processed/Climate/WFDE5/"
output_dir="/lustre/nobackup/WUR/ESG/zhou111/Data/Climate_Forcing/WFDE5/"

lonlatbox_Yangtze='90.75,120.25,24.75,35.75' #[Xmin Xmax Ymin Ymax]
lonlatbox_Rhine='3.75,12.25,46.25,52.25' #[Xmin Xmax Ymin Ymax]
lonlatbox_Indus='65.75,83.25,23.75,38.25' #[Xmin Xmax Ymin Ymax]
lonlatbox_LaPlata='-67.25,-43.25,-35.25,-13.25' #[Xmin Xmax Ymin Ymax]

StudyAreas=('Indus' 'Rhine' 'LaPlata') # 'Yangtze' 'Indus' 'Rhine' 'LaPlata'
MeteoList=('Prec' 'SWdown' 'Tmax' 'Tmin' 'Vap' 'Wind')

# Define the function
CutMask(){
    for StudyArea in "${StudyAreas[@]}"; 
    do 
        lonlatbox_var="lonlatbox_${StudyArea}"
        lonlatbox_value="${!lonlatbox_var}"

        for Meteo in "${MeteoList[@]}";
        do   
            cdo sellonlatbox,${lonlatbox_value} ${input_dir}${Meteo}_daily_1981-2019.nc ${process_dir}${StudyArea}_${Meteo}_daily_1985-2019.nc
            cdo selyear,1985/2019 ${process_dir}${StudyArea}_${Meteo}_daily_1985-2019.nc ${output_dir}${StudyArea}/${StudyArea}_${Meteo}_daily_1985-2019.nc
            # Check if the latitude needs to be inverted or not
            # cdo -invertlat ${process_dir}Yangtze_${Meteo}_daily_1990-2019.nc ${output_dir}${Meteo}_daily_1990-2019.nc
            echo "$Meteo.nc fil for $StudyArea has been cut and saved"
        done
    done
}

# Use the function
CutMask