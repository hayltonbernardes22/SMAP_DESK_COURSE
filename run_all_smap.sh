#!/bin/bash

# bash run_all_smap.sh <date> <model> <n_prev> <vies>
model=$2
date_today=$1
n_prev=$3
vies=$4

# atualizando o historico dos modelos e observado
bash update_prev.sh ${date_today} ${model} ${n_prev}
# criando Pmedias  com remocao de vies
bash roda_remocao.sh ${date_today} ${model} ${n_prev} ${vies}
# rodando smap
bash run_smap.sh  ${date_today} ${model} ${n_prev} ${vies}
