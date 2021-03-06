#/*##########################################################################*/
#' MIK Quality Assurance
#' ==========================================================================
#'
#' by Mark R Payne
#' DTU-Aqua, Charlottenlund, Denmark
#' mpa@aqua.dtu.dk
#'
#  $Rev$
#  $Date$
#'
#' Performs quality assurance checks on the MIK database
#
#  Copyright and license details are provided at the bottom of this script
#
#  To do:
#
#  Notes:
#   - This script contains RMarkdown. Generate HTML by running the script
#     "./src/Automatic_QA_report.r"
#
# /*##########################################################################*/

# ========================================================================
# Initialise system
# ========================================================================
cat(sprintf("\n%s\n","MIK Quality Assurance"))

#Configure markdown style, do house cleaning
rm(list = ls(all.names=TRUE));  graphics.off()
start.time <- proc.time()[3]; options(stringsAsFactors=FALSE)
require(knitr)

#Helper functions, externals and libraries
log.msg <- function(fmt,...) {cat(sprintf(fmt,...));
                              flush.console();return(invisible(NULL))}
library(sp)
library(lattice)
library(tools)
library(geosphere)
library(reshape)
library(maps);library(mapdata);library(maptools)

#Start recording from here
opts_chunk$set(results="markup")
#+results="asis"
cat(sprintf("Analysis performed %s\n\n",date()))

#/* ========================================================================*/
#  Helper functions
#/* ========================================================================*/
#First, setup a display function
disp.err <- function(test,colnames=NULL,from=dat.raw,n.max=250) {
  idxs <- which(test)
  if(length(idxs) ==0) {
    cat("No errors detected\n") 
  } else if(length(idxs)>n.max) {
    cat(sprintf("Errors detected in %i rows. \n",length(idxs)))
    d <- subset(from,test)
    print(table(Campaign=d$Campaign))
  } else {
    #Create a DateTime field for convenient formatting
    print(from[idxs,c("SampleID","Campaign","Country",colnames)],
          row.names=TRUE)
    cat(sprintf("%i rows in total\n",length(idxs)))
  }
}

disp.range <- function(x,n=10) {
  rbind(smallest=sort(x)[1:n],
        largest=sort(x,decreasing=TRUE)[1:n])
}

disp.table <- function(...){
  tbl <- table(...)
  print(tbl,zero.print=".")
  return(invisible(tbl))
}


### ========================================================================
### ICESrectangleFromLonLat
### Mon Dec 30 17:54:47 2013
### lon              :  Vector of longitudinal positions
### lat              :  Vector of latitudinal positions
# Does conversion from lon / lat to ICES statistical rectangles
# Takes into account the full trickiness of the grid, including
# the edges. Formal definition of the ICES grid is found here:
# http://ices.dk/marine-data/maps/Pages/ICES-statistical-rectangles.aspx
#
# This code is derivied from the corresponding function in vmstools
# http://code.google.com/p/vmstools/
# r1327 by Niels.Hintzen on Sep 23, 2013
### ========================================================================
ICESrectangleFromLonLat <-function (lon,lat)
{
  #Check inputs
  if(length(lon)!=length(lat)) {
    stop("Input lat/lon vectors are not the same length")
  }
  
  #Round lon/lat appropriately
  latrnd <- round(lat*2+0.5,0)/2-0.25
  lonrnd <- round(lon+0.5,0)-0.5
  
  #Handle the latitude first, as its easier
  #The grid increments continuously from
  #south to north in 0.5 degree intervals
  latlabels <- sprintf("%02i",1:99)
  lat.mids <- seq(36, 85, 0.5) + 0.25
  lat.idx <- match(latrnd, lat.mids)
  numpart <- latlabels[lat.idx]
  
  #The longtitudinal structure is not so easy
  #There are three main traps:
  #  - A4-A9 do not exist
  #  - There are no I squares
  #  - Grid ends at M8
  lonlabels <- paste(rep(LETTERS[c(2:8,10:13)], each=10), rep(0:9, 
                                                              7), sep = "")
  lonlabels <- c("A0","A1","A2","A3",lonlabels[-length(lonlabels)])
  lon.mids <- -44:68 + 0.5
  lon.idx <- match(lonrnd, lon.mids)
  alphanum <- lonlabels[lon.idx]
  
  #Concatenate!
  ICES.rect <- sprintf("%s%s",numpart,alphanum)
  
  #Check whether it worked
  #If any part of the code is not recognised, both
  #lon and lat should be NA
  failed.codes <- is.na(numpart) | is.na(alphanum)
  if (any(failed.codes)) {
    warning("Some lat/lons are could not be converted")
    ICES.rect[failed.codes] <- NA
  }
  
  #Done
  return(ICES.rect)
}

### ========================================================================
### ICESrectangle2LonLat
### Fri Dec  6 10:37:25 2013
### statsq           :  Vector of 4 charcter ICES stat-square codes
### return.midpoints :  Should the function return lon/lat corresponding to 
###                     the centre of the square (TRUE) or the SW corner (FALSE)
### ========================================================================
ICESrectangle2LonLat <-
  function (statsq,return.midpoints=TRUE)
  {
    #Split the code into its respective parts
    latpart <- substr(statsq, 1, 2)
    lonpart <- substr(statsq, 3, 4)
    
    #Handle the latitude first, as its easier
    #The grid increments continuously from
    #south to north in 0.5 degree intervals
    latlabels <- sprintf("%02i",1:99)
    lat.mids <- seq(36, 85, 0.5) + 0.25
    lat.idx <- match(latpart, latlabels)
    lat <- lat.mids[lat.idx]
    
    #The longtitudinal structure is not so easy
    #There are three main traps:
    #  - A4-A9 do not exist
    #  - There are no I squares
    #  - Grid ends at M8
    lonlabels <- paste(rep(LETTERS[c(2:8,10:13)], each=10), rep(0:9, 
                                                                7), sep = "")
    lonlabels <- c("A0","A1","A2","A3",lonlabels[-length(lonlabels)])
    lon.mids <- -44:68 + 0.5
    lon.idx <- match(lonpart, lonlabels)
    lon <- lon.mids[lon.idx]
    
    #Check whether it worked
    #If any part of the code is not recognised, both
    #lon and lat should be NA
    failed.codes <- is.na(lat) | is.na(lon)
    if (any(failed.codes)) {
      warning("Some stat squares are not valid.")
      lat[failed.codes] <- NA
      lon[failed.codes] <- NA
    }
    
    #Correct for midpoints
    if(!return.midpoints){
      
      lat <- lat - 0.25
      lon <- lon - 0.5
      
    }
    #Done
    return(data.frame(lat=lat,lon=lon))
  }


#/* ========================================================================*/
#'# Introduction
#'  This work documents the results of quality assurance checks on the the
#'  MIK database. The details of the analysed file are as follows:
#/* ========================================================================*/
#Load data file
load("objects//MIK_data_raw.RData")

# File details
f.details <- attr(dat,"source.details")
print(t(f.details))

#'<small>The md5 checksum is used as an indicator of the contents of the file. 
#'Files that have identical contents will have identical md5 checksums, 
#'irrespective of file name, modification date etc. Files are different even
#'by a single bit will have different checksums. </small>
#'
#' ### Analysis subsetting
#' For convenience, it is often easier to analyse the data in subsets. The
#' Campaigns included in this analysis are as follows:
subset.campaigns <- opts_knit$get("subset.campaigns")
if(is.null(subset.campaigns)) {
  log.msg("All data points included")
} else {
  print(subset.campaigns)
  dat <- subset(dat,Campaign %in% subset.campaigns)
}

#Some further  preparations
dat$Campaign <- factor(dat$Campaign)
if(nlevels(dat$Campaign)==1) {
  lat.layout <- c(1,1)
} else if(nlevels(dat$Campaign)<18){
  lat.layout <- c(2,2)
} else {
  lat.layout <- c(3,3)
}

#'
#' ### Data table size
#' Number of rows, number of columns
dim(dat)

#' ### Data fields available
colnames(dat)

#/* ========================================================================*/
#'# Data Summaries
#' The following tables explore the contributions to the database
#' grouped by various key values - the numbers in the matrices represent
#' the number of samples in the database. These tables can be used as
#' a quick overview and to check the quality of data entry, particularly for
#' the fields concerned.
#/* ========================================================================*/
#'#### Data by Campaign
#'This table can be used to check quickly for years that are clearly wrong or
#'mislabelled e.g. years in which the survey did not take place
tbl <- disp.table(Campaign=dat$Campaign)
barplot(tbl,space=0,las=3,ylab="Number of samples")

#'#### Data by Country
#'This table can be used to check for consistency in the labelling of countries. 
#'It is quite common to see countries appearing multiple times with different 
#'labels e.g. NETH and NL
tbl <- disp.table(Country=dat$Country)
barplot(tbl,space=0,las=3,ylab="Number of samples")

#'#### Country by Campaign
#'This table can be used as a cross check on the participation of countries
#'in a given campaign (year). The presence of a few samples from a given country in a given
#'year can be an indicator of a typo.
disp.table(Campaign=dat$Campaign,Country=dat$Country)

#/* ========================================================================*/
#'# Data Parsing and Missing Values
#' The first check is of the ability of R to "parse" the data - parsing here
#' means that the data is converted from its native storage format (e.g. as
#' characters, integers, real numbers) to an internal representation in R.
#' R requires that all elements in a "column" have the same data type - Excel
#' does not and allows characters and numbers to mixed together in the same
#' column. A failure to parse properly therefore indicates a value 
#' that is not in agreement with the expected format. we also distinguish 
#' between values that are already missing (`missing.in.src`) and those that
#' failed to parse (`parse.errors`).
#/* ========================================================================*/
#First, expect that we have all the column names that we expect to retain
#as characters
allowed.char.cols <- c("Campaign","Country","SampleID","Haulnumber","Rectangle","sel")
if(any(!allowed.char.cols %in% colnames(dat))) {
  miss.cols.idxs <- which(!allowed.char.cols %in% colnames(dat))
  miss.cols <- allowed.char.cols[miss.cols.idxs]
  dat[,miss.cols] <- NA
  warning(sprintf("Expected character columns are missing: %s",
                  paste(miss.cols,collapse=",")))
}

#Now convert the other columns to numerics
other.cols <- colnames(dat)[!colnames(dat) %in% allowed.char.cols]
parsed.cols <- lapply(dat[other.cols],function(x) {
                  x.clean <- gsub(",",".",x)
                  return( suppressWarnings(as.numeric(x.clean)))})

#Estimate the parsing failures vs the missing values
dat.missing <- melt(colSums(sapply(dat,is.na)))
parsed.failures <- melt(colSums(sapply(parsed.cols,is.na)))
parsing.sum <- merge(dat.missing,parsed.failures,
                     by="row.names",sort=FALSE,all=TRUE)
colnames(parsing.sum) <- c("col.name","missing.in.src",
                           "missing.after.parsing")
parsing.sum$parse.errors <- parsing.sum$missing.after.parsing - 
                              parsing.sum$missing.in.src
rownames(parsing.sum) <- parsing.sum$col.name
parsing.sum <- parsing.sum[,c(-1,-3)][colnames(dat),]

#Print
print(parsing.sum)

#Add parsed values back into the data
dat.raw <- dat
dat[names(parsed.cols)] <- parsed.cols

#'#### Duplicate Sample IDs
#' We check that the sample IDs are unqiue.
id.freqs <- table(dat$SampleID)
dup.ids <- subset(id.freqs,id.freqs>1)
if(length(dup.ids)>0) {
  cat(sprintf("%i duplicated IDs. \n",length(dup.ids)))
  print(melt(dup.ids))
} else {
  cat("No errors detected\n") 
}

#/* ========================================================================*/
#'# Spatial integrity of the data
#' The following tests check for errors in the spatial coordinates (`LatDec`, 
#' `LongDec`) and agreement between the lon-lat and ICES statistical rectangle
#/* ========================================================================*/
#' #### Missing spatial coordinates
sp.missing <-  is.na(dat$LatDec) | is.na(dat$LongDec)
disp.err(sp.missing,c("LatDec","LongDec"))

#Create spatial object
dat.sp <- subset(dat,!sp.missing)
coordinates(dat.sp) <- ~ LongDec + LatDec
proj4string(dat.sp) <- CRS("+proj=longlat")

#'#### Points on land

#Extract coastlines
map.dat <- map("worldHires",
               xlim=bbox(dat.sp)[1,],
               ylim=bbox(dat.sp)[2,],
               plot=FALSE,fill=TRUE,res=0)
map.sp <- map2SpatialPolygons(map.dat,map.dat$names)
proj4string(map.sp) <- proj4string(dat.sp)

#Test for points on land
onland <- !is.na(over(dat.sp,map.sp))

#If any points found on land, print them out them
if(any(onland)) {
  onland.pts <- as.data.frame(subset(dat.sp,onland))
  disp.err(rownames(dat) %in% rownames(onland.pts),c("LongDec","LatDec"))
} else {
  cat("No points found on land\n")
}
  
#'#### Plot spatial distribution
#'Check here that all of the points appear within the expected domain. Points
#'identified as being on land above are plotted in red - all other wet points
#'are plotted in blue.
plot(dat.sp,pch=16,cex=0.5,col="blue")
map("worldHires",add=TRUE,col="grey",fill=TRUE)
box()
plot(dat.sp,add=TRUE,pch=16,col=ifelse(onland,"red",NA))

#'#### ICES Stat-Square check
#'Check that the longitude and latitude are in agreement with the ICES statistical
#'rectangle listed. The ICES rectangle derived from the long and lat is called `rect.from.ll`
#'below, while `Rectangle` is the value listted in the database. 'dist' is the disttance
#'in km between the centre of listed rectangle, and the long-latitude
d.rect <- transform(dat,
                    rect.from.ll=ICESrectangleFromLonLat(LongDec,LatDec),
                    ll.from.ss=ICESrectangle2LonLat(Rectangle))
d.rect$dist <- with(d.rect,
                    distHaversine(cbind(ll.from.ss.lon,ll.from.ss.lat),
                                  cbind(LongDec,LatDec)))
d.rect$dist <- round(d.rect$dist/1000)
d.rect <- d.rect[rev(order(d.rect$dist)),]
disp.err(d.rect$rect.from.ll!=d.rect$Rectangle,
         c("Rectangle","rect.from.ll","dist"),
         from=d.rect)

#/* ========================================================================*/
#'# Temporal Data
#' These algorithms parse and look for specific errors in the temporal data. 
#/* ========================================================================*/
# ##### Distribution of Date formats 
# #Number of lines that successfully parsed in each format. Format NA indicates
# #that no format was successful
# #Generic system to specify date formats (good luck with that!)
# datefmt <- setClass("datefmt",
#                     slots=list(name="character",
#                                fmt="character",
#                                strlen="numeric",
#                                pad.zeros="logical"),
#                     prototype=prototype(strlen=as.numeric(NULL),
#                                         pad.zeros=FALSE))
# 
# date.fmts <- list(datefmt(name="31.12.1976",fmt="%d.%m.%Y",strlen=10),
#                   datefmt(name="31.12.76",fmt="%d.%m.%y",strlen=8),
#                datefmt(name="31-12-76",fmt="%d-%m-%y",strlen=8),
#                datefmt(name="31/12/76",fmt="%d/%m/%y",strlen=8),
#                datefmt(name="311276",fmt="%d%m%y",strlen=6,pad.zeros=TRUE))
# names(date.fmts) <- sapply(date.fmts,slot,"name")
# date.parsed <- lapply(date.fmts,function(df) {
#   x<- dat$Date
#   #If we are not padding, and string length does not match, return NA
#   if(!df@pad.zeros) {
#       x <- ifelse(nchar(x)!=df@strlen,NA,x) }
#   #If string length is too short, pad it
#   if(df@pad.zeros) {
#     x <- sprintf(sprintf("%%0%ii",df@strlen),suppressWarnings(as.numeric(x)))
#   }
#   #Format
#   strptime(x,format=df@fmt,tz="GMT")
# })
# #Select parsed date
# date.num <- sapply(date.parsed,as.numeric)
# parsed.datefmt <- rowSums((!is.na(date.num))*col(date.num))
# parsed.datefmt[parsed.datefmt==0] <- NA
# ambig.datefmt <- rowSums(!is.na(date.num))>1
# parsed.datefmt[ambig.datefmt] <- NA
# dat$date.num <- date.num[cbind(seq(nrow(dat)),parsed.datefmt)] 
# #Make pretty output table
# datefmt.strs <- names(date.fmts)[parsed.datefmt]
# datefmt.strs[ambig.datefmt] <- "Ambiguous"
# disp.table(Campaign=dat$Campaign,format=datefmt.strs,useNA="ifany")

##### Distribution of Time formats 
#Number of lines that successfully parsed in each format. Format NA indicates
#that no format was successful
# time.fmts <- c("2211"=function(x){x.num <- suppressWarnings(as.numeric(x))
#                                   x.fmt <- sprintf("%04i",x.num)
#                                   strptime(x.fmt,"%H%M",tz="GMT")},
#                "22:11:00"=function(x) strptime(x,"%H:%M:%s",tz="GMT"))
# time.parsed <- lapply(time.fmts,do.call,args=list(x=dat$Time))
# time.num <- sapply(time.parsed,function(x) difftime(x,trunc(x,"days"),
#                                                     units="secs"))
# parsed.timefmt <- rowSums((!is.na(time.num))*col(time.num))
# parsed.timefmt[parsed.timefmt==0] <- NA
# ambig.timefmt <- rowSums(!is.na(time.num))>1
# parsed.timefmt[ambig.timefmt] <- NA
# dat$time.num <- time.num[cbind(seq(nrow(dat)),parsed.timefmt)] 
# #Make pretty output table
# timefmt.strs <- names(time.fmts)[parsed.timefmt]
# timefmt.strs[ambig.timefmt] <- "Ambiguous"
# disp.table(Campaign=dat$Campaign,format=timefmt.strs,useNA="ifany")

#'#### Rows where it has not been possible to fully construct a date-time
dat$POSIX <- with(dat,ISOdatetime(year,month,day,hour,minute,0,tz="GMT"))
disp.err(is.na(dat$POSIX),c("year","month","day","hour","minute"))

#'#### Check sample date by country
#'An easy way to check for date-time typos stems from the fact that that the data is 
#'collected in bursts by vessels, and should therefore occur in clusters. 
#'Isolated data points therefore suggest the presence of a typo. Note that 
#'this analysis only includes those samples where it has been possible to 
#'parse the date-time fields.
xyplot(factor(Country)~ POSIX | Campaign,data=dat,
       as.table=TRUE,groups=Country,
       xlab="Day of Year",ylab="Country",
       scales=list(x=list(relation="free")),
       layout=lat.layout)

#'Another approach is to look at the order in the database. In theory the data
#'should more or less be in sequence, as it is processed and submitted 
#'country-wise. Points out of sequence may indicate a failure to
#'parse the date correctly, or a typo. This of course is not perfect, but it 
#'can be a useful indicator.
xyplot(POSIX~ seq(nrow(dat)) | Campaign,data=dat,
       as.table=TRUE,groups=Country,
       xlab="Row number",ylab="Date",
       scales=list(relation="free"),
       auto.key=list(space="right"),
       layout=lat.layout)

#'We can furthermore use "out-of-sequence" points as a firm test. The two rows 
#'surrounding the out of sequence points are given, together with the time 
#'difference (in seconds) between subsequent hauls. Note that POSIX is a 
#'UNIX standard for the representation of date-time data, and is derived 
#'based on the supplied date-time fields.
out.of.seq <- c(NA,diff(as.numeric(dat$POSIX))) < 0
country.changes <- cumsum(rle(dat$Country)$lengths)+1
out.of.seq[country.changes[-length(country.changes)]] <- NA
seq.dat <- dat
seq.dat$diff <- c(NA,diff(as.numeric(seq.dat$POSIX)))
if(length(which(out.of.seq))<50) {
  for(i in which(out.of.seq)) {
    print(seq.dat[seq(i-2,i+2),c("Campaign","Country","Haulnumber","POSIX","diff")]  )
  }
} else {
  log.msg("More than 50...\n")
}

#'#### Check sample time by country
#'We can also check for errors in the day/night timing. The MIK is only performed
#'at night, so any times during the day are also likely to be typos. Note that 
#'this analysis only includes those samples where it has
#'been possible to parse the date-time field.
dat$tod <- as.numeric(difftime(dat$POSIX,trunc(dat$POSIX,units="days"),
                               units="hours"))
xyplot(factor(Country)~ tod | Campaign,data=dat,
       as.table=TRUE,groups=Country,
       xlab="Time of day (hours)",ylab="Country",
       layout=lat.layout)

#'#### Check solar angle by country
#'Another way to check for date-time errors is by calculating the solar angle 
#'when sample was taken. In theory, all samples should be at night. However, 
#'if a sample is not taken at night, we need to ask why. One reason may be 
#'that it was simply not entered correctly. The three definitions of 
#'sunrise/sunset are marked as grid lines ie at 6 (civil), 12 (nautical), 
#'and 18 (astronomical) degrees below the horizon.
calc.sol.el <- with(dat,ifelse(!is.na(LatDec) & ! is.na(LongDec) & !is.na(POSIX),
                              TRUE,FALSE))
sol.dat <- subset(dat,calc.sol.el)
coordinates(sol.dat) <- ~ LongDec + LatDec
proj4string(sol.dat) <- proj4string(dat.sp) 
azel.mat <- solarpos(sol.dat,sol.dat$POSIX)
dat$sol.el <- NA
dat$sol.el[calc.sol.el] <- azel.mat[,2]
xyplot(sol.el~ seq(nrow(dat)) | Campaign,data=dat,
       as.table=TRUE,groups=Country,
       auto.key=list(space="right"),
       xlab="Row number",ylab="Solar elevation",
       scales=list(x=list(relation="free")),
       layout=lat.layout,
       panel=function(...) {
         panel.abline(h=c(-18,-12,-6),col="lightgrey")
         panel.superpose(...)
       })
#'Solar elevations greater than 0.
disp.err(dat$sol.el > 0,c("LongDec","LatDec","POSIX", "sol.el"),from=dat)

#/* ========================================================================*/
#'# Sampling details
#' Details of the sampling process.
#/* ========================================================================*/
#'#### sel field is missing
disp.err(is.na(dat$sel),"sel")

#'#### Distribution of sel values by year
disp.table(Campaign=dat$Campaign,sel=dat$sel)

#'#### Both Hauldepth and Waterdepth are missing or did not parse
#' Hauldepth is needed - however, it can replaced by Waterdepth - 5m in
#' situations where Hauldepth is missing.
disp.err(is.na(dat$Hauldepth) & is.na(dat$Waterdepth),
         c("Hauldepth","Waterdepth"))

#'#### Insufficient information to calculate volume filtered
#'The volume filtered can be calculated in several ways, and the exact method
#'to be used is indicated by the 'sel' column. When `sel=="f"`, the calculation
#'is done from the flowmeter and therefore needs the `Flowmeterrevs.`, 
#'`Revspermeter` and `Geararea` fields. Failure to calculate volume filtered
#' when `sel=="f"` therefore indicattes a problem in at least one of these fields.
dat$volFlowmeter <- dat$Flowmeterrevs./dat$Revspermeter*dat$Geararea
disp.err(is.na(dat$volFlowmeter) & dat$sel=="f",
         c("Flowmeterrevs.","Revspermeter","Geararea","sel"))

#'Alternatively, if `sel=="d"`, then the volume filtered is to be calculated
#'from the haul geometry, requiring `Hauldepth`, `Distance` and `Geararea`)
dat$volFromGeometry <- sqrt(dat$Hauldepth^2 + dat$Distance^2/4)*2* dat$Geararea
disp.err(is.na(dat$volFromGeometry) & dat$sel=="d",
         c("Hauldepth","Distance","Geararea","sel"))

#'#### Distribution of Geararea field values
#' Check for consistency of entered values.
disp.table(Campaign=dat$Campaign,Geararea=dat$Geararea)
         
#'#### Distribution of Revspermeter (Flowmeter calibration) values (from valid flowmeters)
bwplot(Revspermeter ~ Country | Campaign,data=dat,
       scales=list("free"),
       subset=sel=="f",
       xlab="Country",
       as.table=TRUE,
       layout=lat.layout)

#'#### Distribution of Volume Filtered values (from valid flowmeters)
bwplot(volFlowmeter ~ Country | Campaign,data=dat,
       scales=list("free"),
       subset=sel=="f",
       xlab="Country",ylab="Volume filtered from flowmeter (m³)",
       as.table=TRUE,
       layout=lat.layout)

#'#### durmin and/or dursec are missing or did not parse
disp.err(is.na(dat$durmin)| is.na(dat$dursec),c("durmin","dursec"))

#'#### Distribution of Haul durations by Country
#'Ideally each haul should last at least 10 minutes (600s: grey line).
dat$haul.duration <- dat$durmin*60 + dat$dursec
bwplot(haul.duration ~ Country | Campaign,data=dat,
       scales=list("free"),
       xlab="Country",ylab="Haul duration (s)",
       as.table=TRUE,
       layout=lat.layout,
       panel=function(...) {
         panel.abline(h=600,col="grey")
         panel.bwplot(...)
       })

#'#### Haul Distance is missing or did not parse
disp.err(is.na(dat$Distance) | dat$Distance ==0,"Distance")

##### Distribution of Haul Distances by Country
# bwplot(Distance ~ Country | Campaign,data=dat,
#        scales=list("free"),
#        xlab="Country",ylab="Haul Distance (m)",
#        as.table=TRUE,
#        layout=lat.layout)

#'#### Distribution of Haul Speeds by Country
#'Haul speed is not reported directly in the database. However, it can
#'be inferred from the combination of `Distance` and `haul.duration`. Target
#'haul speed is 3 kts.
dat$haul.speed <- dat$Distance/dat$haul.duration*1.94384449 
xyplot(haul.speed ~ seq(nrow(dat)) | Campaign,data=dat,groups=Country,
       scales=list(relation="free"),
       xlab="Row number",ylab="Haul Speed (kts)",
       auto.key=list(space="right"),
       as.table=TRUE,
       layout=lat.layout,
       panel=function(...) {
         panel.abline(h=c(2,4),col="grey")
         panel.superpose(...)
       })

#'Haul speeds more than 6 kts are deeply suspicious.
disp.err(dat$haul.speed>6,
         c("durmin","dursec","haul.duration",
           "Distance","haul.speed"),from=dat)

#'#### Mismatch between volumes estimated from flowmeter and haul geometry
#'Estimates of the filtered volume can be derived from the haul geometry 
#'(single/double oblique in nature), the distance covered along the surface, and 
#'the depth of the haul. In theory, these should be the same as those values 
#'derived from the flowmeter. The ratio between these two values is therefore 
#'useful as a metric of data quality, and particularly as a check for 
#'malfunctining flowmeters.
#'
#'Only hauls where the flowmeter data should be used (as indicated by the `sel` 
#'column) are shown. The grey line indicates the 1:1 line, where the volumes
#'derived from the two methods are the same, and in theory,
#'all values should lie. Note the logarithmic scaling on the vertical axis. Note 
#'also that there should be no effective difference between single and double 
#'oblique hauls here.
dat$volRatio <- dat$volFlowmeter/dat$volFromGeometry
xyplot(volRatio ~ seq(nrow(dat)) | Campaign,data=dat,groups=Country,
      subset=sel=="f",
      scales=list(x=list(relation="free"),
                  y=list(log=TRUE,equispaced.log=FALSE)),
      xlab="Row number",ylab="Volume from Flowmeter / Volume from Haul Geometry",
      as.table=TRUE,
      auto.key=list(space="right"),
      layout=lat.layout,
      panel=function(...){
        panel.abline(h=0,col="grey")
        panel.superpose(...)
      })

#'Values greater than 2 or less than 0.5 are suspicious. 
disp.err((dat$volRatio > 2 | dat$volRatio < 0.5) & dat$sel=="f",
         c("sel","volRatio","haul.speed"),from=dat)
#'For reference, we have also displayed the haul-speed calculated above, 
#'which should ideally be 3 knts. As both values incorporate the Distance 
#'hauled, a high volRatio and a low haul 
#'speed suggest that the reported distance is too low and vice versa.

#/* ========================================================================*/
#'# Larval data
#' Checks for the quality and consistency of the entered larval count data.
#/* ========================================================================*/
#'#### Number of larvae is missing or did not parse
disp.err(is.na(dat$Numberlarvae),"Numberlarvae")

#'#### Larvae length distribution is missing
#' The larval length distribution is reported missing if the sum of the values
#' in the length distribution (`sum_len_dist`) is zero but larvae were reported 
#' in the `Numberlarvae` field. However, a case may also arise where all captured
#' larvae were damanged, and could not be length measured - this is not reported
#' here.
larv.cols <- grep("^X[[:digit:]]+$",colnames(dat),value=TRUE)
dat$sum_len_dist <-rowSums(as.matrix(dat[,larv.cols]),na.rm=TRUE)
disp.err(dat$sum_len_dist==0 & dat$Numberlarvae!=0 & dat$Numberlarvae!=dat$damaged,
         c("Numberlarvae","sum_len_dist","damaged"),from=dat)

#'#### Larvae length distribution is present but NumberLarvae is empty
disp.err(dat$sum_len_dist!=0 & dat$Numberlarvae==0,
         c("Numberlarvae","sum_len_dist"),from=dat)

#'#### Length distribution does not tally with other fields
#'We check that there is agreement between what has been measured and 
#'not measured. Ideally, the `Numberlarvae` should equal the sum of the 
#'larvae reported in the length distribution fields (`sum_len_dist`), plus 
#'the larvae reported as `notmeasured` (e.g. due to subsampling) and `damaged`. 
#'The discrepancy between these is reported in the `diff` field. An error 
#'is reported if this value is non-zero, after rounding.
#'
#'Note that this option has been disabled, due to missing "not.measured" and
#'"damaged" fields
#'
# d <- dat
# d$diff <- round(d$Numberlarvae - d$sum_len_dist-d$not.measured-d$damaged,1)
# disp.err(d$diff!=0 & d$sum_len_dist!=0 & d$Numberlarvae!=0,
#          c("Numberlarvae","sum_len_dist","not.measured","damaged","diff"),
#          from=d)

#/* ========================================================================*/
#   Complete
#/* ========================================================================*/
#Save results
save(dat,file="objects//MIK_data_QA.RData")

#+ echo=FALSE,results='asis'
#Close files
if(grepl("pdf|png|wmf",names(dev.cur()))) {dmp <- dev.off()}
log.msg("\nAnalysis complete in %.1fs at %s.\n",proc.time()[3]-start.time,date())

#' -----------
#' <small>*This work by Mark R Payne is licensed under a  Creative Commons
#' Attribution-NonCommercial-ShareAlike 3.0 Unported License. 
#' For details, see http://creativecommons.org/licenses/by-nc-sa/3.0/deed.en_US
#' Basically, this means that you are free to "share" and "remix" for 
#' non-commerical purposes as you see fit, so long as you "attribute" me for my
#' contribution. Derivatives can be distributed under the same or 
#' similar license.*</small>
#'
#' <small>*This work comes with ABSOLUTELY NO WARRANTY or support.*</small>
#'
#' <small>*This work is also subject to the BEER-WARE License. For details, see
#' http://en.wikipedia.org/wiki/Beerware*</small>
#' 
#' -----------
#' 
#' <small> Script version:
#'$Rev$ $Date$ </small>
#'
#' -----------

# End
