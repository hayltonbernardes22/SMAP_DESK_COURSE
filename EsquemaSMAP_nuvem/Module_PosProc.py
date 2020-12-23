'''
Module for be used in the PosProc of SMAP
'''
import glob
import pandas as pd
import numpy as np


def travel_time(pbase,tv):
    poutbase=pbase.copy()
    if tv<=24:
        for i in range(1,len(pbase)):
            poutbase[i]=(tv*pbase[i-1] + (24-tv)*pbase[i])/24

    else:
        for i in range(2,len(pbase)):
            poutbase[i]=((tv-24)*pbase[i-2] + (48-tv)*pbase[i-1])/24
            
    
    return poutbase


def Incre2total(DATA_POSTOS):

    '''
    Converte de vazao incremental ao total
    '''

    DATA_POSTOS=DATA_POSTOS.copy()
    DATA_POSTOS['211']+=DATA_POSTOS['001']
    DATA_POSTOS['006']+=DATA_POSTOS['211']
    DATA_POSTOS['007']+=DATA_POSTOS['006']
    DATA_POSTOS['008']+=DATA_POSTOS['007']
    DATA_POSTOS['009']+=DATA_POSTOS['008']
    DATA_POSTOS['010']+=DATA_POSTOS['009']
    DATA_POSTOS['011']+=DATA_POSTOS['010']
    DATA_POSTOS['012']+=DATA_POSTOS['011']
    DATA_POSTOS['015']+=DATA_POSTOS['014']
    DATA_POSTOS['016']+=DATA_POSTOS['015']
    DATA_POSTOS['017']+=DATA_POSTOS[['016','012']].sum(axis=1)
    DATA_POSTOS['018']+=DATA_POSTOS['017']

    DATA_POSTOS['251']+=DATA_POSTOS['022']
    DATA_POSTOS['024']+=DATA_POSTOS['251']
    DATA_POSTOS['241']+=DATA_POSTOS['294']
    DATA_POSTOS['248']+=DATA_POSTOS['247']
    DATA_POSTOS['261']+=DATA_POSTOS['248']
    DATA_POSTOS['023']+=DATA_POSTOS['205']
    DATA_POSTOS['209']+=DATA_POSTOS['023']
    DATA_POSTOS['206']+=DATA_POSTOS['025']
    DATA_POSTOS['207']+=DATA_POSTOS['206']
    DATA_POSTOS['028']+=DATA_POSTOS['207']
    DATA_POSTOS['031']+=(DATA_POSTOS[['209','024','028']].sum(axis=1))
    DATA_POSTOS['032']+=DATA_POSTOS['031']
    DATA_POSTOS['033']+=DATA_POSTOS['032']
    
    PREV_118=DATA_POSTOS['119'].values.copy()*(0.813)+0.185
    DATA_POSTOS['161']+=(DATA_POSTOS[['160','117']].sum(axis=1).values+PREV_118)

    DIF=0.1*(DATA_POSTOS['161']-DATA_POSTOS['117']-PREV_118)+DATA_POSTOS['117']+PREV_118

    DATA_POSTOS['237']+=DATA_POSTOS['161']
    DATA_POSTOS['238']+=DATA_POSTOS['237']
    DATA_POSTOS['239']+=DATA_POSTOS['238']
    DATA_POSTOS['240']+=DATA_POSTOS['239']
    DATA_POSTOS['242']+=DATA_POSTOS['240']

    NAVANHANDA_NAT=DATA_POSTOS['242'].copy()

    # transformação em artificial
    DATA_POSTOS['237']-=DIF
    DATA_POSTOS['238']-=DIF
    DATA_POSTOS['239']-=DIF
    DATA_POSTOS['240']-=DIF
    DATA_POSTOS['242']-=DIF
    DATA_POSTOS['118']=PREV_118
    DATA_POSTOS['104']=DATA_POSTOS['118']+DATA_POSTOS['117']
    DATA_POSTOS['109']=DATA_POSTOS['118']
    DATA_POSTOS['116']=DATA_POSTOS['119']-PREV_118
    DATA_POSTOS['318']=DATA_POSTOS['116']+DIF
    

    CANOASI=DATA_POSTOS[['249','050','051','052']].sum(axis=1)
    DATA_POSTOS['048']+=DATA_POSTOS['047']
    DATA_POSTOS['049']+=DATA_POSTOS['048']
    DATA_POSTOS['249']+=DATA_POSTOS['049']
    DATA_POSTOS['050']+=DATA_POSTOS['249']
    DATA_POSTOS['051']+=DATA_POSTOS['050']
    DATA_POSTOS['052']+=DATA_POSTOS['051']
    DATA_POSTOS['061']+=(DATA_POSTOS[['249','057']].sum(axis=1)+CANOASI)
    DATA_POSTOS['062']+=DATA_POSTOS['061']
    DATA_POSTOS['063']+=DATA_POSTOS['062']
    
    ######################################## 
    #       PARANA
    #########################################
    

    DATA_POSTOS['034']+=DATA_POSTOS[['018','099','241','261','033']].sum(axis=1)
    DATA_POSTOS['243']+=NAVANHANDA_NAT
    DATA_POSTOS['245']+=DATA_POSTOS[['034','243']].sum(axis=1)
    DATA_POSTOS['246']+=DATA_POSTOS[['245','154']].sum(axis=1)
    DATA_POSTOS['266']+=(DATA_POSTOS[['246','063']].sum(axis=1)).copy()-DIF
   
    DATA_POSTOS['243']-=DIF
    DATA_POSTOS['246']-=DIF
    DATA_POSTOS['245']-=DIF

    ###########################
    #     SAO FRANCISCO
    ###########################
    DATA_POSTOS['156']+=DATA_POSTOS['155']

    ###############################
    # IGUAÇU 
    ###############################

    DATA_POSTOS['072']+=DATA_POSTOS['071']
    DATA_POSTOS['073']+=DATA_POSTOS['072']
    DATA_POSTOS['076']+=DATA_POSTOS['074']
    DATA_POSTOS['077']+=DATA_POSTOS[['076','073']].sum(axis=1)
    DATA_POSTOS['078']+=DATA_POSTOS['077']
    DATA_POSTOS['222']+=DATA_POSTOS['078']
    # artificial
    DATA_POSTOS['076']+=np.array([np.min([DATA_POSTOS['073'].values[i]-10,173.5]) for i in range(len(DATA_POSTOS['073']))])

    

    ########################################
    # URUGUAI
    #######################################
   
    DATA_POSTOS['216']+=DATA_POSTOS['089']

    DATA_POSTOS['217']+=DATA_POSTOS[['216','215']].sum(axis=1)
    DATA_POSTOS['092']+=DATA_POSTOS['217']
    DATA_POSTOS['220']+=DATA_POSTOS['093']
    DATA_POSTOS['094']+=DATA_POSTOS[['092','220']].sum(axis=1)
    DATA_POSTOS['103']+=DATA_POSTOS['102']

    return (DATA_POSTOS)





def Incremental_by_points(DATA_SMAP):

    DATA_F=pd.DataFrame([],index=DATA_SMAP.index)

    '''
    Incremental por cada posto
     
    '''

    ##############################################################################
    #                         GRANDE
    ###############################################################################
    DATA_F['001']=DATA_SMAP['CAMARGOS']
    DATA_F['002']=DATA_SMAP['CAMARGOS']*0
    DATA_F['211']=DATA_SMAP['FUNIL MG'] #Funil Grande
    DATA_F['006']=DATA_SMAP.FURNAS.values+travel_time(DATA_SMAP.PARAGUACU.values, 10)+ travel_time(DATA_SMAP.PBUENOS.values, 12)  
    DATA_F['007']=DATA_SMAP['PCOLOMBIA']*.377
    DATA_F['008']=DATA_SMAP['PCOLOMBIA']*.087
    DATA_F['009']=DATA_SMAP['PCOLOMBIA']*.036
    DATA_F['010']=DATA_SMAP['PCOLOMBIA']*.103
    DATA_F['011']=DATA_SMAP['PCOLOMBIA']*.230 #Volta Grande
    DATA_F['012']=DATA_SMAP['PCOLOMBIA']*.167
    DATA_F['014']=DATA_SMAP['EDACUNHA']*.610 #Caconde
    DATA_F['015']=DATA_SMAP['EDACUNHA']*.390
    DATA_F['016']=DATA_SMAP['MARIMBONDO']*.004
    DATA_F['017']=DATA_SMAP['MARIMBONDO']* .996 +travel_time(DATA_SMAP['PASSAGEM'].values, 16)
    DATA_F['018']=DATA_SMAP['AVERMELHA']

    ######################################
    #  PARANAIBA
    #####################################

    DATA_F['022']=DATA_SMAP['SDOFACAO']*.615
    DATA_F['251']=DATA_SMAP['SDOFACAO']* .385
    DATA_F['024']=DATA_SMAP['EMBORCACAO'] 
    DATA_F['099']=DATA_SMAP['ESPORA']

    DATA_F['294']=DATA_SMAP['SALTOVERDI']*.923
    DATA_F['247']=DATA_SMAP['FOZCLARO']*.8940

    DATA_F['241']=DATA_SMAP['SALTOVERDI']*.077
    DATA_F['248']=DATA_SMAP['FOZCLARO']*.037
    DATA_F['261']=DATA_SMAP['FOZCLARO']*.069
    DATA_F['205']=DATA_SMAP['CORUMBAIV']
    DATA_F['023']=DATA_SMAP['CORUMBA1']*.10
    DATA_F['209']=DATA_SMAP['CORUMBA1']*.90

    DATA_F['025']=DATA_SMAP['NOVAPONTE']
    DATA_F['206']=DATA_SMAP['ITUMBIARA']*.040
    DATA_F['207']=DATA_SMAP['ITUMBIARA']*.005
    DATA_F['028']=DATA_SMAP['ITUMBIARA']*.012

    DATA_F['031']=DATA_SMAP['ITUMBIARA']*.943

    DATA_F['032']=DATA_SMAP['SSIMAO2']*.109
    DATA_F['033']=DATA_SMAP['SSIMAO2']*.891+travel_time(DATA_SMAP['RVERDE'].values,8)
    
    #########################
    #        TIETE
    #########################
    DATA_F['160']=DATA_SMAP['ESOUZA']*.073 
    DATA_F['117']=DATA_SMAP['ESOUZA']*.120
    DATA_F['119']=DATA_SMAP['ESOUZA']* .183
    DATA_F['161']=DATA_SMAP['ESOUZA']*0.624 
    DATA_F['237']=DATA_SMAP['BBONITA'] 
    DATA_F['238']=DATA_SMAP['IBITINGA']*.344 
    DATA_F['239']=DATA_SMAP['IBITINGA']* .656
    DATA_F['240']=DATA_SMAP['NAVANHANDA']*.719
    DATA_F['242']=DATA_SMAP['NAVANHANDA']*.281

    ###########################################
    #    PARANAPANEMA
    ###########################################
    DATA_F['047']=DATA_SMAP['JURUMIRIM']
    DATA_F['048']=DATA_SMAP['CHAVANTES']*.046
    DATA_F['049']=DATA_SMAP['CHAVANTES']*.954
    DATA_F['249']=DATA_SMAP['CANOASI']*.031



    DATA_F['050']=DATA_SMAP['CANOASI']*.778  
    DATA_F['051']=DATA_SMAP['CANOASI']*.061
    DATA_F['052']=DATA_SMAP['CANOASI']*.130
    DATA_F['057']=DATA_SMAP['MAUA'] 
    DATA_F['061']=DATA_SMAP['CAPIVARA'] 
    DATA_F['062']=DATA_SMAP['ROSANA']*.299
    DATA_F['063']=DATA_SMAP['ROSANA']*.701
    #########################################
    #   PARANA
    #########################################
    DATA_F['034']=DATA_SMAP['ILHAEQUIV']*.94
    DATA_F['243']=DATA_SMAP['ILHAEQUIV']*.06
    DATA_F['154']=DATA_SMAP['SDO']
    DATA_F['245']=DATA_SMAP['JUPIA']
    DATA_F['246']=DATA_SMAP['PPRI']+travel_time(DATA_SMAP['FZB'].values,26) 
    DATA_F['266']=DATA_SMAP['ITAIPU']+travel_time(DATA_SMAP['BALSA'].values,32)+travel_time(DATA_SMAP['FLOR+ESTRA'].values,33)+ \
travel_time(DATA_SMAP['IVINHEMA'].values,45)+travel_time(DATA_SMAP['PTAQUARA'].values,36)

    DATA_F['155']=DATA_SMAP['RB-SMAP']
    DATA_F['156']=DATA_SMAP['TM-SMAP']
    DATA_F['158']=DATA_SMAP['QM']

    DATA_F['270']=DATA_SMAP['SMESA']
    
    DATA_F['071']=DATA_SMAP['STACLARA']
    DATA_F['072']=DATA_SMAP['JORDSEG']*.039
    DATA_F['073']=DATA_SMAP['JORDSEG']*.157

    DATA_F['074']=DATA_SMAP['FOA']+travel_time(DATA_SMAP['UVITORIA'].values, 17.4) # Este é Foz de areia

    DATA_F['076']=DATA_SMAP['JORDSEG']*.804 
    DATA_F['976']=DATA_SMAP['JORDSEG']*.0 
    DATA_F['077']=DATA_SMAP['SCAXIAS']*.258 
    DATA_F['078']=DATA_SMAP['SCAXIAS']*.102
    DATA_F['222']=DATA_SMAP['SCAXIAS']*.640 


    DATA_F['089']=DATA_SMAP['CN']*.910
    DATA_F['216']=DATA_SMAP['CN']*.090
    DATA_F['215']=DATA_SMAP['BG']
    DATA_F['217']=DATA_SMAP['MACHADINHO']
    DATA_F['092']=DATA_SMAP['ITA']
    DATA_F['286']=DATA_SMAP['QQUEIXO']
    DATA_F['093']=DATA_SMAP['MONJOLINHO']*.586
    DATA_F['220']=DATA_SMAP['MONJOLINHO']*.414
    DATA_F['094']=DATA_SMAP['FOZCHAPECO']
    DATA_F['102']=DATA_SMAP['SJOAO']*.963
    DATA_F['103']=DATA_SMAP['SJOAO']*.037

    

    return DATA_F


