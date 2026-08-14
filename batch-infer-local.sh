#!/bin/bash
# batch-infer-local  —  local workstation replacement for the Euler `batch-infer` script
#
# Usage:
#   ./batch-infer-local METHOD RESULTS_DIR [--dry-run]
#
# Examples:
#   ./batch-infer-local alphafold3_onegpu results/alphafold3_adhoc_examples
#   ./batch-infer-local alphafold3_onegpu results/alphafold3_adhoc_examples --dry-run
#   ./batch-infer-local boltz             results/boltz_example
#
# What changed vs the original `batch-infer`:
#   - No longer wraps output in an sbatch heredoc; runs Snakemake directly
#   - Uses smk-simple-slurm-local profile (Snakemake v8 SLURM executor plugin)
#   - Loads defaults-local.yaml (local paths) after defaults.yaml
#   - Uses workflow/profiles/local instead of workflow/profiles/default
#   - Sets TMPDIR to fast NVMe scratch
#   - Sets up conda env instead of Euler venv+modules
#   - Logs to RESULTS_DIR/.snakemake-local/logs/

set -euo pipefail
export SLURM_UMASK=${SLURM_UMASK:-0002}
umask "$SLURM_UMASK"

METHOD=${1:?Usage: $0 METHOD RESULTS_DIR [--dry-run]}
RESULTS_DIR=${2:?Usage: $0 METHOD RESULTS_DIR [--dry-run]}
EXTRA=${3:-}   # optional --dry-run or other snakemake flags

# ── Paths (all relative to repo root) ────────────────────────────────────────
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="$REPO_ROOT/software/smk-simple-slurm-local"
WORKFLOW_PROFILE="$REPO_ROOT/workflow/profiles/local"
DEFAULTS="$REPO_ROOT/workflow/config/defaults.yaml"
DEFAULTS_LOCAL="$REPO_ROOT/workflow/config/defaults-local.yaml"
LOGS_DIR="$RESULTS_DIR/.snakemake-local/logs/$(date +%y-%m-%d)"
RUNTIME_PROFILE="$RESULTS_DIR/.snakemake-local/runtime-profile"
CLUSTER_LOG_ROOT="$RESULTS_DIR/.snakemake-local/cluster-logs"

# ── Fast NVMe scratch ────────────────────────────────────────────────────────
SCRATCH_ROOT=${BATCH_INFER_TMP_ROOT:-/mnt/local_scratch/tmp/batch-infer}
RUN_USER=${USER:-$(id -un 2>/dev/null || echo unknown)}
RUN_USER=$(printf '%s' "$RUN_USER" | sed -e 's#[^A-Za-z0-9._-]#_#g')
RUN_NAME=$(basename "$RESULTS_DIR" | sed -e 's#[^A-Za-z0-9._-]#_#g')
RUN_ID=${SLURM_JOB_ID:-$$}
export TMPDIR="$SCRATCH_ROOT/$RUN_USER/${RUN_NAME}_${RUN_ID}"
mkdir -p "$TMPDIR"

# Some portal users may not have an initialized home directory on the HPC.
# Keep Conda/Snakemake config and cache writes inside the job folder instead.
JOB_HOME="$RESULTS_DIR/.snakemake-local/home"
export HOME="$JOB_HOME"
export XDG_CACHE_HOME="$JOB_HOME/.cache"
export XDG_CACHE_SNAKEMAKE="$JOB_HOME/.cache/snakemake"
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
mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_STATE_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_SNAKEMAKE"

# ── Render a runtime Snakemake profile with the correct absolute status script ─
cp "$PROFILE/config.yaml" "$RUNTIME_PROFILE/config.yaml"
sed -i.bak "s#__STATUS_CMD__#$REPO_ROOT/software/smk-simple-slurm-local/slurm-status.sh#g" "$RUNTIME_PROFILE/config.yaml"
sed -i.bak "s#__CLUSTER_LOG_ROOT__#$CLUSTER_LOG_ROOT#g" "$RUNTIME_PROFILE/config.yaml"
sed -i.bak "s#__TMPDIR__#$TMPDIR#g" "$RUNTIME_PROFILE/config.yaml"
sed -i.bak "s#__SLURM_GID_OPTION__#$SLURM_GID_OPTION#g" "$RUNTIME_PROFILE/config.yaml"
rm -f "$RUNTIME_PROFILE/config.yaml.bak"

# ── Conda / Snakemake environment ─────────────────────────────────────────────
# Activate the batch-infer conda env (create it first if needed — see README)
CONDA_ENV_NAME="batch-infer-env"
if ! conda run -n "$CONDA_ENV_NAME" snakemake --version &>/dev/null; then
    echo "[batch-infer-local] Creating conda env '$CONDA_ENV_NAME' from workflow/envs/batch-infer.yaml ..."
    conda env create -n "$CONDA_ENV_NAME" -f "$REPO_ROOT/workflow/envs/batch-infer.yaml"
fi


# ── Run ───────────────────────────────────────────────────────────────────────

echo "[batch-infer-local] Starting: method=$METHOD results=$RESULTS_DIR tmpdir=$TMPDIR"
if [ -n "$SLURM_GID_OPTION" ]; then
    echo "[batch-infer-local] Slurm gid option: $SLURM_GID_OPTION"
fi
echo "[batch-infer-local] Logs: $LOGS_DIR"

conda run -n "$CONDA_ENV_NAME" \
    snakemake "$METHOD" \
        --snakefile "$REPO_ROOT/workflow/targets/$METHOD.smk" \
        --configfile "$DEFAULTS" "$DEFAULTS_LOCAL" "$RESULTS_DIR/config.yaml" \
        --profile "$RUNTIME_PROFILE" \
        --workflow-profile "$WORKFLOW_PROFILE" \
        --directory "$RESULTS_DIR" \
        --rerun-triggers input \
        --keep-going \
        $EXTRA \
    2>&1 | tee "$LOGS_DIR/batch-infer-local_${METHOD}_$(date +%H%M%S).log"