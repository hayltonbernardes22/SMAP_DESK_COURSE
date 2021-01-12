roda_bacia <-function(bacia,dia_previsao,tempo_regressao,dias_previstos,agrupamento,modelos,alpha,beta,lambdas){

#=======================================pega  os arquivos de precipitação prevista==============================================
  precs<-lapply(modelos,function(x){
    pr<-NULL
    for( i in 201:1){
      if (file.exists(paste0("./Arq_Entrada/",x,"/",x,"_m_",format(dia_previsao-i+1,"%d%m%y"),".dat"))){
        leitura<-read.table(paste0("./Arq_Entrada/",x,"/",x,"_m_",format(dia_previsao-i+1,"%d%m%y"),".dat"),header=F,stringsAsFactors	=F)  
        dia<-cbind(dia_previsao-i+1,leitura[which(leitura[,1]==bacia),4:ncol(leitura)])
        pr<-rbind(pr,dia)
      }
    }
    pr
  })

#print(ncol(precs[[0]]))
#print(precs)  
#===================================== ordena a lista por ordem de tamanho de horizonte ========================================
num_de_previsoes<-sapply(precs, function(x) ncol(x))
ord<-order(num_de_previsoes,decreasing = TRUE)
precs<-precs[ord]
modelos<-modelos[ord]
num_de_previsoes<-num_de_previsoes[ord]-1
num_mod_hor<-rep(0,dias_previstos)
for (i in 1:length(modelos)){for (j in 1:num_de_previsoes[i]){num_mod_hor[j]<-num_mod_hor[j]+1}}
#===================================== checa se a soma dos agrupamentos é igual ao número de dias previstos=====================
if (sum(agrupamento)!=dias_previstos){stop("soma dos dias dos agrupamentos diferente do numero de dias previstos")}
#=====================================checa se para cada agrupamento o número de modelos é igual================================
for(j in 1:length(agrupamento)){
  for( i in (1+sum(agrupamento[1:j])-agrupamento[j]):(sum(agrupamento[1:j]))){
    if (num_mod_hor[i]!= num_mod_hor[1+sum(agrupamento[1:j])-agrupamento[j]]){stop(paste0("Numero diferente de modelos no ",j,"agrupamento para a bacia ",bacia))}
  }
}
#===================================== pega o verificado e formata a data ======================================================
obss<-as.data.frame(matrix(NA,nrow =199,ncol=2))

for( i in 200:2){
  obss[201-i,1] <-format(dia_previsao-i+1,'%d/%m/%Y')
  if (file.exists(paste0("Arq_Entrada/Observado/PSAT_ONS/psat_",format(dia_previsao-i+1,"%d%m%Y"),".txt"))){
    leitura<-read.table(paste0("Arq_Entrada/Observado/PSAT_ONS/psat_",format(dia_previsao-i+1,"%d%m%Y"),".txt"),header=F,stringsAsFactors	=F)  
    obss[201-i,2] <-leitura[which(leitura[,1]==bacia),4]
  }
}
obss[, 1]<- as.Date(obss[, 1], '%d/%m/%Y')

obs<-as.data.frame(matrix(NA,nrow =199,ncol=max(num_de_previsoes)+1))
for( i in 2:201){
  obs[201-i,1]<- format(dia_previsao-i,'%d/%m/%Y')
  for(j in 1:max(num_de_previsoes)){
    if (j-i<0){
      obs[201-i,1+j]<-obss[which(obss[,1]==dia_previsao-i+j),2]
    }
  }
}
precs<-c(precs,list(obs))
precs<- lapply(precs, function(x) {x[, 1] <- as.Date(x[, 1], '%d/%m/%Y'); x})
for (i in 1:(length(modelos))){if (length(which(precs[[i]][,1]==dia_previsao))==0){stop (paste0("o modelo " , modelos[i], " nao possui a data de de previsao para a bacia:",bacia))}}

#=======================================acha o modelo/observado com o menor historio ===========================================
tt<-lapply(precs,function (x) min(x[,1]))
for(j in 1:length(modelos)){if (is.na(tt[j][1])){tt[[j]]<-NULL}}
maior_data <-max(do.call(c,tt))
volta<-roda_vies(precs,tempo_regressao,dias_previstos,maior_data,dia_previsao)
precs<-volta[[1]]
#=======================================cria  a lista com as matrizes por horizonte=============================================
precs3<-list()
for (i in 1:dias_previstos){precs3[[i]]<-matrix(NA_real_, nrow =tempo_regressao , ncol = num_mod_hor[i]+1)}
#=======================================preenche a lista com as previsões=======================================================
for (i in 1:dias_previstos){
  soma<-1
  k=1
  while(soma<=tempo_regressao){
    dia<-dia_previsao -k # dia sendo buscado para ver se a regressão existe
    res<-rep(NA_integer_,num_mod_hor[i]+1)
    for(j in 1:num_mod_hor[i]){if(length(which(precs[[j]][,1]==dia))){res[j]<-which(precs[[j]][,1]==dia)}} # acha a posição do dia
    if(length(which(precs[[num_mod_hor[1]+1]][,1]==dia))){res[num_mod_hor[i]+1]<-which(precs[[num_mod_hor[1]+1]][,1]==dia)}
    if (sum((sapply(res, function(y) y[1]!=-1)),na.rm = TRUE) == length(res)){  # if para ver se a data existe em todos modelos e no observado
      
      #======================================= checa se no horizonte "i" todo mundo tem valor======================================================
      valor<-rep(NA_real_,num_mod_hor[i]+1)
      for(j in 1:num_mod_hor[i]){valor[j]<-precs[[j]][res[j],i+1]}
      valor[num_mod_hor[i]+1]<-precs[[num_mod_hor[1]+1]][res[num_mod_hor[i]+1],i+1]
      if (sum((sapply(valor, function(y) !is.na(y))),na.rm = TRUE) == length(res)){
        #=======================================escreve os valores na matriz da lista precs3=========================================================
        for(j in 1:num_mod_hor[i]){precs3[[i]][soma,j]<-precs[[j]][res[j],i+1]}
        precs3[[i]][soma,num_mod_hor[i]+1]<-precs[[num_mod_hor[1]+1]][res[num_mod_hor[i]+1],i+1]
        soma<-soma +1
      }
    }
    if (maior_data> dia){stop("Numero insuficiente de elementos para o tamanho da regressao solicitada")}
    k=k+1
  }
}
#===================================== Loop para rodar a regressão========================================================================
ens<-rep(0,dias_previstos)
lambdass<-rep(0,length(agrupamento))
Coefs<-matrix(NA_real_,nrow =dias_previstos,ncol=num_mod_hor[1])
Coefs2<-matrix(NA_real_,nrow =dias_previstos,ncol=num_mod_hor[1])
prec_remvies<-matrix(NA_real_,ncol =dias_previstos,nrow=num_mod_hor[1])
colnames(Coefs)<-modelos[]
colnames(Coefs2)<-modelos[]
row.names(prec_remvies)<-modelos
for (j in 1:length(agrupamento)){
  l <- precs3[seq(1+sum(agrupamento[1:j])-agrupamento[j],sum(agrupamento[1:j]))]
  l2 <- lapply(l, function(x) x[!x[, ncol(l[[1]])] == 0, ])
  if(ncol(l[[1]])>2){
     l3<-list(lapply(l, function(x) x[c(TRUE,FALSE), ]),lapply(l, function(x) x[c(FALSE,TRUE), ]))
     numero_de_lambdas<-length(lambdas)
     erro_lambda<-matrix(0,numero_de_lambdas,agrupamento[j])
     for (h in 1:numero_de_lambdas){
       lambda<-lambdas[h]
       for( w in 1:2){
         b<-roda_lp(l3[[w]],alpha[j],beta[j],lambda)
         l4<-l3[[1 + (w %% 2)]]
         l5<-lapply(seq_along(l4), function(x) {
           m <- l4[[x]]
           v <- b[x, ]
           m[, -ncol(l4[[1]])] <- m[, -ncol(l4[[1]])] %*% diag(v)
           abs(m[, ncol(l4[[1]])] - apply(m[, -ncol(l4[[1]])], 1, sum))
         })
         erro_lambda[h, ]<- sapply(l5, mean) + erro_lambda[h, ]
       }
     }
     erro<-apply(erro_lambda, 1, mean)
     lambda<-lambdas[which.min(erro)]
   } else {
     lambda<-0 # caso com apenas um modelo
   }
  b<-roda_lp(l,alpha[j],beta[j],lambda)
  lambdass[j]<-lambda
  for(k in 1:agrupamento[j]){
    for( w in 1:num_mod_hor[k +sum(agrupamento[1:j])-agrupamento[j]]){
      ens[k +sum(agrupamento[1:j])-agrupamento[j]]<-ens[k +sum(agrupamento[1:j])-agrupamento[j]]+precs[[w]][which(precs[[w]][,1]==dia_previsao),k +1 +sum(agrupamento[1:j])-agrupamento[j]]*b[k,w]
      Coefs[k +sum(agrupamento[1:j])-agrupamento[j],w]<-b[k,w]
      Coefs2[k +sum(agrupamento[1:j])-agrupamento[j],w]<-volta[[2]][w,k+sum(agrupamento[0:(j-1)])]
      prec_remvies[w,k +sum(agrupamento[1:j])-agrupamento[j]]<-precs[[w]][which(precs[[w]][,1]==dia_previsao),k +1 +sum(agrupamento[1:j])-agrupamento[j]]
    }
  }
}
resultado<-list(ens,Coefs,Coefs2,prec_remvies)
return(resultado)
}


roda_lp <- function(l,alpha,beta,lambda){
#==========================================================bloco que depois vai virar a função======================================================
library(lpSolve)
num_modelos<-ncol(l[[1]])-1
t_regre_t<-sum(unlist(lapply(l,nrow)))
num_dias<-length(l)
# formatos => x=[w1+,....,w1-,fi1,..fin,] c=[1,...,1,....,0,...,0], u=[y1,0,..,yn,0,y1,0,....,yn,0,...,0,a,-b] min Ct.x s.a: Ax>=u
# formatos 2 => x
#========================================= Preenche a Matriz A==========================================================================================
A<-matrix(0, nrow = 4*t_regre_t +4 + num_dias*num_modelos + num_dias*2, ncol = 2*t_regre_t +2 + num_modelos*num_dias)
for (i in 1:(2*t_regre_t +2 )){ # preenche com 1 a parte da matriz para  W+ e W-
  A[1+(i-1)*2,1+(i-1)]<-1
  A[2+(i-1)*2,1+(i-1)]<-1
}
for(i in 1:(num_modelos*num_dias)){A[4*t_regre_t +4 +i,2*t_regre_t +2 + i]<-1} # preenche com 1 a parte dos fis para garantir que eles sejam maiores que 0
t_regre<-0
for(i in 1:num_dias){ # preenche com os valores diários de prec prevista
  for(j in 1:num_modelos){
    for(k in 1:(nrow(l[[i]]))){
      A[1 +(k-1)*4+4*t_regre,2*t_regre_t + 2 + j + num_modelos*(i-1)]<-l[[i]][k,j]
      A[3 +(k-1)*4+4*t_regre,2*t_regre_t + 2 + j + num_modelos*(i-1)]<--l[[i]][k,j]
    }
  }
  t_regre<-t_regre +nrow(l[[i]])
}

for(i in 1:num_dias){ # preenche com os valores médios de prec prevista
  for(j in 1:num_modelos){
    A[1 + 4*t_regre_t,2*t_regre_t + 2 + j +num_modelos*(i-1)]<- mean( l[[i]][ ,j])/num_dias
    A[3 + 4*t_regre_t,2*t_regre_t + 2 + j +num_modelos*(i-1)]<- -mean( l[[i]][ ,j])/num_dias
  }
}

for(i in 1:num_dias){ # preenche com os fis para o li e ls
  for(j in 1:num_modelos){
    A[4*t_regre_t +4 + num_dias*num_modelos + 1 +(i-1)*2,2*t_regre_t +2 + j+ (i-1)*num_modelos]<- 1 # preenche li
    A[4*t_regre_t +4 + num_dias*num_modelos + 2 +(i-1)*2,2*t_regre_t +2 + j+ (i-1)*num_modelos]<- -1 # preenche ls
  }
}


#======================================== Preenche o U ===========================================================================================
U<-rep(0,4*t_regre_t +4 + num_dias*num_modelos + num_dias*2)
t_regre<-0
for(i in 1:num_dias){ # preenche com os valores diários de prec observada
  for(k in 1:(nrow(l[[i]]))){
    U[1 +(k-1)*4+4*t_regre]<-l[[i]][k,num_modelos + 1]
    U[3 +(k-1)*4+4*t_regre]<--l[[i]][k,num_modelos +1]
  }
  t_regre<-t_regre +nrow(l[[i]])
}
U[1 + 4*t_regre_t]<- mean(unlist(lapply(l, function(x) mean(x[, num_modelos +1]))))
U[3 + 4*t_regre_t]<- -mean(unlist(lapply(l, function(x) mean(x[, num_modelos +1]))))

for(i in 1:num_dias){ # preenche com os fis para o li e ls
    U[4*t_regre_t +4 + num_dias*num_modelos + 1 +(i-1)*2]<- 0.9 # preenche li
    U[4*t_regre_t +4 + num_dias*num_modelos + 2 +(i-1)*2]<- -1.1 # preenche ls
}



#=======================================Preenche o OBJ===============================================================================================
OBJ<-rep(lambda,2*t_regre_t +2 + num_modelos*num_dias) # já preenche com o valor do lambda para o peso dos modelos o resto será substituido
t_regre<-0
for(i in 1:num_dias){ # preenche com os valores diários de prec prevista
  for(k in 1:(nrow(l[[i]]))){
    OBJ[1 +(k-1)*2+2*t_regre]<-alpha/(nrow(l[[i]])*num_dias)
    OBJ[2 +(k-1)*2+2*t_regre]<-alpha/(nrow(l[[i]])*num_dias)
  }
  t_regre<-t_regre +nrow(l[[i]])
}
OBJ[2*t_regre_t +1]<-beta
OBJ[2*t_regre_t +2]<-beta

VI<-rep(">=", 4*t_regre_t +4 + num_dias*num_modelos + num_dias*2)
#======== rodar o pl==============
a<-lp("min",OBJ,A,VI,U)$solution
b<-matrix(tail(a, num_dias*num_modelos), num_dias, num_modelos, byrow = T)
return(b)
}

roda_vies<-function(precs,tempo_regressao,dias_previstos,maior_data,dia_previsao){
  library(minpack.lm)
  precs2<-list()
  pesos<-matrix(NA,nrow=length(precs)-1,ncol =dias_previstos)
  for (i in 1:length(precs)){precs2[[i]]<-matrix(NA_real_, nrow =tempo_regressao , ncol =min(dias_previstos,(ncol(precs[[i]]))-1))}
  #=======================================preenche a lista com as previsões=======================================================
  soma<-1
  k=(dias_previstos+1)
  while(soma<=(tempo_regressao)){
    dia<-dia_previsao -k # dia sendo buscado
    teste<-TRUE
    for(i in 1:length(precs)){if(length(which(precs[[i]][,1]==dia))==0){teste=FALSE}}
    if(teste==TRUE){
      for(i in 1:length(precs)){
        for(j in 1:min(dias_previstos,(ncol(precs[[i]]))-1)){
          precs2[[i]][soma,j]<-precs[[i]][which(precs[[i]][,1]==dia),j+1]
        }
      }
      soma<-soma+1
    }
    if (maior_data> dia){stop("Numero insuficiente de elementos para o tamanho da regressao solicitada")}
    k=k+1
  }
  #===================================== bloco para fazer a regressão============================================================================
  for( i in 1:(length(precs2)-1)){
    num_colunas<- ncol(precs2[[i]])
    num_blocos_int<- (num_colunas%/%7 -1)
    #==================================bloco que faz para os grupos com 7 dias completos =========================================================
    if(num_blocos_int>0){
      for ( j in 1:num_blocos_int){
        soma_prec<-sort(rowSums(precs2[[i]][,(1+(j-1)*7):(j*7)]))
        soma_obs<-sort(rowSums(precs2[[length(precs2)]][,(1+(j-1)*7):(j*7)])) 
        soma_prec2<-soma_prec^2
        modelo<-coef(nlsLM(soma_obs ~ a*soma_prec2 + b*soma_prec,lower=c(-Inf, -Inf), upper=c(Inf, Inf), start=list(a=0, b=1)))
        for( m in 1:nrow(precs[[i]])){
          sp<-rowSums(precs[[i]][m,(2+(j-1)*7):(1+(j*7))])
          if(is.na(sp)==FALSE){
            fator<-roda_fator(sp,modelo,soma_prec[round(tempo_regressao*0.95,0)])
            for( k in 1:7){
              precs[[i]][m,(k+1+(j-1)*7)]<- precs[[i]][m,(k+1+(j-1)*7)]*fator
              if( precs[[i]][m,1]==dia_previsao ){pesos[i,(k+(j-1)*7)]=fator}
            }
          }
        } 
      }  
    }
    #================================ bloco que faz para o ultimo bloco que tem entre 7 e 13 dias===================================================
    soma_prec<-sort(rowSums(precs2[[i]][,(1+(num_blocos_int)*7):(ncol(precs2[[i]]))]))
    soma_obs<-sort(rowSums(precs2[[length(precs2)]][,(1+(num_blocos_int)*7):(ncol(precs2[[i]]))]))
    soma_prec2<-soma_prec^2
    modelo<-coef(nlsLM(soma_obs ~ a*soma_prec2 + b*soma_prec,lower=c(-Inf, -Inf), upper=c(Inf, Inf), start=list(a=0, b=1)))
    for( m in 1:nrow(precs[[i]])){
      sp<-rowSums(precs[[i]][m,(2+(num_blocos_int)*7):(ncol(precs[[i]]))])
      if(is.na(sp)==FALSE){
        fator<-roda_fator(sp,modelo,soma_prec[round(tempo_regressao*0.95,0)])
        for( k in (2+(num_blocos_int)*7):(ncol(precs[[i]]))){
          precs[[i]][m,k]<- precs[[i]][m,k]*fator
          if( precs[[i]][m,1]==dia_previsao ){pesos[i,k-1]=fator}
        }
      }
    }    
  }
  resultado<-list(precs,pesos)
  return (resultado)
}

roda_fator<-function(sp,modelo,x_95){
  if(sp==0) {fator<-1}else{
    y_95<-(x_95*modelo[2]+modelo[1]*x_95^2)
    x_max<- -(modelo[2]/(2*modelo[1]))
    y_max<- -(((modelo[2])^2)/(4*modelo[1]))
    #================================bloco para a positivo ========================
    if (modelo[1]>0){
      if (x_95>sp){ # bloco para quando a soma estiver abaixo de 95% da amostra
        fator<-(sp*modelo[2]+modelo[1]*sp^2)/sp
      } else {
        if (x_95>(y_95)){ # bloco para quando soma acima de 95%, porém abaixo da reta x=y
          if(sp> ((sp*modelo[2]+modelo[1]*sp^2))){
            fator<-(sp*modelo[2]+modelo[1]*sp^2)/sp
          }else{fator<-1}
        } else{
          if (sp< y_95 ){# bloco para quando soma acima de 95% e acima da reta x=y
            fator<-y_95/sp
          }else{fator<-1}
        }
      }
    }
    #================================bloco para a negativo ========================
    if (modelo[1]<0){
      if (x_95>(y_95)){ # bloco para quando y95 está abaixo da reta x=y
        if (x_max>sp){
          fator<-(sp*modelo[2]+modelo[1]*sp^2)/sp
        }else{ fator<- y_max/sp}
      } else { # bloco para quando y95 está acima da reta x=y ou sobre a reta 
        if (sp<x_max){
          if (sp< ((sp*modelo[2]+modelo[1]*sp^2))){
            fator<-(sp*modelo[2]+modelo[1]*sp^2)/sp
          }else{fator<-1} 
          }else{
            if (sp< y_max){
              fator<-y_max/sp
            } else{fator<-1}  
          }
        }
      }
    #================================bloco para a zero ========================
    if(modelo[1]==0){fator<-modelo[2]}
  }
  if(fator<0){fator<-1}
  return(fator)
}




