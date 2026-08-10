#!/bin/bash
# batch-infer-local  —  local workstation replacement for the Euler `batch-infer` script
# modified by Iris Barbier 
#
# Usage:
#   ./batch-infer-local METHOD RESULTS_DIR [--dry-run]
#
# Examples:
#   ./batch-infer-local alphafold3_onegpu results/alphafold3_adhoc_examples
#   ./batch-infer-local alphafold3_onegpu results/alphafold3_adhoc_examples --dry-run
#   ./batch-infer-local boltz             results/boltz_example
#   ./batch-infer-local-iris.sh ./ ./results --dry-run #in /mnt/local_scratch/iris_projects/Yeast_screening_pipeline
    
#
# What changed vs the original `batch-infer`:
#   - No longer wraps output in an sbatch heredoc; runs Snakemake directly
#   - Uses smk-simple-slurm-local profile (Snakemake v8 SLURM executor plugin)
#   - Loads defaults-local.yaml (local paths) after defaults.yaml
#   - Uses workflow/profiles/local instead of workflow/profiles/default
#   - Sets TMPDIR to fast NVMe scratch
#   - Sets up conda env instead of Euler venv+modules
#   - Logs to RESULTS_DIR/.snakemake-local/logs/

set -euxo pipefail
# set -e => exit if any command has a non zero exit status => stops everything if unhandled runtime error 
# set -u => affect variables => reference to undefined variable leads to an error (like in python)
# set -x => enable a shell more where all executed commands are printed in terminal (used for debugging)
# set -o pipefail => prevents errors in pipeline from being masked - return the error code instead of the last cmd code 
export SLURM_UMASK=${SLURM_UMASK:-0002}
umask "$SLURM_UMASK" #used to set default permissions for files or directories the user creates.
# 002 => write only permission 

METHOD=${1:?Usage: $0 METHOD RESULTS_DIR [--dry-run]} #get the path to method pipeline 
RESULTS_DIR=${2:?Usage: $0 METHOD RESULTS_DIR [--dry-run]} #get path to output directory 
EXTRA=${3:-}   # optional --dry-run or other snakemake flags #get any other input variables 


# ── Paths (all relative to repo root) ────────────────────────────────────────
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # get full path to current directory : /Users/ibarbier/Desktop/Yeast_screening_pipeline
PROFILE="$REPO_ROOT/profiles" #get path to directory where config.yaml and slurm-status.sh are store 
WORKFLOW_PROFILE="$REPO_ROOT/workflow_profiles" #get path to directory to where the local_config.yaml is stored 
DEFAULTS="$REPO_ROOT/defaults.yaml" #path to defaults.yaml
DEFAULTS_LOCAL="$REPO_ROOT/defaults-local.yaml" #path to defaults-local.yaml
LOGS_DIR="$RESULTS_DIR/.snakemake-local/logs/$(date +%y-%m-%d)" # path to logs - in the results folder - results/.snakemake-local/logs/26-08-10
RUNTIME_PROFILE="$RESULTS_DIR/.snakemake-local/runtime-profile" # path to tuntimes - in the results folder - results/.snakemake-local/runtime-profile 
CLUSTER_LOG_ROOT="$RESULTS_DIR/.snakemake-local/cluster-logs" # path to cluser logs - in the resiults folder - results/esults/pipeline/.snakemake-local/cluster-logs


# ── Fast NVMe scratch ────────────────────────────────────────────────────────
SCRATCH_ROOT=${BATCH_INFER_TMP_ROOT:-/mnt/local_scratch/iris_projects/tmp/batch-infer} 
# SCRATCH_ROOT=/mnt/local_scratch/iris_projects/tmp/batch-infer
SCRATCH_ROOT=${BATCH_INFER_TMP_ROOT:-/mnt/local_scratch/tmp/batch-infer}
RUN_NAME=$(basename "$RESULTS_DIR" | sed -e 's#[^A-Za-z0-9._-]#_#g')
RUN_ID=${SLURM_JOB_ID:-$$}
export TMPDIR="$SCRATCH_ROOT/${RUN_NAME}_${RUN_ID}"
mkdir -p "$TMPDIR" # create a folder in /mnt/local_scratch/iris_projects/tmp/batch-infer/RunName_RunID

# Some portal users may not have an initialized home directory on the HPC.
# Keep Conda/Snakemake config and cache writes inside the job folder instead.
JOB_HOME="$RESULTS_DIR/.snakemake-local/home"
export HOME="$JOB_HOME"
export XDG_CACHE_HOME="$JOB_HOME/.cache"
export XDG_CONFIG_HOME="$JOB_HOME/.config"
export XDG_STATE_HOME="$JOB_HOME/.local/state"
export XDG_DATA_HOME="$JOB_HOME/.local/share"

SLURM_GID_OPTION=""
if [ -n "${BATCH_INFER_SLURM_GID:-}" ]; then
    if [ "$(id -u)" -eq 0 ]; then
        SLURM_GID_OPTION="--gid=${BATCH_INFER_SLURM_GID}"
    else
        echo "[batch-infer-local] Ignoring BATCH_INFER_SLURM_GID=$BATCH_INFER_SLURM_GID because sbatch --gid is only permitte>
    fi
fi


mkdir -p "$LOGS_DIR"
mkdir -p "$RUNTIME_PROFILE"
mkdir -p "$CLUSTER_LOG_ROOT"
mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_STATE_HOME" "$XDG_DATA_HOME"
