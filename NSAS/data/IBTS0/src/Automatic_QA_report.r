#/*##########################################################################*/
#' Generate MIK Quality Assurance HTML Report
#' ==========================================================================
#'
#' by Mark R Payne
#' DTU-Aqua, Charlottenlund, Denmark
#' mpa@aqua.dtu.dk
#'
#  $Rev: 926 $
#  $Date: 2015-03-15 14:10:09 +0100 (Sun, 15 Mar 2015) $
#'
#' Performs quality assurance checks on the MIK database
#
#  Copyright and license details are provided at the bottom of this script
#
#  To do:
#
#  Notes:
#
# /*##########################################################################*/

# ========================================================================
# Initialise system
# ========================================================================
cat(sprintf("\n%s\n","Automatic QA Reporting"))

#Configure markdown style, do house cleaning
rm(list = ls(all.names=TRUE));  graphics.off()
start.time <- proc.time()[3]; options(stringsAsFactors=FALSE)
require(knitr)

#Helper functions, externals and libraries
log.msg <- function(fmt,...) {cat(sprintf(fmt,...));
                              flush.console();return(invisible(NULL))}

# ========================================================================
# Import data
# ========================================================================
source("src/Data_import.r")

# ========================================================================
# Perform QA analysis
# ========================================================================
#Configuration----------
QA.script <- "src//MIK_Quality_assurance.r"
opts_knit$set(output.suffix="QA.html",
              subset.campaigns=NULL)  

#Code follows----------
library(knitr);library(markdown)
opts_knit$set(root.dir=getwd(),width=120,unnamed.chunk.label="unnamed")
opts_chunk$set(echo=FALSE,results="hide",fig.width=10,
               message=FALSE,error=FALSE,fig.path="plots/")
QA.script.HTML <- spin(QA.script)
options("markdown.HTML.options"=c(markdownHTMLOptions(TRUE),"toc"))
markdownToHTML(gsub("html$","md",QA.script.HTML),QA.script.HTML)
file.rename(QA.script.HTML,sprintf("outputs/%s_%s",
                                     basename(rownames(f.details)),
                                     opts_knit$get("output.suffix")))
file.remove(gsub("html$","md",QA.script.HTML))

# ========================================================================*/
# Complete
# ========================================================================*/
log.msg("\nAnalysis complete in %.1fs at %s.\n",proc.time()[3]-start.time,date())
