#################################################################
#  IMPORTING PACKAGES 
################################################################

import numpy as np
#from shapely.geometry import MultiPoint, Point, Polygon,shape
from shapely.geometry import  Point, polygon

#from shapely.geometry.polygon import Polygon
import os
import pandas as pd
import datetime 
import sys
import glob

######################################################################
# READING CONFIGURATION FILES 
#########################################################

file_xlsx=os.getcwd()+'/Parametros/Configuracao.xlsx'
lookup_xlsx=pd.read_excel(file_xlsx,sheet_name = "Plan1")

# caminho dos contornos
caminhocontornos=os.getcwd()+'/Parametros/Contornos/ETA40'
input_bacias=lookup_xlsx[['Macro-Bacia','Nome']]

#NUMERO_DAY=30

#DATE=str(sys.argv[1])
MODELO=str(sys.argv[1])
nprev=int(sys.argv[2])


today=datetime.datetime.today().date()


#MODELO=MODEL
#today=datetime.datetime.strptime(DATE,"%Y%m%d").date()


##########################################
# All mode files located 
###########################################

FILES=glob.glob('Arq_Entrada/Previsao/%s/*.dat' %MODELO)



#########################################################################
# For estimation of PMEDIA
##########################################################################



ALL_LIST=[]

print('Rodando prev_remvies for %s........'%MODELO)


for file in FILES:
    #file=files.split('/')[-1]



    ###################################################################
    # extrating data from the file
    data_i_str=file.split('/')[-1].split('a')[0].split('p')[1] 
    data_p_tsr=file.split('/')[-1].split('a')[1].split('.')[0] 
    date_p=datetime.datetime.strptime(data_p_tsr,"%d%m%y").date() 
    date_i=datetime.datetime.strptime(data_i_str,"%d%m%y").date() 

    ################################################################

    
    

    
    print('Lendo arquivo %s e procesando ......' %file)
    print(date_i,date_p)
    PP_mod=np.loadtxt(file)   

    
    

    
    


    DATA_COINCI=PP_mod[:,2] # taking a column for preciptation
    PP_mod_pos=PP_mod[:,:2] #array of lon, lat
    
    for i,contor in enumerate(lookup_xlsx['contorno_ETA']):
        bac=lookup_xlsx['Macro-Bacia'][i]
        name_sub=lookup_xlsx['Nome'][i]
        tg=pd.read_csv(caminhocontornos+'/'+bac.strip()+'/'+contor+'.bln',header=None,skiprows=1)
        lonblng=tg[0]
        latblng=tg[1]
        coords = list(zip(latblng,lonblng))
        bac_pol =polygon.Polygon(coords)
        
        lati=lookup_xlsx[lookup_xlsx['Nome']==name_sub]['Latitude'].values[0]
        loni=lookup_xlsx[lookup_xlsx['Nome']==name_sub]['Longitude'].values[0]

            # tomando so uma area de 5 graus a partir del ponto da subvacia
        IDD_LON=(PP_mod_pos[:,0]<=loni+5) & (PP_mod_pos[:,0]>=loni-5) 
        IDD_LAT=(PP_mod_pos[:,1]<=lati+8) & (PP_mod_pos[:,1]>=lati-8 )

            #ETA_40_grid[IDD_LON &IDD_LAT,:]
            # indeces de onde estao esses pontos dentro los datos de GFS
        NUMERO=np.where((IDD_LON) & (IDD_LAT))[0]
        
        BOOL=[Point((PP_mod_pos[i,1],PP_mod_pos[i,0])).within(bac_pol) for i in NUMERO]
            #BOOL=append(Point((lat,lon)).within(bac_pol))
        
        if sum(BOOL)>0:
            MEAN=np.mean(DATA_COINCI[NUMERO[BOOL]])
            ALL_LIST.append((loni,lati,MEAN,bac,name_sub.strip(),date_i,date_p))
    



############################################################################    
#    making a Dataframe for appending to the current file
#################################################################################                                               
ALL_LIST=pd.DataFrame(ALL_LIST,columns=['lon','lat','PP','bacia','subb','date_0','date_p']) 

ALL_LIST['dia']=[(ALL_LIST['date_p'].values[i]-ALL_LIST['date_0'].values[i]).days for i in range(ALL_LIST.shape[0])]

for var,Data in ALL_LIST.groupby(['subb','bacia']):
    sub=var[0]
    bacia=var[1]
   
    FILE_TRABALHO='Trabalho/%s/%s/%s.csv' %(bacia,sub.strip(),MODELO)

    if not os.path.exists(FILE_TRABALHO):

        print('O Arquivo  %s nao existe , sera criado ' %FILE_TRABALHO)
        DATA=pd.DataFrame([],columns=['D%d'%i for i in range(1,nprev+1)])

        for ddate in Data.date_0.unique():
            SERIE={}
            for dias in range(1,nprev+1):
                val=Data.loc[(Data.dia==dias) & (Data.date_0==ddate),'PP'].values[0]
                SERIE['D%d'%(dias)]='%5.2f'%val

            row = pd.Series(SERIE,name='/'.join([str(ddate.day),str(ddate.month),str(ddate.year)]))
            DATA = DATA.append(row)

        DATA.index=pd.to_datetime(DATA.index,dayfirst=True)
        DATA=DATA.sort_index() # ordering index, 

        DATA.index=DATA.index.strftime('%d/%m/%Y') # converting to the format 
        
        DATA[DATA.columns]=DATA[DATA.columns].astype(float) # every columns in float format 


        DATA.to_csv(FILE_TRABALHO,sep=';',decimal=',') #writing a file

    else:

        DATA_C=pd.read_csv(FILE_TRABALHO,delimiter=';',index_col=0,decimal=',')
        DATA_C.index=pd.to_datetime(DATA_C.index,dayfirst=True)
        DATA=pd.DataFrame([],columns=['D%d'%i for i in range(1,nprev+1)])

        for ddate in  Data.date_0.unique():
            SERIE={}
            for dias in range(1,nprev+1):
                val=Data.loc[(Data.dia==dias) & (Data.date_0==ddate),'PP'].values[0]
                SERIE['D%d'%(dias)]='%5.2f'%val

            row = pd.Series(SERIE,name='/'.join([str(ddate.day),str(ddate.month),str(ddate.year)]))
            DATA = DATA.append(row)

        DATA.index=pd.to_datetime(DATA.index,dayfirst=True)
        DATA=DATA.sort_index() 



        #print('Appending to  ' %FILE_TRABALHO)
        P=0   

        CONCA=[DATA_C]

        DDF=abs(np.diff(np.array((DATA.index-DATA_C.index[-1]).days))) # diferences of days  between every date

        DIF_dias=np.array((DATA.index-DATA_C.index[-1]).days) # diferences of days respect to the last day saved in Trabalho/<sub>.csv file 


        if sum(DDF==1)==len(DDF) and 1 in DIF_dias:
            for nidx,idx in enumerate(DATA.index):
                DIFF=(idx-DATA_C.index[-1]).days 
                if DIFF>0:
                    P+=1
                    print('Atualizando historico para data %s  em %s' %(idx.date(),FILE_TRABALHO))
                    CONCA.append(DATA.loc[DATA.index==idx,:])

            CONCAT=pd.concat(CONCA,axis=0,sort=False) 
            CONCAT.index=CONCAT.index.strftime('%d/%m/%Y')
            
            CONCAT[CONCAT.columns]=CONCAT[CONCAT.columns].astype(float)
            CONCAT.to_csv(FILE_TRABALHO,sep=';',decimal=',') 
            

            if P==0:
                print('Atualizacao nao feita em %s' %(FILE_TRABALHO))
        else:
            print(' ...Cuidado ...\n Atualizacao nao feita para  %s .....\n  porque os dias de previsao nao continuam a ultima data do historico ou faltam algum arquivo em  %s \n' %(FILE_TRABALHO,'Arq_Entrada/Previsao/%s' %MODELO))






