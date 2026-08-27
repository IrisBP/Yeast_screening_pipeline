###################################### Segment cells and nucleii ############################
# Made by Iris Barbier - summer 2026
# Snakemake implementation of cellpose segmentation 
##############################################################################################################################
import os 
from collections import Counter
import numpy as np 
import matplotlib.pyplot as plt 
#from cellSAM import cellsam_pipeline, get_model
from cellpose import models, io
import tifffile as tif # requires pip install imagecodecs for .tiff 
import cv2 
#############################################################################################################################

def segmentation_snakemake(dpc,g,r,fr, cell_outpath, nucleus_outpath): 
    '''
    Takes path to 4 channels (dpc, g, r, fr)
    create a composite image of the 4 channels, and if the image is not empty
        - use the CellPose model on the composite image to create segmentation mask
        - use Otsu thresholding on the red channel to create the nuclear segmentation mask
    return both masks and save them in cell_outpath and nucleus_outpath
    '''
    # read all 4 channels 
    DPC=tif.imread(dpc)
    G=tif.imread(g)
    R=tif.imread(r)
    FR=tif.imread(fr)
    #create composite image by adding all 4 channels 
    composite=DPC+G+R+FR

    # load the CellPose model 
    model = models.CellposeModel(gpu=False)

    
    if composite.max()>0: # if the image isn't blank (actually contains cells)
        # segment the composite image for cell masks  
        mask, flows, styles = model.eval([composite])
        mask=mask[0].astype('uint16')

        # segment the red channel using Otsu thresholding for nuclear masks 
        ret2, nucleus_mask= cv2.threshold(R,0,1,cv2.THRESH_BINARY+cv2.THRESH_OTSU)
        k = np.ones((3, 3), np.uint8)
        nucleus_mask = cv2.morphologyEx(nucleus_mask, cv2.MORPH_CLOSE, k)
    else: # if the image is black / missing frame => just return a blank mask (the original image)
        mask=composite.copy()
        nucleus_mask=composite.copy()
    #save both masks to provided location
    tif.imwrite(cell_outpath, mask)
    tif.imwrite(nucleus_outpath, nucleus_mask)
    return 


# Snakemake implementation 
# snakemake inputs 0-3 : all 4 channels (dpc, g, r, fr)
# snakemake outputs: paths to save the cell and nuclear masks 
segmentation_snakemake(snakemake.input[0],snakemake.input[1],snakemake.input[2],snakemake.input[3],
            snakemake.output[0], snakemake.output[1])











      





