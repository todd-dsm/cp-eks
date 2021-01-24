/*
  -----------------------------------------------------------------------------
                                    OUTPUTS
  -----------------------------------------------------------------------------
*/
# Dynamically generate a list of Available AZs, no matter the region
data "aws_availability_zones" "available" {
  state = "available"
}

//# a quick output test
//output "myRegion" {
//  value = var.region
//}

//# snag the worker configmap
//output "worker-configmap" {
//  value = module.apps.worker-configmap
//}
//
//output "kms_key" {
//  value = module.apps.kms_key_id
//}

//# grab node max; should probably define this somewhere else
//output "asgMaxNodes" {
//  value = module.apps.asgMaxNodes
//}

//output "xdn" {
//  value = var.dns_zone
//}

//# admin-key-pair
//output "master-key" {
//  value = "${module.admin-key-pair.private_key_filename}"
//}
