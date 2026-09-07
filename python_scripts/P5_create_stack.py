import tifffile as tif 
import numpy as np 

cell_masks=snakemake.input.cell[:] #list of path to images 
nucleus_masks=snakemake.input.nucleus[:] #list of path to images 
path_cell_stack=snakemake.output[0] #lpath to final stack
path_nucleus_stack=snakemake.output[1] #lpath to final stack

def create_stack(list_files):
    list_img=[]
    for file in list_files:
        img=tif.imread(file)
        list_img.append(img)
    return np.array(list_img)

stack_cell=create_stack(cell_masks)
stack_nucleus=create_stack(nucleus_masks)
tif.imwrite(path_cell_stack, np.array(stack_cell))
tif.imwrite(path_nucleus_stack, np.array(stack_nucleus))