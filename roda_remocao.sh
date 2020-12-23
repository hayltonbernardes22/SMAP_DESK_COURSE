#!/bin/bash

#############################################################
#   SCRIPT PARA GERAR PMEDIAS USANDO REMOCAO DE VIES OU NAO
#   TAMBEM PODE RODAR CONJUNTO
#    TEMPOOK
#   COMO USAR:
#   ./rodaremocao <date> <model> <n_prev> <vies>
#    date=yyyymmdd
#    model="GEFS", "TOKA","GFS","ECMWF"
#    caso de ser conjunto usa - entre modelos: EX: TOKA-GFS-ECMWF  
#    Em  Arq_Saida_com_remocao_vies vao os PMEDIAS da remoçao de Vies
#    Em  Arq_Saida_sem_remocao_vies vao os PMEDIAS da remoçao de Vies
###########################################################

date_today=$1 # dia de inicializacion
model=$2
n_prev=$3
vies=$4
agrupamento=3
regression=120
observado="observado"
dir_in=$(pwd)

cd ${dir_in}/RemoveViesNuvem/

if [ "${vies}" == "com" ] ; then
  rm -f ${dir_in}/RemoveViesNuvem/Arq_Saida_com_remocao_vies/*
  echo "------------------------------------------------"
  echo "Running Remocao de Vies "
  echo "-------------------------------------"

  sed 's,xnprevx,'"${n_prev}"',g' "Codigos/Roda_Conjunto_V1.1_by_model.R-cat" > "Codigos/Roda_Conjunto_V1.1_by_model.R"
  sed -i 's,xtodayx,'"${date_today}"',g' "Codigos/Roda_Conjunto_V1.1_by_model.R"
  sed -i 's,xmodelx,'"${model}"',g' "Codigos/Roda_Conjunto_V1.1_by_model.R"
  sed -i 's,xagrupx,'"${agrupamento}"',g' "Codigos/Roda_Conjunto_V1.1_by_model.R"
  sed -i 's,xobsx,'"${observado}"',g' "Codigos/Roda_Conjunto_V1.1_by_model.R"
  sed -i 's,xtregx,'"${regression}"',g' "Codigos/Roda_Conjunto_V1.1_by_model.R"
  Rscript Codigos/Roda_Conjunto_V1.1_by_model.R
  mkdir -p  ${dir_in}/EsquemaSMAP_nuvem/tmp/${model}
  rm -f  ${dir_in}/EsquemaSMAP_nuvem/tmp/${model}/*
  cp ${dir_in}/RemoveViesNuvem/Arq_Saida_com_remocao_vies/*${model}*   ${dir_in}/EsquemaSMAP_nuvem/tmp/${model}/.
else
   rm -f ${dir_in}/RemoveViesNuvem/Arq_Saida_sem_remocao_vies/*
   echo "----------------------------------------"
   echo "Creating PMEDIAS sem remoção de Vies"
   echo "---------------------------------------"
   python Codigos/platlon2pmedia.py ${model} ${date_today} ${n_prev}
   rm -f  ${dir_in}/EsquemaSMAP_nuvem/tmp/${model}/*
   cp ${dir_in}/RemoveViesNuvem/Arq_Saida_sem_remocao_vies/*${model}*   ${dir_in}/EsquemaSMAP_nuvem/tmp/${model}/.
fi
