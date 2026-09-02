# Yeast screening pipeline

Last update: 31 August 2026 \
Trying the pipeline on 20260427_phenix1_screen_5nM_3.3 => ran successfully for 476 positions \ 
After a first successful run, applying the pipeline to the other positions: \
- 20260428_phenix1_screen_5nM_4.3  
- 20260511_phenix1_screen_5nM_5.1
- 20260514_phenix1_screen_5nM_1.1 (currently running)


## Analysis pipeline for image based screening in yeast

This pipeline takes as input images acquired on the Phenix Microscope over multiple time points. 
Images are acquired in 4 channels: DPC, green, red, far red over multiple hours time course. 
The pipeline performs segmentation (CellPose), tracking (Hungarian) and single cell analysis. It records the mean, max and standard deviation of fluorescence intensity in all 3 fluorescence channels, use the PIFia model to characterize the protein behavior and the SchmooNet model to classify the cell behavior at each frame. 

Parallel execution implemented with Snakemake - designed for SLURM on cluster 

## Useful Euler / Bash commands 
Navigate to home directory: `cd /cluster/home/ibarbier` \
Navigate to scratch: `cd /cluster/scratch/ibarbier ` \
To count file nb: `ls -1q | wc -l` \
To remove entire directory and its content: `rm -rf Dir_name`\
To remove conda environment: `conda env remove -n pipeline`
To copy back to NAS: `rsync -av --ignore-existing ibarbier@euler.ethz.ch:/cluster/scratch/ibarbier/20260511_phenix1_screen_5nM_5.1/results/ /nfs/nas22/fs2202/biol_bc_barral_2/ibarbier/2026_GFP_screen/20260511_phenix1_screen_5nM_5.1/Results/`


## INSTALLATION ON EULER 

in home directory: 
- Download Miniconda and install: \
`wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh` \
`bash ~/Miniconda3-latest-Linux-x86_64.sh` \ 
to check the installation and version: `conda -V `
- Download the pipeline: 
`git clone https://github.com/IrisBP/Yeast_screening_pipeline.git`  
- Create the conda environment: 
`conda env create -f /cluster/home/ibarbier/Yeast_screening_pipeline/pipeline.yaml` 
- Create a slurm_out folder in home directory: `mkdir array_slurm_out`
- Might need to run Cellpose once to avoid URL errors: `source /cluster/home/ibarbier/Yeast_screening_pipeline/DL_cellpose.sh`

## RUNNING THE PIPELINE
This require the experimental data to be copied on the Nas with the following path:\
 `biol_bc_barral_2/ibarbier/2026_GFP_screen/$EXP_DAY/$EXP_DAY/Images/` \
Pass the name of the experimental day as CL variable (ex: 20260427_phenix1_screen_5nM_3.3): \
`source /cluster/home/ibarbier/Yeast_screening_pipeline/pipeline_array_CPU_launch.sh exp_day`. \
The pipeline first create the output folder in scratch and copy the data from the NAS to the scratch.
Given the name of the experiment, it extract the experimental IDs and create a list of positions
For each position, a job is submitted using an array sbatch submission. 
The job run the `pipeline_array_CPU.sh` script which consist of a bash wrapper for the snakemake pipeline. 

path to output: /cluster/scratch/ibarbier/EXPDAY/results/POSITION/

## STEPS:
- have the data on the Nas with the following data structure: \
 `/Volumes/biol_bc_barral_2/ibarbier/2026_GFP_screen/20260511_phenix1_screen_5nM_5.1/20260511_phenix1_screen_5nM_5.1/Images` \
 Use `rsyncy -av --ignore-existing '/Volumes/ADATA_SE880/20260501_phenix1_screen_5nM_2.2__2026-05-01T16_57_27' '/Volumes/biol_bc_barral_2/ibarbier/2026_GFP_screen/20260501_phenix1_screen_5nM_2.2__2026-05-01T16_57_27' ` to copy data to NAS then rename the folder by remobing the 2026-05-01T16_57_27 extension
- Connect to Euler home directory and run `source /cluster/home/ibarbier/Yeast_screening_pipeline/pipeline_array_CPU_launch.sh exp_day` \
 This should take ~8h 
- Copy the data back to NAS: `rsync -av --ignore-existing ibarbier@euler.ethz.ch:/cluster/scratch/ibarbier/20260511_phenix1_screen_5nM_5.1/results/ /nfs/nas22/fs2202/biol_bc_barral_2/ibarbier/2026_GFP_screen/20260511_phenix1_screen_5nM_5.1/Results/`
- Make sure that every positions has been run correctly use the local_pipeline: \
 `cd Desktop/local_pipeline` \
 `source ./Yeast_screening_pipeline/pipeline_local2.sh 20260511_phenix1_screen_5nM_5.1 /Volumes/biol_bc_barral_2/ibarbier/2026_GFP_screen`
- Copy the data to final destination 


## Note to self: 
see test_cellpose \
    1) test run of Cellpose on 1 image submitted to the slurm system => took over 1h for the segmentation \
     but it worked ok => mask was generated \
    2) now trying with GPU \
            .py => when loading the model: gpu=True \
            .sh #SBATCH --gpus=1\
                #SBATCH --gres=gpumem:20000m\
        Works super well and very fast !!\
--- it seems that running the model in the home directory once before sending to slurm solved the download problem as seen in error.txt \(leading to OSError: [Errno 99] Cannot assign requested address)\
    >> test of pipeline_WIP.sh\
    1) only the segmentation test with 1 position \
        took around 1h30 \
        completed without error + masks were generated ! \
    2) Trying with GPU and all 35 positions \
        first test with 20GB of ram lead to Out of memory error under 10min \
        trying again with 40GB\
        Failed again => trying with assigning 4 threads to each segmentation job within the snakefile \
    ---- assigning more thread to each segmentation job seem to have fixed the OOM issue\
    3) On GPU, doing segmentation and tracking \
        11min in and holding good !\
    ---- Tracking OK!\
    4) On GPU, testing full snakemake pipeline \
        successful run - 73 jobs completed - runtime: 1h20 \
----- Pipeline_WIP.sh renamed to pipeline_1pos_GPU.sh \
        Creation of pipeline_1pos_CPU.sh and associated snakefile \
        attempting to run the pipeline on CPU only \
        +> cpu-per-task=10\
        +> mem-per_cpu=40000   \
        Ran successfully in ~5h30 \
----- Trying with array for a couple of positions \
        > sbatch --array=[1-5] --wrap="echo \"Hello, I am an independent job\""\
        when submitted => Submitted batch job 12258111\
        then when finished =>  slurm-12258111_1.out to  slurm-122581\
        11_5.out\
        > sbatch --array=[1-3] --output="/cluster/home/ibarbier/test_out/result.%A.%a" --wrap="sbatch /cluster/home/ibarbier/test.sh \\$SLURM_ARRAY_TASK_ID"\
            + use $1 to call the job number within the bash script \
            1) submit 1 array job\
            2) submit 5 independant jobs \
            3) those job then submit the test.sh job \
        mkdir array_slurm_out\
        rm -rf array_slurm_out\
     trying pipeline_array_CPU_launch.sh \
     > source /cluster/home/ibarbier/Yeast_screening_pipeline/pipeline_array_CPU_launch.sh 20260427_phenix1_screen_5nM_3.3\
        pipeline_array_CPU_launch.sh worked and submitted job  - job ID 12282628\
        Jobs well separated and waiting to be submitted \
            JOBID     PARTITION    NODEs\
            12282807  bigmem.24  eu-g5-004-3\
            12282808  bigmem.24  eu-g5-004-4\
            12282811  bigmem.24  eu-g5-005-1\
        Yippppeeeee it seems to work! \


  



    


