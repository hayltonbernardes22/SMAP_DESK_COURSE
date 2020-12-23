rm(list=ls())

Sys.setlocale("LC_TIME", "C")

# funcoes
tempoViagem <- function(pbase, tv){
  poutbase <- pbase
  if(tv <= 24){
    for(i in 2:length(pbase)){
      poutbase[i] <- (tv*pbase[i-1] + (24-tv)*pbase[i])/24
    }
  } else{
    for(i in 3:length(pbase)){
      poutbase[i] <- ((tv-24)*pbase[i-2] + (48-tv)*pbase[i-1])/24
    }
  }
  return(poutbase)
}
###################################################
### Guardando por cada Posto
################################################

writing_by_points<- function(Basin,DF){
 
    

df<- DF
df$date<-format(as.Date(df$date), format="%d/%m/%Y")

data_ID=read.table('../../Postos_ONS_ID.csv',header = T,sep=',',colClasses='character')

NAME<-names(df)

for (n in 2:length(NAME)){ 
name=NAME[n]  
    
Id_name=data_ID[data_ID$posto==name,]

ID_name=Id_name$id
ID_name=trimws(ID_name)

    
file=paste('../../out_POSTOS/ECMWF/',ID_name,'_',name,'_',Basin,'_D',".txt", sep="")
SUBSET<- df[,c(1,which(names(df)== name))]
SUBSET[,name]=round(SUBSET[,name],2)
names(SUBSET)=c('data','vazao')    
write.table(SUBSET, file =file, append = FALSE, quote = FALSE, sep = "\t",
           eol = "\n", na = "NA", dec = ".", row.names = F,
          col.names =T,
           fileEncoding = "") 
    
        
    
 }   
    
    
    
    
}


DATAF <- data.frame()

#######################################################################




exportaEstilo <- function(header, bacia, df){
  fname <- paste("SMP_",bacia,"_PMEDIA_ORIG_PREVISAO", sep="")
  write.table(header[1], file=paste(fname, "_D.txt", sep=""), row.names = F, col.names = F, quote = F, append=T)
  write.table(header[2], file=paste(fname, "_D.txt", sep=""), row.names = F, col.names = F, quote = F, append=T)
  write.table(header[3], file=paste(fname, "_D.txt", sep=""), row.names = F, col.names = F, quote = F, append=T)

  
  
  for(i in 1:nrow(df)){
    sub <- paste(as.character(sprintf("%21.2f", df[i,-1])), collapse = '')
    write.table(paste(format(df[i,1], "%d/%m/%Y"), sub, sep=""), file=paste(fname, "_D.txt", sep=""), row.names = F, col.names = F, quote = F, append=T)
  
  }
  
}

# MAIN
load("/home/middle/SMAP_DESK_COURSE/EsquemaSMAP_nuvem/20200810_ECMWF_Simulacoes.RData")
setwd("/home/middle/SMAP_DESK_COURSE/EsquemaSMAP_nuvem/out/ECMWF")
headerSMAP <- array()

####################################################################################
####                 Bacia Rio Grande
####################################################################################

namesBacia <- c("EDACUNHA", "CAPESCURO", "CAMARGOS", "PBUENOS", "FUNIL MG", "PARAGUACU", "PASSAGEM", "PCOLOMBIA", "MARIMBONDO", "FURNAS", "AVERMELHA")
df <- junta[,names(junta) %in% c("date", namesBacia)]
headerSaida <- c("Camargos", "Itutinga", "Furnas", "MascMoraes", "Estreito", "Jaguara", "Igarapava", 
                 "VoltaGrande", "PColombia", "Caconde", "ECunha", "Limoeiro", "Marimbondo", "AVermelha", "FunilGrande")

df_final <- data.frame(matrix(NA, nrow=nrow(df), ncol=length(headerSaida)))
names(df_final) <- headerSaida
df_final <- data.frame(date=df$date, df_final)

# f(Camargos)
df_final$Camargos <- 1.0 * df$CAMARGOS
df_final$Itutinga <- 0.0 * df$CAMARGOS
# Funil-Grande
df_final$FunilGrande <- df$`FUNIL MG`
# Furnas
df_final$Furnas <- df$FURNAS + tempoViagem(df$PARAGUACU, 10) + tempoViagem(df$PBUENOS, 12)
# f(PColombia)
df_final$MascMoraes   <- 0.377 * df$PCOLOMBIA
df_final$Estreito     <- 0.087 * df$PCOLOMBIA
df_final$Jaguara      <- 0.036 * df$PCOLOMBIA
df_final$Igarapava    <- 0.103 * df$PCOLOMBIA
df_final$VoltaGrande  <- 0.230 * df$PCOLOMBIA
df_final$PColombia    <- 0.167 * df$PCOLOMBIA + tempoViagem(df$CAPESCURO, 8)
# f(Euc da Cunha)
df_final$Caconde <- 0.610 * df$EDACUNHA
df_final$ECunha  <- 0.390 * df$EDACUNHA
# f(Marimbondo)
df_final$Limoeiro   <- 0.004 * df$MARIMBONDO
df_final$Marimbondo <- 0.996 * df$MARIMBONDO + tempoViagem(df$PASSAGEM, 16)
# AVermelha
df_final$AVermelha <- df$AVERMELHA

df_final <- df_final[(nrow(df_final)-9+1):nrow(df_final),]
headerSMAP[1] <- "                       CAMARGOS             ITUTINGA               FURNAS            M. MORAES        L. C. BARRETO              JAGUARA            IGARAPAVA         VOLTA GRANDE          P. COLOMBIA              CACONDE          E. DA CUNHA             LIMOEIRO           MARIMBONDO          A. VERMELHA             FUNIL-MG"
headerSMAP[2] <- "                            001                  002                  006                  007                  008                  009                  010                  011                  012                  014                  015                  016                  017                  018                  211"
headerSMAP[3] <- "                    INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL"
exportaEstilo(headerSMAP, "GRANDE", df_final)




writing_by_points('GRANDE',df_final)

#######################################################
############################################
#### Bacia Rio Paranaiba
###############################################
namesBacia <- c("ESPORA","CORUMBAIV", "SDOFACAO","SALTOVERDI","FOZCLARO", "NOVAPONTE", "EMBORCACAO", "CORUMBA1", "ITUMBIARA", "RVERDE", "SSIMAO2")
df <- junta[,names(junta) %in% c("date", namesBacia)]
headerSaida <- c("Espora","Batalha", "CorumbaIII", "Emborcacao", "NovaPonte", "CapimBranco2", "Itumbiara", "CachDourada", 
                 "SaoSimao", "CorumbaIV", "Miranda", "CapimBranco1", "CorumbaI", "SerraFacao","Salto","FozClaro","Cacu",
                 "Coqueiros","Verdinho")

df_final <- data.frame(matrix(NA, nrow=nrow(df), ncol=length(headerSaida)))
names(df_final) <- headerSaida
df_final <- data.frame(date=df$date, df_final)

# f(SdoFacao)
df_final$Batalha    <- 0.615 * df$SDOFACAO
df_final$Espora <-  df$ESPORA
df_final$FozClaro <- df$FOZCLARO*0.069
df_final$Salto <-df$SALTOVERDI*0.923
df_final$SerraFacao <- 0.385 * df$SDOFACAO
# Emboracao
df_final$Emborcacao <- df$EMBORCACAO
# Nova Ponte
df_final$NovaPonte <- df$NOVAPONTE
# f(Itumbiara)
df_final$Miranda      <- 0.040 * df$ITUMBIARA
df_final$CapimBranco1 <- 0.005 * df$ITUMBIARA
df_final$CapimBranco2 <- 0.012 * df$ITUMBIARA
df_final$Itumbiara    <- 0.943 * df$ITUMBIARA
# Corumba IV
df_final$CorumbaIV <- df$CORUMBAIV
# f(CorumbaI)
df_final$CorumbaIII <- 0.100 * df$CORUMBA1
df_final$CorumbaI   <- 0.900 * df$CORUMBA1
# f(Sao Simao)
df_final$CachDourada <- 0.109 * df$SSIMAO2
df_final$SaoSimao    <- 0.891 * df$SSIMAO2 + tempoViagem(df$RVERDE, 8)

df_final$Cacu <- 0.8940* df$FOZCLARO
df_final$Coqueiros <-0.037* df$FOZCLARO
df_final$Verdinho <- 0.077* df$SALTOVERDI

df_final <- df_final[(nrow(df_final)-9+1):nrow(df_final),]
###### escrita SMAP
headerSMAP[1] <- "                         ESPORA            BATALHA            CORUMBA-3           EMBORCAÇÃO           NOVA PONTE           C.BRANCO-2            ITUMBIARA           C. DOURADA            SÃO SIMÃO            CORUMBA-4              MIRANDA           C.BRANCO-1              CORUMBA             S.DO FACÃO            SALTO           FOZ DO RIO CLARO           CACU              B.COQUEIROS            S.R.VERDINHO "
headerSMAP[2] <- "                          099              022                  023                  024                  025                  028                  031                    032                  033                  205                  206                  207                  209                  251                  294                 261                     247                   248                 241  "
headerSMAP[3] <- "                         TOTAL           INCREMENTAL          INCREMENTAL          INCREMENTAL                TOTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL                TOTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL         INCREMENTAL       INCREMENTAL              INCREMENTAL             INCREMENTAL           INCREMENTAL            INCREMENTAL"
exportaEstilo(headerSMAP, "PNAIBA", df_final)


writing_by_points('PNAIBA',df_final)
##########################################

################################################################
#### Bacia Rio Tiete
#############################################################

namesBacia <- c("ESOUZA", "IBITINGA", "NAVANHANDA", "BBONITA")
df <- junta[,names(junta) %in% c("date", namesBacia)]
headerSaida <- c("Guarapiranga", "Billings+Pedra", "PonteNova", "ES+Pinheiros", 
                 "BarraBonita", "Bariri", "Ibitinga", "Promissao", "NAvanhandava")

df_final <- data.frame(matrix(NA, nrow=nrow(df), ncol=length(headerSaida)))
names(df_final) <- headerSaida
df_final <- data.frame(date=df$date, df_final)

# f(E Souza)
df_final$PonteNova      <- 0.073 * df$ESOUZA
df_final$Guarapiranga   <- 0.120 * df$ESOUZA
df_final$Billings.Pedra <- 0.183 * df$ESOUZA
df_final$ES.Pinheiros   <- 0.624 * df$ESOUZA
# f(Barra Bonita)
df_final$BarraBonita <- df$BBONITA
# f(Ibitinga)
df_final$Bariri   <- 0.344 * df$IBITINGA
df_final$Ibitinga <- 0.656 * df$IBITINGA
# f(NAvanhandava)
df_final$Promissao    <- 0.719 * df$NAVANHANDA
df_final$NAvanhandava <- 0.281 * df$NAVANHANDA

df_final <- df_final[(nrow(df_final)-9+1):nrow(df_final),]

headerSMAP[1] <- "                   GUARAPIRANGA        BILL E PEDRAS           PONTE NOVA    E. S. + PINHEIROS            B. BONITA               BARIRI             IBITINGA            PROMISSÃO       N. AVANHANDAVA"
headerSMAP[2] <- "                            117                  119                  160                  161                  237                  238                  239                  240                  242"
headerSMAP[3] <- "                    INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL"

exportaEstilo(headerSMAP, "Tiete", df_final)

writing_by_points('Tiete',df_final)

#################################################################################
#### Bacia Rio Paranapanema
#################################################################################
namesBacia <- c("CHAVANTES", "CANOASI", "MAUA", "ROSANA", "JURUMIRIM", "CAPIVARA")
df <- junta[,names(junta) %in% c("date", namesBacia)]
headerSaida <- c("Jurumirim", "Piraju", "Chavantes", "SaltoGrande", "Canoas2", 
                 "Canoas1", "Maua", "Capivara", "Taquarucu", "Rosana", "Ourinhos")

df_final <- data.frame(matrix(NA, nrow=nrow(df), ncol=length(headerSaida)))
names(df_final) <- headerSaida
df_final <- data.frame(date=df$date, df_final)

# Jurumirim
df_final$Jurumirim <- df$JURUMIRIM
# f(Chavantes)
df_final$Piraju    <- 0.046 * df$CHAVANTES
df_final$Chavantes <- 0.954 * df$CHAVANTES
# f(CanoasI)
df_final$Ourinhos    <- 0.031 * df$CANOASI
df_final$SaltoGrande <- 0.778 * df$CANOASI
df_final$Canoas2     <- 0.061 * df$CANOASI
df_final$Canoas1     <- 0.130 * df$CANOASI
# Maua
df_final$Maua <- df$MAUA
# Capivara
df_final$Capivara <- df$CAPIVARA
# f(Rosana)
df_final$Taquarucu <- 0.299 * df$ROSANA
df_final$Rosana    <- 0.701 * df$ROSANA

df_final <- df_final[(nrow(df_final)-9+1):nrow(df_final),]

headerSMAP[1] <- "                      JURUMIRIM               PIRAJU            CHAVANTES      SALTO GRANDE CS            CANOAS II             CANOAS I                 MAUA             CAPIVARA            TAQUARUÇU               ROSANA             OURINHOS"
headerSMAP[2] <- "                            047                  048                  049                  050                  051                  052                  057                  061                  062                  063                  249"
headerSMAP[3] <- "                          TOTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL                TOTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL"

exportaEstilo(headerSMAP, "PNMA", df_final)


writing_by_points('PNMA',df_final)

###########################################
#### Bacia Rio Sao Francisco
#####################################
namesBacia <- c("QM", "RB-SMAP", "SFR2", "TM-SMAP", "SRM2")
df <- junta[,names(junta) %in% c("date", namesBacia)]
headerSaida <- c("RetiroBaixo", "TresMarias", "Queimado")

df_final <- data.frame(matrix(NA, nrow=nrow(df), ncol=length(headerSaida)))
names(df_final) <- headerSaida
df_final <- data.frame(date=df$date, df_final)

# Retiro Baixo
df_final$RetiroBaixo <- df$`RB-SMAP`
# Tres Marias
df_final$TresMarias <- df$`TM-SMAP`
# Queimado
df_final$Queimado <- df$QM

df_final <- df_final[(nrow(df_final)-9+1):nrow(df_final),]

headerSMAP[1] <- "                   RETIRO BAIXO          TRÊS MARIAS             QUEIMADO"
headerSMAP[2] <- "                            155                  156                  158"
headerSMAP[3] <- "                          TOTAL          INCREMENTAL                TOTAL"
exportaEstilo(headerSMAP, "SF3", df_final)

    
writing_by_points('SF3',df_final)

########################################
#### Bacia do Tocantins
#########################################
namesBacia <- c("SMESA")
df <- junta[,names(junta) %in% c("date", namesBacia)]
headerSaida <- c("SerraMesa")

df_final <- data.frame(matrix(NA, nrow=nrow(df), ncol=length(headerSaida)))
names(df_final) <- headerSaida
df_final <- data.frame(date=df$date, df_final)

# Serra da Mesa
df_final$SerraMesa <- df$SMESA

df_final <- df_final[(nrow(df_final)-9+1):nrow(df_final),]

headerSMAP[1] <- "                  SERRA DA MESA"
headerSMAP[2] <- "                            270"
headerSMAP[3] <- "                          TOTAL"
exportaEstilo(headerSMAP, "TOC", df_final)


writing_by_points('TOC',df_final)

#######################################





##################################################
####              Bacia do Iguacu
############################################
namesBacia <- c("STACLARA", "JORDSEG", "FOA", "SCAXIAS", "UVITORIA")
df <- junta[,names(junta) %in% c("date", namesBacia)]
headerSaida <- c("SantaClara", "Fundao", "Jordao", "GBMunhoz", "Segredo", "SaltoSantiago", "SaltoOsorio", "SaltoCaxias", "Segredo+Jordao")

df_final <- data.frame(matrix(NA, nrow=nrow(df), ncol=length(headerSaida)))
names(df_final) <- headerSaida
df_final <- data.frame(date=df$date, df_final)

# Santa Clara
df_final$SantaClara <- df$STACLARA
# f(Jord Seg)
df_final$Fundao         <- 0.039 * df$JORDSEG
df_final$Jordao         <- 0.157 * df$JORDSEG
df_final$Segredo        <- 0.804 * df$JORDSEG
df_final$Segredo.Jordao <- 0.000 * df$JORDSEG
# G B Munhoz
df_final$GBMunhoz <- df$FOA + tempoViagem(df$UVITORIA, 17.4)
# f(SCaxias)
df_final$SaltoSantiago <- 0.258 * df$SCAXIAS
df_final$SaltoOsorio   <- 0.102 * df$SCAXIAS
df_final$SaltoCaxias   <- 0.640 * df$SCAXIAS

df_final <- df_final[(nrow(df_final)-9+1):nrow(df_final),]

headerSMAP[1] <- "                 SANTA CLARA-PR               FUNDÃO               JORDÃO         G. B. MUNHOZ              SEGREDO       SALTO SANTIAGO         SALTO OSORIO         SALTO CAXIAS       SEGREDO+JORDAO"
headerSMAP[2] <- "                            071                  072                  073                  074                  076                  077                  078                  222                  976"
headerSMAP[3] <- "                          TOTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL"
exportaEstilo(headerSMAP, "Iguacu", df_final)




writing_by_points('Iguacu',df_final)



##########################################
#### Bacia do Uruguai
######################################
namesBacia <- c("QQUEIXO", "MONJOLINHO", "FOZCHAPECO", "MACHADINHO", "SJOAO", "BG", "ITA", "CN")
df <- junta[,names(junta) %in% c("date", namesBacia)]
headerSaida <- c("Garibaldi", "Ita", "PassoFundo", "FozChapeco", "SaoJose", "PassoSaoJoao", 
                 "BarraGrande", "CamposNovos", "Machadinho", "Monjolinho", "QuebraQueixo")

df_final <- data.frame(matrix(NA, nrow=nrow(df), ncol=length(headerSaida)))
names(df_final) <- headerSaida
df_final <- data.frame(date=df$date, df_final)

# f(CN)
df_final$Garibaldi   <- 0.910 * df$CN
df_final$CamposNovos <- 0.090 * df$CN
# Ita
df_final$Ita <- df$ITA
# f(Monjolinho)
df_final$PassoFundo <- 0.586 * df$MONJOLINHO
df_final$Monjolinho <- 0.414 * df$MONJOLINHO
# Foz Chapeco
df_final$FozChapeco <- df$FOZCHAPECO
# f(Sao Joao)
df_final$SaoJose      <- 0.963 * df$SJOAO
df_final$PassoSaoJoao <- 0.037 * df$SJOAO
# Barra Grande
df_final$BarraGrande <- df$BG
# Machadinho
df_final$Machadinho <- df$MACHADINHO
# Quebra Queixo
df_final$QuebraQueixo <- df$QQUEIXO

df_final <- df_final[(nrow(df_final)-9+1):nrow(df_final),]

headerSMAP[1] <- "                      GARIBALDI                  ITÁ          PASSO FUNDO          FOZ CHAPECO             SAO JOSE       PASSO SAO JOAO         BARRA GRANDE         CAMPOS NOVOS           MACHADINHO           MONJOLINHO        QUEBRA QUEIXO"
headerSMAP[2] <- "                            089                  092                  093                  094                  102                  103                  215                  216                  217                  220                  286"
headerSMAP[3] <- "                    INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL                TOTAL          INCREMENTAL          INCREMENTAL          INCREMENTAL                TOTAL"
exportaEstilo(headerSMAP, "URUG", df_final)

writing_by_points('URUG',df_final)



###########################################################
#### Bacia do Parana
###################################################
namesBacia <- c("FLOR+ESTRA", "BALSA", "IVINHEMA", "PTAQUARA",
"SDO","JUPIA","FZB","ILHAEQUIV","PPRI", "ITAIPU")
df <- junta[,names(junta) %in% c("date", namesBacia)]
headerSaida <- c("Itaipu","SDomingo","Jupia","Solteira",
"Tres_irmaos","Ppri")

df_final <- data.frame(matrix(NA, nrow=nrow(df), ncol=length(headerSaida)))
names(df_final) <- headerSaida
df_final <- data.frame(date=df$date, df_final)

# Itaipu
df_final$Itaipu <- df$ITAIPU + tempoViagem(df$BALSA, 32) + tempoViagem(df$`FLOR+ESTRA`, 33) + tempoViagem(df$IVINHEMA, 45) + tempoViagem(df$PTAQUARA, 36)
df_final$SDomingo <-df$SDO
df_final$Jupia <- df$JUPIA
df_final$Solteira <-0.94 *df$ILHAEQUIV
df_final$Tres_irmaos <-0.06 *df$ILHAEQUIV
df_final$Ppri <- df$PPRI +tempoViagem(df$FZB, 26)

df_final <- df_final[(nrow(df_final)-9+1):nrow(df_final),]

headerSMAP[1] <- "                         ITAIPU           SAO DOMINGOS           JUPIA           I. SOLTEIRA           TRÊS IRMÃOS           PORTO PRIMAVERA "
headerSMAP[2] <- "                            266           154                     245                034                  243               246"
headerSMAP[3] <- "                    INCREMENTAL           INCREMENTAL          INCREMENTAL        INCREMENTAL        INCREMENTAL              INCREMENTAL"
exportaEstilo(headerSMAP, "PARANA", df_final)

writing_by_points('PARANA',df_final)









