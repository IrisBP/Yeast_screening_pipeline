# Yeast_screening_pipeline
Analysis pipeline for image based screening in yeast

This pipeline takes as input images acquired on the Phenix Microscope over multiple time points. 
Images are acquired in 4 channels: DPC, green, red, far red over multiple hours time course. 
The pipeline performs segmentation (CellPose), tracking (Hungarian) and single cell analysis. It records the mean, max and standard deviation of fluorescence intensity in all 3 fluorescence channels, use the PIFia model to characterize the protein behavior and the SchmooNet model to classify the cell behavior at each frame. 

Parallel execution implemented with Snakemake - designed for SLURM on cluster 

in home directory (/cluster/home/ibarbier): 
> wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
> bash ~/Miniconda3-latest-Linux-x86_64.sh
+ check version > conda -V 
To install the pipeline
> git clone https://github.com/IrisBP/Yeast_screening_pipeline.git  
( rm -rf Yeast_screening_pipeline )
> conda env create -f /cluster/home/ibarbier/Yeast_screening_pipeline/pipeline.yaml 
( conda env remove -n pipeline )

to run the pipeline:
> sbatch /cluster/home/ibarbier/Yeast_screening_pipeline/pipeline.sh 

Navigate to scratch: cd /cluster/scratch/ibarbier 
path to output: /cluster/scratch/ibarbier/20260424_phenix1_screen_5nM_2.3/results/p2rep3_r05c06f02/masks


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
    


