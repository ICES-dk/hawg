### ============================================================================
### ============================================================================
### ============================================================================
### Setup
### ============================================================================
### ============================================================================
### ============================================================================

rm(list=ls()); graphics.off(); start.time <- proc.time()[3]
options(stringsAsFactors=FALSE)
log.msg     <-  function(string) {cat(string);}
log.msg("\nNSH Final Assessment\n=====================\n")

# local path
#path <- "D:/Repository/ICES_HAWG/wg_HAWG/NSAS/benchmark/"
path <- "D:/git/wg_HAWG/NSAS/"
try(setwd(path),silent=TRUE)

### ======================================================================================================
### Define parameters and paths for use in the assessment code
### ======================================================================================================
output.dir          <-  file.path(".","results//")        # figures directory
output.base         <-  file.path(output.dir,"NSH Assessment")  # Output base filename, including directory. Other output filenames are built by appending onto this one
n.retro.years       <-  10                                      # Number of years for which to run the retrospective
assessment_name     <- 'NSH_HAWG2018'

### ============================================================================
### imports
### ============================================================================
library(FLSAM); library(FLEDA)
source(file.path("./setupAssessmentObjects.r"))
source(file.path("./setupControlObject_sf.r"))
source(file.path("../_Common/HAWG_Common_module.r"))

### ============================================================================
### ============================================================================
### ============================================================================
### Assessment
### ============================================================================
### ============================================================================
### ============================================================================
NSH.sam               <- FLSAM(NSH,NSH.tun,NSH.ctrl)
NSH                   <- NSH + NSH.sam

save(NSH,NSH.tun,NSH.ctrl,NSH.sam,file=file.path(output.dir,paste(assessment_name,'_current.Rdata'),sep=""))

### ============================================================================
### ============================================================================
### ============================================================================
### plots
### ============================================================================
### ============================================================================
### ============================================================================

### ============================================================================
### Model fit
### ============================================================================

# figure - residual plots at each age for each time series
png(file.path(output.dir,paste(assessment_name,"_fit_diagnostics_%02d.png",sep="")),units = "px", height=800,width=672, bg = "white")
residual.diagnostics(NSH.sam)
dev.off()

windows()
# figure - assessment result, spawning stock biomass, fishing mortality, recruitment
plot(NSH.sam,futureYrs=F)
savePlot(paste(output.dir,assessment_name,"_stock_trajectory.png",sep = ""),type="png")

# figure - uncertainties as a function of time
#par(mfrow=c(1,2))
#CV.yrs <- ssb(NSH.sam)$year
#CV.dat <- cbind(SSB=ssb(NSH.sam)$CV,
#                Fbar=fbar(NSH.sam)$CV,Rec=rec(NSH.sam)$CV)
#matplot(CV.yrs,CV.dat,type="l",ylim=range(pretty(c(0,CV.dat))),yaxs="i",
#        xlab="Year",ylab="CV of estimate",main="Uncertainties of key parameters")
#grid()
#legend("topleft",legend=colnames(CV.dat),lty=1:5,col=1:6,bty="n")
#CV.yrs <- ssb(NSH.sam)$year
#CV.dat <- cbind(SSB=ssb(NSH.sam)$CV,
#                Fbar=fbar(NSH.sam)$CV,Rec=rec(NSH.sam)$CV)
#matplot(CV.yrs,CV.dat,type="l",ylim=range(pretty(c(0,CV.dat))),yaxs="i",
#        xlab="Year",ylab="CV of estimate",main="Uncertainties of key parameters")
#grid()
#legend("topleft",legend=colnames(CV.dat),lty=1:5,col=1:6,bty="n")
#CV.yrs <- ssb(NSH.sam)$year
#CV.dat <- cbind(SSB=ssb(NSH.sam)$CV,
#                Fbar=fbar(NSH.sam)$CV,Rec=rec(NSH.sam)$CV)
#matplot(CV.yrs,CV.dat,type="l",ylim=range(pretty(c(0,CV.dat))),yaxs="i",
#        xlab="Year",ylab="CV of estimate",main="Uncertainties of key parameters")
#grid()
#legend("topleft",legend=colnames(CV.dat),lty=1:5,col=1:6,bty="n")

# figure - catchabilities at age from HERAS
catch <- catchabilities(NSH.sam)
xyplot(value+ubnd+lbnd ~ age | fleet,catch,
             scale=list(alternating=FALSE,y=list(relation="free")),as.table=TRUE,
             type="l",lwd=c(2,1,1),col=c("black","grey","grey"),
             subset=fleet %in% c("HERAS"),
             main="Survey catchability parameters",ylab="Catchability",xlab="Age")

savePlot(paste(output.dir,assessment_name,"_catchability_HERAS.png",sep = ""),type="png")

# figure - variance by data source
obv <- obs.var(NSH.sam)
obv$str <- paste(obv$fleet,ifelse(is.na(obv$age),"",obv$age))
obv <- obv[order(obv$value),]
bp <- barplot(obv$value,ylab="Observation Variance",
              main="Observation variances by data source",col=factor(obv$fleet))
axis(1,at=bp,labels=obv$str,las=3,lty=0,mgp=c(0,0,0))
legend("topleft",levels(obv$fleet),pch=15,col=1:nlevels(obv$fleet),pt.cex=1.5)

savePlot(paste(output.dir,assessment_name,"_variances.png",sep = ""),type="png")

# figure - variance vs uncertainty for each data source
plot(obv$value,obv$CV,xlab="Observation variance",ylab="CV of estimate",log="x",
pch=16,col=obv$fleet,main="Observation variance vs uncertainty")
text(obv$value,obv$CV,obv$str,pos=4,cex=0.75,xpd=NA)

savePlot(paste(output.dir,assessment_name,"_CV_vs_var.png",sep = ""),type="png")

# figure - fishing age selectivity per year
sel.pat <- merge(f(NSH.sam),fbar(NSH.sam),
               by="year",suffixes=c(".f",".fbar"))
sel.pat$sel <- sel.pat$value.f/sel.pat$value.fbar
sel.pat$age <- as.numeric(as.character(sel.pat$age))
xyplot(sel ~ age|sprintf("%i's",floor((year+2)/5)*5),sel.pat,
             groups=year,type="l",as.table=TRUE,
             scale=list(alternating=FALSE),
             main="Selectivity of the Fishery by Pentad",xlab="Age",ylab="F/Fbar")

savePlot(paste(output.dir,assessment_name,"_fishing_selectivity.png",sep = ""),type="png")

# figure - correlation matrix of model parameters
cor.plot(NSH.sam)

savePlot(paste(output.dir,assessment_name,"_corr_SAM_params.png",sep = ""),type="png")

# figure - catch residuals per year per age
dat <- subset(residuals(NSH.sam),fleet=="catch unique")
xyplot(age ~ year,data=dat,cex=dat$std.res,col="black",main="Residuals by year Catch",
panel=function(...){
    lst <- list(...)
    panel.xyplot(lst$x,lst$y,pch=ifelse(lst$cex>0,1,19),col="black",cex=3*abs(lst$cex))
})

savePlot(paste(output.dir,assessment_name,"_residuals_catch.png",sep = ""),type="png")

# figure - acosutic index residuals per year per age  
dat <- subset(residuals(NSH.sam),fleet=="HERAS")
xyplot(age ~ year,data=dat,cex=dat$std.res,col="black",main="Residuals by year HERAS",
panel=function(...){
    lst <- list(...)
    panel.xyplot(lst$x,lst$y,pch=ifelse(lst$cex>0,1,19),col="black",cex=3*abs(lst$cex))
})

savePlot(paste(output.dir,assessment_name,"_residuals_HERAS.png",sep = ""),type="png")

# process error in terms of N
procerr.plot(NSH+NSH.sam,weight="stock.wt",type="n",rel=T)

savePlot(paste(output.dir,assessment_name,"_process_error_N.png",sep = ""),type="png")

# process error in terms of additional mortality
procerr.plot(NSH+NSH.sam,weight="stock.wt",type="mort",rel=F)

savePlot(paste(output.dir,assessment_name,"_process_error_M.png",sep = ""),type="png")

### ============================================================================
### time series
### ============================================================================

windows()
## === Plot the time series of weight in the stock and catch in the stock ===
# figure - times series for each age, stock
timeseries(window(NSH,1975,range(NSH)["maxyear"]),slot="stock.wt")
savePlot(paste(output.dir,assessment_name,"_time_series_stock_weight.png",sep = ""),type="png")
# figure - times series for each age, catches
timeseries(window(NSH,1975,range(NSH)["maxyear"]),slot="catch.wt")
savePlot(paste(output.dir,assessment_name,"_time_series_catch_weight.png",sep = ""),type="png")
# figure - times series for each age, harvest
timeseries(window(NSH,2000,range(NSH)["maxyear"]),slot="harvest")
savePlot(paste(output.dir,assessment_name,"_time_series_harvest.png",sep = ""),type="png")
# figure - times series for each age, maturity
timeseries(window(NSH,1990,range(NSH)["maxyear"]),slot="mat")
savePlot(paste(output.dir,assessment_name,"_time_series_mat.png",sep = ""),type="png")
## figure - times series for each age, mortality
timeseries(window(NSH,1947,range(NSH)["maxyear"]),slot="m")
savePlot(paste(output.dir,assessment_name,"_time_series_M.png",sep = ""),type="png")

# figure - internal consistency HERAS
plot(NSH.tun[["HERAS"]],type="internal")

savePlot(paste(output.dir,assessment_name,"_HERAS_consistency.png",sep = ""),type="png")

# figure - internal consistency IBTSQ3
plot(NSH.tun[["IBTS-Q3"]],type="internal")

savePlot(paste(output.dir,assessment_name,"_IBTSQ3_consistency.png",sep = ""),type="png")

# figure the overlay of tuning series - !!!!!!!!!!!!!!!! needs sorting !!!!!!!!!!!!!!
## figure - plot of time series: HERAS, IBTS0, IBTSQ1 by cohort.
#print(overlayTimeseries(lapply(NSH.tun,index),nyrs=20,ages=0:1))
## figure - plot of time series: IBTS0, IBTSQ1 by cohort.
#print(overlayTimeseries(FLQuants(IBTS0=NSH.tun[["IBTS0"]]@index,IBTSQ1=NSH.tun[["IBTS-Q1"]]@index),nyrs=20,ages=0:1))
#  
## figure - time series of all data by age
#print(surveyTimeseries(NSH.tun))

#savePlot(paste(output.dir,assessment_name,"_survey_time_series.png",sep = ""),type="png")

#figure - TACs and catches - !!!!!!!!!!!!!Need to update historic table !!!!!!!!!!!!!!!!!!!!!!
TACs          <- read.csv(file.path(".","data","historic data","TAC-historic.csv"))
TAC.plot.dat  <- data.frame(year=rep(TACs$year,each=2)+c(-0.5,0.5),TAC=rep(rowSums(TACs[,c("Agreed_A","Bycatch_B")],na.rm=T),each=2))
catch         <- as.data.frame(NSH@catch[,ac(TACs$year)]/1e3)
plot(0,0,pch=NA,xlab="Year",ylab="Catch",xlim=range(c(catch$year,TAC.plot.dat$year)),ylim=range(c(0,TAC.plot.dat$TAC,catch$data)),cex.lab=1.2,cex.axis=1.1,font=2)
rect(catch$year-0.5,0,catch$year+0.5,catch$data,col="grey")
lines(TAC.plot.dat,lwd=3)
legend("topright",legend=c("Catch","TAC"),lwd=c(1,5),lty=c(NA,1),pch=c(22,NA),col="black",pt.bg="grey",pt.cex=c(2),box.lty=0)
box()
title(main=paste(NSH@name,"Catch and TAC"))

savePlot(paste(output.dir,assessment_name,"_TAC_catch.png",sep = ""),type="png")

## === Plot the proportion of different quantities at age ===

# figure - catch number at age
stacked.area.plot(data~year| unit, as.data.frame(pay(NSH@catch.n)),groups="age",main="Proportion of Catch numbers at age",ylim=c(-0.01,1.01),xlab="years",col=gray(9:0/9))

savePlot(paste(output.dir,assessment_name,"_prop_catch.png",sep = ""),type="png")

# figure - proportion of stock weight at age
stacked.area.plot(data~year| unit, as.data.frame(pay(NSH@stock.wt)),groups="age",main="Proportion of Stock weight at age",ylim=c(-0.01,1.01),xlab="years",col=gray(9:0/9))

savePlot(paste(output.dir,assessment_name,"_prop_stock_weight.png",sep = ""),type="png")

# figure - proportion of catch weight at age
stacked.area.plot(data~year| unit, as.data.frame(pay(NSH@catch.wt)),groups="age",main="Proportion of Catch weight at age",ylim=c(-0.01,1.01),xlab="years",col=gray(9:0/9))

savePlot(paste(output.dir,assessment_name,"_prop_catch_weight.png",sep = ""),type="png")

## figure - acoustic index at age
stacked.area.plot(data~year| unit, as.data.frame(pay(NSH.tun[["HERAS"]]@index)),groups="age",main="Proportion of Acoustic index at age",ylim=c(-0.01,1.01),xlab="years",col=gray(9:0/9))

savePlot(paste(output.dir,assessment_name,"_prop_acoustic_index.png",sep = ""),type="png")

# figure - proportion of natural mortality at age
stacked.area.plot(data~year| unit, as.data.frame(pay(NSH@m)),groups="age",main="Proportion of natural mortality at age",ylim=c(-0.01,1.01),xlab="years",col=gray(9:0/9))

savePlot(paste(output.dir,assessment_name,"_prop_nat_mort.png",sep = ""),type="png")

### ============================================================================
### miscellaneous
### ============================================================================

# figure - otholith. Warning, this takes very long!
otolith(NSH.sam,n=1000)

savePlot(paste(output.dir,assessment_name,"_otolith.png",sep = ""),type="png")

# kobe plot. !!!!!!!!!!!!!!kobe package not available for R 3.4.3!!!!!!!!!!!!!!!
#plot.kobe(NSH.sam,fmsy=0.31,bmsy=1.5e6)

#savePlot(paste(output.dir,assessment_name,"_kobe.png",sep = ""),type="png")

# mohns rho. Needs long retro
#plot(mean(mohns.rho(NSH.retro,ref.year=2016,span=7,type="fbar")[1:7,1]),ylab="Mohns rho",xlab="")

#savePlot(paste(output.dir,assessment_name,"_mohns_rho_retro.png",sep = ""),type="png")

#### ============================================================================
#### Management
#### ============================================================================
#
## figure - fishing mortality vs SSB, management plan
plot(x=c(0,0.8,1.5,2.6),y=c(0.1,0.1,0.26,0.26),type="l",ylim=c(0,0.4),lwd=2,xlab="SSB in million tonnes",ylab="Fbar",cex.lab=1.3,main="Management plan North Sea Herring")
abline(v=0.8,col="red",lwd=2,lty=2)
abline(v=1.0,col="blue",lwd=2,lty=2)
abline(v=1.5,col="darkgreen",lwd=2,lty=2)
text(0.8,0,labels=expression(B[lim]),col="red",cex=1.3,pos=2)
text(1.0,0,labels=expression(B[pa]),col="blue",cex=1.3,pos=2)
text(1.5,0,labels=expression(B[trigger]),col="darkgreen",cex=1.3,pos=4)

points(y=fbar(NSH[,ac(2005:2017)]), x=(ssb(NSH[,ac(2005:2017)])/1e6),pch=19)
lines(y=fbar(NSH[,ac(2005:2017)]),  x=(ssb(NSH[,ac(2005:2017)])/1e6))
text(y=fbar(NSH[,ac(2005:2017)]),   x=(ssb(NSH[,ac(2005:2017)])/1e6),labels=ac(2005:2017),pos=3,cex=0.7)

savePlot(paste(output.dir,assessment_name,"_management_plan.png",sep = ""),type="png")

### ============================================================================
### ============================================================================
### ============================================================================
### Document Assessment
### ============================================================================
### ============================================================================
### ============================================================================
#
#log.msg("GENERATING DOCUMENTATION...\n")
##Document the run with alternative table numbering and a reduced width
old.opt           <- options("width","scipen")
options("width"=75,"scipen"=1000)
#
##2013 fix
NSH.sam@control@sam.binary <- "character()"
sam.out.file      <- FLSAM.out(NSH,NSH.tun,NSH.sam,format="TABLE 2.6.3.%i North Sea Herring.")
write(sam.out.file,file=paste(output.base,"sam.out",sep="."))
options("width"=old.opt$width,"scipen"=old.opt$scipen)
#
##And finally, write the results out in the lowestoft VPA format for further analysis
writeFLStock(NSH,output.file=file.path(output.dir,"NSAS_47d3_"))
writeFLStock(NSH,file.path(output.dir,"hawg_her-47d3.ypr"),type="YPR")
writeFLStock(wbss,file.path(output.dir,"hawg_her-IIIa.ypr"),type="YPR")
##Prepare standard graph table
#NSH.brp <- brp(FLBRP(NSH,sr=NSH.SRR,fbar=seq(0,1,length.out=100),refpts=refpts()))
## Calculate the spawners in number
#spawners                          <- colSums(NSH.brp@stock.n * sweep(exp(sweep(-sweep(NSH.brp@harvest,c(1,3:6),NSH.brp@harvest.spwn,"*"),
#                                             c(1,3:6),NSH.brp@m*NSH.brp@m.spwn,"-")),c(1,3:6),NSH.brp@mat,"*"))
## Put all the standard input in a dataframe in columns
#standardGraphTable                <- cbind(NSH.brp@fbar,yield(NSH.brp),ssb(NSH.brp),rec(NSH.brp),yield(NSH.brp)/rec(NSH.brp),
#                                           ssb(NSH.brp)/rec(NSH.brp),spawners,landings(NSH.brp))
#standardGraphTable                <- data.frame(standardGraphTable)
#colnames(standardGraphTable)      <- c("Fbar","Yield","SSB","Recruits","Yield.Recruit","SSB.Recruit","Spawners","Landings")
## Round some values
#standardGraphTable$Fbar           <- round(an(ac(standardGraphTable$Fbar)),3)
#standardGraphTable$Yield          <- round(an(ac(standardGraphTable$Yield)))
#standardGraphTable$SSB            <- round(an(ac(standardGraphTable$SSB)))
#standardGraphTable$Recruits       <- round(an(ac(standardGraphTable$Recruits)))
#standardGraphTable$Yield.Recruit  <- round(an(ac(standardGraphTable$Yield.Recruit)),4)
#standardGraphTable$SSB.Recruit    <- round(an(ac(standardGraphTable$SSB.Recruit)),3)
#standardGraphTable$Spawners       <- round(an(ac(standardGraphTable$Spawners)))
#standardGraphTable$Landings       <- round(an(ac(standardGraphTable$Landings)))
#standardGraphTable                <- rbind(c(paste("Ages ",range(stck.)["minfbar"],"-",range(stck.)["maxfbar"],sep=""),
#                                           "Tonnes","Tonnes","Number","","","Number","Tonnes"),standardGraphTable)
## Write the standard graph to file and the reference points as well
#write.table(standardGraphTable,file=file.path(output.dir,"standardGraphTable.csv"),col.names=T,row.names=F,sep=",")
#
stockSummaryTable <- cbind(rec(NSH.sam)$year,
                           rec(NSH.sam)$value,      rec(NSH.sam)$lbnd,    rec(NSH.sam)$ubnd,
                           tsb(NSH.sam)$value,      tsb(NSH.sam)$lbnd,    tsb(NSH.sam)$ubnd,
                           ssb(NSH.sam)$value,      ssb(NSH.sam)$lbnd,    ssb(NSH.sam)$ubnd,
                           catch(NSH.sam)$value,    catch(NSH.sam)$lbnd,  catch(NSH.sam)$ubnd,
                           catch(NSH.sam)$value / ssb(NSH.sam)$value, catch(NSH.sam)$lbnd / ssb(NSH.sam)$lbnd, catch(NSH.sam)$ubnd / ssb(NSH.sam)$ubnd,
                           fbar(NSH.sam)$value,     fbar(NSH.sam)$lbnd,   fbar(NSH.sam)$ubnd,
                           c(quantMeans(harvest(NSH.sam)[ac(0:1),])),
                           c(sop(NSH),NA),
                           c(catch(NSH),NA))
colnames(stockSummaryTable) <-
                     c("Year",paste(rep(c("Recruits Age 0 (Thousands)","Total biomass (tonnes)","Spawing biomass (tonnes)",
                       "Landings (tonnes)","Yield / SSB (ratio)","Mean F ages 2-6"),each=3),c("Mean","Low","High")),"Mean F ages 0-1","SoP (%)","WG Catch")
stockSummaryTable[nrow(stockSummaryTable),] <- NA
stockSummaryTable[nrow(stockSummaryTable),"Spawing biomass (tonnes) Mean"] <- 2271364
stockSummaryTable[nrow(stockSummaryTable),2:4] <- c(rec(NSH.sam)$value[nrow(rec(NSH.sam))],rec(NSH.sam)$lbnd[nrow(rec(NSH.sam))],rec(NSH.sam)$ubnd[nrow(rec(NSH.sam))])
write.csv(stockSummaryTable,file=file.path(output.dir,paste(name(NSH),"stockSummaryTable.csv",sep="_")))
options("width"=old.opt$width,"scipen"=old.opt$scipen)

### ============================================================================
### Finish
### ============================================================================
log.msg(paste("COMPLETE IN",sprintf("%0.1f",round(proc.time()[3]-start.time,1)),"s.\n\n"))

### ============================================================================
### ============================================================================
### ============================================================================
### run retrospective - takes time!!
### ============================================================================
### ============================================================================
### ============================================================================

### ============================================================================
### run retrospective
### ============================================================================

# Run retrospective, turn residuals off as it takes a long time
NSH.ctrl@residuals    <- FALSE
NSH.retro             <- retro(NSH,NSH.tun,NSH.ctrl,n.retro.years)

#mean(mohns.rho(NSH.retro,ref.year=2017,span=6,type="fbar")[1:6,1]) #-8.4
#mean(mohns.rho(NSH.retro,ref.year=2017,span=6,type="ssb")[1:6,1]) #10.1
#mean(mohns.rho(NSH.retro,ref.year=2017,span=6,type="rec")[1:6,1]) #17.5

save(NSH.retro,file=file.path(output.dir,paste(assessment_name,'_current.Rdata',sep=""),sep=""))

### ============================================================================
### figures
### ============================================================================
windows()
#Setup plots
# stock trajectory retrospective
plot(NSH.retro)

savePlot(paste(output.dir,assessment_name,"_stock_trajectory_retro.png",sep = ""),type="png")

# model parameters retrospective
retroParams(NSH.retro)

savePlot(paste(output.dir,assessment_name,"_SAM_params_retro.png",sep = ""),type="png")

# stock trajectory retrospective
retroSelectivity(NSH.retro,2009:2017)

savePlot(paste(output.dir,assessment_name,"_sel_retro.png",sep = ""),type="png")

# LAI components retrospective

windows()
yearListRetro <- names(NSH.retro)

idxyear <- 1

NSH_components  <- t(components(NSH.retro[[idxyear]]))
NSH_residuals   <- residuals(NSH.retro[[idxyear]])
LAI_BUN_residuals   <- subset(NSH_residuals, fleet == 'LAI-BUN')
LAI_CNS_residuals   <- subset(NSH_residuals, fleet == 'LAI-CNS')
LAI_ORSH_residuals   <- subset(NSH_residuals, fleet == 'LAI-ORSH')
LAI_SNS_residuals   <- subset(NSH_residuals, fleet == 'LAI-SNS')

yearList            <- data.frame(as.numeric(row.names(NSH_components)))
names(yearList)     <- 'year'
LAI_data <- c(NSH_components[,1], NSH_components[,2], NSH_components[,3], NSH_components[,4])
LAI_names <- c(rep('LAI_ORSH',dim(NSH_components)[1]), rep('LAI_CNS',dim(NSH_components)[1]), rep('LAI_BUN',dim(NSH_components)[1]), rep('LAI_SNS',dim(NSH_components)[1]))
LAI_years <- c(yearList$year, yearList$year, yearList$year, yearList$year)
NSH_components <- as.data.frame(t(rbind(LAI_years,LAI_names,LAI_data)))

NSH_components[,1] <- as.numeric(NSH_components[,1])
NSH_components[,3] <- as.numeric(NSH_components[,3])

NSH_components <- NSH_components[NSH_components$LAI_names == 'LAI_ORSH',]
#a <- NSH_components[NSH_components$LAI_names == 'LAI_ORSH',]

g <- ggplot(NSH_components, aes(x= LAI_years, y = LAI_data, colour = LAI_names)) + geom_line() + ylab("index") + xlab("years")


#subset(NSH_temp,)

st.names <- c("HAWG2017","SMS2017","HAWG2017 profiled","SMS2017 profiled")
#st.names <- c("0_basecase","2_newM","2_newM","2_newM")
names(M) <- st.names
#names(M) <- c("HAWG_2016","SMS_2017","SMS_2017_profiling","SMS_2017_profiling")#st.names#c("HAWG 2016", "SMS 2017", "SMS 2017 profiling", "SMS 2017 profiling")#st.names
ggplot(M , aes (x =year ,y =data  , colour = qname)) + geom_line() + facet_wrap(~age) + ylab("M") + xlab("year") + theme(legend.position="bottom") + scale_colour_discrete(name = "")

windows()
yearListRetro <- names(NSH.retro)

# LAI_ORSH
a <- list()
for(idxyear in 1:length(yearListRetro)){
  
  NSH_components  <- t(components(NSH.retro[[idxyear]]))
  NSH_residuals   <- residuals(NSH.retro[[idxyear]])
  LAI_BUN_residuals   <- subset(NSH_residuals, fleet == 'LAI-BUN')
  LAI_CNS_residuals   <- subset(NSH_residuals, fleet == 'LAI-CNS')
  LAI_ORSH_residuals   <- subset(NSH_residuals, fleet == 'LAI-ORSH')
  LAI_SNS_residuals   <- subset(NSH_residuals, fleet == 'LAI-SNS')
  
  yearList            <- data.frame(as.numeric(row.names(NSH_components)))
  names(yearList)     <- 'year'
  LAI_data <- c(NSH_components[,1], NSH_components[,2], NSH_components[,3], NSH_components[,4])
  LAI_names <- c(rep('LAI_ORSH',dim(NSH_components)[1]), rep('LAI_CNS',dim(NSH_components)[1]), rep('LAI_BUN',dim(NSH_components)[1]), rep('LAI_SNS',dim(NSH_components)[1]))
  LAI_years <- c(yearList$year, yearList$year, yearList$year, yearList$year)
  NSH_components <- as.data.frame(t(rbind(LAI_years,LAI_names,LAI_data)))
  
  NSH_components[,1] <- as.numeric(NSH_components[,1])
  NSH_components[,3] <- as.numeric(NSH_components[,3])
  
  NSH_components_new <- NSH_components[NSH_components$LAI_names == 'LAI_ORSH',]
  NSH_components_new[,4] <- rep(toString(max(NSH_components_new[,1])),length(NSH_components_new[,1]))
  names(NSH_components_new)[4] <- 'year_retro'
  #a <- NSH_components[NSH_components$LAI_names == 'LAI_ORSH',]
  
  a <- rbind(a,NSH_components_new)
  
  #g <- g + geom_line(data=NSH_components, aes(x= LAI_years, y = LAI_data, colour = LAI_names))# + geom_line() + ylab("index") + xlab("years")
}

ggplot(a, aes(x= LAI_years, y = LAI_data, colour = year_retro)) + geom_line() + ylab("index") + xlab("years") + ggtitle('Orkney/Shetland')

savePlot(paste(output.dir,assessment_name,"_LAI_ORSH_retro.png",sep = ""),type="png")

# LAI_CNS
a <- list()
for(idxyear in 1:length(yearListRetro)){
  
  NSH_components  <- t(components(NSH.retro[[idxyear]]))
  NSH_residuals   <- residuals(NSH.retro[[idxyear]])
  LAI_BUN_residuals   <- subset(NSH_residuals, fleet == 'LAI-BUN')
  LAI_CNS_residuals   <- subset(NSH_residuals, fleet == 'LAI-CNS')
  LAI_ORSH_residuals   <- subset(NSH_residuals, fleet == 'LAI-ORSH')
  LAI_SNS_residuals   <- subset(NSH_residuals, fleet == 'LAI-SNS')
  
  yearList            <- data.frame(as.numeric(row.names(NSH_components)))
  names(yearList)     <- 'year'
  LAI_data <- c(NSH_components[,1], NSH_components[,2], NSH_components[,3], NSH_components[,4])
  LAI_names <- c(rep('LAI_ORSH',dim(NSH_components)[1]), rep('LAI_CNS',dim(NSH_components)[1]), rep('LAI_BUN',dim(NSH_components)[1]), rep('LAI_SNS',dim(NSH_components)[1]))
  LAI_years <- c(yearList$year, yearList$year, yearList$year, yearList$year)
  NSH_components <- as.data.frame(t(rbind(LAI_years,LAI_names,LAI_data)))
  
  NSH_components[,1] <- as.numeric(NSH_components[,1])
  NSH_components[,3] <- as.numeric(NSH_components[,3])
  
  NSH_components_new <- NSH_components[NSH_components$LAI_names == 'LAI_CNS',]
  NSH_components_new[,4] <- rep(toString(max(NSH_components_new[,1])),length(NSH_components_new[,1]))
  names(NSH_components_new)[4] <- 'year_retro'
  
  a <- rbind(a,NSH_components_new)
}

ggplot(a, aes(x= LAI_years, y = LAI_data, colour = year_retro)) + geom_line() + ylab("index") + xlab("years") + ggtitle('Banks')

savePlot(paste(output.dir,assessment_name,"_LAI_CNS_retro.png",sep = ""),type="png")

# LAI_BUN
a <- list()
for(idxyear in 1:length(yearListRetro)){
  
  NSH_components  <- t(components(NSH.retro[[idxyear]]))
  NSH_residuals   <- residuals(NSH.retro[[idxyear]])
  LAI_BUN_residuals   <- subset(NSH_residuals, fleet == 'LAI-BUN')
  LAI_CNS_residuals   <- subset(NSH_residuals, fleet == 'LAI-CNS')
  LAI_ORSH_residuals   <- subset(NSH_residuals, fleet == 'LAI-ORSH')
  LAI_SNS_residuals   <- subset(NSH_residuals, fleet == 'LAI-SNS')
  
  yearList            <- data.frame(as.numeric(row.names(NSH_components)))
  names(yearList)     <- 'year'
  LAI_data <- c(NSH_components[,1], NSH_components[,2], NSH_components[,3], NSH_components[,4])
  LAI_names <- c(rep('LAI_ORSH',dim(NSH_components)[1]), rep('LAI_CNS',dim(NSH_components)[1]), rep('LAI_BUN',dim(NSH_components)[1]), rep('LAI_SNS',dim(NSH_components)[1]))
  LAI_years <- c(yearList$year, yearList$year, yearList$year, yearList$year)
  NSH_components <- as.data.frame(t(rbind(LAI_years,LAI_names,LAI_data)))
  
  NSH_components[,1] <- as.numeric(NSH_components[,1])
  NSH_components[,3] <- as.numeric(NSH_components[,3])
  
  NSH_components_new <- NSH_components[NSH_components$LAI_names == 'LAI_BUN',]
  NSH_components_new[,4] <- rep(toString(max(NSH_components_new[,1])),length(NSH_components_new[,1]))
  names(NSH_components_new)[4] <- 'year_retro'
  
  a <- rbind(a,NSH_components_new)
}

ggplot(a, aes(x= LAI_years, y = LAI_data, colour = year_retro)) + geom_line() + ylab("index") + xlab("years") + ggtitle('Buchan')

savePlot(paste(output.dir,assessment_name,"_LAI_BUN_retro.png",sep = ""),type="png")

# LAI_SNS
a <- list()
for(idxyear in 1:length(yearListRetro)){
  
  NSH_components  <- t(components(NSH.retro[[idxyear]]))
  NSH_residuals   <- residuals(NSH.retro[[idxyear]])
  LAI_BUN_residuals   <- subset(NSH_residuals, fleet == 'LAI-BUN')
  LAI_CNS_residuals   <- subset(NSH_residuals, fleet == 'LAI-CNS')
  LAI_ORSH_residuals   <- subset(NSH_residuals, fleet == 'LAI-ORSH')
  LAI_SNS_residuals   <- subset(NSH_residuals, fleet == 'LAI-SNS')
  
  yearList            <- data.frame(as.numeric(row.names(NSH_components)))
  names(yearList)     <- 'year'
  LAI_data <- c(NSH_components[,1], NSH_components[,2], NSH_components[,3], NSH_components[,4])
  LAI_names <- c(rep('LAI_ORSH',dim(NSH_components)[1]), rep('LAI_CNS',dim(NSH_components)[1]), rep('LAI_BUN',dim(NSH_components)[1]), rep('LAI_SNS',dim(NSH_components)[1]))
  LAI_years <- c(yearList$year, yearList$year, yearList$year, yearList$year)
  NSH_components <- as.data.frame(t(rbind(LAI_years,LAI_names,LAI_data)))
  
  NSH_components[,1] <- as.numeric(NSH_components[,1])
  NSH_components[,3] <- as.numeric(NSH_components[,3])
  
  NSH_components_new <- NSH_components[NSH_components$LAI_names == 'LAI_SNS',]
  NSH_components_new[,4] <- rep(toString(max(NSH_components_new[,1])),length(NSH_components_new[,1]))
  names(NSH_components_new)[4] <- 'year_retro'
  
  a <- rbind(a,NSH_components_new)
}

ggplot(a, aes(x= LAI_years, y = LAI_data, colour = year_retro)) + geom_line() + ylab("index") + xlab("years") + ggtitle('Downs')

savePlot(paste(output.dir,assessment_name,"_LAI_SNS_retro.png",sep = ""),type="png")