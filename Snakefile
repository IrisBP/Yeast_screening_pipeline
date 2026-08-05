#snakemake --cores 6 --use-conda --conda-frontend conda --scheduler greedy
# requires P1, P2, P3, P4 and hungarian in the working directory 
import glob 

POSITION='p2rep3_r03c08f05'
# first, find matches to filenames of this form:
#files = glob_wildcards("/Volumes/ADATA_SE880/20260424_phenix1_screen_5nM_2.3__2026-04-24/Images/{position}{sample}.tiff")
PATH=
TIMES=glob_wildcards("/Volumes/ADATA_SE880/20260424_phenix1_screen_5nM_2.3__2026-04-24/Images/{position}ch1{time}.tiff")
# collect all results we want to generate for the run 
rule all:
    input:
        expand('20260424_phenix1_screen_5nM_2.3/{position}/masks/{position}{t}_mask.tif', t=TIMES.time, position=POSITION), #single frame segmentation masks
        expand('20260424_phenix1_screen_5nM_2.3/{position}/masks/{position}{t}_NuclearMask.tif', t=TIMES.time), #single frame nuclear segmentation mask
        expand('20260424_phenix1_screen_5nM_2.3/{position}/{position}_mask.tif', # tracked mask - with all 35 frames 
        expand('20260424_phenix1_screen_5nM_2.3/{position}/{position}_nucleus_mask.tif', # tracked nuclear masks with all 35 frames 
        expand('20260424_phenix1_screen_5nM_2.3/{position}/{position}_description.csv'


rule segmentation:
    input:
        '/Volumes/ADATA_SE880/20260424_phenix1_screen_5nM_2.3__2026-04-24/Images/{position}ch1{t}.tiff',
        '/Volumes/ADATA_SE880/20260424_phenix1_screen_5nM_2.3__2026-04-24/Images/{position}ch2{t}.tiff',
        '/Volumes/ADATA_SE880/20260424_phenix1_screen_5nM_2.3__2026-04-24/Images/{position}ch3{t}.tiff',
        '/Volumes/ADATA_SE880/20260424_phenix1_screen_5nM_2.3__2026-04-24/Images/{position}ch4{t}.tiff',
    params:
        gpu=True
    threads: 1
    resources:
        partition="gpu",
        gpu=1
    output:
        '20260424_phenix1_screen_5nM_2.3/{position}/masks/{position}{t}_mask.tif', 
        '20260424_phenix1_screen_5nM_2.3/{position}/masks/{position}{t}_NuclearMask.tif', 
    conda: 
        "pipeline.yaml"
    script: 
        "/pipeline/P1_segmentation.py"



rule tracking: 
    input: 
        cell=[f'20260424_phenix1_screen_5nM_2.3/{position}/masks/{position}t{i}_mask.tif'.format() for i in range(1,36)],
        nucleus=[f'20260424_phenix1_screen_5nM_2.3/{position}/masks/{position}t{i}_NuclearMask.tif'.format() for i in range(1,36)]
    output:
        '20260424_phenix1_screen_5nM_2.3/{position}/{position}_mask.tif',
        '20260424_phenix1_screen_5nM_2.3/{position}/{position}_nucleus_mask.tif'
    conda: 
        "pipeline.yaml"
    script: 
        "/pipeline/P2_tracking.py"

rule description: 
    input: 
        '20260424_phenix1_screen_5nM_2.3/{position}/{position}_mask.tif',
        '20260424_phenix1_screen_5nM_2.3/{position}/{position}_nucleus_mask.tif',
        '/Volumes/ADATA_SE880/20260424_phenix1_screen_5nM_2.3__2026-04-24/Images/{position}ch2{t}.tiff',
        '/Volumes/ADATA_SE880/20260424_phenix1_screen_5nM_2.3__2026-04-24/Images/{position}ch3{t}.tiff',
        '/Volumes/ADATA_SE880/20260424_phenix1_screen_5nM_2.3__2026-04-24/Images/{position}ch4{t}.tiff'
    output: 
        '20260424_phenix1_screen_5nM_2.3/{position}/temp/description_{t}.csv'
    conda: 
        "pipeline.yaml"
    threads: 10   
    script:
        '/pipeline/P3_description.py'
        
        
rule merge_results:
    input: 
        table=[f'20260424_phenix1_screen_5nM_2.3/{position}/temp/description_t{i}.csv'.format() for i in range(1,36)],
    params:
        path='20260424_phenix1_screen_5nM_2.3/{position}/temp/'
    output:
        '20260424_phenix1_screen_5nM_2.3/{position}/{position}_description.csv'
    conda: 
        "pipeline.yaml"
    threads: 3  
    script:
        '/pipeline/P4_mergetable.py'





        
    
        
