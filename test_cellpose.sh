#!/bin/bash

#SBATCH --account=es_biol
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00
#SBATCH --mem-per-cpu=20000
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err

source ~/.bashrc
conda activate /cluster/home/ibarbier/miniconda3/envs/pipeline
echo "Conda environment currently activated: "
echo "-- $CONDA_DEFAULT_ENV"

python /cluster/home/ibarbier/test.py