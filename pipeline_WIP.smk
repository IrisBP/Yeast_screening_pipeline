#snakemake --cores 6 --use-conda --conda-frontend conda --scheduler greedy
# requires P1, P2, P3, P4 and hungarian in the Code directory 
import glob 

#get input from CLI / .sh script
POSITION=config["position"]
CODEDIR=config["codedir"]
WORKDIR=config["workdir"]

# create path to images and results 
OUTPATH=f'{WORKDIR}results/{POSITION}/'.format()
SOURCE=f'{WORKDIR}Images/'.format()

# first, find matches to filenames of this form to get the Time wildcard:
PATH=f"{SOURCE}{POSITION}".format()
TIMES=glob_wildcards(PATH+"ch1{time}.tiff")


# collect all results we want to generate for the run 
rule all:
    input:
        expand(OUTPATH+'masks/{pos}{t}_mask.tif', t=TIMES.time, pos=POSITION), #single frame segmentation masks
        expand(OUTPATH+'masks/{pos}{t}_NuclearMask.tif',t=TIMES.time, pos=POSITION), #single frame nuclear segmentation mask
        f'{OUTPATH}{POSITION}_mask.tif'.format(), # tracked mask - with all 35 frames 
        f'{OUTPATH}{POSITION}_nucleus_mask.tif'.format(), # tracked nuclear masks with all 35 frames

# segmentation 
rule segmentation:
    input:
        SOURCE+POSITION+'ch1{t}.tiff',
        SOURCE+POSITION+'ch2{t}.tiff',
        SOURCE+POSITION+'ch3{t}.tiff',
        SOURCE+POSITION+'ch4{t}.tiff',
    threads: 4
    output:
        OUTPATH+'masks/'+POSITION+'{t}_mask.tif', 
        OUTPATH+'masks/'+POSITION+'{t}_NuclearMask.tif', 
    conda:
        "/cluster/home/ibarbier/miniconda3/envs/pipeline"

    script: 
        CODEDIR+"/python_scripts/P1_segmentation_GPU.py"

# tracking 
rule tracking: 
    input: 
        cell=[f'{OUTPATH}masks/{POSITION}t{i}_mask.tif'.format() for i in range(1,36)],
        nucleus=[f'{OUTPATH}masks/{POSITION}t{i}_NuclearMask.tif'.format() for i in range(1,36)]
    output:
        OUTPATH+POSITION+'_mask.tif',
        OUTPATH+POSITION+'_nucleus_mask.tif'
    conda:
        "/cluster/home/ibarbier/miniconda3/envs/pipeline"

    script: 
        CODEDIR+"/python_scripts/P2_tracking.py"



# single cell description of intensity
rule description: 
    input: 
        f'{OUTPATH}{POSITION}_mask.tif'.format(),
        f'{OUTPATH}{POSITION}_nucleus_mask.tif'.format(),
        SOURCE+POSITION+'ch2{t}.tiff',
        SOURCE+POSITION+'ch3{t}.tiff',
        SOURCE+POSITION+'ch4{t}.tiff', 
        CODEDIR+'/ref_table.csv',
    output: 
        OUTPATH+'temp/description_{t}.csv'
    conda:
        "/cluster/home/ibarbier/miniconda3/envs/pipeline"
    threads: 10   
    script:
        CODEDIR+'/python_scripts/P3_description.py'
        
# collecting all the description files and merging them into 1 single large file for the position    
rule merge_results:
    input: 
        table=[f'{OUTPATH}temp/description_t{i}.csv'.format() for i in range(1,36)],
    params:
        path=f'{OUTPATH}temp/'.format()
    output:
        f'{OUTPATH}{POSITION}_description.csv'.format()
    conda:
        "/cluster/home/ibarbier/miniconda3/envs/pipeline"
    threads: 1 
    script:
        CODEDIR+'/python_scripts/P4_mergetable.py'





        
    
        
