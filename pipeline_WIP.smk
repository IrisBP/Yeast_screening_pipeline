#snakemake --cores 6 --use-conda --conda-frontend conda --scheduler greedy
# requires P1, P2, P3, P4 and hungarian in the Code directory 
import glob 

#get input from CLI / .sh script
POSITION=config["position"]
CODEDIR=config["codedir"]
WORKDIR=config["workdir"]
IMGDIR=config["imgdir"]

# create path to images and results 
OUTPATH=f'{WORKDIR}results/{POSITION}/'.format()
SOURCE=f'{WORKDIR}Images/'.format()

# first, find matches to filenames of this form to get the Time wildcard:
PATH=f"{SOURCE}{POSITION}".format()
TIMES=glob_wildcards(PATH+"ch1{time}.tiff")


# collect all results we want to generate for the run 
rule all:
    input:
        expand(OUTPATH+'masks/{pos}t11_mask.tif', pos=POSITION), #single frame segmentation masks
        expand(OUTPATH+'masks/{pos}t11_NuclearMask.tif', pos=POSITION), #single frame nuclear segmentation mask


# segmentation 
rule segmentation:
    input:
        SOURCE+POSITION+'ch1t11.tiff',
        SOURCE+POSITION+'ch2t11.tiff',
        SOURCE+POSITION+'ch3t11.tiff',
        SOURCE+POSITION+'ch4t11.tiff',
    threads: 1
    output:
        OUTPATH+'masks/'+POSITION+'t11_mask.tif', 
        OUTPATH+'masks/'+POSITION+'t11_NuclearMask.tif', 

    script: 
        CODEDIR+"/python_scripts/P1_segmentation.py"





        
    
        
