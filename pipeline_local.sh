#!/bin/bash

#================ To modify =======================

EXP_DAY='20260424_phenix1_screen_5nM_2.3'
EXP_ID='p2rep3'
POS='p2rep3_r05c06f02'

#============= Localization Variables =============
# path to the various directory required for the pipeline 
WORKDIR="/Users/ibarbier/Desktop/local_pipeline/$EXP_DAY"
RESULTSDIR="$WORKDIR/results/"

IMGDIR="/Volumes/ADATA_SE880/20260424_phenix1_screen_5nM_2.3__2026-04-24/Images/"

CODEDIR="/Users/ibarbier/Desktop/local_pipeline//Yeast_screening_pipeline"
SNAKEFILE="$CODEDIR/pipeline_local.smk"

#================ Script =======================

conda activate /opt/miniconda3/envs/pipeline

# check that the conda environment has been activated properly
echo "Conda environment currently activated: "
echo "-- $CONDA_DEFAULT_ENV"

# create the result folder 
if [ ! -d "$WORKDIR" ]; then
  mkdir $WORKDIR
fi

# create the result folder 
if [ ! -d "$RESULTSDIR" ]; then
  mkdir $RESULTSDIR
fi

# submit snakemake 
# --use-conda --conda-frontend conda

snakemake --cores 6 --use-conda --conda-frontend conda --scheduler greedy --snakefile $SNAKEFILE --config position=$POS codedir=$CODEDIR workdir=$WORKDIR imgdir=$IMGDIR


