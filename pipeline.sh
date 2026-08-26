#!/bin/bash

#SBATCH --account=es_biol
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00
#SBATCH --mem-per-cpu=1024
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err

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

#================ Script =======================
echo $WORKDIR
echo $SOURCEDIR
echo $RESULTS_DIR
echo $CODEDIR
echo $IMGDIR

source ~/.bashrc
conda activate pipeline

if [ ! -d "$IMGDIR" ]; then
  echo "$IMGDIR does not exist. Copying data now"
  mkdir $WORKDIR
  cp -R $SOURCEDIR $WORKDIR
fi


mkdir $RESULTSDIR

python /cluster/home/ibarbier/Yeast_screening_pipeline/make_array_file.py  $WORKDIR $EXP_ID

snakemake --slurm --use-conda --conda-frontend conda --scheduler greedy --snakefile pipeline.smk --config position=$POS codedir=$CODEDIR workdir=$WORKDIR

