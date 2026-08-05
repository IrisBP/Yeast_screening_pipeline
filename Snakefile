#snakemake --cores 6 --use-conda --conda-frontend conda --scheduler greedy
# requires P1, P2, P3, P4 and hungarian in the working directory 
import glob 

POSITION=config["position"]
SOURCE=config["sourcedir"]
WORK=config["workdir"]
EXP=config["exp"]
OUTPATH=WORK+EXP

# first, find matches to filenames of this form:

PATH=f"{SOURCE}{POSITION}".format()
TIMES=glob_wildcards(PATH+"ch1{time}.tiff")
# collect all results we want to generate for the run 

# collect all results we want to generate for the run 
rule all:
    input:
        expand(OUTPATH+'/{pos}/masks/{pos}{t}_mask.tif', t=TIMES.time, pos=POSITION), #single frame segmentation masks
        expand(OUTPATH+'/{pos}/masks/{pos}{t}_NuclearMask.tif', t=TIMES.time, pos=POSITION), #single frame nuclear segmentation mask
        f'{OUTPATH}/{POSITION}/{POSITION}_mask.tif'.format(), # tracked mask - with all 35 frames 
        f'{OUTPATH}/{POSITION}/{POSITION}_nucleus_mask.tif'.format(), # tracked nuclear masks with all 35 frames 
        f'{OUTPATH}/{POSITION}/{POSITION}_description.csv'.format()


rule segmentation:
    input:
        SOURCE+POSITION+'ch1{t}.tiff',
        SOURCE+POSITION+'ch2{t}.tiff',
        SOURCE+POSITION+'ch3{t}.tiff',
        SOURCE+POSITION+'ch4{t}.tiff',
    params:
        gpu=True
    threads: 1
    resources:
        partition="gpu",
        gpu=1
    output:
        OUTPATH+'/'+POSITION+'/masks/'+POSITION+'{t}_mask.tif', 
        OUTPATH+'/'+POSITION+'/masks/'+POSITION+'{t}_NuclearMask.tif', 
    conda: 
        "pipeline.yaml"
    script: 
        "P1_segmentation.py"



rule tracking: 
    input: 
        cell=[f'{OUTPATH}/{POSITION}/masks/{POSITION}t{i}_mask.tif'.format() for i in range(1,36)],
        nucleus=[f'{OUTPATH}/{POSITION}/masks/{POSITION}t{i}_NuclearMask.tif'.format() for i in range(1,36)]
    output:
        OUTPATH+'/'+POSITION+'/'+POSITION+'_mask.tif',
        OUTPATH+'/'+POSITION+'/'+POSITION+'_nucleus_mask.tif'
    conda: 
        "pipeline.yaml"
    script: 
        "P2_tracking.py"

rule description: 
    input: 
        f'{OUTPATH}/{POSITION}/{POSITION}_mask.tif'.format(),
        f'{OUTPATH}/{POSITION}/{POSITION}_nucleus_mask.tif'.format(),
        SOURCE+POSITION+'ch2{t}.tiff',
        SOURCE+POSITION+'ch3{t}.tiff',
        SOURCE+POSITION+'ch4{t}.tiff',
    output: 
        OUTPATH+'/'+POSITION+'/temp/description_{t}.csv'
    conda: 
        "pipeline.yaml"
    threads: 10   
    script:
        'P3_description.py'
        
        
rule merge_results:
    input: 
        table=[f'{OUTPATH}/{POSITION}/temp/description_t{i}.csv'.format() for i in range(1,36)],
    params:
        path=f'{OUTPATH}/{POSITION}/temp/'.format()
    output:
        f'{OUTPATH}/{POSITION}/{POSITION}_description.csv'.format()
    conda: 
        "pipeline.yaml"
    threads: 3  
    script:
        'P4_mergetable.py'





        
    
        
