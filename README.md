# Yeast_screening_pipeline
Analysis pipeline for image based screening in yeast

This pipeline takes as input images acquired on the Phenix Microscope over multiple time points. 
Images are acquired in 4 channels: DPC, green, red, far red over multiple hours time course. 
The pipeline performs segmentation (CellPose), tracking (Hungarian) and single cell analysis. It records the mean, max and standard deviation of fluorescence intensity in all 3 fluorescence channels, use the PIFia model to characterize the protein behavior and the SchmooNet model to classify the cell behavior at each frame. 

Parallel execution implemented with Snakemake - designed for SLURM on cluster 

check ressources: > my_share_info
3688 CPU cores, 25552 GiB of system RAM, and 61 GPUs

mkdir /cluster/scratch/ibarbier/20260427_phenix1_screen_5nM_3.3/
cp -R /nfs/nas22/fs2202/biol_bc_barral_2/ibarbier/2026_GFP_screen/20260427_phenix1_screen_5nM_3.3/20260427_phenix1_screen_5nM_3.3/Images /cluster/scratch/ibarbier/20260427_phenix1_screen_5nM_3.3

in home directory (/cluster/home/ibarbier): 
> wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
> bash ~/Miniconda3-latest-Linux-x86_64.sh
+ check version > conda -V 
To install the pipelinecd 
> git clone https://github.com/IrisBP/Yeast_screening_pipeline.git  
( rm -rf Yeast_screening_pipeline )
> conda env create -f /cluster/home/ibarbier/Yeast_screening_pipeline/pipeline.yaml 
( conda env remove -n pipeline )
# create the output folder 
> mkdir /cluster/scratch/ibarbier/20260427_phenix1_screen_5nM_3.3/
# copy the data from nas 
> cp -R /nfs/nas22/fs2202/biol_bc_barral_2/ibarbier/2026_GFP_screen/20260427_phenix1_screen_5nM_3.3/20260427_phenix1_screen_5nM_3.3/Images /cluster/scratch/ibarbier/20260427_phenix1_screen_5nM_3.3

to run the pipeline:
> sbatch /cluster/home/ibarbier/Yeast_screening_pipeline/pipeline.sh 

Navigate to scratch: cd /cluster/scratch/ibarbier 
path to output: /cluster/scratch/ibarbier/20260424_phenix1_screen_5nM_2.3/results/p2rep3_r05c06f02/masks
to count file nb: > ls -1q | wc -l

Note to self:
    >> see test_cellpose 
    1) test run of Cellpose on 1 image submitted to the slurm system => took over 1h for the segmentation 
     but it worked ok => mask was generated 
    2) now trying with GPU 
            .py => when loading the model: gpu=True 
            .sh #SBATCH --gpus=1
                #SBATCH --gres=gpumem:20000m
        Works super well and very fast !!
--- it seems that running the model in the home directory once before sending to slurm solved the download problem as seen in error.txt (leading to OSError: [Errno 99] Cannot assign requested address)
    >> test of pipeline_WIP.sh
    1) only the segmentation test with 1 position 
        took around 1h30 
        completed without error + masks were generated ! 
    2) Trying with GPU and all 35 positions 
        first test with 20GB of ram lead to Out of memory error under 10min 
        trying again with 40GB
        Failed again => trying with assigning 4 threads to each segmentation job within the snakefile 
    ---- assigning more thread to each segmentation job seem to have fixed the OOM issue
    3) On GPU, doing segmentation and tracking 
        11min in and holding good !
    ---- Tracking OK!
    4) On GPU, testing full snakemake pipeline 
        successful run - 73 jobs completed - runtime: 1h20 
----- Pipeline_WIP.sh renamed to pipeline_1pos_GPU.sh 
        Creation of pipeline_1pos_CPU.sh and associated snakefile 
        attempting to run the pipeline on CPU only 
        +> cpu-per-task=10
        +> mem-per_cpu=40000   
        Ran successfully in ~5h30 
----- Trying with array for a couple of positions 
        > sbatch --array=[1-5] --wrap="echo \"Hello, I am an independent job\""
        when submitted => Submitted batch job 12258111
        then when finished =>  slurm-12258111_1.out to  slurm-122581
        11_5.out
        > sbatch --array=[1-3] --output="/cluster/home/ibarbier/test_out/result.%A.%a" --wrap="sbatch /cluster/home/ibarbier/test.sh \$SLURM_ARRAY_TASK_ID"
            + use $1 to call the job number within the bash script 
            1) submit 1 array job
            2) submit 5 independant jobs 
            3) those job then submit the test.sh job 
        mkdir array_slurm_out
        rm -rf array_slurm_out
     trying pipeline_array_CPU_launch.sh 
     > source /cluster/home/ibarbier/Yeast_screening_pipeline/pipeline_array_CPU_launch.sh 20260427_phenix1_screen_5nM_3.3



    


