# ==============================================================================
# Reference points estimation
# North Sea herring; final assessment at benchmark meeting 2018
# Sensititivity analysis
#
# Uses: R 3.4.3
#       FLCore 2.6.5
#       msy 0.1.18
#
# Changed: 16/2/2018 Martin Pastoors
# ==============================================================================

rm(list=ls())

# ***follow the order of loading (1) FLCore and (2) msy
# as SR fuctions have same name but different formulation

# library(devtools)
# install_github("ices-tools-prod/msy")

library(FLCore)
library(FLSAM)
library(msy)       
library(tidyverse)

try(setwd("D:/git/wg_HAWG/NSAS/benchmark/R/7_finalModel/refPoints"),silent=FALSE)


source("Refpoints functions.R")
source("D:/GIT/wg_HAWG/_Common/eqsr_fit_shift.R")

load("D:/WKPELA/06. Data/NSAS/SAM/NSH_final.RData")
NSHbench <- NSH


# -------------------------------------------------------------------------------
# This is for evaluting uncertainty in Fmsy depending on length of time series
# -------------------------------------------------------------------------------

runsFmsy <- list(
  run1=list(srryears=c(1994:2016),  bioyears=c(2007:2016), models=c("Bevholt","Ricker")),
  run2=list(srryears=c(1996:2016),  bioyears=c(2007:2016), models=c("Bevholt","Ricker")),
  run3=list(srryears=c(1998:2016),  bioyears=c(2007:2016), models=c("Bevholt","Ricker")),
  run4=list(srryears=c(2000:2016),  bioyears=c(2007:2016), models=c("Bevholt","Ricker")),
  run5=list(srryears=c(2001:2016),  bioyears=c(2007:2016), models=c("Bevholt","Ricker")),
  run6=list(srryears=c(2002:2016),  bioyears=c(2007:2016), models=c("Bevholt","Ricker")),
  run7=list(srryears=c(2004:2016),  bioyears=c(2007:2016), models=c("Bevholt","Ricker")),
  run8=list(srryears=c(2006:2016),  bioyears=c(2007:2016), models=c("Bevholt","Ricker"))
)

FITMSY <- list()
SIMMSY <- list()

i <- 8

for(i in 1:length(runsFmsy)){
  print(i)
  title   <- names(runsFmsy)[i]; 
  run     <- title
  OBJ     <- trim(NSH, year=runsFmsy[[i]]$srryears)
  
  FITMSY[[i]]  <- eqsr_fit_shift(OBJ, 
                                 nsamp        = 2000,   
                                 rshift       = 1, 
                                 models       = runsFmsy[[i]]$models
                                 )
  
  # write out the SR data to text file
  # sink(paste(run," SRR ",title,".txt",sep="")); FITMSY[i]$sr.det; sink()

  # write out SRR plot
  # png(paste(run," SRR ",title," gg.png",sep=""), width=1500, height=1500, res=200, bg="white"); 
  # eqsr_plot(FITMSY[[i]],n=2e4, ggPlot=TRUE); 
  # dev.off()
  
  SIMMSY[[i]] <- eqsim_run(
    FITMSY[[i]],
    bio.years = runsFmsy[[i]]$bioyears,
    bio.const = FALSE,
    sel.years = runsFmsy[[i]]$bioyears,
    sel.const = FALSE,
    recruitment.trim = c(3, -3),
    Fcv       = 0.27,
    Fphi      = 0.51,
    Blim      = 800000,
    Bpa       = 1000000,
    #  Btrigger  = 1500000,
    Fscan     = seq(0,0.80,len=40),
    verbose   = TRUE,
    extreme.trim=c(0.01,0.99))
  
  # Save the MSY intervals as text file
  # sink(paste(run," MSY ",title,".txt",sep="")); MSY_Intervals(SIMMSY[[i]]); sink()
  # MSY_Intervals(SIMMSY[[i]]); 
  
  # Save the MSY simulation results
  # sink(paste(run," SIM ",title,".txt",sep="")); SIMMSY[[i]]; sink()
  # SIMMSY[[i]];
  
  # png(paste(run," MSY ",title,".png",sep=""), width=1500, height=1500, res=200, bg="white")
  # eqsim_plot(SIMMSY[[i]],catch=TRUE); 
  # dev.off()
  
  fmsy <- round(t(SIMMSY[[i]]$Refs2)["medianMSY","lanF"],3)
  
  print(paste0(i,
               ", SRR years:", min(runsFmsy[[i]]$srryears), "-", max(runsFmsy[[i]]$srryears), 
               ", Bio years:", min(runsFmsy[[i]]$bioyears), "-", max(runsFmsy[[i]]$bioyears),
               ", Models:", paste(runsFmsy[[i]]$models, collapse=" "),
               ", Fmsy = ", fmsy,
               sep="") )
  

}


# save(FITLIM,SIMLIM,file=paste("./simulation_",title,".RData",sep=""))




lsf.str("package:msy")
LLplot(FITMSY[[6]])

round(t(SIMMSY[[5]]$Refs2)["medianMSY","lanF"],6)
round(t(SIMMSY[[6]]$Refs2)["medianMSY","lanF"],6)
summary(OBJ)

for(i in 1:length(runsFmsy)){
  # MSY_Intervals(SIMMSY[[i]])
  print(SIMMSY[[i]]$Refs2[2,4])
}
