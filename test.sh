#!/bin/bash

#SBATCH --account=es_biol
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00
#SBATCH --mem-per-cpu=20000
#SBATCH --output=/cluster/home/ibarbier/test_out/slurm-%j.out
#SBATCH --error=/cluster/home/ibarbier/test_out/slurm-%j.err

source ~/.bashrc
conda activate /cluster/home/ibarbier/miniconda3/envs/pipeline
echo "Conda environment currently activated: "
echo "-- $CONDA_DEFAULT_ENV"

POS_ARRAY="./Yeast_screening_pipeline/arrayID.csv"

EXP_DAY=$2
echo "$EXP_DAY"

job_nb=$1
echo "$job_nb"
line=$((job_nb+1))
echo "$line"
POS=$(awk -v var1=$line -F ',' 'NR ==var1  { print $1 }' $POS_ARRAY)
echo "$POS"
echo "successful test - job nb ${job_nb}" 

