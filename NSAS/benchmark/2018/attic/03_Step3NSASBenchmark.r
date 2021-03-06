######################################################################################################
# NSH Assessment
#
# Author: Niels Hintzen
# IMARES, The Netherlands
#
#
####################################################################################################


### ======================================================================================================
### Final tuning of FLSAM
### ======================================================================================================

  library(FLSAM)

  ### ======================================================================================================
  ### Select the default indices
  ### ======================================================================================================

  NSH.tun   <- NSH.tun
  !Natural mortality selection

  ### ======================================================================================================
  ### Prepare control object for assessment
  ### ======================================================================================================
  source(file.path(".","benchmark","Setup_default_FLSAM_control.r"))

  ### ======================================================================================================
  ### Perform the scans for bindings
  ### ======================================================================================================

  source(file.path(".","benchmark","Scan_catchability_binding.r"))
  source(file.path(".","benchmark","Scan_obs_var_binding.r"))
  source(file.path(".","benchmark","Scan_HERAS_binding.r"))
  source(file.path(".","benchmark","Scan_IBTS_binding.r"))

  ### ======================================================================================================
  ### Compare the results and make a decision
  ### ======================================================================================================




  ### ======================================================================================================
  ### Adapt the Setup_default_FLSAM_control.r
  ### ======================================================================================================

  ### ======================================================================================================
  ### Perform the assessment
  ### ======================================================================================================

  source(file.path(".","benchmark","Setup_default_FLSAM_control.r"))
  NSH.sam   <- FLSAM(NSH,NSH.tun,NSH.ctrl)
  NSH.sam   <- NSH + NSH.sam

  ### ======================================================================================================
  ### Perform retro runs & diagnostics
  ### ======================================================================================================

  source(file.path(".","benchmark","Scan_retrospective.r"))