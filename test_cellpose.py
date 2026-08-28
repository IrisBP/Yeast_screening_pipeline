                                                                                                                                        
from cellpose import models
import tifffile as tif 


model = models.CellposeModel(gpu=False)
print("Model loaded")
img="/nfs/nas22/fs2202/biol_bc_barral_2/ibarbier/2026_GFP_screen/20260424_phenix1_screen_5nM_2.3/20260424_phenix1_screen_5nM_2.3/Images/p2rep3_r05c06f02ch1t10.tiff"
img=tif.imread(img)
print("img loaded")
mask, flows, styles = model.eval([img])
print("img segmented")
tif.imwrite("/cluster/home/ibarbier/mask_test.tif", mask)
print("img saved")

