
import numpy as np
import tensorflow as tf
import os, sys, random
from PIL import Image
import matplotlib.pyplot as plt

import warnings
warnings.filterwarnings("ignore")

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def decode_img_py_func(file_path1, file_path_mask, crop_size,  do_mask=True):
    # open the image from path, get x and y coordinate and crop the image to crop size 
    # apply the mask if needed 
    # return img 

   
    crop_size=int(crop_size.numpy())

       
    if do_mask:
        file_path_mask = str(file_path_mask.numpy())
        if '.tif' in file_path_mask:
            mask_path_split = file_path_mask.split('.tif')
            mask_path = f'{mask_path_split[0]}.tif'
            cell_ID=int(file_path_mask.split('_ID_')[1])

            mask = Image.open(mask_path)
            mask = np.array(mask)
            mask[mask != cell_ID ] = 0
            mask[mask == cell_ID ] = 1

    file_path1=file_path1[0]
    file_path = file_path1.numpy()
    print(file_path)
    file_path=str(file_path)
    print(type(file_path), file_path)

    #file_path1 = str -D:/20260219_phenix1_6nM__2026-02-19T17_24_32-Measurement_1/Images/r01c02f01p01-ch2sk1fk1fl1.tiff_X_719_Y_47

    file_path_split = file_path.split('.tiff')
    img_path = f'{file_path_split[0]}.tiff'
    
    coordinates = file_path_split[1].split('_Y_')
    center_x = int(coordinates[0].replace('_X_', ''))
    center_y = int(coordinates[1])

    loc_left = center_x - crop_size // 2 #using // to divide in case we get an odd number crop size
    loc_upper = center_y - crop_size // 2
    loc_right = center_x + crop_size // 2
    loc_lower = center_y + crop_size // 2

    im = Image.open(img_path)
    if do_mask: 
        im = im*mask
    im = im.crop((loc_left, loc_upper, loc_right, loc_lower)) 
    im = im.resize((64, 64))  # Rescale back to 64x64
    im = np.array(im).reshape(64,64,1)
    im = (im-np.min(im))/(np.max(im)-np.min(im))
    return im 


def process_path_py_func(file_path1, file_path_mask, label, crop_size, do_mask=True, onehot=True):
    img = tf.py_function(func=decode_img_py_func, inp=[file_path1, file_path_mask,crop_size, do_mask],
                         Tout=tf.float32)
    ## open the image from path, get x and y coordinate and crop the image to crop size 
    #img =<class 'tensorflow.python.framework.ops.Tensor'>
   
    if onehot:
        label = tf.one_hot(label, 1)
    return img, label

def standardize_im(image, label):
    image = tf.image.per_image_standardization(image)
    return image, label



def get_dataset_from_lists(imgs_path, masks_path, labels, crop_size, do_mask, batch_size, \
                           standardize=False, onehot=True):

    # imgs_path = [path_to_img_X_Y, ....]
    # masks_path = [none, ...]
    # labels = [0,0,0,0,....]
    # crop size = 64
    # do_mask=False 
    # batch size = 64  
    #    
    #build list_of_ds: list of images, list of masks, list of labels 
    #filenames_channels_list [[path_to_img_X_Y, ....]] - list of list 
    #filenames_channels_list [[path_to_img_X_Y, ....]] - list of list 
    

    # create a tensor DS from list 
    ds_img = tf.data.Dataset.from_tensor_slices(imgs_path)

    # create a list of DS 
    list_of_ds=[ds_img]
   
    #ds_gfp = tf.data.Dataset.from_tensor_slices(filenames_channels_list[0])
    #list_of_ds=[ds_gfp]  #list_ds=list -<TensorSliceDataset shapes: (), types: tf.string>

    #filenames_mask = list [none, none, none, ...] for each images 
    ds_mask = tf.data.Dataset.from_tensor_slices(masks_path)
    list_of_ds.append(ds_mask)
    
    #labels = list [0,0,0,...]
    ds_labels = tf.data.Dataset.from_tensor_slices(labels)
    list_of_ds.append(ds_labels)
   
    # tuple is always constructed as following:
    # [ds_channel_1, ..., ds_channel_N, ds_mask, ds_label]
    # so that all channels are stacked together, mask is applied (if flag set to True) and
    # multi-channel masked image + label are returned at the end
    tuple_of_ds = tuple(list_of_ds)
    dataset = tf.data.Dataset.zip(tuple_of_ds)
  
    # path_to_cell_array_list = []
    # for c_path, c_array in path_to_cell_array.items():
    #     path_to_cell_array_list.append((c_path, c_array))
    #[f1] = file_paths_tuple, f_mask = file_path_mask, label, seek_ch, num_classes, do_mask=True, onehot=True):
    print('Ready to map the dataset')
    dataset = dataset.map(lambda f1,f_mask,l: process_path_py_func([f1],f_mask,l, crop_size, do_mask,onehot), \
                            num_parallel_calls=tf.data.experimental.AUTOTUNE)
    
    #### dataset map the function process, doesnt actually apply it - function get applied when extracting images from dataset 
    if standardize:
        dataset = dataset.map(standardize_im, num_parallel_calls=tf.data.experimental.AUTOTUNE)

    dataset = dataset.batch(batch_size)
    dataset = dataset.prefetch(2)
    return dataset


def get_all_images_from_dataset(dataset_protein):
    im_total = []
    n=0
    for im, l in dataset_protein:
        im_total.append(im)
    im_total = np.vstack(im_total)
   
    return im_total



def get_features(images, model, average=True):
    M=model.get_features(images)
    features = np.array(M)
    if average:
        features = np.mean(features,0)
    return features



def get_features_from_protein_single_position(imgs_path, masks_path, crop_size,  model, do_mask=False, average=True):

    labels_val = [0]*len(imgs_path) # list of nb cells x 0
    dataset_protein = get_dataset_from_lists(imgs_path, masks_path, labels_val, crop_size,
                                                              do_mask, standardize=True,
                                                             onehot=True, batch_size=64)

    # create a dataset with path to images, function to open the images and crop them + emtpy labels 
    
    images = get_all_images_from_dataset(dataset_protein)
  
    # extract the images only from the DS 
    
    features = get_features(images, model, average)
  
    #apply the model to all images and average the features if true 

  
    return features, images



