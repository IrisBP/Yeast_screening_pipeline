# Local workstation overrides for batch-infer
# Replaces Euler cluster paths in defaults.yaml
# Usage: --configfile workflow/config/defaults.yaml workflow/config/defaults-local.yaml

# AF3 container (.sif) - CUDA 12.9 build
alphafold3_docker: /mnt/local_scratch/alphafold/alphafold3/alphafold3_12.9.sif

# AF3 databases
alphafold3_databases: /mnt/local_scratch/alphafold/AF3_DB

# AF3 model weights
alphafold3_models: /mnt/local_scratch/alphafold/alphafold3/weights