#################################################
#       GUIA PARA RODAR SMAP
################################################


Scripts:


1-update_prev.sh: Atualiza os históricos de chuva prevista e chuva observada (do modelo e psat), previamente na pasta Downloads os dados precisam ser colocados.

*** OBSERVAÇÃO: BAIXAR ANTES PARA A PASTA Downloads os arquivos .tar.gz dos dias de previsão que faltam de cada modelo e o psat com data no dia anterior,


bash update_prev.sh ${date} ${model} ${n_prev}

date = data a ser atualizada
model = nome do modelo
n_prev = número de dias de previsão

Exemplo:
para atualizar do dia 20 de junho de 2020 para o Modelo GEFS:

bash update_prev.sh 20200620 GEFS 12

*** OBSERVAÇÃO: BAIXAR ANTES PARA A PASTA Downloads os arquivos .tar.gz dos dias de previsão que faltam de cada modelo e o psat com data no dia anterior,

###########################################################################################################
scripts em python e R em RemoveViesNuvem/Codigos:

#1- psat2csv.py : Cria o histórico de número de dias (n_days) do observado do psat

python psat2csv.py <date> <n_prev> <lag> <n_days>:

date = data de dia para atualizar
n_prev = colunas para o arquivo observado, default 12
lag = lag de dias respeito ao dia para atualizar
n_days = número de dias para atrás

*As saídas ficam em RemoveViesNuvem/Trabalho/<Bacia>/<subbacia>/observado.csv


#2- prev_remvies.py: atualiza o histórico de chuva prevista

python prev_remvies.py ${model} ${n_prev}:

model = nome do modelo
n_prev = número de dias de previsão, colunas do arquivo.

*As saídas ficam em RemoveViesNuvem/Trabalho/<Bacia>/<subbacia>/<model>.csv



##########################################################################################


2-roda_remocao.sh: Cria os PMEDIAS para serem usados  com remoção ou sem remoção de viés.

bash roda_remocao.sh ${date} ${model} ${n_prev} ${vies}

date = data do dia para rodar
model = nome do modelo
vies = "sem", para sem remoção de viés ou "com", para rodar com remoção de viés

Exemplo:

bash roda_remocao.sh 20200620 GEFS 12 com



3-run_smap.sh: roda o smap paralelizando o processo.

bash run_smap.sh <date> <modelo> <n_prev> <vies>
date = data do dia de início da previsão
modelo = nome do modelo
n_prev = dias de previsão
vies = "sem" para sem remoção de viés ou "com" para rodar com remoção de viés


** Dentro da pasta out/<nome do modelo> : estão as saídas correspondentes de vazão incremental e total de cada sub bacia

***Dentro da pasta out_POSTOS/<nome do modelo> : estão as saídas correspondentes de vazão incremental e total para cada um dos postos

########################################################################################################


4-run_all_smap.sh: Com esse script os 3 processos anteriores são agrupados para facilitar


bash run_all_smap.sh <date> <model> <n_prev> <vies>

date = data do dia da rodada
model = nome do modelo
n_prev = número de dias de previsão
vies = "sem" para sem remoção de viés ou "com" para rodar com remoção de viés

Exemplo: Rodando o GEFS para o dia 20 de junho de 2020, com remoção de viés.
** OBSERVAÇÃO: Sempre antes de rodar, baixar e colocar na pasta Downloads os dados de entradas que se precisam

bash roda_remocao.sh 20200620 GEFS 12 com



###########################################################################
#  SCRIPTS ADICIONAIS
##########################################################################

1-EsquemaSMAP_nuvem/PegaParametros.R: Atualiza os parâmetros necessários para serem usados nas rodadas do SMAP, relativos aos coeficientes de regressão, etc.

** Este script é importante quando seja adicionado novas sub bacias no SMAP.

Antes de rodar editar a linha 7 com o nome da pasta do Modelo Chuva Vazão de onde tomar os parâmetros
Rscript PegaParametros.R


2-EsquemaSMAP_nuvem/Read_smap_ONS.py: pega a saida do SMAP dada na pasta Modelos_Chuva_Vazao_yyyymmdd e transforma em vazao total

Ir para EsquemaSMAP_nuvem e rodar:

python Read_smap_ONS.py <date>

date = data da pasta do Modelos_chuva_Vazao [yyyymmdd]



** A pasta Modelos_Chuva_Vazao da data deve ser baixado previamente do portal do ONS, descomprimido e renomeado para o formato Modelos_Chuva_Vazao[yyyymmdd]

Exemplo para o dia 24 de junho de 2020:

cp   Downloads/Modelos_Chuva_Vazao_20200624.zip   EsquemaSMAP_nuvem/.

cd EsquemaSMAP_nuvem/

unzip -q Modelos_Chuva_Vazao_20200624.zip
mv Modelos_Chuva_Vazao  Modelos_Chuva_Vazao_20200624


python Read_smap_ONS.py 20200624

Os resultados são gerados em  EsquemaSMAP_nuvem/Total_ONS-smap_20200624.csv




