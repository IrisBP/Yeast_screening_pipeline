import pandas as pd 
import sys

path=sys.argv[1]
exp=sys.argv[2]
dic={"Position":[],"array_ID":[]}
id=1
for r in range(1,16,2):
    for c in range(2,25,2):
        if r<10:
            R='0'+str(r)
        else:
            R=str(r)
        if c<10:
            C='0'+str(c)
        else:
            C=str(c)
        for f in range(1,6):
            pos=f'{exp}_r{R}c{C}f0{f}'.format()
            dic['array_ID'].append(id)
            dic['Position'].append(pos)
            id+=1
pd.DataFrame(dic).to_csv(path+'arrayID.csv', index=False)
