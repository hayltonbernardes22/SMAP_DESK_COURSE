"""

Script para estimar a vazao total por postos, pode 
ser natural ou artificial 

python PosProc_total.py <data> <modelo> <dias_previsao> <vies>

exemplo para ECMWF para 11 de maio de 2020, 9 dias de previsao sem remoção de vies:

python PosProc_total.py 20200511 ECMWF 9 com

"""
import glob
import sys
import pandas as pd
import pyreadr
import datetime
import numpy as np

data=str(sys.argv[1])
Modelo=str(sys.argv[2])
nprev=int(sys.argv[3])
vies=str(sys.argv[4])

print('Running PosProc_total for model:%s %s vies' %(Modelo,vies))


file_smap='%s_%s_Simulacoes.RData' %(data,Modelo) 
DATA_SMAP=pyreadr.read_r(file_smap)['junta']
DATA_SMAP.index=DATA_SMAP['date']

ID_POSTOS=pd.read_csv('Postos_ONS_ID_2.csv',dtype=str)

data_hj=datetime.datetime.strptime(data,"%Y%m%d")



def travel_time(pbase,tv):
    poutbase=pbase.copy()
    if tv<=24:
        for i in range(1,len(pbase)):
            poutbase[i]=(tv*pbase[i-1] + (24-tv)*pbase[i])/24

    else:
        for i in range(2,len(pbase)):
            poutbase[i]=((tv-24)*pbase[i-2] + (48-tv)*pbase[i-1])/24
            
    
    return poutbase




def Export_Estilo(DATA_POSTOS,HEADER,Bacia,Var):
    # 'SMP_GRANDE_PMEDIA_ORIG_PREVISAO_S.txt'

    DATA_POSTOS_r=DATA_POSTOS.copy()
    DATA_POSTOS_r.index=DATA_POSTOS_r.index.strftime('%d/%m/%Y')
    file_d='out/%s/SMP_%s_PMEDIA_ORIG_PREVISAO_D_%s.txt' %(Modelo,Bacia,Var)

    f_d=open(file_d,'w')
    for il,LL in enumerate(HEADER):
        if il==1:
            f_d.write('\t'+'\t'.join(LL)+'\n')
        elif il==2:
            f_d.write('\t'+'\t'.join(LL)+'\n')

            
        else:
            f_d.write('\t'+'\t'.join(LL)+'\n')

    for i in range(DATA_POSTOS_r.shape[0]):
        f_d.write('%s\t' %DATA_POSTOS_r.index[i])
        for j in range(DATA_POSTOS_r.shape[1]):
            if j<DATA_POSTOS_r.shape[1]-1:
                f_d.write('%5.2f\t' %DATA_POSTOS_r.iloc[i,j])


            else:
                f_d.write('%5.2f\n' %DATA_POSTOS_r.iloc[i,j])

    f_d.close()
    return () 
    


def writing_by_points(Bacia,DATA_POSTOS,var):
    DATA_POSTOS_r=DATA_POSTOS.copy().astype(float)
    DATA_POSTOS_r.index=DATA_POSTOS_r.index.strftime('%d/%m/%Y')



    for col in DATA_POSTOS_r.columns:
        id_val=ID_POSTOS.loc[ID_POSTOS['posto']==col,'id'].values[0].strip()

        DB_SUBSET=DATA_POSTOS_r[col].copy()
        

        #DB_SUBSET.index=DB_SUBSET.index.strftime('%d/%m/%Y')
        VER=pd.Series(DB_SUBSET,name=var) 
        file_name='out_POSTOS/%s/%s_%s_%s_%s_D.txt'%(Modelo,id_val,var,col,Bacia)

        VER.to_csv(path_or_buf=file_name,sep=' ',float_format='%.2f',index_label='data')



    return()





#######################################################################################
#                        GRANDE
#################################################################

DATA_POSTOS=pd.DataFrame([],index=DATA_SMAP.index)
DATA_POSTOS['Camargos']=DATA_SMAP['CAMARGOS'].values
DATA_POSTOS['Itutinga']=DATA_POSTOS['Camargos'].values
DATA_POSTOS['FunilGrande']=DATA_SMAP['FUNIL MG'].values+DATA_POSTOS['Itutinga'].values
DATA_POSTOS['Furnas']=DATA_SMAP.FURNAS.values + travel_time(DATA_SMAP.PARAGUACU.values, 10)+ travel_time(DATA_SMAP.PBUENOS.values, 12)+DATA_POSTOS['FunilGrande']
DATA_POSTOS['MascMoraes']=DATA_SMAP['PCOLOMBIA']*0.377+  DATA_POSTOS['Furnas'] 
DATA_POSTOS['Estreito']= DATA_SMAP['PCOLOMBIA']* 0.087 +DATA_POSTOS['MascMoraes']
DATA_POSTOS['Jaguara']=DATA_SMAP['PCOLOMBIA']* 0.036+DATA_POSTOS['Estreito']
DATA_POSTOS['Igarapava']=DATA_SMAP['PCOLOMBIA']*0.103 +DATA_POSTOS['Jaguara']
DATA_POSTOS['VoltaGrande']=DATA_SMAP['PCOLOMBIA']*0.230 + DATA_POSTOS['Igarapava']
DATA_POSTOS['PColombia']=DATA_SMAP['PCOLOMBIA']*0.167 + travel_time(DATA_SMAP['CAPESCURO'].values, 8)+DATA_POSTOS['VoltaGrande']
DATA_POSTOS['Caconde']=DATA_SMAP['EDACUNHA']*0.610
DATA_POSTOS['ECunha']=DATA_SMAP['EDACUNHA']*0.390+DATA_POSTOS['Caconde'] 
DATA_POSTOS['Limoeiro']=DATA_SMAP['MARIMBONDO']*0.004+DATA_POSTOS['ECunha']
DATA_POSTOS['Marimbondo']=DATA_SMAP['MARIMBONDO']* 0.996 +travel_time(DATA_SMAP['PASSAGEM'].values, 16)+DATA_POSTOS['PColombia']+ DATA_POSTOS['Limoeiro']
DATA_POSTOS['AVermelha']=DATA_SMAP['AVERMELHA']+DATA_POSTOS['Marimbondo']

DATA_POSTOS=DATA_POSTOS.iloc[-nprev:].copy()
DATA_POSTOS_GRANDE=DATA_POSTOS.copy()

HD_1=['CAMARGOS','ITUTINGA','FUNIL-MG,211','FURNAS','M. MORAES','L. C. BARRETO', 'JAGUARA','IGARAPAVA','VOLTA GRANDE', 
'P. COLOMBIA','CACONDE','E. DA CUNHA','LIMOEIRO','MARIMBONDO','A. VERMELHA']
HD_2=['001','002','211','006','007','008','009','010','011','012','014','015','016','017','018']
HD_3=['NATURAL']*len(HD_1)


Export_Estilo(DATA_POSTOS,[HD_1,HD_2,HD_3],'GRANDE','TOTAL')
writing_by_points('GRANDE',DATA_POSTOS,'TOTAL')

     

##################################################################
#                   PARANAIBA BASIN
#################################################################

DATA_POSTOS=pd.DataFrame([],index=DATA_SMAP.index)

DATA_POSTOS['Batalha']=DATA_SMAP['SDOFACAO']*0.615
DATA_POSTOS['SerraFacao']=DATA_SMAP['SDOFACAO']* 0.385+DATA_POSTOS['Batalha']
DATA_POSTOS['Emborcacao']=DATA_SMAP['EMBORCACAO']+DATA_POSTOS['SerraFacao'] 
DATA_POSTOS['Espora']=DATA_SMAP['ESPORA']
DATA_POSTOS['Salto']=DATA_SMAP['SALTOVERDI']*0.923
DATA_POSTOS['Cacu']=DATA_SMAP['FOZCLARO']*0.8940
DATA_POSTOS['Verdinho']=DATA_SMAP['SALTOVERDI']*0.077+DATA_POSTOS['Salto']
DATA_POSTOS['Coqueiros']=DATA_SMAP['FOZCLARO']*0.037+DATA_POSTOS['Cacu']
DATA_POSTOS['FozClaro']=DATA_SMAP['FOZCLARO']*0.069+DATA_POSTOS['Coqueiros']
DATA_POSTOS['CorumbaIV']=DATA_SMAP['CORUMBAIV']
DATA_POSTOS['CorumbaIII']=DATA_SMAP['CORUMBA1']*0.10+DATA_POSTOS['CorumbaIV']
DATA_POSTOS['CorumbaI']=DATA_SMAP['CORUMBA1']*0.90+DATA_POSTOS['CorumbaIII']
DATA_POSTOS['NovaPonte']=DATA_SMAP['NOVAPONTE']
DATA_POSTOS['Miranda']=DATA_SMAP['ITUMBIARA']*0.040+DATA_POSTOS['NovaPonte']
DATA_POSTOS['CapimBranco1']=DATA_SMAP['ITUMBIARA']*0.005+DATA_POSTOS['Miranda']
DATA_POSTOS['CapimBranco2']=DATA_SMAP['ITUMBIARA']*0.012+DATA_POSTOS['CapimBranco1']
DATA_POSTOS['Itumbiara']=DATA_SMAP['ITUMBIARA']*0.943+DATA_POSTOS['CorumbaI']+DATA_POSTOS['Emborcacao']+DATA_POSTOS['CapimBranco2']
DATA_POSTOS['CachDourada']=DATA_SMAP['SSIMAO2']*0.109+DATA_POSTOS['Itumbiara']
DATA_POSTOS['SaoSimao']=DATA_SMAP['SSIMAO2']*0.891+DATA_POSTOS['CachDourada']+travel_time(DATA_SMAP['RVERDE'].values,8)

DATA_POSTOS=DATA_POSTOS.iloc[-nprev:].copy()
DATA_POSTOS_PNAIBA=DATA_POSTOS.copy()


HD_1=[ 'BATALHA','S.DO FACÃO','EMBORCAÇÃO','ESPORA','SALTO','CACU','S.R.VERDINHO','B.COQUEIROS','FOZ DO RIO CLARO','CORUMBA-4','CORUMBA-3','CORUMBA','NOVA PONTE','MIRANDA','C.BRANCO-1','C.BRANCO-2','ITUMBIARA','C. DOURADA','SÃO SIMÃO']
HD_2=['022','251','024','099','294','247','241','248','261','205','023','209','025','206','207','028','031','032','033']
HD_3=['NATURAL']*len(HD_1)
Export_Estilo(DATA_POSTOS,[HD_1,HD_2,HD_3],'PNAIBA','TOTAL')
writing_by_points('PNAIBA',DATA_POSTOS,'TOTAL')




#################################################
#                    BACIA TIETE
#################################################
DATA_POSTOS=pd.DataFrame([],index=DATA_SMAP.index)


DATA_POSTOS['PonteNova']=DATA_SMAP['ESOUZA']*0.073 
DATA_POSTOS['Guarapiranga']=DATA_SMAP['ESOUZA']*0.120
DATA_POSTOS['Billings.Pedra']=DATA_SMAP['ESOUZA']* 0.183
PREV_118=DATA_POSTOS['Billings.Pedra'].values.copy()*(0.813)+0.185
DATA_POSTOS['ES.Pinheiros']=DATA_SMAP['ESOUZA']*0.624 + DATA_POSTOS['PonteNova'] + PREV_118 +DATA_POSTOS['Guarapiranga']


 
DIF=0.1*(DATA_POSTOS['ES.Pinheiros']-DATA_POSTOS['Guarapiranga']-PREV_118)+DATA_POSTOS['Guarapiranga']+PREV_118 # 


print('Diferencia para calculo de vazao artificial')
print(DIF)
DATA_POSTOS['BarraBonita']=DATA_SMAP['BBONITA']+DATA_POSTOS['ES.Pinheiros'] 
DATA_POSTOS['Bariri']=DATA_SMAP['IBITINGA']*0.344 +DATA_POSTOS['BarraBonita']
DATA_POSTOS['Ibitinga']=DATA_SMAP['IBITINGA']* 0.656+DATA_POSTOS['Bariri']
DATA_POSTOS['Promissao']=DATA_SMAP['NAVANHANDA']*0.719+DATA_POSTOS['Ibitinga']
DATA_POSTOS['NAvanhandava']=DATA_SMAP['NAVANHANDA']*0.281+DATA_POSTOS['Promissao']
DATA_POSTOS['BarraBonita']=DATA_POSTOS['BarraBonita']-DIF
DATA_POSTOS['Bariri']=DATA_POSTOS['Bariri']-DIF
DATA_POSTOS['Ibitinga']-=DIF
DATA_POSTOS['Promissao']-=DIF
DATA_POSTOS['NAvanhandava']-=DIF
DATA_POSTOS['Billings']=PREV_118 # ja que Billings é natural
DATA_POSTOS['Traicao']=PREV_118+DATA_POSTOS['Guarapiranga']
DATA_POSTOS['Pedreira']=PREV_118
DATA_POSTOS['Pedras']=DATA_POSTOS['Billings.Pedra']-PREV_118
DATA_POSTOS['HBorden']=DATA_POSTOS['Pedras']+DIF # Artificial


NAVANHANDA_NAT=DATA_POSTOS['NAvanhandava'].copy()+DIF # necesario para ser usado em Tres irmaos no Parana

DATA_POSTOS=DATA_POSTOS.iloc[-nprev:].copy()



DATA_POSTOS_TIETE=DATA_POSTOS.copy()



HD_1=['PONTE NOVA','GUARAPIRANGA','BILL E PEDRAS','E. S. + PINHEIROS','B. BONITA','BARIRI','IBITINGA','PROMISSÃO','N. AVANHANDAVA','BILLINGS','TRAIÇAO','PEDRAS','HBORDEN']
HD_2=['160','117','119','161','237','238','239','240','242','118','109','116','318']
HD_3=['NATURAL','NATURAL','NATURAL','NATURAL','ARTIFICIAL','ARTIFICIAL','ARTIFICIAL','ARTIFICIAL','ARTIFICIAL','NATURAL','NATURAL','NATURAL','ARTIFICIAL']


Export_Estilo(DATA_POSTOS,[HD_1,HD_2,HD_3],'TIETE','TOTAL')
writing_by_points('TIETE',DATA_POSTOS,'TOTAL')





#############################################
#     BACIA DO PARANAPANEMA
#############################################


DATA_POSTOS=pd.DataFrame([],index=DATA_SMAP.index)

DATA_POSTOS['Jurumirim']=DATA_SMAP['JURUMIRIM']
DATA_POSTOS['Piraju']=DATA_SMAP['CHAVANTES']*0.046+DATA_POSTOS['Jurumirim']
DATA_POSTOS['Chavantes']=DATA_SMAP['CHAVANTES']*.954+DATA_POSTOS['Piraju']
DATA_POSTOS['Ourinhos']=DATA_SMAP['CANOASI']*0.031+DATA_POSTOS['Chavantes']
DATA_POSTOS['SaltoGrande']=DATA_SMAP['CANOASI']*0.778+ DATA_POSTOS['Ourinhos'] # Este é o L C garzes
DATA_POSTOS['Canoas2']=DATA_SMAP['CANOASI']*0.061+DATA_POSTOS['SaltoGrande']
DATA_POSTOS['Canoas1']=DATA_SMAP['CANOASI']*0.130+DATA_POSTOS['Canoas2']
DATA_POSTOS['Maua']=DATA_SMAP['MAUA'] 
DATA_POSTOS['Capivara']=DATA_SMAP['CAPIVARA']+DATA_POSTOS['Maua']+ DATA_SMAP['CANOASI']+DATA_POSTOS['Ourinhos'] # Corregido por Thiago porem nao bate muito
DATA_POSTOS['Taquarucu']=DATA_SMAP['ROSANA']*0.299+DATA_POSTOS['Capivara']
DATA_POSTOS['Rosana']=DATA_SMAP['ROSANA']*0.701+DATA_POSTOS['Taquarucu']

DATA_POSTOS=DATA_POSTOS.iloc[-nprev:].copy()
DATA_POSTOS_PPANEMA=DATA_POSTOS.copy()

HD_1=['JURUMIRIM','PIRAJU','CHAVANTES','OURINHOS','SALTO GRANDE CS','CANOAS II','CANOAS I','MAUA','CAPIVARA','TAQUARUÇU','ROSANA']
HD_2=['047','048','049','249','050','051','052','057','061','062','063']
HD_3=['NATURAL']*len(HD_1)

Export_Estilo(DATA_POSTOS,[HD_1,HD_2,HD_3],'PPANEMA','TOTAL')
writing_by_points('PPANEMA',DATA_POSTOS,'TOTAL')


####################################################
#   PARANA
#######################################################
# 
#
DATA_POSTOS=pd.DataFrame([],index=DATA_SMAP.index)

DATA_POSTOS['Solteira']=DATA_SMAP['ILHAEQUIV']*0.94+DATA_POSTOS_GRANDE['AVermelha']+DATA_POSTOS_PNAIBA['Espora']+DATA_POSTOS_PNAIBA['Verdinho']+ \
DATA_POSTOS_PNAIBA['FozClaro']+DATA_POSTOS_PNAIBA['SaoSimao'] 
DATA_POSTOS['Tres_irmaos']=DATA_SMAP['ILHAEQUIV']*0.06+NAVANHANDA_NAT  # tirei isto DATA_SMAP['ILHAEQUIV']*0.06, seguindo as recomendações de Thiago
DATA_POSTOS['SDomingo']=DATA_SMAP['SDO']
DATA_POSTOS['Jupia']=DATA_SMAP['JUPIA']+DATA_POSTOS['Solteira'] + DATA_POSTOS['Tres_irmaos']
DATA_POSTOS['Ppri']=DATA_SMAP['PPRI']+travel_time(DATA_SMAP['FZB'].values,26)+DATA_POSTOS['Jupia']+DATA_POSTOS['SDomingo'] 
DATA_POSTOS['Itaipu']=DATA_SMAP['ITAIPU']+travel_time(DATA_SMAP['BALSA'].values,32)+travel_time(DATA_SMAP['FLOR+ESTRA'].values,33)+ \
travel_time(DATA_SMAP['IVINHEMA'].values,45)+travel_time(DATA_SMAP['PTAQUARA'].values,36)+DATA_POSTOS['Ppri']-DIF+DATA_POSTOS_PPANEMA['Rosana']





DATA_POSTOS['Tres_irmaos']=DATA_POSTOS['Tres_irmaos']-DIF  

DATA_POSTOS['Ppri']=DATA_POSTOS['Ppri']-DIF
DATA_POSTOS['Jupia']=DATA_POSTOS['Jupia']-DIF

DATA_POSTOS=DATA_POSTOS.iloc[-nprev:].copy()
DATA_POSTOS_PARANA=DATA_POSTOS.copy()


HD_1=['I. SOLTEIRA','TRÊS IRMÃOS','SAO DOMINGOS','JUPIA','PORTO PRIMAVERA','ITAIPU']
HD_2=['034','243','245','246','266','154','246','266']
HD_3=['NATURAL','ARTIFICIAL','ARTIFICIAL','ARTIFICIAL','NATURAL','ARTIFICIAL']
Export_Estilo(DATA_POSTOS,[HD_1,HD_2,HD_3],'PARANA','TOTAL')
writing_by_points('PARANA',DATA_POSTOS,'TOTAL')






######################################
# BACIA DE SAO FRANCISCO
######################################
DATA_POSTOS=pd.DataFrame([],index=DATA_SMAP.index)

DATA_POSTOS['RetiroBaixo']=DATA_SMAP['RB-SMAP']
DATA_POSTOS['TresMarias']=DATA_SMAP['TM-SMAP']+DATA_POSTOS['RetiroBaixo'] # duvida aqui

DATA_POSTOS['Queimado']=DATA_SMAP['QM']


HD_1=['RETIRO BAIXO','TRÊS MARIAS','QUEIMADO']
HD_2=['155','156','158']
HD_3=['NATURAL']*3



DATA_POSTOS=DATA_POSTOS.iloc[-nprev:].copy()
DATA_POSTOS_SF=DATA_POSTOS.copy()

Export_Estilo(DATA_POSTOS,[HD_1,HD_2,HD_3],'SF3','TOTAL')

writing_by_points('SF3',DATA_POSTOS,'TOTAL')


############################
# BACIA DE TOCANTINS
##########################
DATA_POSTOS=pd.DataFrame([],index=DATA_SMAP.index)
DATA_POSTOS['SerraMesa']=DATA_SMAP['SMESA']



DATA_POSTOS=DATA_POSTOS.iloc[-nprev:].copy()
DATA_POSTOS_TOC=DATA_POSTOS.copy().astype(float)



HD_1=['SERRA DA MESA']
HD_2=['270']
HD_3=['NATURAL']



Export_Estilo(DATA_POSTOS,[HD_1,HD_2,HD_3],'TOC','TOTAL')
writing_by_points('TOC',DATA_POSTOS,'TOTAL')






#########################################
#            BACIA IGUAÇU
########################################3

DATA_POSTOS=pd.DataFrame([],index=DATA_SMAP.index)

DATA_POSTOS['SantaClara']=DATA_SMAP['STACLARA']
DATA_POSTOS['Fundao']=DATA_SMAP['JORDSEG']*0.039+DATA_POSTOS['SantaClara'] 
DATA_POSTOS['Jordao']=DATA_SMAP['JORDSEG']*0.157+DATA_POSTOS['Fundao'] 
DATA_POSTOS['GBMunhoz']=DATA_SMAP['FOA']+travel_time(DATA_SMAP['UVITORIA'].values, 17.4) 
DATA_POSTOS['Segredo']=DATA_SMAP['JORDSEG']*0.804 +DATA_POSTOS['GBMunhoz']
DATA_POSTOS['Segredo.Jordao']=DATA_SMAP['JORDSEG']*0.0 
DATA_POSTOS['SaltoSantiago']=DATA_SMAP['SCAXIAS']*.258 +DATA_POSTOS['Segredo']+DATA_POSTOS['Jordao'] 
DATA_POSTOS['SaltoOsorio']=DATA_SMAP['SCAXIAS']*0.102+DATA_POSTOS['SaltoSantiago']
DATA_POSTOS['SaltoCaxias']=DATA_SMAP['SCAXIAS']*0.640 +DATA_POSTOS['SaltoOsorio']
DATA_POSTOS['Segredo']=DATA_POSTOS['Segredo'].values+ np.array([np.min([DATA_POSTOS['Jordao'].values[i]-10,173.5]) for i in range(len(DATA_POSTOS['Jordao']))])



DATA_POSTOS=DATA_POSTOS.iloc[-nprev:].copy()
DATA_POSTOS_IGUACU=DATA_POSTOS.copy().astype(float)


HD_1=['SANTA CLARA-PR','FUNDÃO','JORDÃO','G. . BMUNHOZ','SEGREDO','SEGREDO+JORDAO','SALTO SANTIAGO','SALTO OSORIO','SALTO CAXIAS']
HD_2=['071','072','073','074','076','976','077','078','222']
HD_3=['NATURAL']*len(HD_1)
HD_3[4]='ARTIFICIAL'

Export_Estilo(DATA_POSTOS,[HD_1,HD_2,HD_3],'IGUACU','TOTAL')
writing_by_points('IGUACU',DATA_POSTOS,'TOTAL')


####################################################
#            URUGUAI
####################################################
DATA_POSTOS=pd.DataFrame([],index=DATA_SMAP.index)



DATA_POSTOS['Garibaldi']=DATA_SMAP['CN']*0.910
DATA_POSTOS['CamposNovos']=DATA_SMAP['CN']*0.090+DATA_POSTOS['Garibaldi']
DATA_POSTOS['BarraGrande']=DATA_SMAP['BG']
DATA_POSTOS['Machadinho']=DATA_SMAP['MACHADINHO']+DATA_POSTOS['CamposNovos']+DATA_POSTOS['BarraGrande']
DATA_POSTOS['Ita']=DATA_SMAP['ITA']+DATA_POSTOS['Machadinho']
DATA_POSTOS['QuebraQueixo']=DATA_SMAP['QQUEIXO']
DATA_POSTOS['PassoFundo']=DATA_SMAP['MONJOLINHO']*.586
DATA_POSTOS['Monjolinho']=DATA_SMAP['MONJOLINHO']*.414+DATA_POSTOS['PassoFundo']
DATA_POSTOS['FozChapeco']=DATA_SMAP['FOZCHAPECO'] +DATA_POSTOS['Ita']+DATA_POSTOS['Monjolinho']
DATA_POSTOS['SaoJose']=DATA_SMAP['SJOAO']*0.963
DATA_POSTOS['PassoSaoJoao']=DATA_SMAP['SJOAO']*0.037+DATA_POSTOS['SaoJose']

DATA_POSTOS=DATA_POSTOS.iloc[-nprev:].copy()

DATA_POSTOS_URU=DATA_POSTOS.copy().astype(float)


HD_1=['GARIBALDI','CAMPOS NOVOS','BARRA GRANDE','MACHADINHO','ITÁ','QUEBRA QUEIXO','PASSO FUNDO','MONJOLINHO','FOZ CHAPECO','SAO JOSE','PASSO SAO JOAO']
HD_2=['089','216','215','217','092','286','093','220','094','102','103']
HD_3=['NATURAL']*len(HD_1)


Export_Estilo(DATA_POSTOS,[HD_1,HD_2,HD_3],'URU','TOTAL')
writing_by_points('URU',DATA_POSTOS,'TOTAL')

########################################################
#
#  Criando saida para todos os postos
#
#########################################################

DATA_POSTOS=pd.concat([DATA_POSTOS_GRANDE,DATA_POSTOS_PNAIBA,DATA_POSTOS_TIETE,DATA_POSTOS_PARANA,DATA_POSTOS_PPANEMA,DATA_POSTOS_SF,DATA_POSTOS_TOC,DATA_POSTOS_IGUACU,DATA_POSTOS_URU],axis=1)

DATA_POSTOS=DATA_POSTOS[list(ID_POSTOS.posto.values)]
DATA_POSTOS.columns=[i.strip() for i in DATA_POSTOS.columns]
DATA_T_VAZ=DATA_POSTOS.T.copy()
DATA_T_VAZ.columns=['d%d'%i for i in range(DATA_T_VAZ.shape[1])]
DATA_T_VAZ.index=[i.strip() for i in ID_POSTOS.id.values]


file_name='out/%s/%s_%s_vies_%s_all_TOTAL.csv' %(Modelo,Modelo,vies,data)

DATA_T_VAZ=DATA_T_VAZ.astype(float)
DATA_T_VAZ.to_csv(path_or_buf=file_name,sep=',',float_format='%.1f',index_label='posto',header=True)





