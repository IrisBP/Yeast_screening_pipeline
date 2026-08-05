# Yeast_screening_pipeline
Analysis pipeline for image based screening in yeast

This pipeline takes as input images acquired on the Phenix Microscope over multiple time points. 
Images are acquired in 4 channels: DPC, green, red, far red over multiple hours time course. 
The pipeline performs segmentation (CellPose), tracking (Hungarian) and single cell analysis. It records the mean, max and standard deviation of fluorescence intensity in all 3 fluorescence channels, use the PIFia model to characterize the protein behavior and the SchmooNet model to classify the cell behavior at each frame. 


