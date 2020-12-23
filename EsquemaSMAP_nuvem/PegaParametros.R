rm(list=ls())
library("abind")

#################################
# EDITAR AQUI #
# com o nome da pasta do Modelo_Chuva_Vazao
folders <-c('Modelos_Chuva_Vazao_20200810')   # aqui vc coloca a pasta de Modelo Chuva-Vazao

bacias <- c("Grande", "Iguacu", "Parana", "Paranaiba", "Paranapanema", "SaoFrancisco", "Tiete", "Tocantins", "Uruguai")

### first step is getting the parameters files from all folders
### do their names (or quantity) change throughout the time?

namesf <- list()
for(f in 1:length(bacias)){
  
  TodosNomes <- list()
  ii <- 0
  for(i in 1:length(folders)){
    dir <- paste(folders[i],"/SMAP/",bacias[f],"/ARQ_ENTRADA/", sep="")
    filenames <- Sys.glob(paste(dir, "*PARAMETROS.txt",sep=""))
    if(length(filenames) > 0){
      ii <- ii+1
      TodosNomes[[ii]] <- filenames
    }
  }
print(f)
print(TodosNomes)
  namesf[[f]] <- abind(TodosNomes)
  unicosNomes <- function(x){
    for(xx in 1:length(x)){
      x[xx] <- substr(x[xx], 30, nchar(x[xx])) 
    }
    final <- unique(x)
    return(final)
  }
  
  namesf[[f]] <- unicosNomes(namesf[[f]])
}

limpaExporta <- function(nomearq){
  
  varnames <- c("Area", "str", "k2t", "crec", "ai", "capc", "kkt", 
                "k2t2", "H1", "H", "k3t", "k1t", "ecof", "pcof", 
                "ecof2", "sup_ebin", "inf_ebin", "sup_chuva", "inf_chuva")
  x <- readLines(nomearq)
  linhaProb <- x[2]
  n <- as.numeric(substr(linhaProb,1,2))
  
  # n controls the number of columns I want to read
  # it varies from basin to basin
  if(n > 10){
    ntotal <- 6 + 6*n
  } else{
    ntotal <- 7 + 6*n
  }
  
  header <- paste("kt_", seq(1,n), sep="")
  coefs <- gsub(" ", ",", substr(linhaProb,9,ntotal))
  coefs <- read.csv(textConnection(coefs), header=F)
  names(coefs) <- header
  #print(names(coefs))
  df <- data.frame(t(as.numeric(substr(x[-2],1,10))))
  names(df) <- varnames
  df <- cbind(df, coefs)
  
  return(df)
}


todasBacias <- list()
for(f in 1:length(bacias)){
  
  filenames <- namesf[[f]]
  parPorBacia <- list()

  for(j in 1:length(filenames)){
    pars <- list()
    ii <- 0
    for(i in 1:length(folders)){
      fname <- paste(folders[i],"/", filenames[j], sep="")
      if(file_test("-f", fname)){
        ii <- ii+1
        pars[[ii]] <- cbind(data.frame(date=as.POSIXct(substr(fname, 21,28), format="%Y%m%d", tz="GMT")),
                            limpaExporta(fname))

      }
    }
    parPorBacia[[j]] <- do.call(rbind, pars)
    parPorBacia[[j]] <- parPorBacia[[j]][!duplicated(parPorBacia[[j]][,-1]),]
    #print(filenames[j])
    #print(substr(filenames[j], 19+nchar(bacias[f]), nchar(filenames[j])-15))
    parPorBacia[[j]]$subbacia <- substr(filenames[j], 19+nchar(bacias[f]), nchar(filenames[j])-15)
    parPorBacia[[j]]$bacia <- bacias[f]

  }
  todasBacias[[f]] <- Reduce(function(x, y) merge(x,y,all=T), parPorBacia)
}

vertudo <- Reduce(function(x, y) merge(x,y,all=T), todasBacias)

save(vertudo,file='Parametros.RData')

