#!/usr/bin/bash
#SBATCH -n 8
#SBATCH --nodes 1
#SBATCH --mem-per-cpu 30g
#SBATCH --time 04:00:00
#SBATCH -G 1
#SBATCH --gres=gpumem:11g
#SBATCH --tmp 120g
#SBATCH -A BIOL
#SBATCH -J testname_prediction
#SBATCH -e .//testname_%j_err.txt
#SBATCH -o .//testname_%j_out.txt

singularity exec --nv --bind /Users/ibarbier/Desktop/Yeast_screening_pipeline:/mnt/fasta_path_0:ro,/cluster/project/alphafold/uniref90:/mnt/uniref90_database_path:ro,/cluster/project/alphafold/mgnify:/mnt/mgnify_database_path:ro,/cluster/project:/mnt/data_dir:ro,/cluster/project/alphafold/pdb_mmcif:/mnt/template_mmcif_dir:ro,/cluster/project/alphafold/pdb_mmcif:/mnt/obsolete_pdbs_path:ro,/cluster/project/alphafold/pdb70:/mnt/pdb70_database_path:ro,/cluster/project/alphafold/uniref30:/mnt/uniref30_database_path:ro,/cluster/project/alphafold/bfd:/mnt/bfd_database_path:ro,/Users/ibarbier/Desktop:/mnt/output:rw /
--env="NVIDIA_VISIBLE_DEVICES=all" --env="TF_FORCE_UNIFIED_MEMORY=1" --env="XLA_PYTHON_CLIENT_MEM_FRACTION=4.0" --env="OPENMM_CPU_THREADS=8" --env="MAX_CPUS=8" /cluster/apps/nss/alphafold/alphafold-2.3.2/AlphaFold-2.3.2.sif /app/run_alphafold.sh --fasta_paths=/mnt/fasta_path_0/testname.fasta --uniref90_database_path=/mnt/uniref90_database_path/uniref90.fasta --mgnify_database_path=/mnt/mgnify_database_path/mgy_clusters_2022_05.fa --data_dir=/mnt/data_dir/alphafold --template_mmcif_dir=/mnt/template_mmcif_dir/mmcif_files --obsolete_pdbs_path=/mnt/obsolete_pdbs_path/obsolete.dat --pdb70_database_path=/mnt/pdb70_database_path/pdb70 --uniref30_database_path=/mnt/uniref30_database_path/UniRef30_2021_03 --bfd_database_path=/mnt/bfd_database_path/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt --output_dir=/mnt/output/Yeast_screening_pipeline --max_template_date=2026-08-10 --db_preset=full_dbs --model_preset=monomer --benchmark=False --use_precomputed_msas=False --num_multimer_predictions_per_model=5 --use_gpu_relax=True --logtostderr