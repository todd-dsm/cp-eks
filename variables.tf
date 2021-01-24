/*
  -----------------------------------------------------------------------------
                      Initialize/Declare Global Variables
                                  NETWORKING
  -----------------------------------------------------------------------------
*/
variable "envBuild" {
  description = "Build Environment; from ENV; E.G.: envBuild=stage"
  type        = string
}

variable "myCo" {
  description = "Expands to Company Name; E.G.: my-company"
  type        = string
}

variable "myProject" {
  description = "Expands to the purpose of the project; E.G.: project 'green-light'"
  type        = string
}

variable "aws_acct_no" {
  description = "Expands to AWS Account Number; E.G.: 0101-0101-0101"
  type        = string
}

variable "dns_zone" {
  description = "Root DNS Zone for myCo; I.E.: example.tld"
  type        = string
}

variable "myDomain" {
  description = "Root DNS Zone for myCo; I.E.: example.tld; minus the trailing dot"
  type        = string
}


variable "region" {
  description = "Deployment Region; from ENV; E.G.: us-west-2"
  type        = string
}

variable "host_cidr" {
  description = "CIDR block reserved for networking, from ENV; E.G.: export TF_VAR_host_cidr=10.172.0.0/16"
  type        = string
}

/*
  -----------------------------------------------------------------------------
                                   KUBERNETES
  -----------------------------------------------------------------------------
*/
variable "minDistSize" {
  description = "ENV Integer; initial count of distributed subnets, workers, etc; E.G.: export TF_VAR_minDistSize=3"
}

variable "cluster_apps" {
  description = "Evaluates to deployment_env_state; I.E.: apps-stage-or"
  type        = string
}

variable "kubernetes_version" {
  description = "A "
}

variable "myKubeConfig" {
  description = "Location on local file system for KUBECONFIG; REF: https://bit.ly/3mTh3SN"
  type        = string
}

variable "kubeNode_type" {
  description = "EKS worker node type, from ENV; E.G.: export TF_VAR_kubeNode_type."
  type        = string
}

//variable "project" {
//  description = "Project Name: should be set to something like: eks-test"
//  type        = string
//}
//
//
//variable "builder" {
//  description = "Evaluates to $USER; there must be key-piar (with the same name) in EC2 prior to apply."
//}
//
//variable "officeIPAddr" {
//  description = "The IP address of the Current (outbound) Gateway: individual A.B.C.D/32 or block A.B.C.D/29"
//  type        = string
//}
//
//variable "officeIPAddrBKUP" {
//  description = "The fall-back gateway address used when officeIPAddr fails."
//  type        = string
//}

