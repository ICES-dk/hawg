#-------------------------------------------------------------------------------
# Code to do the multifleet short term forecast for North Sea Herring
#
# By: Niels Hintzen
# IMARES
# 2 January 2012
#
#-------------------------------------------------------------------------------

rm(list=ls());
library(minpack.lm)

#Read in data
path <- "N:/Projecten/ICES WG/Haring werkgroep HAWG/2012/Assessment/NSAS/"
try(setwd(path))
source(file.path("../","_Common","HAWG Common assessment module.r"))
try(setwd("./stf/"))

#-------------------------------------------------------------------------------
# Temporarily: Create iters for NSH and NSH.ica object
#-------------------------------------------------------------------------------

NSH     <- propagate(NSH,iter=10)
#---- END Temporarily ----------------------------------------------------------


stk     <- NSH
stk.ica <- NSH.ica

#-------------------------------------------------------------------------------
# Setup control file
#-------------------------------------------------------------------------------

DtY   <- ac(range(stk)["maxyear"]) #Data year
ImY   <- ac(an(DtY)+1) #Intermediate year
FcY   <- ac(an(DtY)+2) #Forecast year
CtY   <- ac(an(DtY)+3) #Continuation year
FuY   <- c(ImY,FcY,CtY)#Future years

#-------------------------------------------------------------------------------
# TAC information
#
#   For the TAC's there is some special things going on. The A-fleet, you can get the TAC from the agreed management plan between Norway-EU. However, there might be catches from Norway from the C-fleet
#   which they are allowed to take in the North Sea. So, substract these catches (which are a percentage of their total C-fleet quota) from the total C-fleet quota and move that into the North Sea
#   Then split the C-fleet and D-fleet into parts from the WBSS and NSH
#   The B-fleet is the bycatch in the North Sea
#   Where to find the information: TAC A-Fleet: Agreement EU-Norway North Sea --> table
#                                  TAC B-Fleet: Agreement EU-Norway North Sea --> in text
#                                  TAC C-Fleet: Agreement EU-Norway Kattegat - Skaggerak --> table
#                                  TAC D-Fleet: Agreement EU-Norway Kattegat - Skaggerak --> in text
#                                  Transfer C-Fleet to A-fleet: Agreement EU-Norway Kattegat - Skaggerak --> in text, and combination with TAC of C-Fleet of Norway
#   Split the C-Fleet and D-Fleet into the WBSS and NSH fraction of the TAC (after taking the transfer from Norway from the C-Fleet)
#   Split information comes from the 'Wonderful Table'
#   Split is based on parts taken in the history
#   TAC's for the C and D fleet for the Forecast and Continuation year come from the Danish. Or:
#   Compute the fraction of NSH caught by the C fleet from the total C fleet catch (wonderful table), the same for the D-fleet
#   Then calculate the proportion of the C fleet that was catching WBSS. Then take the forecasted TAC and
#   multiply it by the C fleet share in WBSS, then divide it by 1-fraction NSH and then times the fraction of NSH. This gives you the TAC's for the C and D Fleet
#   However, this might be changed by the Danish
#-------------------------------------------------------------------------------

#- Source the code to read in the weights at age and numbers at age by fleet, to compute partial F's and partial weights
source("./data/readStfData.r")
source("./data/writeSTF.out.r")

#2011:
TACS        <- FLQuant(NA,dimnames=list(age="all",year=FuY,unit=c("A","B","C","D"),season="all",area=1,iter=1:dims(stk)$iter))
TACS.orig   <- TACS
TACS[,,"A"] <- c(200000+15000,NA,NA);   TACS.orig[,,"A"]  <- c(200000,NA,NA)
TACS[,,"B"] <- c(16539*0.668,NA,NA);    TACS.orig[,,"B"]  <- c(16539,NA,NA)
TACS[,,"C"] <- c(3875,6810,6810);       TACS.orig[,,"C"]  <- c(3875,6810,6810)
TACS[,,"D"] <- c(1723,1938,1938);       TACS.orig[,,"D"]  <- c(1723,1938,1938)

RECS        <- FLQuants("ImY" =FLQuant(stk.ica@param["Recruitment prediction","Value"],dimnames=list(age="0",year=ImY,unit="unique",season="all",area="unique",iter=1:dims(stk)$iter)),
                        "FcY" =exp(apply(log(rec(stk)[,ac((range(stk)["maxyear"]-8):(range(stk)["maxyear"]))]),3:6,mean,na.rm=T)),
                        "CtY" =exp(apply(log(rec(stk)[,ac((range(stk)["maxyear"]-8):(range(stk)["maxyear"]))]),3:6,mean,na.rm=T)))

FS          <- list("A"=FA,"B"=FB,"C"=FC,"D"=FD)
WS          <- list("A"=WA,"B"=WB,"C"=WC,"D"=WD)

yrs1        <- list("m","m.spwn","harvest.spwn","stock.wt")
yrs3        <- list("mat")

dsc         <- "North Sea Herring"
nam         <- "NSH"
dms         <- dimnames(stk@m)
dms$year    <- c(rev(rev(dms$year)[1:3]),ImY,FcY,CtY)
dms$unit    <- c("A","B","C","D")

f01         <- ac(0:1)
f26         <- ac(2:6)

stf.options <- c("mp","-15%","+15%","nf","tacro") #mp=according to management plan, +/-% = TAC change, nf=no fishing, bpa=reach BPA in CtY or if ssb > bpa fish at fpa,
                                                        # tacro=same catch as last year
mp.options  <- c("i") #i=increase in B fleet is allowed, fro=B fleet takes fbar as year before
#===============================================================================
# Setup stock file
#===============================================================================

stf         <- FLStock(name=nam,desc=dsc,m=FLQuant(NA,dimnames=dms))
for(i in dms$unit)
  stf[,,i]  <- window(NSH,start=an(dms$year)[1],end=rev(an(dms$year))[1])
units(stf)  <- units(stk)
# Fill slots that are the same for all fleets
for(i in c(unlist(yrs1),unlist(yrs3))){
  if(i %in% unlist(yrs1)){ for(j in dms$unit){ slot(stf,i)[,FuY,j] <- slot(stk,i)[,DtY]}}
  if(i %in% unlist(yrs3)){ for(j in dms$unit){ slot(stf,i)[,FuY,j] <- yearMeans(slot(stk,i)[,ac((an(DtY)-2):an(DtY))])}}
}
# Fill slots that are unique for the fleets
for(i in dms$unit){
  stf@harvest[,FuY,i]     <- FS[[i]]
  stf@catch.wt[,FuY,i]    <- WS[[i]]
  stf@landings.wt[,FuY,i] <- WS[[i]]
}
# Fill slots that have no meaning for NSAS
stf@discards.n[]          <- 0
stf@discards[]            <- 0
stf@discards.wt[]         <- 0

#===============================================================================
# Intermediate year
#===============================================================================

for(i in dms$unit)    stf@stock.n[,ImY,i]     <- stk.ica@survivors
stf@harvest[,ImY]         <- fleet.harvest(stk=stf,iYr=ImY,TACS=TACS[,ImY])
for(i in dms$unit){
  stf@catch.n[,ImY,i]     <- stf@stock.n[,ImY,i]*(1-exp(-unitSums(stf@harvest[,ImY])-stf@m[,ImY,i]))*(stf@harvest[,ImY,i]/(unitSums(stf@harvest[,ImY])+stf@m[,ImY,i]))
  stf@catch[,ImY,i]       <- computeCatch(stf[,ImY,i])
  stf@landings.n[,ImY,i]  <- stf@catch.n[,ImY,i]
  stf@landings[,ImY,i]    <- computeLandings(stf[,ImY,i])
}


#Intermediate year stf option table
stf.table <- array(NA,dim=c(c(length(stf.options)+1),12,3),
                   dimnames=list("options"=c("intermediate year",stf.options),
                                 "values" =c("Fbar 2-6 A","Fbar 0-1 B","Fbar 0-1 C","Fbar 0-1 D","Fbar 2-6","Fbar 0-1","Catch A","Catch B","Catch C","Catch D","SSB","SSB"),
                                 "stats"  =c("5%","50%","95%")))

stf.table[1,"Fbar 2-6 A",]                                  <- iterQuantile(quantMeans(stf@harvest[f26,ImY,"A"]))
stf.table[1,grep("Fbar 0-1 ",dimnames(stf.table)$values),]  <- aperm(iterQuantile(quantMeans(stf@harvest[f01,ImY,c("B","C","D")])),c(2:6,1))
stf.table[1,"Fbar 2-6",]                                    <- iterQuantile(quantMeans(unitSums(stf@harvest[f26,ImY,])))
stf.table[1,"Fbar 0-1",]                                    <- iterQuantile(quantMeans(unitSums(stf@harvest[f01,ImY,])))
stf.table[1,grep("Catch ",dimnames(stf.table)$values),]     <- aperm(iterQuantile(harvestCatch(stf,ImY)),c(2:6,1))
stf.table[1,grep("SSB",dimnames(stf.table)$values)[1],]     <- iterQuantile(quantSums(stf@stock.n[,ImY,1] * stf@stock.wt[,ImY,1] *
                                                                 exp(-unitSums(stf@harvest[,ImY])*stf@harvest.spwn[,ImY,1]-stf@m[,ImY,1]*stf@m.spwn[,ImY,1]) *
                                                                 stf@mat[,ImY,1]))

#===============================================================================
# Forecast year
#===============================================================================

for(i in dms$unit) stf@stock.n[1,FcY,i]                     <- RECS$FcY
for(i in dms$unit) stf@stock.n[2:(dims(stf)$age-1),FcY,i]   <- (stf@stock.n[,ImY,1]*exp(-unitSums(stf@harvest[,ImY])-stf@m[,ImY,1]))[ac(range(stf)["min"]:(range(stf)["max"]-2)),]
for(i in dms$unit) stf@stock.n[dims(stf)$age,FcY,i]         <- apply((stf@stock.n[,ImY,1]*exp(-unitSums(stf@harvest[,ImY])-stf@m[,ImY,1]))[ac((range(stf)["max"]-1):range(stf)["max"]),],2:6,sum,na.rm=T)

###--- Management options ---###

### Following the management plan ###
if("mp" %in% stf.options){

  res <- matrix(NA,nrow=dims(stf)$unit,ncol=dims(stf)$iter,dimnames=list(dimnames(stf@stock.n)$unit,dimnames(stf@stock.n)$iter))
  for(iTer in 1:dims(stf)$iter)
    res[,iTer]              <- nls.lm(par=rep(1,dims(stf)$unit),find.FAB,stk=iter(stf[,FcY],iTer),f01=f01,f26=f26,mp.options=mp.options,TACS=iter(TACS[,FcY],iTer),jac=NULL)$par
  stf@harvest[,FcY]         <- sweep(stf@harvest[,FcY],c(3,6),res,"*")
  for(i in dms$unit){
    stf@catch.n[,FcY,i]     <- stf@stock.n[,FcY,i]*(1-exp(-unitSums(stf@harvest[,FcY])-stf@m[,FcY,i]))*(stf@harvest[,FcY,i]/(unitSums(stf@harvest[,FcY])+stf@m[,FcY,i]))
    stf@catch[,FcY,i]       <- computeCatch(stf[,FcY,i])
    stf@landings.n[,FcY,i]  <- stf@catch.n[,FcY,i]
    stf@landings[,FcY,i]    <- computeLandings(stf[,FcY,i])
  }
  #Update to continuation year
  for(i in dms$unit) stf@stock.n[1,CtY,i]                     <- RECS$CtY
  for(i in dms$unit) stf@stock.n[2:(dims(stf)$age-1),CtY,i]   <- (stf@stock.n[,FcY,1]*exp(-unitSums(stf@harvest[,FcY])-stf@m[,FcY,1]))[ac(range(stf)["min"]:(range(stf)["max"]-2)),]
  for(i in dms$unit) stf@stock.n[dims(stf)$age,CtY,i]         <- apply((stf@stock.n[,FcY,1]*exp(-unitSums(stf@harvest[,FcY])-stf@m[,FcY,1]))[ac((range(stf)["max"]-1):range(stf)["max"]),],2:6,sum,na.rm=T)
  ssb.CtY                                                     <- quantSums(stf@stock.n[,CtY,1] * stf@stock.wt[,CtY,1]*stf@mat[,CtY,1]*exp(-unitSums(stf@harvest[,FcY])*stf@harvest.spwn[,CtY,1]-stf@m[,CtY,1]*stf@m.spwn[,CtY,1])) #assume same harvest as in FcY

  stf.table["mp","Fbar 2-6 A",]                                  <- iterQuantile(quantMeans(stf@harvest[f26,FcY,"A"]))
  stf.table["mp",grep("Fbar 0-1 ",dimnames(stf.table)$values),]  <- aperm(iterQuantile(quantMeans(stf@harvest[f01,FcY,c("B","C","D")])),c(2:6,1))
  stf.table["mp","Fbar 2-6",]                                    <- iterQuantile(quantMeans(unitSums(stf@harvest[f26,FcY,])))
  stf.table["mp","Fbar 0-1",]                                    <- iterQuantile(quantMeans(unitSums(stf@harvest[f01,FcY,])))
  stf.table["mp",grep("Catch ",dimnames(stf.table)$values),]     <- aperm(iterQuantile(harvestCatch(stf,FcY)),c(2:6,1))
  stf.table["mp",grep("SSB",dimnames(stf.table)$values)[1],]     <- iterQuantile(quantSums(stf@stock.n[,FcY,1] * stf@stock.wt[,FcY,1] *
                                                                 exp(-unitSums(stf@harvest[,FcY])*stf@harvest.spwn[,FcY,1]-stf@m[,FcY,1]*stf@m.spwn[,FcY,1]) *
                                                                 stf@mat[,FcY,1]))
  stf.table["mp",grep("SSB",dimnames(stf.table)$values)[2],]     <- iterQuantile(ssb.CtY)


  #As this is most likely the agreed TAC for the B fleet, use this in all other scenario's too
  TACS[,FcY,"B"]    <- computeCatch(stf[,FcY,"B"])
  #TACSmp            <- harvestCatch(stf,FcY)
}
### No fishing ###
if("nf" %in% stf.options){
  stf@harvest[,FcY] <- 0
  #Update to continuation year
  for(i in dms$unit) stf@stock.n[1,CtY,i]                     <- RECS$CtY
  for(i in dms$unit) stf@stock.n[2:(dims(stf)$age-1),CtY,i]   <- (stf@stock.n[,FcY,1]*exp(-unitSums(stf@harvest[,FcY])-stf@m[,FcY,1]))[ac(range(stf)["min"]:(range(stf)["max"]-2)),]
  for(i in dms$unit) stf@stock.n[dims(stf)$age,CtY,i]         <- apply((stf@stock.n[,FcY,1]*exp(-unitSums(stf@harvest[,FcY])-stf@m[,FcY,1]))[ac((range(stf)["max"]-1):range(stf)["max"]),],2:6,sum,na.rm=T)
  ssb.CtY                                                     <- quantSums(stf@stock.n[,CtY,1] * stf@stock.wt[,CtY,1]*stf@mat[,CtY,1]*exp(-unitSums(stf@harvest[,FcY])*stf@harvest.spwn[,CtY,1]-stf@m[,CtY,1]*stf@m.spwn[,CtY,1])) #assume same harvest as in FcY

  stf.table["nf","Fbar 2-6 A",]                                  <- iterQuantile(quantMeans(stf@harvest[f26,FcY,"A"]))
  stf.table["nf",grep("Fbar 0-1 ",dimnames(stf.table)$values),]  <- aperm(iterQuantile(quantMeans(stf@harvest[f01,FcY,c("B","C","D")])),c(2:6,1))
  stf.table["nf","Fbar 2-6",]                                    <- iterQuantile(quantMeans(unitSums(stf@harvest[f26,FcY,])))
  stf.table["nf","Fbar 0-1",]                                    <- iterQuantile(quantMeans(unitSums(stf@harvest[f01,FcY,])))
  stf.table["nf",grep("Catch ",dimnames(stf.table)$values),]     <- aperm(iterQuantile(harvestCatch(stf,FcY)),c(2:6,1))
  stf.table["nf",grep("SSB",dimnames(stf.table)$values)[1],]     <- iterQuantile(quantSums(stf@stock.n[,FcY,1] * stf@stock.wt[,FcY,1] *
                                                                 exp(-unitSums(stf@harvest[,FcY])*stf@harvest.spwn[,FcY,1]-stf@m[,FcY,1]*stf@m.spwn[,FcY,1]) *
                                                                 stf@mat[,FcY,1]))
  stf.table["nf",grep("SSB",dimnames(stf.table)$values)[2],]     <- iterQuantile(ssb.CtY)
}

### 15% increase in TAC for the A-fleet ###
if("+15%" %in% stf.options){
  #reset harvest for all fleets
  stf@harvest[,FcY] <- stf@harvest[,ImY]

  TACS[,FcY,"A"]            <- TACS.orig[,ImY,"A"]*1.15
  stf@harvest[,FcY]         <- fleet.harvest(stk=stf,iYr=FcY,TACS=TACS[,FcY])
  for(i in dms$unit){
    stf@catch.n[,FcY,i]     <- stf@stock.n[,FcY,i]*(1-exp(-unitSums(stf@harvest[,FcY])-stf@m[,FcY,i]))*(stf@harvest[,FcY,i]/(unitSums(stf@harvest[,FcY])+stf@m[,FcY,i]))
    stf@catch[,FcY,i]       <- computeCatch(stf[,FcY,i])
    stf@landings.n[,FcY,i]  <- stf@catch.n[,FcY,i]
    stf@landings[,FcY,i]    <- computeLandings(stf[,FcY,i])
  }
  #Update to continuation year
  for(i in dms$unit) stf@stock.n[1,CtY,i]                     <- RECS$CtY
  for(i in dms$unit) stf@stock.n[2:(dims(stf)$age-1),CtY,i]   <- (stf@stock.n[,FcY,1]*exp(-unitSums(stf@harvest[,FcY])-stf@m[,FcY,1]))[ac(range(stf)["min"]:(range(stf)["max"]-2)),]
  for(i in dms$unit) stf@stock.n[dims(stf)$age,CtY,i]         <- apply((stf@stock.n[,FcY,1]*exp(-unitSums(stf@harvest[,FcY])-stf@m[,FcY,1]))[ac((range(stf)["max"]-1):range(stf)["max"]),],2:6,sum,na.rm=T)
  ssb.CtY                                                     <- quantSums(stf@stock.n[,CtY,1] * stf@stock.wt[,CtY,1]*stf@mat[,CtY,1]*exp(-unitSums(stf@harvest[,FcY])*stf@harvest.spwn[,CtY,1]-stf@m[,CtY,1]*stf@m.spwn[,CtY,1])) #assume same harvest as in FcY

  stf.table["+15%","Fbar 2-6 A",]                                  <- iterQuantile(quantMeans(stf@harvest[f26,FcY,"A"]))
  stf.table["+15%",grep("Fbar 0-1 ",dimnames(stf.table)$values),]  <- aperm(iterQuantile(quantMeans(stf@harvest[f01,FcY,c("B","C","D")])),c(2:6,1))
  stf.table["+15%","Fbar 2-6",]                                    <- iterQuantile(quantMeans(unitSums(stf@harvest[f26,FcY,])))
  stf.table["+15%","Fbar 0-1",]                                    <- iterQuantile(quantMeans(unitSums(stf@harvest[f01,FcY,])))
  stf.table["+15%",grep("Catch ",dimnames(stf.table)$values),]     <- aperm(iterQuantile(harvestCatch(stf,FcY)),c(2:6,1))
  stf.table["+15%",grep("SSB",dimnames(stf.table)$values)[1],]     <- iterQuantile(quantSums(stf@stock.n[,FcY,1] * stf@stock.wt[,FcY,1] *
                                                                 exp(-unitSums(stf@harvest[,FcY])*stf@harvest.spwn[,FcY,1]-stf@m[,FcY,1]*stf@m.spwn[,FcY,1]) *
                                                                 stf@mat[,FcY,1]))
  stf.table["+15%",grep("SSB",dimnames(stf.table)$values)[2],]     <- iterQuantile(ssb.CtY)
  #TACSmp                                                           <- harvestCatch(stf,FcY)
}

### 15% reduction in TAC for the A-fleet ###
if("-15%" %in% stf.options){

  #reset harvest for all fleets
  stf@harvest[,FcY] <- stf@harvest[,ImY]

  TACS[,FcY,"A"]            <- TACS.orig[,ImY,"A"]*0.85
  stf@harvest[,FcY]         <- fleet.harvest(stk=stf,iYr=FcY,TACS=TACS[,FcY])
  for(i in dms$unit){
    stf@catch.n[,FcY,i]     <- stf@stock.n[,FcY,i]*(1-exp(-unitSums(stf@harvest[,FcY])-stf@m[,FcY,i]))*(stf@harvest[,FcY,i]/(unitSums(stf@harvest[,FcY])+stf@m[,FcY,i]))
    stf@catch[,FcY,i]       <- computeCatch(stf[,FcY,i])
    stf@landings.n[,FcY,i]  <- stf@catch.n[,FcY,i]
    stf@landings[,FcY,i]    <- computeLandings(stf[,FcY,i])
  }
  #Update to continuation year
  for(i in dms$unit) stf@stock.n[1,CtY,i]                     <- RECS$CtY
  for(i in dms$unit) stf@stock.n[2:(dims(stf)$age-1),CtY,i]   <- (stf@stock.n[,FcY,1]*exp(-unitSums(stf@harvest[,FcY])-stf@m[,FcY,1]))[ac(range(stf)["min"]:(range(stf)["max"]-2)),]
  for(i in dms$unit) stf@stock.n[dims(stf)$age,CtY,i]         <- apply((stf@stock.n[,FcY,1]*exp(-unitSums(stf@harvest[,FcY])-stf@m[,FcY,1]))[ac((range(stf)["max"]-1):range(stf)["max"]),],2:6,sum,na.rm=T)
  ssb.CtY                                                     <- quantSums(stf@stock.n[,CtY,1] * stf@stock.wt[,CtY,1]*stf@mat[,CtY,1]*exp(-unitSums(stf@harvest[,FcY])*stf@harvest.spwn[,CtY,1]-stf@m[,CtY,1]*stf@m.spwn[,CtY,1])) #assume same harvest as in FcY

  stf.table["-15%","Fbar 2-6 A",]                                  <- iterQuantile(quantMeans(stf@harvest[f26,FcY,"A"]))
  stf.table["-15%",grep("Fbar 0-1 ",dimnames(stf.table)$values),]  <- aperm(iterQuantile(quantMeans(stf@harvest[f01,FcY,c("B","C","D")])),c(2:6,1))
  stf.table["-15%","Fbar 2-6",]                                    <- iterQuantile(quantMeans(unitSums(stf@harvest[f26,FcY,])))
  stf.table["-15%","Fbar 0-1",]                                    <- iterQuantile(quantMeans(unitSums(stf@harvest[f01,FcY,])))
  stf.table["-15%",grep("Catch ",dimnames(stf.table)$values),]     <- aperm(iterQuantile(harvestCatch(stf,FcY)),c(2:6,1))
  stf.table["-15%",grep("SSB",dimnames(stf.table)$values)[1],]     <- iterQuantile(quantSums(stf@stock.n[,FcY,1] * stf@stock.wt[,FcY,1] *
                                                                 exp(-unitSums(stf@harvest[,FcY])*stf@harvest.spwn[,FcY,1]-stf@m[,FcY,1]*stf@m.spwn[,FcY,1]) *
                                                                 stf@mat[,FcY,1]))
  stf.table["-15%",grep("SSB",dimnames(stf.table)$values)[2],]     <- iterQuantile(ssb.CtY)
  #TACSmp            <- harvestCatch(stf,FcY)
}


### Same TAC for A-fleet as last year ###
if("tacro" %in% stf.options){
  #reset harvest for all fleets
  stf@harvest[,FcY] <- stf@harvest[,ImY]

  TACS[,FcY,"A"]            <- TACS.orig[,ImY,"A"]
  stf@harvest[,FcY]         <- fleet.harvest(stk=stf,iYr=FcY,TACS=TACS[,FcY])
  for(i in dms$unit){
    stf@catch.n[,FcY,i]     <- stf@stock.n[,FcY,i]*(1-exp(-unitSums(stf@harvest[,FcY])-stf@m[,FcY,i]))*(stf@harvest[,FcY,i]/(unitSums(stf@harvest[,FcY])+stf@m[,FcY,i]))
    stf@catch[,FcY,i]       <- computeCatch(stf[,FcY,i])
    stf@landings.n[,FcY,i]  <- stf@catch.n[,FcY,i]
    stf@landings[,FcY,i]    <- computeLandings(stf[,FcY,i])
  }
  #Update to continuation year
  for(i in dms$unit) stf@stock.n[1,CtY,i]                     <- RECS$CtY
  for(i in dms$unit) stf@stock.n[2:(dims(stf)$age-1),CtY,i]   <- (stf@stock.n[,FcY,1]*exp(-unitSums(stf@harvest[,FcY])-stf@m[,FcY,1]))[ac(range(stf)["min"]:(range(stf)["max"]-2)),]
  for(i in dms$unit) stf@stock.n[dims(stf)$age,CtY,i]         <- apply((stf@stock.n[,FcY,1]*exp(-unitSums(stf@harvest[,FcY])-stf@m[,FcY,1]))[ac((range(stf)["max"]-1):range(stf)["max"]),],2:6,sum,na.rm=T)
  ssb.CtY                                                     <- quantSums(stf@stock.n[,CtY,1] * stf@stock.wt[,CtY,1]*stf@mat[,CtY,1]*exp(-unitSums(stf@harvest[,FcY])*stf@harvest.spwn[,CtY,1]-stf@m[,CtY,1]*stf@m.spwn[,CtY,1])) #assume same harvest as in FcY

  stf.table["tacro","Fbar 2-6 A",]                                  <- iterQuantile(quantMeans(stf@harvest[f26,FcY,"A"]))
  stf.table["tacro",grep("Fbar 0-1 ",dimnames(stf.table)$values),]  <- aperm(iterQuantile(quantMeans(stf@harvest[f01,FcY,c("B","C","D")])),c(2:6,1))
  stf.table["tacro","Fbar 2-6",]                                    <- iterQuantile(quantMeans(unitSums(stf@harvest[f26,FcY,])))
  stf.table["tacro","Fbar 0-1",]                                    <- iterQuantile(quantMeans(unitSums(stf@harvest[f01,FcY,])))
  stf.table["tacro",grep("Catch ",dimnames(stf.table)$values),]     <- aperm(iterQuantile(harvestCatch(stf,FcY)),c(2:6,1))
  stf.table["tacro",grep("SSB",dimnames(stf.table)$values)[1],]     <- iterQuantile(quantSums(stf@stock.n[,FcY,1] * stf@stock.wt[,FcY,1] *
                                                                 exp(-unitSums(stf@harvest[,FcY])*stf@harvest.spwn[,FcY,1]-stf@m[,FcY,1]*stf@m.spwn[,FcY,1]) *
                                                                 stf@mat[,FcY,1]))
  stf.table["tacro",grep("SSB",dimnames(stf.table)$values)[2],]     <- iterQuantile(ssb.CtY)
}

### Bpa in continuation year but obeying the management plan targets ###
if("bpa" %in% stf.options){
   #reset harvest for all fleets
  stf@harvest[,FcY] <- stf@harvest[,ImY]
  TACS[,FcY]        <- TACSmp[,FcY]
  stf@harvest[,FcY] <- fleet.harvest(stf,FcY,TACS)

  res <- matrix(NA,nrow=dims(stf[,,c("A","B")])$unit,ncol=dims(stf)$iter,dimnames=list(dimnames(stf@stock.n[,,c("A","B")])$unit,dimnames(stf@stock.n)$iter))
  for(iTer in 1:dims(stf)$iter)
    res[,iTer]                  <- optim(par=rep(2,dims(stf[,,c("A","B")])$unit),find.Bpa,stk=iter(stf[,c(FcY,CtY)],iTer),rec=iter(RECS$CtY,iTer),bpa=1.3e6,fpa=0.25,
                                         f01=f01,f26=f26,method = c("L-BFGS-B"),lower=0,upper=5)$par
  stf@harvest[,CtY,c("A","B")]  <- sweep(stf@harvest[,FcY,c("A","B")],c(3,6),res,"*")
  for(i in dms$unit){
    stf@catch.n[,FcY,i]         <- stf@stock.n[,FcY,i]*(1-exp(-unitSums(stf@harvest[,FcY])-stf@m[,FcY,i]))*(stf@harvest[,FcY,i]/(unitSums(stf@harvest[,FcY])+stf@m[,FcY,i]))
    stf@catch[,FcY,i]           <- computeCatch(stf[,FcY,i])
    stf@landings.n[,FcY,i]      <- stf@catch.n[,FcY,i]
    stf@landings[,FcY,i]        <- computeLandings(stf[,FcY,i])
  }
  #Update to continuation year
  for(i in dms$unit) stf@stock.n[1,CtY,i]                     <- RECS$CtY
  for(i in dms$unit) stf@stock.n[2:(dims(stf)$age-1),CtY,i]   <- (stf@stock.n[,FcY,1]*exp(-unitSums(stf@harvest[,FcY])-stf@m[,FcY,1]))[ac(range(stf)["min"]:(range(stf)["max"]-2)),]
  for(i in dms$unit) stf@stock.n[dims(stf)$age,CtY,i]         <- apply((stf@stock.n[,FcY,1]*exp(-unitSums(stf@harvest[,FcY])-stf@m[,FcY,1]))[ac((range(stf)["max"]-1):range(stf)["max"]),],2:6,sum,na.rm=T)
  ssb.CtY                                                     <- quantSums(stf@stock.n[,CtY,1] * stf@stock.wt[,CtY,1]*stf@mat[,CtY,1]*exp(-unitSums(stf@harvest[,CtY])*stf@harvest.spwn[,CtY,1]-stf@m[,CtY,1]*stf@m.spwn[,CtY,1])) #assume same harvest as in FcY

  stf.table["bpa","Fbar 2-6 A",]                                  <- iterQuantile(quantMeans(stf@harvest[f26,FcY,"A"]))
  stf.table["bpa",grep("Fbar 0-1 ",dimnames(stf.table)$values),]  <- aperm(iterQuantile(quantMeans(stf@harvest[f01,FcY,c("B","C","D")])),c(2:6,1))
  stf.table["bpa","Fbar 2-6",]                                    <- iterQuantile(quantMeans(unitSums(stf@harvest[f26,FcY,])))
  stf.table["bpa","Fbar 0-1",]                                    <- iterQuantile(quantMeans(unitSums(stf@harvest[f01,FcY,])))
  stf.table["bpa",grep("Catch ",dimnames(stf.table)$values),]     <- aperm(iterQuantile(harvestCatch(stf,FcY)),c(2:6,1))
  stf.table["bpa",grep("SSB",dimnames(stf.table)$values)[1],]     <- iterQuantile(quantSums(stf@stock.n[,FcY,1] * stf@stock.wt[,FcY,1] *
                                                                      exp(-unitSums(stf@harvest[,FcY])*stf@harvest.spwn[,FcY,1]-stf@m[,FcY,1] *
                                                                      stf@m.spwn[,FcY,1]) * stf@mat[,FcY,1]))
  stf.table["bpa",grep("SSB",dimnames(stf.table)$values)[2],]     <- iterQuantile(ssb.CtY)
}
if("fmsy" %in% stf.options){
  stf.table["fmsy",] <- stf.table["bpa",]
}


#- Writing the STF to file
for(i in c("catch","catch.n","stock.n","harvest")){
  slot(stf,i)[,FcY] <- ""
  slot(stf,i)[,CtY] <- ""
}

options("width"=80,"scipen"=1000)
stf.out.file <- stf.out(stf,RECS,format="TABLE 2.7.%i NORTH SEA HERRING.")
write(stf.out.file,file=paste(output.base,"stf.out",sep="."))

#- Write the stf.table to file
write.table(stf.table,file=paste(output.base,"stf.table",sep="."),append=F,col.names=T,row.names=T)

#- Save the output to an RData file
save.image(file=paste(output.base,"ShortTermForecast Workspace.RData"))