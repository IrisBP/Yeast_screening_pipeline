import pandas as pd 
import os
import shutil



list_files=snakemake.input.table[:]
df = pd.concat(map(pd.read_csv, list_files), ignore_index=True)
df.to_csv(snakemake.output[0], index=False)

# Directory path
dir_path = r"/content/sample_data"

# List all files in the directory
for filename in list_files:
    
    if os.path.isfile(filename):
        os.remove(filename)  # Remove the file

shutil.rmtree(snakemake.params.path, ignore_errors=False)
    