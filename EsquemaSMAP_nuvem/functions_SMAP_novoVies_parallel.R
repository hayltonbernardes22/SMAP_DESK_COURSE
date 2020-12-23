rm(list=ls())

### aplicaCoefsTempo
### this function applies kt coefficients of Parametros.RData file
### to already space-averaged rain of each sub-basin
aplicaCoefsTempo <- function(x,y, subname){
  # x is the data.frame cointaing prec from obs and model to apply the coefficients
  # y is data.frame containing the coefs
  # sb is the sub-basin name
  y <- y[y$subbacia == subname, substr(names(y),1,3) == "kt_"]
  y <- y[!is.na(y)]
    
    
  ini <- length(y)-2
  #print(y[ini])
  
  #print(x$mediaT)

  x$mediaT <- x$media
  for(ii in ini:(nrow(x)-2)){
    #print(y[ini])
    #print(y[ini+1])
    #print(y[ini+2])
    

    x$mediaT[ii] <- x$mediaT[ii]*y[ini] + x$mediaT[ii+1]*y[ini+1] + x$mediaT[ii+2]*y[ini+2]
    #print('before')
    #print(x$mediaT[ii])
    restantes <- length(y)-3
    #print(restantes)
    count <- 0
    while(restantes > 0){
      count <- count+1
      x$mediaT[ii] <- x$mediaT[ii] + (y[ini-count]*x$media[ii-count])
      #print(x$media[ii-count])
      #print(ii-count)
      #print((y[ini-count]*x$media[ii-count]))
      restantes <- restantes - 1
    }
  #print(ii)
  #print(x$mediaT[ii])
  }

  return(x)
}

### consertaNomes
### Rain gauge names have 8 strings. When reading the input files,
### some are only numeric and reduce their names. It corrects this error.
consertaNomes <- function(x){
  # x is an array with the original names
  for(xx in 1:length(x)){
    if(nchar(x[xx]) < 8){
      x[xx] <- paste(paste(rep("0", 8-nchar(x[xx])), collapse = ""), x[xx], sep="")
    }
  }
  return(x)
}


### SMAP-ONS 
smap <- function(tuin, ebin, supin, 
                 ad,
                 kkt, k1t, k2t, k2t2, k3t,
                 str, crec, ai, capcc, 
                 H, H1,
                 pcof, ecoef, ecoef2,
                 ep, dados_prec,
                 pesos,
                 iprint){
  
  # ajusta unidades dos parametros
  capc <- capcc/100
  
  crec <- crec/100
  kk <- 0.5^(1/kkt)
  k1 <- 0.5^(1/k1t)
  k2 <- 0.5^(1/k2t)
  k22 <- 0.5^(1/k2t2)
  k3 <- 0.5^(1/k3t)
  
  #inicializacao dos reservatorios
  rsolo <- tuin/100*str
  rss <- (ebin*86.4)/((1-kk)*ad)
  res <- (supin*86.4)/((1-k2)*ad)
  res2 <- 0
  
  qca <- array()
  ndias <- nrow(dados_prec)
  prec_med <- array()
  
  emarg <- ep*ecoef2
  ep <- ep*ecoef
  
  dados_prec[,2] <- dados_prec[,2]*pesos 
  


  #print('precipitac....')
  #print(dados_prec)
  for(i in 1:ndias){
    
    #pre <- dados_prec[i,2]*pcof*pesos[i]
    pre <- dados_prec[i,2]
    prec_med[i] <- pre
    tu <- rsolo/str    # calcula teor de umidade
    
    
    # calcula escoamento superficial
    if(pre > ai){
      es <- (pre - ai)^2 / (pre - ai + str - rsolo)
    } else{
      es <- 0
    }
    # calcula evapotranspiracao real
    if( (pre-es) > ep[i] ){
      er <- ep[i]
    } else{
      er <- (pre-es)+(ep[i]-(pre-es))*tu
    }
    # calcula recarga
    if( rsolo > (capc*str)){
      rec <- crec*tu*(rsolo - (capc*str))
    } else{
      rec <- 0
    }
    
    # Calcula fluxo para segundo reservatorio de superficie
    if(res > H){
      marg <- (res - H)*(1-k1)
    } else{
      marg <- 0
    }
    
    #ed <- (res+es)*(1-k2)     # calcula escoamento direto
    ed <- min((res - marg), H1)*(1-k2)
    ed3 <- max((res - marg - H1), 0)*(1-k22)
    ed2 <- res2*(1-k3)
    eb <- rss*(1-kk)           # calcula esoamento basico
    
    
    rsolo <- min((rsolo+pre-es-er-rec),str)                                  # atualiza res. do solo
    res <- res + es -ed - ed3 - marg + max(0, rsolo+pre-es-er-rec-str)       # atualiza res. da superficie
    res2 <- max(res2 + marg - ed2 - emarg,0)                                 # atualiza segundo res. da superficie
    rss <- rss-eb+rec                                                        # atualiza res. subterraneo
    
    if(iprint==1){
      #write adjusted tuin, ebin and supin
      ebin <- rss*((1-kk)*ad)/86.4
      supin <- res*((1-k2)*ad)/86.4
      write.table(data.frame(sprintf("%.2f", tu*100), sprintf("%.2f", ebin), sprintf("%.2f", supin)),
                  file="AJUSTE_LEO.txt", row.names = F, col.names = F, quote = F, append=T)
    }
    
    qca[i] <- (ed+ed2+ed3+eb)*ad/86.4 # calcula vazao total
    
    
  }
  return(qca)
}



### geraSerieChuvaModel
### Creates the time series of forecast rainfall for a given sub-basin
geraSerieChuvaModel <- function(dir, subname, modname){
  
  ### A partir do arquivo com os pontos da sub-bacia que pertencem ao arquivo completo de pontos,
  ### gera a serie media para a sub-bacia (PREVISAO)
  pontos <- read.table(paste(dir, subname, "_PMEDIA.txt", sep=""), skip=1)
  todosMod <- Sys.glob(paste(dir, modname, "/", "PMEDIA_*", sep=""))
  startDates <- unique(substr(todosMod, nchar(todosMod)-16, nchar(todosMod)-11))
  print(startDates)
  idx <- which.min(abs(as.POSIXct(startDates, format="%d%m%y", tz="GMT")-as.POSIXct(gsub("\\D", "", dir),format="%Y%m%d",tz="GMT")))
  fnames <- Sys.glob(paste(dir, modname, "/", "PMEDIA_", modname, "_p", startDates[idx],"*", sep=""))
  geraChuva <- list()
  print(length(fnames))
  for(i in 1:length(fnames)){
    geraChuva[[i]] <- read.table(fnames[i])
    geraChuva[[i]] <- merge(geraChuva[[i]], pontos)
    geraChuva[[i]] <- data.frame(date=as.POSIXct(substr(fnames[i],nchar(fnames[i])-9,nchar(fnames[i])-4), format="%d%m%y", tz="GMT"), media=mean(geraChuva[[i]][,3]))
  }
  
  geraChuvaf <- do.call(rbind, geraChuva)
  geraChuvaf <- geraChuvaf[order(geraChuvaf$date),]
  geraChuvaf <- rbind(geraChuvaf,
                      data.frame(date=seq(from=geraChuvaf[nrow(geraChuvaf),1] + 3600*24, 
                                          to=geraChuvaf[nrow(geraChuvaf),1] + 3600*24*5, by="day"), media=mean(geraChuvaf$media)))
  geraChuvaf$media[c(nrow(geraChuvaf)-1, nrow(geraChuvaf))] <- 0
  return(geraChuvaf)
  ### fim da previsao
}

### geraSerieObservada
### Creates the time series of the mean observed rainfall for a given sub-basin
geraSerieObservada <- function(dir, subname){
  
  # Chuva observada
  pluNames <- read.table(paste(dir, subname, "_POSTOS_PLU.txt", sep=""), skip=1)
  pesos <- pluNames$V2
  pluNames <- as.character(pluNames[,1])
  pluNames <- consertaNomes(pluNames)
  
  if(length(pluNames) > 0){
    prec <- list()
    for(p in 1:length(pluNames)){
      prec[[p]] <- read.table(paste(dir, pluNames[p],"_C.txt",sep=""), na.strings="-")
      prec[[p]] <- data.frame(date=prec[[p]][,2], prec=prec[[p]][,4])
      prec[[p]]$date <- as.POSIXct(prec[[p]]$date, format="%d/%m/%Y", tz="GMT")
      names(prec[[p]])[2] <- pluNames[p]
    }
  }
  
  obs <- Reduce(function(x, y) merge(x,y,all=T), prec)
  somaPesos <- obs[,-1]
  binNA <- function(x){
    if(is.na(x)){
      x <- 0
    } else{
      x <-1
    }
  }
  
  if(length(pluNames) > 1){
    somaPesos <- data.frame(apply(somaPesos, c(1,2), binNA))
    somaPesos$peso <- rowSums(data.frame(mapply(`*`,somaPesos, pesos)))
    obs$media <- rowSums(data.frame(mapply(`*`,obs[,-1], pesos)), na.rm = T)
    obs$media <- obs$media/somaPesos$peso
  } else{
    names(obs)[2] <- "media"
  }
  
  
  return(obs[c('date', 'media')])
}


### geraChuvaSMAP
### Merges the observed and forecast rainfall for a given basin
### and applies the kt coefficients
### mod - forecast rain
### obs - observed rain
### parametros - data.frame of parameters for all sub-basins
### pcoef - factor to multiply the rain series
### subname - sub-basin name
### y - number of days to increase the 31 days warm up in order to correct the rain with kt
### lag - number of days to "increase" forecast (case to run in advance using MERGE data. =0 if not used)
geraChuvaSMAP <- function(datei, diasWarm, diasPrev, mod, obs, parametros, pcoef, subname, y, lag){
  
  #dateFull <- data.frame(date=seq(from=obs[nrow(obs),1]-3600*24*(31+y), to=obs[nrow(obs),1], by="day"))
  dateFull <- data.frame(date=seq(from=datei-3600*24*(diasWarm+y), to=datei, by="day"))
  
  #print(dateFull)
  obs <- merge(obs, dateFull)
  
  prec <- rbind(obs, mod)
  prec[,2] <- prec[,2]*pcoef
  #print(prec)
  prec <- aplicaCoefsTempo(prec, parametros, subname)[,c(1,3)]
  print(prec)

  dateObs <- data.frame(date=seq(from=datei-3600*24*(diasWarm-1), to=datei-3600*24, by="day"))
  precObs <- merge(prec, dateObs)
  datePre <- data.frame(date=seq(from=datei, length.out=diasPrev+lag, by="day"))
  precPre <- merge(prec, datePre)
  return(list(precObs, precPre,prec))
  
}



### leVazaoObs
### Reads the observed streamflow data and export
leVazaoObs <- function(dir, subname){
  
  dado <- read.table(paste(dir, subname, ".txt", sep=""), sep="|")
  dado <- dado[,5:6]
  names(dado) <- c("date", "vazaoObs")
  dado$date <- as.POSIXct(dado$date, format="%Y-%m-%d %H:%M:%S", tz="GMT")
  
  return(dado)
}


### funObjetivo
### Calculates the different objective functions from ONS
### MAPE - mean absolute percentual error
### NASH - Nash-Sutcliffe
### DM - Multicriteria distance (function of MAPE and NASH)
### SOMACOEF - Coefficients sum (function of MAPE and NASH)
### Parameters:
### qcalc <- calculated streamflow
### qobs <- observed streamflow
### type <- type of objective function (MAPE, NASH, DM or SOMACOEFF)
### ipeso <- flag to proceed with weightning (2) or not (1)
funObjetivo <- function(qcalc, qobs, type, ipeso){
  
  if(ipeso == "off"){
    peso <- 1
  } else{
    dpres <- seq(31,1)
    peso <- (log(dpres+1)-log(dpres))/log(32)

  }
  
  
  if(type == "mape"){
    fob <- sum(abs((qobs-qcalc)*peso/qobs))/length(qobs)
  }
  if(type == "cef"){
    fob <- 1 - sum(((qobs-qcalc)*peso)^2)/sum((qobs-mean(qobs))^2)
  }
  if(type == "dm" | type == "somacoef"){
    mape <- sum(abs((qobs-qcalc)*peso/qobs))/length(qobs)

    nash <- 1 - sum(((qobs-qcalc)*peso)^2)/sum((qobs-mean(qobs))^2)
    if(type == "dm"){
      fob <- sqrt(mape^2 + (1-nash)^2)
    } else{
      fob <- nash + (1-mape)
    }
  }
  return(fob)
}


### readInic
### Gets the initial values of ebin, tuin, supin, number of days to warm up
### the model
readInic <- function(dir, subname){
  dado <- readLines(paste(dir, subname, "_INICIALIZACAO.txt", sep=""))
  date <- as.POSIXct(substr(dado[1],1,10), format="%d/%m/%Y", tz="GMT")
  dado <- dado[2:6]
  return(list(infos=as.numeric(substr(dado, 1, 10)), date=date))
}

readBat <- function(dir){
  bat <- readLines(paste(dir,"bat.conf",sep=""))
  par <- c("amplitude", "alvo", "iteracoes", "particulas", "pulso", "constA", 
           "constB", "objetivo", "pesos", "graficos", "semente")
  saidas <- data.frame(parametros=par, valores=NA)
  for(i in 1:length(bat)){
    virgulas <- as.numeric(which(strsplit(bat, "")[[i]]=="="))
    quote <- as.numeric(which(strsplit(bat, "")[[i]]=="'"))
    if(length(quote) != 0){
      if(i >= 8 & i <= 10){
        saidas[i,2] <- gsub(" ", "", substr(bat[i],virgulas+1,quote-1), fixed=TRUE)
      } else{
        saidas[i,2] <- as.numeric(substr(bat[i],virgulas+1,quote-1))
      }
    } else{
      if(i >= 8 & i <= 10){
        saidas[i,2] <- gsub(" ", "", substr(bat[i],virgulas+1,virgulas+10), fixed=TRUE)
      } else{
        saidas[i,2] <- as.numeric(substr(bat[i],virgulas+1,virgulas+10))
      }
    }
  }
  
  return(saidas)
  
}


### bat optimization
### D - number of dimensions
### NP - population size (number of microbats)
### N_Gen - number of iterations
### A - loudness, between 0 and 1
### r - pulse rate, >0
### Qmin - minimum frequency
### Qmax - maximum frequency
### Lower - lower bound of the search variables (VERY IMPORTANT!!)
### Upper - upper bound of the search variables (VERY IMPORTANT!!)
bat_optim_leo <- function(D, NP, N_Gen, A, gamma, Lower, Upper, tuin,
                          param, df, evapo, vazaoObs,
                          alvo, semente, constA, constB, ipeso, tipo){
  



  print(param)
  

  #    D <- 33
  #    NP = 24
  #    N_Gen = 10000
  #    A = 0.5
  r0 = 0.5
  Qmin = 0
  Qmax = 2
  #    Lower = c(rep(0.5,31), 0.8*ebin, 0)
  #    Upper = c(rep(2.0,31), 2.0*ebin, 1000)
  #    alvo <- 0
  
  #    set.seed(9952)
  
  set.seed(semente)

  
  f_min <- 0
  Lb <- matrix(Lower, nrow = 1)
  Ub <- matrix(Upper, nrow = 1)
  Q <- matrix(rep(0, NP), nrow = 1)
  v <- matrix(0, nrow = NP, ncol = D)
  Sol <- matrix(0, nrow = NP, ncol = D)
  Fitness <- matrix(rep(0, NP), nrow = 1)
  best <- matrix(rep(0, D), nrow = 1)
  r <- r0
  
  cat("Initializing the virtual microbats...\n")
  for (i in 1:NP) {
    Q[i] <- 0
    for (j in 1:D) {
      rnd <- runif(1, min = 0, max = 1)
      v[i, j] <- 0
      Sol[i, j] <- Lb[j] + (Ub[j] - Lb[j]) * rnd
    }
    
    Sol[i,31] <- 1
    qcalc <- smap(tuin, Sol[i,32], Sol[i,33],
                  param$Area, 
                  param$kkt, param$k1t, param$k2t, param$k2t2, param$k3t,
                  param$str, param$crec, param$ai, param$capc, 
                  param$H, param$H1,
                  param$pcof, param$ecof, param$ecof2,
                  evapo, df,
                  Sol[i,1:31],
                  0)
    
    
    #Fitness[i] <- funObjetivo(qcalc, vaz$vazaoObs, "dm", 2)
    Fitness[i] <- funObjetivo(qcalc, 
      vazaoObs, tipo, ipeso)
    Fitness[i] <- abs(Fitness[i]-alvo)
  }

  #print(Fitness)
  
  cat("Finding the best bat\n")
  best <- Sol[which.min(Fitness),]
  f_min <- Fitness[which.min(Fitness)]
  #print(f_min)
  #print(best)
  cat("Moving the bats via random walk\n")
  S <- matrix(0, nrow = NP, ncol = D)
  for (t in 1:N_Gen) {
    for (i in 1:NP) {
      rnd <- runif(1, min = 0, max = 1)
      Q[i] <- Qmin + (Qmin - Qmax) * rnd
      v[i, ] <- v[i, ] + (Sol[i, ] - best) * Q[i]
      S[i, ] <- Sol[i, ] + v[i, ]
      
      rnd <- runif(1, min = 0, max = 1)
      if (rnd > r) {
        S[i, 1:31] <- best[1:31]  + constA * rnorm(31, mean = 0, sd = 1)
        S[i,32:33] <- best[32:33] + constB * rnorm(2, mean = 0, sd = 1)
        #S[i, ] <- best + 0.001 * rnorm(D, mean = 0, sd = 1)
      }
      
      # me quede aqui
      #
      S[i, 1:30][S[i, 1:30] > 2] <- 2
      S[i, 1:30][S[i, 1:30] < 0.5] <- 0.5
      S[i,31] <- 1
      if(S[i, 32] > Ub[32]) S[i,32] <- Ub[32]
      if(S[i, 32] < Lb[32]) S[i,32] <- Lb[32]
      #if(S[i, 33] > Ub[33]) S[i,33] <- Ub[33]
      if(S[i, 33] < Lb[33]) S[i,33] <- Lb[33]
      
      qcalc <- smap(tuin, S[i,32], S[i,33],
                    param$Area, 
                    param$kkt, param$k1t, param$k2t, param$k2t2, param$k3t,
                    param$str, param$crec, param$ai, param$capc, 
                    param$H, param$H1,
                    param$pcof, param$ecof, param$ecof2,
                    evapo, df,
                    S[i,1:31],
                    0)
      
      
      #Fnew <- funObjetivo(qcalc, vaz$vazaoObs, "dm",2)
      Fnew <- funObjetivo(qcalc, vazaoObs, tipo, ipeso)
      Fnew <- abs(Fnew-alvo)
      
      rnd <- runif(1, min = 0, max = 1)
      
      if (Fnew <= Fitness[i] & rnd < A) {
        Sol[i,] <- S[i,]
        Fitness[i] <- Fnew
        A <- A*0.9
        r <- r0*(1-exp(-gamma*t))
      }
      if (Fnew <= f_min) {
        best <- S[i,]
        f_min <- Fnew
      }
    }
  }
  
  return(best)
}
