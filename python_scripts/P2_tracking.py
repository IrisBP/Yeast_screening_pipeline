############################################## Track cell masks objects  ###################################
# Made by Iris Barbier - summer 2026
# Snakemake tracking cells in cellpose masks  
##############################################################################################################################
import os 
from collections import Counter 
import tifffile as tif 
import numpy as np 
import pipeline.hungarian as hu
import matplotlib.pyplot as plt 
import math 
import cv2 
import pandas as pd
import tqdm

################################################################ functions #################################################################

def check_for_missing_frames(pos, T, mask_path):
    # check that all 35 frames have beem segmented and are in the mask_path 
    for t in range(1,T+1):
        if f"{pos}t{t}_mask.tif".format() not in os.listdir(mask_path):
            return False
    return True

def find_match_min_distance(f1,f2):
    new_id=[]
    new_x=[]
    new_y=[]
    for i in range(len(f2)):
        x1,y1=f2['com_x'][i], f2['com_y'][i]
        
        list_distances=[math.dist(np.array((x1,y1)),  np.array((f1['com_x'][j], f1['com_y'][j]))) for j in range(len(f1))]
        index=list_distances.index(min(list_distances))
        new_id.append(f1['cell'][index])
        new_x.append(f1['com_x'][index])
        new_y.append(f1['com_y'][index])
    return new_id, new_x, new_y

def correction_min_dist(m1, m2):
    feat1, ix_to_cell1 = hu.get_features(m1, 1)
    feat2, ix_to_cell2 = hu.get_features(m2, 2)
    new_id, new_x, new_y=find_match_min_distance(feat1,feat2)
    feat2['new_id']=new_id 
    feat2['new_x']=new_x   
    feat2['new_y']=new_y
    new = m2.copy()
    for i in range(len(feat2)):
        key=feat2['cell'][i]
        val=feat2['new_id'][i]
        new[m2==key] = val
    return new 

def get_new_id(m1, cx,cy):
    '''
    Given a centroid coordinate (cx, cy), return the pixel value most represented in the 3 by 3 square around the centroid in the image m1
    Used to match cell IDs between frames 
    '''
    # erode the image for more precise result
    X,Y=m1.shape
    kernel = np.ones((5, 5), np.uint8)
    m1_temp = cv2.erode(m1, kernel)
    # get all the pixel values in the 3 x 3 square around the (cx,cy) centroid
    list_ids=[]
    for i in range(-1,2):
        for j in range(-1,2):
            if cx+i<X and cy+j <Y:
                list_ids.append(m1_temp[cx+i,cy+j])
    # remove the 0 
    list_ids=[i for i in list_ids if i!=0]
    
    if len(list_ids)<1: # if the list is empty, the new Id is zeros
        new_id=0
    else: # if the list isnt empty, the new ID is the most represented value in the square 
        list_ids=Counter(list_ids)
        sorted_dict = dict(sorted(list_ids.items(), key=lambda item: item[1], reverse=True)) 
        new_id=list(sorted_dict.keys())[0]
    return new_id

def missing_number(myList): # myList is assumed to be sorted ascending
    return sorted(set(myList).symmetric_difference(range(myList[0], myList[-1]+1)))

def correction_match_value(m1, m2):
    '''
    Match the values of cells in 2 consecutive frames 
    '''
    # get the object features including the centroid coordinates
    feat2, ix_to_cell2 = hu.get_features(m2, 2)
    # get the new ID by getting the pixel value around the centroid in the previous frame 
    new_id = [get_new_id(m1, int(feat2['com_x'][i]), int(feat2['com_y'][i])) for i in range(len(feat2))]
    feat2['new_id']=new_id 
    # modify m2 with the new IDs => new is m2 with IDs matching m1 
    new = m2.copy()
    maximum=max(list(feat2["new_id"]))
    for i in range(len(feat2)):
        key=feat2['cell'][i]
        val=feat2['new_id'][i]
        if val==0: # deal with new cells 
            maximum += 1
            val=maximum 
        feat2.loc[i, 'new_id']=val
        # update the pixel values of m2 
        new[m2==key] = val
    kernel = np.ones((3, 3), np.uint8)
    new = cv2.morphologyEx(new, cv2.MORPH_CLOSE, kernel)
    return new 

def rmv_weird_border(img):

    cells = list(np.unique(img))
    if 0 in cells:
        cells.remove(0)

    new_img=np.zeros(img.shape)
    
    for c in cells:
        mask=np.copy(img)
        mask[mask != c] = 0
        mask[mask == c] = 1
        # Creating kernel
        kernel = np.ones((5, 5), np.uint8)
        mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)

        new_img+=mask*c
    return new_img

def correct_shift(m1, m2):
    '''
    correct frameshift (match m2 to m1 using the warp affine correction of the OpenCv library)
    '''
    # define the type of motion 
    warp_mode = cv2.MOTION_AFFINE
    warp_matrix = np.eye(2, 3, dtype=np.float32)

    # Specify the number of iterations.
    number_of_iterations = 100

    # Specify the threshold of the increment in the correlation 
    # coefficient between two iterations
    termination_eps = 1e-7

    criteria = (cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 
                number_of_iterations, termination_eps)
    
    try:
         # Run the ECC algorithm. The results are stored in warp_matrix.
        (cc, warp_matrix) = cv2.findTransformECC(m1, m2, warp_matrix, 
                                                warp_mode, criteria)
        target_shape = m2.shape

        aligned_image = cv2.warpAffine(
                                m2, 
                                warp_matrix, 
                                (target_shape[1], target_shape[0]), 
                                flags=cv2.INTER_LINEAR + cv2.WARP_INVERSE_MAP,
                                borderMode=cv2.BORDER_CONSTANT, 
                                borderValue=0)
        #applying the warpAffine transformation adds a weird border to the mask that needs to be removed 
        aligned_image=rmv_weird_border(aligned_image)
        return aligned_image
    except cv2.error as e: #if the the algorithm doesn't converge 
        return m2

def update_des(des, frame, t):
    feat2, ix_to_cell2 = hu.get_features(frame, t)
    if 'time' in feat2.columns:
        for k in des.keys():
            des[k]+=list(feat2[k])
    return des 

def add_nuclear_info(df, des_nucleus):
    nuclear_area=[]
    for i in range(len(df)):
        frame=df['frame'][i]
        cell_id=df['cell'][i]
        data_n=des_nucleus[des_nucleus['time']==frame]
        if cell_id in list(data_n['cell']):
            a=list(des_nucleus[des_nucleus['cell']==cell_id]['area'])[0]
            nuclear_area.append(a)
        else:
            nuclear_area.append(0)
    return nuclear_area

def track(pos, T, mask_path, track_path, path):
    #check all the frames have been segmented 
    
    if check_for_missing_frames(pos, T, mask_path):
        #initialise the tracking 
        img0=tif.imread(f"{mask_path}{pos}t1_mask.tif".format()).astype('uint16')

        n_mask0=tif.imread(f"{mask_path}{pos}t1_mask_nucleus.tif".format())
        n_mask0=np.multiply(img0,n_mask0) 
        temp=[img0]
        temp_n=[n_mask0]
        des={"time":[], "cell":[], "area":[], "com_x":[], "com_y":[]}
        des=update_des(des,img0 , 1)
        des_nucleus={"time":[], "cell":[], "area":[], "com_x":[], "com_y":[]}
        des_nucleus=update_des(des_nucleus,n_mask0 , 1)
        

        for t in tqdm.tqdm(range(2, T+1), desc='Tracking', leave=True):         
            prev=temp[t-2]
            curr=tif.imread(f"{mask_path}{pos}t{t}_mask.tif".format())
            n_mask=tif.imread(f"{mask_path}{pos}t{t}_mask_nucleus.tif".format())
            if curr.max()>0:
                curr=curr.astype('uint16')
                # correct for potential frame shift / plate movement
                # tracking is done on shift corrected timelaps 
                # the masks are shifted back to the original position before being saved 
                
                curr_shifted=correct_shift(prev, curr)
                #apply hungarian algorithm (from the YeaZ implementation)
                corrected=hu.correspondence(prev, curr_shifted.astype('uint16'))
                #for later time frames, additional correction based on value matching 
                if t>4: 
                    corrected=correction_match_value(prev, corrected)
                #shift the image back to original place (to be applied to raw imgs)
                corrected=correct_shift(curr, corrected)
                corrected=corrected.astype('uint16')
            else:
                #account for missing frames by copying the previous frame 
                corrected=prev
            n_mask=np.multiply(corrected, n_mask)

            des=update_des(des, corrected, t)
            
            des_nucleus=update_des(des_nucleus,n_mask , t)
           
            temp.append(corrected)
            temp_n.append(n_mask)


        #save the track stack as .tif tile in dedicated folder 
        tif.imwrite(f"{track_path}{pos}_track.tif".format(), np.array(temp))
        tif.imwrite(f"{track_path}{pos}_track_nucleus.tif".format(), np.array(temp_n))

        #make dataframe from description dictionary, add annotation and save as .csv in dedicated folder 
        df=pd.DataFrame.from_dict(des)
        des_nucleus=pd.DataFrame.from_dict(des_nucleus)
        df.rename(columns={'time': 'frame'}, inplace=True)
        df['Cx']=[int(i) for i in df['com_x']]
        df['Cy']=[int(i) for i in df['com_y']]
        df['Nuclear area']=add_nuclear_info(df, des_nucleus)
        df['position']=[pos for i in range(len(df))]
        df['GFP_path']=[f"{path}{pos}ch2t{df['frame'][i]}.tiff".format() for i in range(len(df))]

        return df
    else: 
        return 'not found'

def main_tracker(path):
    # for each position (row x col x fov) - match the cell ID accross frames (hungarian algorithm + correction) => _track.tif
    # + create output file with basic cell description (centroi coordinates and size) => _track.csv
    exp_name=path.split("/")[3].split('__')[0]
    #mask_path='./'+exp_name+'_masks/'
    mask_path='./'+exp_name+'_masks_cellpose/'
    track_path=exp_name+'_tracks'
    out_path=exp_name+'_tables'


    if track_path not in os.listdir():
        os.mkdir('./'+track_path)
    if out_path not in os.listdir():
        os.mkdir('./'+out_path)
    
    track_path='./'+track_path+'/'
    out_path='./'+out_path+'/'

    list_files=[i for i in os.listdir(mask_path) if ".tif" in i]

    list_positions=sorted(list(Counter([i.split("t")[0] for i in list_files]).keys()))
    T=max(list(Counter([int(i.split('_mask')[0].split("t")[1]) for i in list_files]).keys()))
    for pos in list_positions:
        print(pos)
        if f"{pos}_track.csv".format() not in os.listdir(out_path):
            
            
            df=track(pos, T, mask_path, track_path, path)
            if type(df)!=str:
                
                df.to_csv(f"{out_path}{pos}_track.csv", index=False)
                print( f'{pos} - Tracking Ok'.format())
           
 
    return 

def tracking_snakemake(cell_masks, nucleus_masks, path_cell_track, path_nucleus_track):
    '''
    Snakemake implementation of tracking using the hungarian algorithm from the YeaZ pipeline 
    '''
    #initialise the tracking with the 1st frames for both the cell and nuclear masks 
    img0=tif.imread(cell_masks[0]).astype('uint16')
    nuc0=tif.imread(nucleus_masks[0]).astype('uint16')
    # match the nuclear IDs to the cell IDs 
    nuc0=img0*nuc0
    # add the first frame to the tracks 
    cell_track=[img0]
    nucleus_track=[nuc0]
    for t in range(1, len(cell_masks)):
        prev=cell_track[t-1]         
        curr=tif.imread(cell_masks[t])
        curr_n=tif.imread(nucleus_masks[t])
        if curr.max()>0: #if the current frame isn't blank 
            curr=curr.astype('uint16')
            # correct for potential frame shift / plate movement
            # tracking is done on shift corrected timelaps 
            # the masks are shifted back to the original position before being saved 
            curr_shifted=correct_shift(prev, curr)
            #apply hungarian algorithm (from the YeaZ implementation)
            corrected=hu.correspondence(prev, curr_shifted.astype('uint16'))
            #for later time frames, additional correction based on value matching 
            if t>4: 
                corrected=correction_match_value(prev, corrected)
            #shift the image back to original place (to be applied to raw imgs)
            corrected=correct_shift(curr, corrected)
            corrected=corrected.astype('uint16')
        else:
            #account for missing frames by copying the previous frame 
            corrected=prev
        # add the corrected frame to the cell track
        cell_track.append(corrected)
        # match the nuclear IDs to the cell IDs and add the frame to the nuclear track 
        corrected_n=corrected*curr_n
        nucleus_track.append(corrected_n)
    # save the final tracked masks to the provided path 
    tif.imwrite(path_cell_track, np.array(cell_track))
    tif.imwrite(path_nucleus_track, np.array(nucleus_track))
    return 
################################################################ script #################################################################


#path='/Volumes/ADATA SD810/20260514_phenix1_screen_5nM_1.1__2026-05-14T17_10_46/images/'
#main_tracker(path)

cell_masks=snakemake.input.cell[:]
nucleus_masks=snakemake.input.nucleus[:]
path_cell_track=snakemake.output[0]
path_nucleus_track=snakemake.output[1]

tracking_snakemake(cell_masks, nucleus_masks, path_cell_track, path_nucleus_track)







