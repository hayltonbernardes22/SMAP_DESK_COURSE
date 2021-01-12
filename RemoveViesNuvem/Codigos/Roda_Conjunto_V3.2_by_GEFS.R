cat("\014") 
rm(list=ls())
library(parallel)
library(readxl)
source('./Codigos/Conjunto_V3.0.R')

# arquivo log
arq_log<- paste0("log.txt")
write("-----Calculando Previsao do conjunto com remocao de vies-----",file=arq_log,append=TRUE)

#=================================data (caso queira rodar outra data alterar aqui)================================================================================


model_nam<-"GEFS"
dias_previstos<-15
fecha<-"20210105" 
dia_previsao<-as.Date(fecha,"%Y%m%d")
model_name<-unlist(strsplit(model_nam, '-'))
modelos <- model_name
tempo_regressao<-120

print(modelos)

print(dia_previsao)
caminho_data = file.path("./Arq_Entrada/data.txt")
if(file.exists(caminho_data)){
  aux <- readLines(caminho_data)
  dia_previsao <- as.Date(aux,"%d/%m/%Y")
  file.remove(caminho_data)
}

texto = paste0("data da rodada:",dia_previsao,"\n")
cat(texto)
write(texto,file=arq_log,append=TRUE)

#=================================Parametros da rodada============================================================================================================
lambdas<-seq(0,0.5,by=0.02)
if(dias_previstos<=9){
  agrupamento<-cbind(3,3,3)
  alpha<-cbind(2,2,2)
  beta<-cbind(1,1,1)
  


  }else{
    alpha<-cbind(2,2,2,2)
    beta<-cbind(1,1,1,1)
    agrupamento<-cbind(3,3,3,dias_previstos-9)
    print(agrupamento)

   
}


#=================================Leitura do arquivo de configuracao===============================================================================================
planilha <- read_xlsx("./Arq_Entrada/Configuracao_rem.xlsx",sheet = "Dados")
bacias<-planilha$'Codigo ANA'
texto = "Arquivo de configuracao lido com sucesso \n"
cat(texto)
write(texto,file=arq_log,append=TRUE)
#================================ cria o cluster ==================================================================================================================
numCores <- 12 #detectCores()
ensemble<-matrix(NA_real_,nrow=dias_previstos,ncol=length(bacias))
clust <- makeCluster(numCores-1, type = 'PSOCK') 
clusterExport(clust, varlist = c('roda_bacia', 'roda_lp','roda_vies','roda_fator','dia_previsao','tempo_regressao','dias_previstos','agrupamento','modelos','alpha','beta','bacias','lambdas'), envir = .GlobalEnv)

#=========================== roda o conjunto para as bacias ========================================================================================================
texto = "Gerando Conjunto \n"
cat(texto)
write(texto,file=arq_log,append=TRUE)

res<-parLapply(clust,1:length(bacias), function(x) roda_bacia(bacias[x],dia_previsao,tempo_regressao,dias_previstos,agrupamento,modelos,alpha,beta,lambdas))
stopCluster(clust)

texto = "Conjunto gerado \n"
cat(texto)
write(texto,file=arq_log,append=TRUE)

#======================================================= aplica limite semanal =====================================================================================
pesos_sem<-matrix(1,ncol =dias_previstos,nrow=length(bacias))
for (i in 1:length(bacias)){
  mes_prev<-as.numeric(format(dia_previsao,"%m"))
  if(mes_prev %in% c(12,1)){lim_sem<-planilha$`DEZ-JAN`[i]}
  if(mes_prev %in% c(2,3)){lim_sem<-planilha$`FEV-MAR`[i]}
  if(mes_prev %in% c(4,5)){lim_sem<-planilha$`ABR-MAI`[i]}
  if(mes_prev %in% c(6,7)){lim_sem<-planilha$`JUN-JUL`[i]}
  if(mes_prev %in% c(8,9)){lim_sem<-planilha$`AGO-SET`[i]}
  if(mes_prev %in% c(10,11)){lim_sem<-planilha$`OUT-NOV`[i]}
  for( j in 1: (dias_previstos/7)){
    soma<-sum(res[[i]][[1]][(1 + (j-1)*7):(j*7)])
    if( soma > lim_sem){
      fator<-lim_sem/soma
      for ( k in 1:7){
        res[[i]][[1]][(k+(j-1)*7)]<-res[[i]][[1]][(k+(j-1)*7)]*fator
        pesos_sem[i,(k+(j-1)*7)]<-fator
      }
    }
  }
}

#===========================aplica os limites diarios======================================================================================================================
pesos_d<-matrix(1,ncol =dias_previstos,nrow=length(bacias))
for( i in 1:length(bacias)){
  for ( j in 1:dias_previstos){
    pesos_d[i,j]<-min(1,planilha$Diario[i]/res[[i]][[1]][j])
    res[[i]][[1]][j]<-min(planilha$Diario[i],res[[i]][[1]][j])
  }
}

#============================ gera os arquivos de saida ============================================================================================================
texto = "Gerando arquivos de saida\n"
cat(texto)
write(texto,file=arq_log,append=TRUE)

for( i in 1:dias_previstos){

  arq<-paste0(getwd(),"/Arq_Saida_com_remocao_vies/PMEDIA_",model_nam,"_p",format(dia_previsao, format="%d%m%y"),"a",format((dia_previsao+i), format="%d%m%y"),".dat")
  
  file.create(arq)
  for( j in 1:length(bacias)){
    texto<-paste0(formatC(planilha$Longitude[j], 2, 6, "f", 0)," ",formatC(planilha$Latitude[j], 2, 6, "f", 0)," ", format(round(res[[j]][[1]][i],1),nsmall=2))
    write.table(texto,arq, dec=".",row.names = FALSE,col.names = FALSE,append = TRUE,quote = FALSE)
  }

  #adicionado por Jorge para adicionar a subbacia Jirau2 para SMAP

  jirau2_media<-res[[76]][[1]][i]*0.87+res[[80]][[1]][i]*0.13

  jirau2_media<-round(jirau2_media,1)
  texto<-paste0(formatC(-64.66, 2, 6, "f", 0)," ",formatC(-9.26, 2, 6, "f", 0)," ", format(jirau2_media,nsmall=2))
  write.table(texto,arq, dec=".",row.names = FALSE,col.names = FALSE,append = TRUE,quote = FALSE)




}

#=========================== gera os pesos ==========================================================================================================================

unlink(paste0(getwd(),"/Arq_Saida/Pesos"), recursive=TRUE) #apaga a pasta dos pesos
dir.create(paste0(getwd(),"/Arq_Saida/Pesos")) # gera a pasta dos pesos 
for( j in 1:length(bacias)){ # for para realizar todas as bacias 
  arq<-paste0(getwd(),"/Arq_Saida/Pesos/Pesos_Bacia_",planilha$Nome[j],".dat") # cria o nome do arquivo de saida
  file.create(arq) # cria o arquivo de saida 
  texto<-format("dia",width=11,flag=" ") # cria o cabeçalho
  for( k in 1:NCOL(res[[j]][[3]])){
    texto<-paste0(texto,format(paste0(colnames(res[[j]][[3]])[k],"_R"),width=8,flag=" "))
  }
  for( k in 1:NCOL(res[[j]][[2]])){
    texto<-paste0(texto,format(paste0(colnames(res[[j]][[2]])[k],"_P"),width=8,flag=" "))
  }
  texto<-paste0(texto,format("Lim_Sem",width=8,flag=" "),format("Lim_d",width=8,flag=" "))
  write.table(texto,arq, dec=".",row.names = FALSE,col.names = FALSE,append = TRUE,quote = FALSE) # escreve no arquivo o cabeçalho
  for( i in 1:dias_previstos){ # for para escrever para todos os dias previstos 
    texto<-paste0(format((dia_previsao+i), format="%d/%m/%Y",))
    for( k in 1:NCOL(res[[j]][[3]])){
      texto<-paste0(texto," ",format(round(res[[j]][[3]][i,k],digits = 5),width=7,flag=" "))
    }
    for( k in 1:NCOL(res[[j]][[2]])){
      texto<-paste0(texto," ",format(round(res[[j]][[2]][i,k],digits = 5),width=7,flag=" "))
    }
    texto<-paste0(texto," ",format(round(pesos_sem[j,i],digits = 4),width=7,flag=" "),format(round(pesos_d[j,i],digits = 4),width=7,flag=" "))
    write.table(texto,arq, dec=".",row.names = FALSE,col.names = FALSE,append = TRUE,quote = FALSE)# escreve no arquivo o valor do dia k
  }
}

#=========================== gera saida remocao de vies  ==========================================================================================================================
for (i in 1:length(modelos)){
  arq<-paste0(getwd(),"/Arq_Saida/",modelos[i],"_rem_vies.dat") # cria o nome do arquivo de saida
  file.create(arq) # cria o arquivo de saida  
}
for( j in 1:length(bacias)){
  for (k in 1:nrow(res[[j]][[4]])){
    texto<-paste0(format(planilha$`Codigo ANA`[j],width=9,flag=" "),format(formatC(planilha$Longitude[j], 2, 6, "f", 0),width=8,flag=" "),format(formatC(planilha$Latitude[j], 2, 6, "f", 0),width=8,flag=" "))
  for( a in 1:ncol(res[[j]][[4]])){
    texto<-paste0(texto,format(round(res[[j]][[4]][k,a],digits = 1),nsmall = 2,width=7,flag=" "))
    }
    write.table(texto,paste0(getwd(),"/Arq_Saida/",row.names(res[[j]][[4]])[k],"_rem_vies.dat"), dec=".",row.names = FALSE,col.names = FALSE,append = TRUE,quote = FALSE)# escreve no arquivo o valor do dia k
  }
}


texto = "Arquivos de saida gerados com sucesso!"
cat(texto)
write(texto,file=arq_log,append=TRUE)

