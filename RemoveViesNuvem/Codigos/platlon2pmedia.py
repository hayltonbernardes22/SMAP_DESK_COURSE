import pandas as pd
import os
import numpy as np
import sys
import datetime

'''
for exporting data of rain without removing Bias

python Codigos/platlon2pmedia_v2 <model> <date> <n_prev>

it needs to run after running with bias remotion

'''

MODELO=sys.argv[1]
today=datetime.datetime.strptime(str(sys.argv[2]),"%Y%m%d").date()
n_prev=int(sys.argv[3])

planilha=pd.read_excel('Parametros/Configuracao.xlsx',sheet_name= "Plan1")
LAT=planilha.Latitude.values
LON=planilha.Longitude.values
bacias=[planilha['Macro-Bacia'].values,planilha['Nome'].values]



diretorios=[(os.getcwd()+"/Trabalho/"+bacias[0][i]+"/"+bacias[1][i]).rstrip() for i in range(len(planilha))]





for dias in range(1,n_prev+1):
    date_i=today.strftime('%d%m%y')
    data=today+datetime.timedelta(dias)
    date_f=data.strftime('%d%m%y')

    file='Arq_Saida_sem_remocao_vies/'+'PMEDIA_%s_p%sa%s.dat' %(MODELO,date_i,date_f)
    
    

    DATA_F=[]
    for pp,direct in enumerate(diretorios):
        data=pd.read_csv(direct+'/'+MODELO+'.csv',decimal=',',sep=';',skiprows=1,header=None,dayfirst=True,parse_dates=True)
        data.index=pd.to_datetime(data[0],format='%d/%m/%Y')

        try :
            data_day=data.loc[data.index==str(today)].values[0]
            DATA_F.append([LON[pp],LAT[pp],data_day[dias]])


        except:

            print('Error the date you look for is not saved in the Model History or \n \
nprev is not covered along the column of Model Historic')
            sys.exit()

        
            
    print('Creating %s' %(file))        
    np.savetxt(fname=file,X=np.array(DATA_F),delimiter='  ', fmt='%.2f')
 
   

      