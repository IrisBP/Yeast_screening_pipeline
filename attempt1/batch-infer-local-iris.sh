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
#   sbatch ./Yeast_screening_pipeline/batch-infer-local-iris.sh ./Yeast_screening_pipeline ./Results --dry-run #in /mnt/local_scratch/iris_projects/Yeast_screening_pipeline
#   sbatch ./Yeast_screening_pipeline/batch-infer-local-iris.sh ./Yeast_screening_pipeline ./Results 

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
REPO_ROOT="/mnt/local_scratch/iris_projects/Yeast_screening_pipeline" # get full path to current directory : /Users/ibarbier/Desktop/Yeast_screening_pipeline
PROFILE="$REPO_ROOT/profiles" #get path to directory where config.yaml and slurm-status.sh are store 
WORKFLOW_PROFILE="$REPO_ROOT/workflow_profiles" #get path to directory to where the local_config.yaml is stored 
# DEFAULTS="$REPO_ROOT/defaults.yaml" #path to defaults.yaml + removed --configfile "$DEFAULTS" "$DEFAULTS_LOCAL" "$RESULTS_DIR/config.yaml" \ from cmd 
# DEFAULTS_LOCAL="$REPO_ROOT/defaults-local.yaml" #path to defaults-local.yaml
LOGS_DIR="$RESULTS_DIR/.snakemake-local/logs/$(date +%y-%m-%d)" # path to logs - in the results folder - results/.snakemake-local/logs/26-08-10
RUNTIME_PROFILE="$RESULTS_DIR/.snakemake-local/runtime-profile" # path to runtimes - in the results folder - results/.snakemake-local/runtime-profile 
CLUSTER_LOG_ROOT="$RESULTS_DIR/.snakemake-local/cluster-logs" # path to cluser logs - in the resiults folder - results/esults/pipeline/.snakemake-local/cluster-logs


# ── Fast NVMe scratch ────────────────────────────────────────────────────────

SCRATCH_ROOT=${BATCH_INFER_TMP_ROOT:-/mnt/local_scratch/tmp/batch-infer}
RUN_USER=${USER:-$(id -un 2>/dev/null || echo unknown)}
RUN_NAME=$(basename "$RESULTS_DIR" | sed -e 's#[^A-Za-z0-9._-]#_#g')
RUN_ID=${SLURM_JOB_ID:-$$}
export TMPDIR="$SCRATCH_ROOT/ibarbier/${RUN_NAME}_${RUN_ID}"
mkdir -p "$TMPDIR"


# Some portal users may not have an initialized home directory on the HPC.
# Keep Conda/Snakemake config and cache writes inside the job folder instead.
JOB_HOME="$RESULTS_DIR/.snakemake-local/home"
export HOME="$JOB_HOME"
export XDG_CACHE_HOME="$JOB_HOME/.cache"
export XDG_CONFIG_HOME="$JOB_HOME/.config"
export XDG_STATE_HOME="$JOB_HOME/.local/state"
export XDG_DATA_HOME="$JOB_HOME/.local/share"

mkdir -p "$LOGS_DIR"
mkdir -p "$RUNTIME_PROFILE"
mkdir -p "$CLUSTER_LOG_ROOT"
mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_STATE_HOME" "$XDG_DATA_HOME"


# ── Render a runtime Snakemake profile with the correct absolute status script ─
cp "$PROFILE/config.yaml" "$RUNTIME_PROFILE/config.yaml"
sed -i.bak "s#__STATUS_CMD__#$PROFILE/slurm-status-ibc.sh#g" "$RUNTIME_PROFILE/config.yaml"
sed -i.bak "s#__CLUSTER_LOG_ROOT__#$CLUSTER_LOG_ROOT#g" "$RUNTIME_PROFILE/config.yaml"
sed -i.bak "s#__TMPDIR__#$TMPDIR#g" "$RUNTIME_PROFILE/config.yaml"
rm -f "$RUNTIME_PROFILE/config.yaml.bak"

# ── Conda / Snakemake environment ─────────────────────────────────────────────
# Activate the batch-infer conda env (create it first if needed — see README)
CONDA_ENV_NAME="batch-infer-env"
if ! conda run -n "$CONDA_ENV_NAME" snakemake --version &>/dev/null; then
    echo "[batch-infer-local] Creating conda env '$CONDA_ENV_NAME' from workflow_profiles/batch_infer_env.yaml ..."
    conda env create -n "$CONDA_ENV_NAME" -f "$REPO_ROOT/workflow_profiles/batch_infer_env.yaml"
fi


# ── Run ───────────────────────────────────────────────────────────────────────

echo "[batch-infer-local] Starting: method=$METHOD results=$RESULTS_DIR tmpdir=$TMPDIR"
echo "[batch-infer-local] Logs: $LOGS_DIR"

conda run -n "$CONDA_ENV_NAME" \
    snakemake "$METHOD" \
        --snakefile "$REPO_ROOT/pipeline.smk" \
        --configfile "$RUNTIME_PROFILE/config.yaml" \
        --profile "$RUNTIME_PROFILE" \
        --workflow-profile "$WORKFLOW_PROFILE" \
        --directory "$RESULTS_DIR" \
        --keep-going \
        --config position='p2rep3_r07c06f02' sourcedir="/mnt/biol_bc_barral_2/ibarbier/2026_GFP_screen/20260424_phenix1_screen_5nM_2.3__2026-04-24/20260424_phenix1_screen_5nM_2.3__2026-04-24/Images/" workdir="/mnt/local_scratch/iris_projects/Yeast_screening_pipeline" exp="20260424_phenix1_screen_5nM_2.3" results="$RESULTS_DIR" \
        
    2>&1 | tee "$LOGS_DIR/batch-infer-local_${METHOD}_$(date +%H%M%S).log"


'/mnt/local_scratch/iris_projects/tmp/batch-infer/Results_2155/
Results/.snakemake-local/home/.cache/snakemake/snakemake/source-cache/runtime-cache/tmpmioocw45/file/mnt/local_scratch/iris_projects/Yeast_screening_pipeline/pipeline.smkg86y1p18'