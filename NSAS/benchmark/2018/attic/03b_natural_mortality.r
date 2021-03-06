################################################################################
# NSH_SAM Natural mortality
#
# $Rev$
# $Date$
#
# Author: HAWG model devlopment group
#
# Examines the effect of introducing a variable natural mortality
#
# Developed with:
#   - R version 2.13.0
#   - FLCore 2.4
#
# To be done:
#
# Notes: Have fun running this assessment!
#
################################################################################

### ============================================================================
### Initialise system, including convenience functions and title display
### ============================================================================
rm(list=ls()); graphics.off(); start.time <- proc.time()[3]
options(stringsAsFactors=FALSE)
log.msg     <-  function(string) {
	cat(string);flush.console()
}
log.msg("\nNSH SAM Natural Mortality\n================================\n")

### ============================================================================
### Setup assessment
### ============================================================================
#Somewhere to store results
resdir <- file.path("benchmark","resultsSAM")
respref <- "03b_natural_mortality" #Prefix for output files
resfile <- file.path(resdir,paste(respref,".RData",sep=""))

#Dependencies
all.in.file <- file.path(resdir,"03a_selected_surveys.RData")
if(!file.exists(all.in.file)) {
  stop(paste("Cannot find dependency",all.in.file,
      "Please run appropriate script to generate this file"))
} 

#Import externals
library(FLSAM)
source(file.path("benchmark","Setup_objects.r"))
SCAI.sam <- local({load(all.in.file);return(NSH.sam)})
SCAI.sam@name <- "SCAI"

#Set surveys aside
NSH.tun.all <- NSH.tun

### ============================================================================
### Run the assessment with variable natural mortality and fixed natural mortality
### ============================================================================
#Only do the assessment if we are running in batch mode, or
#if the results file is missing
if(!file.exists(resfile) | !interactive()) {
   #First run with variable natural mortality
   source(file.path("benchmark","03_Setup_selected_surveys.r"))
   variable.sam <- FLSAM(NSH,NSH.tun,NSH.ctrl)
   variable.sam@name <- "Variable M"
   
   #fix natural mortality
   NSH@m[]   <- c(1,1,0.3,0.2,rep(0.1,6))
   source(file.path("benchmark","03_Setup_selected_surveys.r"))
   fixed.sam <- FLSAM(NSH,NSH.tun,NSH.ctrl)
   fixed.sam@name <- "Fixed M"
   
   #Combine into one
   M.variations <- FLSAMs(variable.sam,fixed.sam)
   names(M.variations) <- sapply(M.variations,name)
   
   #Save any results
   save(NSH,NSH.tun.all,NSH.ctrl,M.variations,file=resfile)
} else {
  #Load the file
  load(resfile)
}

### ============================================================================
### Plots
### ============================================================================
#Setup plots
pdf(file.path(resdir,paste(respref,".pdf",sep="")),pointsize=16)

#Comparison of assessments with different plus groups
plot(M.variations,main="Effects of variable natural mortality")
plot(M.variations,xlim=c(1990,2011),
    main="Effects of variable vs. fixed natural mortality")

#total mortality
source(file.path("benchmark","Setup_objects.r"))
mortsVariable <- cbind(as.data.frame(NSH@m + (NSH+M.variations[[1]])@harvest),type="Variable")
  NSH@m[]     <- c(1,1,0.3,0.2,rep(0.1,6))
mortsFixed    <- cbind(as.data.frame(NSH@m + (NSH+M.variations[[2]])@harvest),type="Fixed")
morts         <- rbind(mortsVariable,mortsFixed)
print(xyplot(data ~ year|as.factor(age),data=morts,type="l",groups=type,ylab="total mortality",main="Total mortality by age",auto.key=T))

#Comparison of weightings
obvs <- obs.var(M.variations)
obvs$str <- paste(obvs$fleet,ifelse(is.na(obvs$age),"",obvs$age))
obvs.stack <- unstack(obvs,value ~ str)
barplot(as.matrix(obvs.stack),beside=TRUE,las=3,
   legend=unique(obvs$name),col=c("red","black"),
   args.legend=list(x="topleft"),
   main="Variable vs fixed natural mortality",
   ylab="Observation variance")


#Plot diagnostics of both runs
residual.diagnostics(M.variations[["Variable M"]])
residual.diagnostics(M.variations[["Fixed M"]])



### ============================================================================
### Finish
### ============================================================================
dev.off()
log.msg(paste("COMPLETE IN",sprintf("%0.1f",round(proc.time()[3]-start.time,1)),"s.\n\n"))
