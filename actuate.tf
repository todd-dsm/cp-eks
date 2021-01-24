# -----------------------------------------------------------------------------
# Kubernetes Cluster for Applications
# -----------------------------------------------------------------------------
module "label" {
  source  = "cloudposse/label/null"
  version = "0.22.1"

  # This is the preferred way to add attributes. It will put "cluster" first
  # before any attributes set in `var.attributes` or `context.attributes`.
  # In this case, we do not care, because we are only using this instance
  # of this module to create tags.
  attributes = ["cluster"]
}

locals {
  # The usage of the specific kubernetes.io/cluster/* resource tags below are required
  # for EKS and Kubernetes to discover and manage networking resources
  # https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#base-vpc-networking
  tags = merge(module.label.tags, map("kubernetes.io/cluster/${module.label.id}", "shared"))

  # Unfortunately, most_recent (https://github.com/cloudposse/terraform-aws-eks-workers/blob/34a43c25624a6efb3ba5d2770a601d7cb3c0d391/main.tf#L141)
  # variable does not work as expected, if you are not going to use custom ami you should
  # enforce usage of eks_worker_ami_name_filter variable to set the right kubernetes version for EKS workers,
  # otherwise will be used the first version of Kubernetes supported by AWS (v1.11) for EKS workers but
  # EKS control plane will use the version specified by kubernetes_version variable.
  eks_worker_ami_name_filter = "amazon-eks-node-${var.kubernetes_version}*"
}

# -----------------------------------------------------------------------------
# Networking: VPC
# https://registry.terraform.io/modules/cloudposse/vpc/aws/latest
# -----------------------------------------------------------------------------
module "apps_vpc" {
  source                  = "cloudposse/vpc/aws"
  version                 = "0.18.2"
  namespace               = var.myCo
  name                    = var.myProject
  stage                   = var.envBuild
  cidr_block              = var.host_cidr
  enable_dns_support      = true
  enable_internet_gateway = true
}

# -----------------------------------------------------------------------------
# Networking: Subnets
# https://registry.terraform.io/modules/cloudposse/dynamic-subnets/aws/latest
# -----------------------------------------------------------------------------
module "apps_subnets" {
  source               = "cloudposse/dynamic-subnets/aws"
  version              = "0.34.0"
  availability_zones   = data.aws_availability_zones.available.names
  namespace            = var.myCo
  stage                = var.envBuild
  name                 = var.myProject
  vpc_id               = module.apps_vpc.vpc_id
  igw_id               = module.apps_vpc.igw_id
  cidr_block           = module.apps_vpc.vpc_cidr_block
  nat_gateway_enabled  = false
  nat_instance_enabled = false
}

# -----------------------------------------------------------------------------
# EKS: Managed Kubernetes Masters
# https://registry.terraform.io/modules/cloudposse/eks-cluster/aws/latest
# -----------------------------------------------------------------------------
module "apps_cluster" {
  source                      = "cloudposse/eks-cluster/aws"
  version                     = "0.32.0"
  namespace                   = var.myCo
  stage                       = var.envBuild
  region                      = var.region
  name                        = var.myProject
  vpc_id                      = module.apps_vpc.vpc_id
  subnet_ids                  = module.apps_subnets.public_subnet_ids
  kubernetes_version          = var.kubernetes_version
  map_additional_aws_accounts = ["taysmith", "mtanton"]
  oidc_provider_enabled       = true
  enabled_cluster_log_types   = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# Ensure ordering of resource creation to eliminate the race conditions when applying the Kubernetes Auth ConfigMap.
# Do not create Node Group before the EKS cluster is created and the `aws-auth` Kubernetes ConfigMap is applied.
# Otherwise, EKS will create the ConfigMap first and add the managed node role ARNs to it,
# and the kubernetes provider will throw an error that the ConfigMap already exists (because it can't update the map, only create it).
# If we create the ConfigMap first (to add additional roles/users/accounts), EKS will just update it by adding the managed node role ARNs.
data "null_data_source" "wait_for_cluster_and_kubernetes_configmap" {
  inputs = {
    cluster_name             = module.apps_cluster.eks_cluster_id
    kubernetes_config_map_id = module.apps_cluster.kubernetes_config_map_id
  }
}

# -----------------------------------------------------------------------------
# EKS: Kubernetes Workers: managed node groups
# https://registry.terraform.io/modules/cloudposse/eks-node-group/aws/latest
# -----------------------------------------------------------------------------
module "apps_node_group" {
  source         = "cloudposse/eks-node-group/aws"
  version        = "0.17.1"
  namespace      = var.myCo
  stage          = var.envBuild
  name           = var.myProject
  count          = 4
  subnet_ids     = module.apps_subnets.public_subnet_ids
  instance_types = [var.kubeNode_type]
  desired_size   = var.minDistSize
  min_size       = var.minDistSize
  max_size       = 8
  cluster_name   = data.null_data_source.wait_for_cluster_and_kubernetes_configmap.outputs["cluster_name"]
  #cluster_name       = module.apps_cluster.eks_cluster_id
  kubernetes_version = module.apps_cluster.eks_cluster_version

  #kubernetes_labels = var.kubernetes_labels
  #disk_size         = var.disk_size
  #before_cluster_joining_userdata = var.before_cluster_joining_userdata

  context = module.this.context
}