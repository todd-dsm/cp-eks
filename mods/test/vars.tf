/*
  -----------------------------------------------------------------------------
                          Initialize/Declare Variables
                                 MODULE-LEVEL
  -----------------------------------------------------------------------------
*/
variable "dns_zone" {
  description = "Root DNS Zone for myCo; I.E.: example.tld"
  type        = string
}

variable "officeIPAddr" {
  description = "IP address of current gateway"
  type        = string
}


variable "builder" {
  description = "builder of the things"
  type        = string
}