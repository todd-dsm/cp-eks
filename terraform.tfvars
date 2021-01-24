/*
  -----------------------------------------------------------------------------
                                BUILD CONSTANTS
  -----------------------------------------------------------------------------
*/
kubernetes_version = "1.18"
# This is the primary egress gateway from which we exit The Office
//officeIPAddr = "0.0.0.0/0"
# In the case that the primary address flakes, this is the fail-over egress
//officeIPAddrBKUP = "0.0.0.0/0"
// For pre-existing keys
//kms_arn = ""