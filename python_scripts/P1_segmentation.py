###################################### Segment cells and nucleii ############################
# Made by Iris Barbier - summer 2026
# Various functions for segmentation for both local and snakemake implementation
# very fast - can be run locally 

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

def segmentation_cellpose_folder(path, to_do):
    io.logger_setup()
    #Running CellPose with GPU == True => ~6s/img s
    model = models.CellposeModel(gpu=True)
    #######
    exp_name=path.split("/")[3].split('__')[0]
    mask_path=exp_name+'_masks_cellpose'
    if mask_path not in os.listdir():
        os.mkdir('./'+mask_path)
    mask_path='./'+mask_path+'/'

    list_files=[i for i in os.listdir(path) if ".tif" in i]
    list_positions=list(Counter([i.split("ch")[0] for i in list_files]).keys())
    list_times=list(Counter([int(i.split('.tiff')[0].split("t")[1]) for i in list_files]).keys())
    if len(to_do)>0:
        list_positions=[] 
        for pos in to_do:
            list_positions+=[pos+'f0'+str(fov) for fov in range(1,6)]
        

    nb_img=len(list_positions)*len(list_times)
    print(f'{nb_img} to segment'.format())
    n=0
    for pos in list_positions:
        for t in list_times:
            n+=1
            if f"{pos}t{t}_mask.tif".format not in os.listdir(mask_path):
                dpc=tif.imread(f"{path}{pos}ch1t{t}.tiff".format())
                g=tif.imread(f"{path}{pos}ch2t{t}.tiff".format())
                r=tif.imread(f"{path}{pos}ch3t{t}.tiff".format())
                fr=tif.imread(f"{path}{pos}ch4t{t}.tiff".format())
                composite=dpc+g+r+fr
                if composite.max()>0:
                    mask, flows, styles = model.eval([composite])
                    #mask=cellsam_pipeline(composite, use_wsi=False, low_contrast_enhancement=False, gauge_cell_size=False)
                    mask=mask[0].astype('uint16')
                    ret2, nucleus_mask= cv2.threshold(r,0,1,cv2.THRESH_BINARY+cv2.THRESH_OTSU)
                else:
                    mask=composite.copy()
                    nucleus_mask=composite.copy()
                name=f"{mask_path}{pos}t{t}_mask.tif".format()
                tif.imwrite(name, mask)
                name2=f"{mask_path}{pos}t{t}_mask_nucleus.tif".format()
                tif.imwrite(name2, nucleus_mask)
            print(f"Progress {round(100*n/(nb_img),4)}%".format(), end='\r')
    return 

def nucleus_segmentation_folder(path):
    exp_name=path.split("/")[3].split('__')[0]
    mask_path=exp_name+'_masks_cellpose'
    if mask_path not in os.listdir():
        os.mkdir('./'+mask_path)
    mask_path='./'+mask_path+'/'

    list_files=[i for i in os.listdir(path) if ".tif" in i]
    list_positions=list(Counter([i.split("ch")[0] for i in list_files]).keys())
    list_times=list(Counter([int(i.split('.tiff')[0].split("t")[1]) for i in list_files]).keys())
    nb_img=len(list_positions)*len(list_times)
    n=0
    for pos in list_positions:
        for t in list_times:
            n+=1
            if f"{pos}t{t}_mask_nucleus.tif".format not in os.listdir(mask_path):
                r=tif.imread(f"{path}{pos}ch3t{t}.tiff".format())
                if r.max()>0:
                    ret2, nucleus_mask= cv2.threshold(r,0,1,cv2.THRESH_BINARY+cv2.THRESH_OTSU)
                    k = np.ones((3, 3), np.uint8)
                    nucleus_mask = cv2.morphologyEx(nucleus_mask, cv2.MORPH_CLOSE, k)
                else:
                    nucleus_mask=r.copy()
                name2=f"{mask_path}{pos}t{t}_mask_nucleus.tif".format()
                tif.imwrite(name2, nucleus_mask)
            print(f"Progress {round(100*n/(nb_img),4)}%".format(), end='\r')
    return 

def segmentation_snakemake(dpc,g,r,fr, cell_outpath, nucleus_outpath): 
    '''
    Takes path to 4 channels + gpu value (True or False)
    create a composite image of the 4 channels, and if the image is not empty
        - use the CellPose model on the composite image to create segmentation mask
        - use Otsu thresholding on the red channel to create the nuclear segmentation mask
    return both masks  
    '''


    DPC=tif.imread(dpc)
    G=tif.imread(g)
    R=tif.imread(r)
    FR=tif.imread(fr)
    composite=DPC+G+R+FR

    #io.logger_setup()
    #Running CellPose with GPU == True => ~6s/img s
    model = models.CellposeModel(gpu=False)

    
    if composite.max()>0:
        mask, flows, styles = model.eval([composite])
        #mask=cellsam_pipeline(composite, use_wsi=False, low_contrast_enhancement=False, gauge_cell_size=False)
        mask=mask[0].astype('uint16')
        ret2, nucleus_mask= cv2.threshold(R,0,1,cv2.THRESH_BINARY+cv2.THRESH_OTSU)
        k = np.ones((3, 3), np.uint8)
        nucleus_mask = cv2.morphologyEx(nucleus_mask, cv2.MORPH_CLOSE, k)
    else:
        mask=composite.copy()
        nucleus_mask=composite.copy()

    tif.imwrite(cell_outpath, mask)
    tif.imwrite(nucleus_outpath, nucleus_mask)
    return 


segmentation_snakemake(snakemake.input[0],snakemake.input[1],snakemake.input[2],snakemake.input[3],
            snakemake.output[0], snakemake.output[1])











      





