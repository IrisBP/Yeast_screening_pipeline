#!/bin/bash
#SBATCH --account=ibarbier
#SBATCH --job-name=20260424_phenix1_screen_5nM_2.3
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=35
#SBATCH --mem-per-cpu=1GB
#SBATCH --gpus=nvidia_geforce_rtx_5090:2
#SBATCH --time=02:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err


# =====================================================================
#  Pipeline Part 1:
#  P1_segmentation => P2_tracking => P3_description => P4_mergetable 
#  
#  requirements to DL from github: 
#       python code: P1, P2, P3, P4, hungarian
#       conda environment: pipeline.yaml
#       Snakefile    
# for 1 position: 
# =====================================================================

SOURCEDIR=/mnt/biol_bc_barral_2/ibarbier/2026_GFP_screen/20260424_phenix1_screen_5nM_2.3__2026-04-24/20260424_phenix1_screen_5nM_2.3__2026-04-24/images
WORKDIR=/mnt/local_scratch/iris_projects

# =====================================================================

# find conda on the IBCGPU 
source /share/miniforge/etc/profile.d/conda.sh
#create and activate the conda environment 
conda env create -f pipeline.yaml
conda activate pipeline

snakemake --cores 6 --use-conda --conda-frontend conda --scheduler greedy