############################################## Describe cell objects (size and fluo I)  ###################################
# Made by Iris Barbier - summer 2026
# Snakemake implementation of object description
##############################################################################################################################
import pandas as pd 
import numpy as np
import tifffile as tif 
import pipeline.hungarian as hu 
from multiprocessing import Pool, cpu_count

def get_dist(mask, raw):
    '''
    Mask the raw image and get pixel distribution of the masked object - return mean, max and standard dev of the distribution 
    '''
    masked=mask*raw
    dist=np.array([i for i in masked.ravel() if i !=0])
    if len(dist)>0:
            return dist.mean(), dist.max(), dist.std()
    else:
        return 0,0, 0 

def get_fluo_info(V):
    '''
    Apply the get_dist function to all 3 channels to obtain the mean, max and std of each cell 
    '''
    c, mask, G, R, FR = V 
    m=mask.copy()
    m[m != c] = 0
    m[m == c] = 1
    return [int(c)], list(get_dist(m, G)), list(get_dist(m, R)), list(get_dist(m, FR))
   
def describe(cell_masks, nucleus_masks, t, thread_count, g,r,fr):
    '''
    for each cell in the frame, get the area, centroid coordinate, intensity distribution for both cell and nucleus
    Output the information as a table 
    '''
    # open cell and nucleus masks
    c_mask=tif.imread(cell_masks)[t-1]
    n_mask=tif.imread(nucleus_masks)[t-1]
    # read the raw fluo images 
    G=tif.imread(g)
    R=tif.imread(r)
    FR=tif.imread(fr)

    # get basic cell and nuclear feature (size and coordinates)
    cell_feat, ix_to_cell2 = hu.get_features(c_mask, t)
    nuclear_feat, ix_to_cell2 = hu.get_features(n_mask, t)
    # rename the column names of the nuclear table 
    nuclear_feat.rename(columns={'sqrtarea': 'N_sqrtarea', 'area': 'N_area','com_x': 'N_com_x','com_y': 'N_com_y' }, inplace=True)
    nuclear_feat=nuclear_feat.drop(["time"], axis=1)
    # merge the cell and nuclear tables into 1 
    results = pd.merge(cell_feat, nuclear_feat, on="cell", how="left")

    # using multiprocessing parallelization, extract the fluo information for every cell in the masks 
    with Pool(thread_count) as p:
        list_V=[(results['cell'][i], c_mask, G, R, FR) for i in range(len(results))]
        infos=p.map(get_fluo_info, list_V ) #get fluo info ouput mean/max/std for all 3 channels 
        infos_table=np.array([[j for i in infos[k] for j in i] for k in range(len(infos))])
        #update the table 
        infos_table_cell = pd.DataFrame(data=infos_table, columns=['cell','G_mean','G_max','G_std','R_mean', 'R_max','R_std', 'Fr_mean', 'Fr_max', 'Fr_std'])
        #do the same thing with the nuclear masks 
        list_V=[(results['cell'][i], n_mask, G, R, FR) for i in range(len(results))]
        infos=p.map(get_fluo_info, list_V )
        infos_table=np.array([[j for i in infos[k] for j in i] for k in range(len(infos))])
        infos_table_nucleus = pd.DataFrame(data=infos_table, columns=['cell','N_G_mean','N_G_max','N_G_std','N_R_mean', 'N_R_max','N_R_std', 'N_Fr_mean', 'N_Fr_max', 'N_Fr_std'])

        #merge all the tables 
        results = pd.merge(results, infos_table_cell, on="cell", how="left")
        results = pd.merge(results, infos_table_nucleus, on="cell", how="left")
       
    return results


if __name__ == '__main__':

    cell_masks=snakemake.input[0]
    nucleus_masks=snakemake.input[1]
    g=snakemake.input[2]
    r=snakemake.input[3]
    fr=snakemake.input[4]

    thread_count=snakemake.threads

    t=int(g.split("ch2t")[1].split('.tiff')[0])
    exp=cell_masks.split('/')[0]
    pos=cell_masks.split('/')[1].split('_mask')[0]

    results= describe(cell_masks, nucleus_masks, t, thread_count, g,r,fr)
    col_names=['exp_ID', 'position']+results.columns.to_list()
    results['exp_ID']=[exp for i in range(len(results))]
    results['position']=[pos for i in range(len(results))]

    results=results.loc[:, col_names]
    results.to_csv(snakemake.output[0], index=False)

