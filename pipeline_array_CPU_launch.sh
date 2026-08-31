#!/bin/bash

#================ Experimental day =======================
# from CLI
# source /cluster/home/ibarbier/Yeast_screening_pipeline/pipeline_array_CPU_launch.sh 20260427_phenix1_screen_5nM_3.3
EXP_DAY=$1

echo "------------ $EXP_DAY ------------"

#================ EXP ID =======================
# extracting the experimental ID from the name of the experimental day 
IFS="_" read -r date scope screen conc expID  <<< "$EXP_DAY"
IFS="." read -r p rep  <<< "$expID"

EXP_ID="p${p}rep${rep}"


#============= Localization Variables =============
# path to the various directory required for the pipeline 
WORKDIR="/cluster/scratch/ibarbier/$EXP_DAY/"
RESULTSDIR="${WORKDIR}results/"
IMGDIR="${WORKDIR}Images/"
SLURM_OUT="/cluster/scratch/ibarbier/slurm_out/"
#
SOURCEDIR="/nfs/nas22/fs2202/biol_bc_barral_2/ibarbier/2026_GFP_screen/$EXP_DAY/$EXP_DAY/Images/"
CODEDIR="/cluster/home/ibarbier/Yeast_screening_pipeline/"
BASHFILE="${CODEDIR}pipeline_array_CPU.sh"
ARRAY_PY="${CODEDIR}make_array_file.py"
#================ Script =======================

# activate the conda environment 
source ~/.bashrc
conda activate /cluster/home/ibarbier/miniconda3/envs/pipeline

# check that the conda environment has been activated properly
echo "Conda environment currently activated: "
echo "-- $CONDA_DEFAULT_ENV"

# create the image folder and copy the data
echo "Raw images status: "
if [ ! -d "$IMGDIR" ]; then
  echo "-- $IMGDIR does not exist. Copying data now"
  mkdir $WORKDIR
  cp -R $SOURCEDIR $WORKDIR
else
  echo "-- Data already copied from source"
fi

# create the slurm output folder 
if [ ! -d "$SLURM_OUT" ]; then
  mkdir $SLURM_OUT
fi

# create the result folder 
if [ ! -d "$RESULTSDIR" ]; then
  mkdir $RESULTSDIR
fi


# create the array ID table with all the position names 
python $ARRAY_PY $WORKDIR $EXP_ID
echo 'Array ID created' 

# submit array job to the slurm system 
sbatch --array=[1-480] --output="/cluster/home/ibarbier/array_slurm_out/result.%A.%a" --wrap="sbatch $BASHFILE \$SLURM_ARRAY_TASK_ID $EXP_DAY"

echo 'Jobs submitted'

conda deactivate 
