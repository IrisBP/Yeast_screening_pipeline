#!/bin/bash
# Translate SLURM job states to snakemake cluster-generic expected values:
# running, success, failed
JOBID=$1
STATUS=$(squeue --noheader --format=%T -j "$JOBID" 2>/dev/null)

if [ -z "$STATUS" ]; then
    # Job not in queue — check if it completed successfully via exit code
    # Since sacct is disabled, assume success if not in queue
    echo "success"
    exit 0
fi

case "$STATUS" in
    RUNNING|PENDING|CONFIGURING|COMPLETING|RESIZING|SUSPENDED)
        echo "running"
        ;;
    COMPLETED)
        echo "success"
        ;;
    FAILED|CANCELLED*|TIMEOUT|NODE_FAIL|PREEMPTED|BOOT_FAIL|DEADLINE|OUT_OF_MEMORY)
        echo "failed"
        ;;
    *)
        echo "running"
        ;;
esac


