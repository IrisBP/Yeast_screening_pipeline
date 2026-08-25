#!/bin/bash

#SBATCH --account=es_biol
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00
#SBATCH --mem-per-cpu=1024

source /cluster/home/ibarbier/miniconda3/bin/conda.sh

if conda info --envs | grep -q pipeline; then
 echo "Pipeline environment already exists"; else 
 conda conda env create -f pipeline.yaml
fi

conda activate pipeline