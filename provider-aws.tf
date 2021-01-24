/*
  -----------------------------------------------------------------------------
                                PROVIDER CONFIG
  -----------------------------------------------------------------------------
*/
# REF: Provider Configuration: https://www.terraform.io/docs/configuration/providers.html

provider "aws" {
  region = var.region
}

terraform {
  required_version = "~> 0.12"
}

terraform {
  backend "s3" {
  }
}
//
//provider "local" {
//  version = "~> 1.4"
//}
//
//provider "template" {
//  version = "~> 2.1"
//}
//
//provider "external" {
//  version = "~> 1.2"
//}