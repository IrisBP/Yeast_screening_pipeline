import os.path
from pathlib import Path
from pifia_tool_functions import get_features_from_protein_single_position
import pifia_models as models
from PIL import Image
import pandas as pd
import argparse
import math
import numpy as np 

import warnings
warnings.filterwarnings("ignore")



def PIFIA(input_path, img_path, output_dir, crop_size, model):
    # Load single-cell data
    df_main = pd.read_csv(input_path)
    df_to_concat=[]
    for t in np.unique(df_main['time']):
        df=df_main[df_main['time']==t]
        df=df.reset_index(drop=True)

        imgs_path=[]
        masks_path=[]
        for i in range(len(df)):
            center_x = int(df['com_x'][i])
            center_y = int(df['com_y'][i])
            pos=df['position'][i]
            exp=df['exp_ID'][i]
            time=df['time'][i]
            img=f'{img_path}{exp}_{pos}ch2t{time}.tiff'.format()
            cell_path = f'{img}_X_{center_x}_Y_{center_y}'
            imgs_path.append(cell_path)
            masks_path.append('none')

        protein_features, protein_images = get_features_from_protein_single_position(imgs_path, masks_path,crop_size,  model, do_mask=False,   average=False)
        #print("protein_features", protein_features.shape)
        #print("protein_images", protein_images.shape)

        #save the results as npy files 
        output_path = f'{output_dir}/{exp}_{pos}_{t}_scFP.npy'
        np.save(output_path, protein_features)

        # add the results to dataframe as a new column and save it 
        df['PIFIA']=[i for i in protein_features]
        df_to_concat.append(df)
        df_out=pd.concat(df_to_concat)
        path_to_description=input_path.split('.cs')[0]
        df_out.to_csv(f'{path_to_description}2.csv', index=False)
    return 





# turned into CLI inputs 
'''
input_path = '/Volumes/biol_bc_barral_2/ibarbier/2026_GFP_screen/20260424_phenix1_screen_5nM_2.3/Results/p2rep3_r01c10f02/p2rep3_r01c10f02_description.csv'
img_path='/Volumes/biol_bc_barral_2/ibarbier/2026_GFP_screen/20260424_phenix1_screen_5nM_2.3/20260424_phenix1_screen_5nM_2.3/Images/'
output_dir="./pifia_out"
crop_size = "64"
'''

parser = argparse.ArgumentParser()
parser.add_argument('-d', '--description-path', type=str,
                    help='Path to file containing single-cell information. Required columns are: exp_id, position, time, com_x, com_y')
parser.add_argument('-i', '--img-path', type=str, help='Path to folder with the raw images ')
parser.add_argument('-n', '--num-classes', type=int, default=4049,
                    help='Number of classes in the training set. Default is 4049.')
parser.add_argument('-c', '--crop-size', type=int, default=64, help="Single-cell crop size. Default is 64.")
parser.add_argument('-o', '--output-dir', type=str, default="./pifia_out", help="Folder where to save single-cell feature profiles.")

args = parser.parse_args()
 
input_path = args.description_path #path to description csv file 
img_path = args.img_path #path to raw images 
crop_size = args.crop_size # crop size => should be '64'
output_dir= args.output_dir # path to output directory
num_classes = args.num_classes

# ########### this should be part of the snakemake pipeline 
# Make output directory
if not os.path.exists(output_dir):
    Path(output_dir).mkdir(parents=True, exist_ok=True)



# Load the model
model = models.pifia_network(num_classes, k=1, num_features=64, dense1_size=128, last_block=True)
path_to_weights='/cluster/home/ibarbier/Yeast_screening_pipeline/python_scripts/pretrained_weights/pifia_weights_i0'
model.load_weights(path_to_weights).expect_partial()

PIFIA(input_path, img_path, output_dir, crop_size, model)
