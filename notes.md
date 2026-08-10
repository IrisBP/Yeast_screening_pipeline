From studying the Alphafold deployment on the IBC gpu 

=> snakemake file that compile indivually build rules 
# to look into >> snakemake commands: 
    include - used to split the workflow into multiple snakefiles - Snakemake allows you to define external workflows as modules. 
    wildcard_constraints: define local or global wildcard constraints that apply for all rules


local_config.yaml: 
Controls HOW the workflow runs (not how jobs are submitted -- that is the --profile).
 Disables Euler-specific envmodules. Sets thread counts for EPYC 9654 (96-core).


Will likely need this: 

>> slurm-status-ibc.sh | accessible by batch-infer-local 
Translate SLURM job states to snakemake cluster-generic expected values:
running, success, failed
Since sacct is disabled, assume success if not in queue
--- used in batch-infer-local.sh

>> batch-infer-local.sh  | keep what I need and use as my pipeline.sh 
local workstation replacement for the Euler `batch-infer` script
# to look into >> Fast NVMe scratch
- NVMe = Non-Volatile Memory Express = communication interface designed for SSDs and communicates between the storage interface and the system’s CPU using high-speed PCIe sockets without the limitations of form factor.
=> here: direct how to transfer the data 

#  runtime Snakemake profile
=> profile = configuration file 
"$RUNTIME_PROFILE/config.yaml" => likely config-ibc.yaml => the config file for the actually smk pipeline 
conda run -n "$CONDA_ENV_NAME" \
    snakemake "$METHOD" \
        --snakefile "$REPO_ROOT/workflow/targets/$METHOD.smk" \
        --configfile "$DEFAULTS" "$DEFAULTS_LOCAL" "$RESULTS_DIR/config.yaml" \
        --profile "$RUNTIME_PROFILE" \
        --workflow-profile "$WORKFLOW_PROFILE" \ #workflow profile hjere is local_config.yaml
        --directory "$RESULTS_DIR" \
        --rerun-triggers input \
        --keep-going \
        $EXTRA \
    2>&1 | tee "$LOGS_DIR/batch-infer-local_${METHOD}_$(date +%H%M%S).log"

# bacth infer local created a conda environment with 
- snakemake-executor-plugin-cluster-generic for native v8 SLURM supportugin-slurm  # replaces clu
- snakemake-executor-plugin-cluster-generic # kept for colabfold target compatibility
A generic Snakemake executor plugin for submission of jobs to cluster systems that provide a submission command that accepts the path to a job script (like PBS, LSF, SGE, ...).
-  snakemake-storage-plugin-fs # Snakemake storage plugin that reads and writes from a locally mounted filesystem using rsync.

Difference with what im using ?
- snakemake-executor-plugin-slurm==2.7.1
- snakemake-executor-plugin-slurm-jobstep==0.6.1

>> config-ibc.yaml | use as inspo for my smk config file
config-ibc.yaml and slurm-status-ibc.sh in the same folder /opt/ibc/alphafold3/batch-infer/current/software/smk-simple-slurm-local
Differences between config-ibc and config-ibc2
in config-ibc only 
SMK_SLURM_GID_OPTION="__SLURM_GID_OPTION__" vs 3: SMK_SLURM_GID_OPTION="" &&
--export=ALL,TMPDIR=__TMPDIR_
+
set-resources:

in config-ibc2 only 
--tmp={resources.disk_mb}

2: cluster-generic-status-cmd: status-sacct.sh vs 
1: cluster-generic-status-cmd: __STATUS_CMD__
3: cluster-generic-status-cmd: /opt/ibc/alphafold3/batch-infer/current/software/smk-simple-slurm-local/slurm-status.sh

2: disk_mb: 1024 vs 1/3: disk_mb: 51200
2: restart-times: 3 vs 1: restart-times: 0
2: jobs: 500 vs 1: jobs: 4

>> python generate_SLURM_script.py  | both found in /opt/ibc/alphafold3/batch-infer/current/workflow/scripts/alphafold2/setup_run_script_AF2.3.2
==>>>> missing generate_singularity_cmd
python generate_SLURM_script.py -f [path ot fastafile] -o [output/working directory] -s [your share for GPU usage]

python generate_SLURM_script.py -f testname.fasta -o ./ -s BIOL

to run alphafold: 
Run time:            04:00:00 (hh:mm:ss)
Number of CPUs:      8
CPU memory per CPU:  30 (GB)
Number of GPUs:      1
Total GPU memory:    11 (GB)
Total scratch space: 120 (GB)

# what is Apache / FastAPI ? 
https://en.wikipedia.org/wiki/Apache_HTTP_Server

API =  application programming interface (API) is a connection between computers or between computer programs. connects computers or pieces of software to each other
One of the main purpose of APIs is to hide the internal details of how a system works, exposing only those parts a programmer will find useful and keeping them consistent even if the internal details later change. An API may be custom-built for a particular pair of systems, or it may be a shared standard allowing interoperability among many systems.
An API opens a software system to interactions from the outside. It allows two software systems to communicate across a boundary — an interface — using mutually agreed-upon signals.[4] In other words, an API connects software entities together