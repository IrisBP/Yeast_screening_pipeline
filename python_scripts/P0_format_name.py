###################################### Rename all the image files with the correct nomenclature ############################
# Made by Iris Barbier - summer 2026
# take rename images from the Phenix output format to expday_RowColFovChannelTime.tif
#very fast - can be run locally 

##############################################################################################################################

import os 

def rename(path):
    '''
    Look for folders with 'screen' in their name (ex: 20260424_phenix1_screen_5nM_2.3 )
    Extract the experimental ID from the folder name  (plate=2, replica =3)
    Rename the images contained in the ./folder/Images/ to the corrected format: p{plate}rep{replica}_r{row}c{col}f0{fov}ch{channel}t{time}.tiff
    '''
    if "screen" in path:
        exp_ID=path.split("_5nM_")[1].split("__")[0]
        print(exp_ID)
        plate=exp_ID.split(".")[0]
        replica=exp_ID.split(".")[1]
        #for img in tqdm.tqdm(os.listdir(full_path), desc='Renaming', leave=True):
        n=0
        print(path)
        L=len(os.listdir(path))
        for img in os.listdir(path):
            if ".tiff" in img:
                if "p"+plate+"rep"+replica not in img:
                    source=path+img
                    pos=img.split("p")[0]
                    channel=img.split("ch")[1][0]
                    time=img.split("sk")[1].split("fk")[0]
                    new_name="p"+plate+"rep"+replica+"_"+pos+"ch"+channel+"t"+time+".tiff"
                    destination=path+new_name
                    print(f"done - {round(100*n/L,2)}%".format(), end='\r')
                    #print(new_name)
                    os.rename(source, destination)
                    n+=1
                else:
                    n+=1
    return 

path='/Volumes/ADATA SE880/'
for f in os.listdir(path):
    rename(path+f+'/images/')
