#!/bin/bash

source ~/.bashrc
conda activate /cluster/home/ibarbier/miniconda3/envs/pipeline
echo "Conda environment currently activated: "
echo "-- $CONDA_DEFAULT_ENV"

python /cluster/home/ibarbier/Yeast_screening_pipeline/DL_cellpose.py