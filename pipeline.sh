#!/bin/bash
#SBATCH --account=ibarbier
#SBATCH --partition=slurm
#SBATCH --job-name=20260424_phenix1_screen_5nM_2.3
#SBATCH --nodes=1                     # Number of nodes
#SBATCH --ntasks-per-node=1          # Number of tasks per node           
#SBATCH --cpus-per-task=80             # Number of CPU cores per task
#SBATCH --mem-per-cpu=1GB
#SBATCH --gpus=nvidia_geforce_rtx_5090:2
#SBATCH --time=02:00:00               # Maximum runtime (D-HH:MM:SS)
#SBATCH --output=/mnt/local_scratch/iris_projects/Yeast_screening_pipeline/out.txt
#SBATCH --error=/mnt/local_scratch/iris_projects/Yeast_screening_pipeline/error.txt


# =====================================================================
#  Pipeline Part 1:
#  P1_segmentation => P2_tracking => P3_description => P4_mergetable 
#  
#  requirements to DL from github: 
#       python code: P1, P2, P3, P4, hungarian
#       conda environment: pipeline.yaml
#       Snakefile    
# rm -rf Yeast_screening_pipeline
# git clone https://github.com/IrisBP/Yeast_screening_pipeline.git  
# cd ./Yeast_screening_pipeline
# to submit: sbatch pipeline.sh
#
#
# sbatch --array=1-96%1  # Job array from task ID 1 to 100, with a step size of 1
# =====================================================================

SOURCEDIR="/mnt/biol_bc_barral_2/ibarbier/2026_GFP_screen/20260424_phenix1_screen_5nM_2.3__2026-04-24/20260424_phenix1_screen_5nM_2.3__2026-04-24/Images/"
EXP="20260424_phenix1_screen_5nM_2.3"
WORKDIR="/mnt/local_scratch/iris_projects/"
POS='p2rep3_r03c08f05'
# =====================================================================

# find conda on the IBCGPU 
source /share/miniforge/etc/profile.d/conda.sh
#create and activate the conda environment 
conda env create -f pipeline.yaml
conda activate pipeline
echo 'Pipeline conda environment up and running !' 

echo 'Looking at ' $POS 

# --jobs is the number of jobs to run in parallel 
srun snakemake --cores 80 --sdm conda --workflow-profile profiles \
    --configfile profiles/config.yaml \
    --snakefile pipeline.smk \
    --config position=$POS sourcedir=$SOURCEDIR workdir=$WORKDIR exp=$EXP
