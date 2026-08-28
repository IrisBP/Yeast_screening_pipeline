#!/bin/bash

#SBATCH --account=es_biol
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00
#SBATCH --mem-per-cpu=20000
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err

#export OMP_NUM_THREADS=35

#================ To modify =======================

EXP_DAY='20260424_phenix1_screen_5nM_2.3'
EXP_ID='p2rep3'
POS='p2rep3_r05c06f02'

#============= Localization Variables =============
# path to the various directory required for the pipeline 
WORKDIR="/cluster/scratch/ibarbier/$EXP_DAY/"
RESULTSDIR="/cluster/scratch/ibarbier/$EXP_DAY/results/"
IMGDIR="/cluster/scratch/ibarbier/$EXP_DAY/Images/"
SOURCEDIR="/nfs/nas22/fs2202/biol_bc_barral_2/ibarbier/2026_GFP_screen/$EXP_DAY/$EXP_DAY/Images/"
CODEDIR="/cluster/home/ibarbier/Yeast_screening_pipeline/"

ARRAY_PY=/cluster/home/ibarbier/Yeast_screening_pipeline/make_array_file.py
SNAKEFILE=/cluster/home/ibarbier/Yeast_screening_pipeline/pipeline.smk
#================ Script =======================

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

# create the result folder 
if [ ! -d "$RESULTSDIR" ]; then
  mkdir $RESULTSDIR
fi

# create the array ID table 
python $ARRAY_PY $WORKDIR $EXP_ID

# submit snakemake 
# --use-conda --conda-frontend conda

snakemake --cores 35 --use-conda --conda-frontend conda --scheduler greedy --snakefile $SNAKEFILE --config position=$POS codedir=$CODEDIR workdir=$WORKDIR

