#!/bin/bash

#SBATCH --account=es_biol
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH --time=24:00:00
#SBATCH --mem-per-cpu=40000
#SBATCH --output=/cluster/scratch/ibarbier/slurm_out/slurm-%j.out
#SBATCH --error=/cluster/scratch/ibarbier/slurm_out/slurm-%j.err

#================ Experimental day =======================
# extract from command line 
# sbatch --array=[1-3] --output="/cluster/home/ibarbier/test_out/result.%A.%a" --wrap="sbatch /cluster/home/ibarbier/test.sh \$SLURM_ARRAY_TASK_ID 20260427_phenix1_screen_5nM_3.3"
EXP_DAY=$2
echo "------------ $EXP_DAY ------------"


#================ EXP ID =======================
# extracting the experimental ID from the name of the experimental day 
IFS="_" read -r date scope screen conc expID  <<< "$EXP_DAY"
IFS="." read -r p rep  <<< "$expID"

EXP_ID="p${p}rep${rep}"


#============= Path Variables =============
# path to the various directory required for the pipeline 
WORKDIR="/cluster/scratch/ibarbier/$EXP_DAY/"
RESULTSDIR="${WORKDIR}results/"
IMGDIR="${WORKDIR}Images/"
SOURCEDIR="/nfs/nas22/fs2202/biol_bc_barral_2/ibarbier/2026_GFP_screen/$EXP_DAY/$EXP_DAY/Images/"
CODEDIR="/cluster/home/ibarbier/Yeast_screening_pipeline"

POS_ARRAY="${WORKDIR}arrayID.csv"

SNAKEFILE="${CODEDIR}/pipeline_CPU.smk"

#================ Conda environment =======================
# activate the conda environment 
source ~/.bashrc
conda activate /cluster/home/ibarbier/miniconda3/envs/pipeline

# check that the conda environment has been activated properly
echo "Conda environment currently activated: "
echo "-- $CONDA_DEFAULT_ENV"



#================ Position =======================

# extracting the position from the corresponding row in the position array file 
# extract the position to look at from the $SLURM_ARRAY_TASK_ID
# $1 = $SLURM_ARRAY_TASK_ID 
job_nb=$1
echo "Array task ID: $job_nb"
line=$((job_nb+1))
echo "Extracting position from line $line"
POS=$(awk -v var1=$line -F ',' 'NR ==var1  { print $1 }' $POS_ARRAY)
echo "Currently looking at position $POS"


#================ Script =======================

now="$(date +"%T")"
echo "Start time : $now"

# start the snakemake pipeline 
snakemake --cores 35 --scheduler greedy --snakefile $SNAKEFILE --config position=$POS codedir=$CODEDIR workdir=$WORKDIR

now="$(date +"%T")"
echo "End time : $now"