#!/bin/bash

#########################################################################
#           RODANDO PREVIA A REMOÇAO DE VIES
#           ATUALIZANDO HISTORICO DE MODELOS
#          ATUALIZANDO HISTORICO DE OBSERVADO
#                     TEMPOOK
########################################################################

date_today=$1 # dia de inicializacion
model=$2
# modelos disponiveis: GFS, TOKA, ECMWF, GEFS
n_prev=$3

dir_in=$(pwd)

rm -f ${dir_in}/RemoveViesNuvem/Arq_Entrada/Previsao/${model}/*
rm  -f ${dir_in}/RemoveViesNuvem//Arq_Entrada/Observado/PSAT_ONS/*


#############################################
# Copiando o dados do psat do Downloads
lag=1
data_fmt=`date "+%d%m%Y" --date="${date_today}"-${lag}day`
echo ${data_fmt}

cp Downloads/psath_${data_fmt}.zip  ${dir_in}/RemoveViesNuvem/Arq_Entrada/Observado/PSAT_ONS/.
cd ${dir_in}/RemoveViesNuvem/Arq_Entrada/Observado/PSAT_ONS/

/cygdrive/c/Users/haylton.bernardes/Downloads/unzip.exe -q psath_${data_fmt}.zip
rm psath_${data_fmt}.zip
cd -

############################################
# copiando dados de precipitação prevista
cd ${dir_in}/Downloads/
for file in  $(ls *${model}*); do
    echo ${file}
    cp ${file} ${dir_in}/RemoveViesNuvem/Arq_Entrada/Previsao/${model}/
    cd ${dir_in}/RemoveViesNuvem/Arq_Entrada/Previsao/${model}/
    tar -xzf ${file}
    rm ${file}
    cd  ${dir_in}/Downloads/
    done

# atualizando historido do modelo na pasta Trabalho
cd ${dir_in}/RemoveViesNuvem/ 
/cygdrive/c/Users/haylton.bernardes/Anaconda3/python.exe Codigos/prev_remvies.py ${model} ${n_prev}

# Atualizando historico dos dados do PSAT.

echo "-------------------------------------------------"
echo "Reading psat. And creating file observado.csv"
echo "-----------------------------------------------" 
#python psat2csv <date> <nprev> <lag> <ndays>
/cygdrive/c/Users/haylton.bernardes/Anaconda3/python.exe Codigos/psat2csv.py ${date_today} 12 1 150


