### ============================================================================
### ============================================================================
### ============================================================================
### NSAS single fleet assessment
### ============================================================================
### ============================================================================
### ============================================================================

rm(list=ls()); graphics.off(); start.time <- proc.time()[3]
options(stringsAsFactors=FALSE)
log.msg     <-  function(string) {cat(string);}
log.msg("\nNSH Final Assessment (single fleet)\n=====================\n")

# local path
path <- "J:/git/wg_HAWG/NSAS/"

try(setwd(path),silent=TRUE)

### ======================================================================================================
### Define parameters and paths for use in the assessment code
### ======================================================================================================
dir.create("assessment",showWarnings = FALSE)

data.dir            <-  file.path(".","data/")
output.dir          <-  file.path(".","assessment/")              # result directory\
script.dir          <-  file.path(".","side_scripts/")            # result directory
assessment_name     <- 'NSH_HAWG2021_sf_scanM'

### ============================================================================
### imports
### ============================================================================
library(FLSAM); library(FLEDA)
addM <- 0
source(file.path(script.dir,"setupAssessmentObjects_sf.r"))
source(file.path(script.dir,"setupControlObject_sf.r"))

NSH.sam               <- FLSAM(NSH,NSH.tun,NSH.ctrl)

stk0.NSH.sam <- NSH.sam

load(file.path(output.dir,paste0(assessment_name,'.Rdata')))

#0.11
mOrig <- NSH@m
#NSH.sams <- new("FLSAMs")
for(iM in seq(0.11,0.6,0.01)){
  print(iM)
  NSH@m <- mOrig + iM
  NSH.sams[[ac(iM)]] <- FLSAM(NSH,NSH.tun,NSH.ctrl,starting.values = stk0.NSH.sam)#,starting.values = stk0.NSH.sam
}

save(NSH.sams,file=file.path(output.dir,paste0(assessment_name,'.Rdata')))




### ============================================================================
### Dump
### ============================================================================



rm(list=ls()); graphics.off(); start.time <- proc.time()[3]
options(stringsAsFactors=FALSE)
log.msg     <-  function(string) {cat(string);}
log.msg("\nNSH Final Assessment\n=====================\n")

# local path
path <- "D:/Repository/ICES_HAWG/wg_HAWG/NSAS/benchmark/"
try(setwd(path),silent=TRUE)

### ======================================================================================================
### Define parameters and paths for use in the assessment code
### ======================================================================================================
output.dir          <-  file.path(".","results/7_finalModel/")        # figures directory
output.base         <-  file.path(output.dir,"NSH Assessment")  # Output base filename, including directory. Other output filenames are built by appending onto this one
n.retro.years       <-  10                                      # Number of years for which to run the retrospective


### ============================================================================
### imports
### ============================================================================
library(FLSAM); library(FLEDA)
source(file.path("R/0_basecase/setupAssessmentObjects_basecase.r"))
oldM <- NSH@m
source(file.path("R/6_multifleet/setupAssessmentObjects_LAI.r"))
source(file.path("R/6_multifleet/setupControlObject_sf.r"))

mOrig <- NSH@m
NSH.sams <- new("FLSAMs")
for(iM in seq(-0.1,0.6,0.01)){
  print(iM)
  NSH@m <- mOrig + iM
  NSH.sams[[ac(iM)]] <- FLSAM(NSH,NSH.tun,NSH.ctrl)
}

plot(unlist(lapply(NSH.sams,nlogl)))
addMNew <- an(names(which.min(unlist(lapply(NSH.sams,nlogl)))))
save(NSH.sams,file="D:/Repository/ICES_HAWG/wg_HAWG/NSAS/benchmark/results/2_newM/scanM.RData")

mOrig <- oldM
NSH.samsOld <- new("FLSAMs")
for(iM in seq(-0.1,0.6,0.01)){
  print(iM)
  NSH@m <- mOrig + iM
  NSH.samsOld[[ac(iM)]] <- FLSAM(NSH,NSH.tun,NSH.ctrl)
}

plot(y=unlist(lapply(NSH.samsOld[ac(seq(-0.1,0.22,0.01))],nlogl)),x=an(names(NSH.samsOld[ac(seq(-0.1,0.22,0.01))])),xlab="Additive M",ylab="Negative log-likelihood",las=1)
points(y=unlist(lapply(NSH.sams,nlogl)),x=an(names(NSH.sams)),pch=19,col=3)
addMOld <- an(names(which.min(unlist(lapply(NSH.samsOld,nlogl)))))

comb <- rbind(cbind(model="oldM",as.data.frame(oldM)),
              cbind(model="newM",as.data.frame(NSH@m)),
              cbind(model="oldM+profile",as.data.frame(oldM+addMOld)),
              cbind(model="newM+profile",as.data.frame(NSH@m+addMNew)))
              
xyplot(data ~ year | as.factor(age),groups=model,data=comb,type="l",auto.key=T)


