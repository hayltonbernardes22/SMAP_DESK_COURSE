#!/bin/bash

# bash run_smap.sh <date> <modelo> <n_prev>

date_today=$1
model=$2
n_prev=$3
vies=$4
dir_in=$(pwd)

rm -rf ${dir_in}/EsquemaSMAP_nuvem/Modelos_Chuva_Vazao_${date_today} 
cp   ${dir_in}/Downloads/Modelos_Chuva_Vazao_${date_today}.zip   ${dir_in}/EsquemaSMAP_nuvem/.

cd ${dir_in}/EsquemaSMAP_nuvem/

echo "Descomprimento pasta Modelo_Chuva_vazao"
unzip -q Modelos_Chuva_Vazao_${date_today}.zip
mv Modelos_Chuva_Vazao  Modelos_Chuva_Vazao_${date_today}
rm Modelos_Chuva_Vazao_${date_today}.zip

##########################################
# PREPARANDO PARA SMAP
#########################################
script_name="PreparaParaSMAP.R" 
sed 's,xlocal_dirx,'"${dir_in}"',g' ${script_name}-cat > ${script_name}
sed -i 's,xdate_filex,'"${date_today}"',g' ${script_name} 
sed -i 's,xmodelx,'"${model}"',g' ${script_name}
echo "Processing ${script_name} for ${model}"
Rscript ${script_name}

script_name="FazBaciasMain_parallel.R"
sed 's,xlocal_dirx,'"${dir_in}"',g' ${script_name}-cat > ${script_name}
sed -i 's,xdate_filex,'"${date_today}"',g' ${script_name}
sed -i 's,xmodelx,'"${model}"',g' ${script_name}
sed -i 's,xnprevx,'"${n_prev}"',g' ${script_name}
echo "Processing ${script_name} for ${model}"
Rscript ${script_name}

mkdir -p ${dir_in}/EsquemaSMAP_nuvem/out_POSTOS/${model}
mkdir -p ${dir_in}/EsquemaSMAP_nuvem/out/${model} 

#############################################
#   POS-PROCESAMENTO
########################################### 

script_name="PosProc.R"
sed 's,xlocal_dirx,'"${dir_in}"',g' ${script_name}-cat > ${script_name}
sed -i 's,xtodayx,'"${date_today}"',g' ${script_name}
sed -i 's,xmodelx,'"${model}"',g' ${script_name}
sed -i 's,xnprevx,'"${n_prev}"',g' ${script_name}
echo "Processing ${script_name} for ${model}"
Rscript ${script_name}

###############################
#      vazao total
##########################
python PosProc_total.py ${date_today} ${model} ${n_prev} ${vies}
