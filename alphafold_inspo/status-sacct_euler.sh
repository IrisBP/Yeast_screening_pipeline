                                                                                           
#!/usr/bin/env bash
# `install -D /dev/stdin` from https://stackoverflow.com/questions/21052925/bash-redirect-and-append-to-non-existent-file-dir>
# Check status of Slurm job

jobid="$1"

if [[ "$jobid" == Submitted ]]
then
  echo smk-simple-slurm: Invalid job ID: "$jobid" >&2
  echo smk-simple-slurm: Did you remember to add the flag --parsable to your sbatch call? >&2
  exit 1
fi

output=`sacct -j "$jobid" --format State --noheader | head -n 1 | awk '{print $1}'`

if [[ $output =~ ^(COMPLETED).* ]]
then
  echo success
  sacct --jobs="$jobid" --json | install -D /dev/stdin .snakemake-eu/sacct/"$jobid".json
  myjobs -j "$jobid" | install -D /dev/stdin .snakemake-eu/myjobs/"$jobid".txt
elif [[ $output =~ ^(RUNNING|PENDING|COMPLETING|CONFIGURING|SUSPENDED).* ]]
then
  echo running
elif [[ -z "$output" ]]
then
  echo smk-simple-slurm: sacct for job ID "$jobid" is null/empty, exiting with "running" >&2
  echo running
else
  echo smk-simple-slurm: sacct for job ID "$jobid" returned: "'$output'", exiting with "failed" >&2
  echo failed
  sacct --jobs="$jobid" --json | install -D /dev/stdin .snakemake-eu/sacct/"$jobid".json
  myjobs -j "$jobid" | install -D /dev/stdin .snakemake-eu/myjobs/"$jobid".txt
fi
