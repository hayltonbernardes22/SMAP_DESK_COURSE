
"""
Script para convertir a vazao incremental dada no Arq_Pos_Processamento do deck
de SMAP para a vazao total e gerado no arquivo 'Total_ONS-smap_<date>.csv'

python Read_smap_ONS.py <date>

date= data da pasta Modelos_Chuva_Vazao[yyyymmdd]


"""


import pandas as pd
import sys
import glob
from Module_PosProc import Incre2total

Date_file=sys.argv[1]


 

VER=glob.glob('Modelos_Chuva_Vazao_%s/SMAP/*/Arq_Pos_Processamento/*PREVISAO_D.txt'%Date_file)
                    
DATA_ONS=pd.concat([pd.read_csv(file,skiprows=[0,2],delim_whitespace=True,parse_dates=True,dayfirst=True) for file in VER],axis=1)
DATA_ONS.drop(columns='244',inplace=True)

DATA_ONS_TOTAL=Incre2total(DATA_ONS)


DATA_ONS_T=DATA_ONS_TOTAL.T

DATA_ONS_T.columns=['d%d'%(i) for i in range(DATA_ONS_T.shape[1])]

DATA_ONS_T.to_csv('Total_ONS-smap_%s.csv' %(Date_file),header=True,index_label='posto',float_format='%.1f')








