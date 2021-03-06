################################################################################
# Scan Catch bindings
#
# $Rev$
# $Date$
#
# Author: HAWG model devlopment group
#
# The FLSAM model has the ability to bind the observation variances (weightings)
# and catchabilities of age groups together, effectively using one parameter 
# for many age groups. 
# The appropriate bindings can be identified by performing a series of assessments 
# for each combination and then comparing the results using AIC / LR tests.
#
# Developed with:
#   - R version 2.13.2
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
log.msg("\nNSH SAM Catch states     \n===========================\n")

### ============================================================================
### Setup assessment
### ============================================================================
#Scanning parameters
scan.surv <- "catch"
scan.slot <- "states"

#Somewhere to store results
resdir <- file.path("benchmark","resultsSAM")
respref <- sprintf("04b_%s_%s",scan.surv,scan.slot) #Prefix for output files
resfile <- file.path(resdir,paste(respref,".RData",sep=""))

#Import externals
library(FLSAM)
source(file.path("benchmark","Setup_objects.r"))
source(file.path("benchmark","04_Setup_refined_data.r"))

### ============================================================================
### Setup control objects
### ============================================================================
#Setup defaults
NSH.ctrl@timeout <- 2700  #Lets not mess around here 
ctrls <- list()

#Setup bindings "7+" is the default
binding.list <- list()
for(i in 2:7) {
   base <- slot(NSH.ctrl,scan.slot)[scan.surv,]
   base[] <- 1:9
   base[ac(i:8)] <- 100
   binding.list[[sprintf("%i8",i)]] <- base  
}
binding.list[["01,78"]] <- c(100,100,102,103,104,105,106,107,107)
binding.list[["02,78"]] <- c(100,100,100,103,104,105,106,107,107)
binding.list[["01,38"]] <- c(100,100,102,103,103,103,103,103,103)
binding.list[["34,58"]] <- c(100,101,102,103,103,105,105,105,105)

#Convert bindings to ctrl objects
for(bnd.name in names(binding.list)) {
   ctrl.obj <- NSH.ctrl
   ctrl.obj@name <- bnd.name
   ctrl.obj@desc <- paste(scan.surv,scan.slot,bnd.name)
   bindings <- binding.list[[bnd.name]]
   slot(ctrl.obj,scan.slot)[scan.surv,] <- bindings
   ctrls[[ctrl.obj@name]] <- update(ctrl.obj)
}

#Update and finish control objects
ctrls <- c(ctrls,NSH.ctrl)
ctrls <- lapply(ctrls,update)
names(ctrls) <- lapply(ctrls,function(x) x@name)

### ============================================================================
### Run the assessments
### ============================================================================
#Only do the assessment if we are running in batch mode, or
#if the results file is missing
if(!file.exists(resfile) | !interactive()) {
   #Perform assessment
   ass.res <- lapply(ctrls,FLSAM,stck=NSH,tun=NSH.tun,batch.mode=TRUE)
  
   #Drop any that failed to converge, then create an FLSAMs object
   scan.sams <- FLSAMs(ass.res[!sapply(ass.res,is.null)]); 

   #Save results
   save(NSH,NSH.tun,scan.sams,file=resfile)

} else {
  #Load the file
  load(resfile)
}
scan.sams <- scan.sams[-10]
### ============================================================================
### Outputs
### ============================================================================
pdf(file.path(resdir,paste(respref,".pdf",sep="")),pointsize=16)
#Plot AICs
scan.AICs  <- AIC(scan.sams)
plot(scan.AICs,main=sprintf("%s %s scan",scan.surv,scan.slot),
   ylab="AIC",xaxt="n",xlab="Model",pch=16)
axis(1,labels=names(scan.AICs),at=seq(scan.AICs),las=3)

#Plot all assessments on one plot
print(plot(scan.sams,main=sprintf("%s %s scan",scan.surv,scan.slot)))

#Write likelihood test table
#lr.tbl <- lr.test(scan.sams)
#write.table(lr.tbl,file=file.path(resdir,paste(respref,".txt",sep="")))

### ============================================================================
### Finish
### ============================================================================
dev.off()
log.msg(paste("COMPLETE IN",sprintf("%0.1f",round(proc.time()[3]-start.time,1)),"s.\n\n"))
