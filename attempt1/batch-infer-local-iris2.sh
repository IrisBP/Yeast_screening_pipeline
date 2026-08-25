#!/bin/bash
# batch-infer-local  —  local workstation replacement for the Euler `batch-infer` script
#
# Usage:
#   ./batch-infer-local METHOD RESULTS_DIR [--dry-run]
#
# Examples:
#   sbatch ./Yeast_screening_pipeline/batch-infer-local-iris2.sh Yeast_screening_pipeline ./Results 
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

METHOD=${1:?Usage: $0 METHOD RESULTS_DIR [--dry-run]}
RESULTS_DIR=${2:?Usage: $0 METHOD RESULTS_DIR [--dry-run]}
EXTRA=${3:-}   # optional --dry-run or other snakemake flags
POS='p2rep3_r07c06f02'
SOURCEDIR="/mnt/biol_bc_barral_2/ibarbier/2026_GFP_screen/20260424_phenix1_screen_5nM_2.3__2026-04-24/20260424_phenix1_screen_5nM_2.3__2026-04-24/Images/"
WORKDIR="/mnt/local_scratch/iris_projects"
EXP="20260424_phenix1_screen_5nM_2.3"

# ── Paths (all relative to repo root) ────────────────────────────────────────
#REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$WORKDIR/$METHOD"
PROFILE="$REPO_ROOT/profiles"
RUNTIME_PROFILE="$RESULTS_DIR/runtime-profile/$POS"
mkdir -p "$RUNTIME_PROFILE"
cp "$PROFILE/config.yaml" "$RUNTIME_PROFILE/config.yaml"
sed -i.bak "s#__STATUS_CMD__#$PROFILE/slurm-status-ibc.sh#g" "$RUNTIME_PROFILE/config.yaml"
sed -i.bak "s#____POS__ __#$POS#g" "$RUNTIME_PROFILE/config.yaml"
sed -i.bak "s#__SOURCE__#$SOURCEDIR#g" "$RUNTIME_PROFILE/config.yaml"
sed -i.bak "s#__EXP__#$EXP#g" "$RUNTIME_PROFILE/config.yaml"
sed -i.bak "s#__WORK__#$WORKDIR#g" "$RUNTIME_PROFILE/config.yaml"
rm -f "$RUNTIME_PROFILE/config.yaml.bak"


# ── Conda / Snakemake environment ─────────────────────────────────────────────

# Activate the batch-infer conda env (create it first if needed — see README)

CONDA_ENV_NAME="batch-infer-env"
if ! conda run -n "$CONDA_ENV_NAME" snakemake --version &>/dev/null; then
    echo "[batch-infer-local] Creating conda env '$CONDA_ENV_NAME' from '$REPO_ROOT'/workflow_profiles/batch_infer_env.yaml ..."
    conda env create -n "$CONDA_ENV_NAME" -f "$REPO_ROOT/workflow_profiles/batch_infer_env.yaml"
fi


# ── Run ───────────────────────────────────────────────────────────────────────

#echo "[batch-infer-local] Starting: method=$METHOD results=$RESULTS_DIR tmpdir=$TMPDIR"

conda run -n "$CONDA_ENV_NAME" \
    snakemake \
        --snakefile "$REPO_ROOT/pipeline.smk" \
        --configfile "$RUNTIME_PROFILE/config.yaml" \
        --workflow-profile "$RUNTIME_PROFILE" \
        --keep-going \
        
        
    