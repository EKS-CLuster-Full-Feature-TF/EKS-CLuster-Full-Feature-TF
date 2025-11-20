#create vpc

module "vpc" {
  source               = "./modules/data-plane/network/"
  application_name     = var.application_name
  cidr_blocks          = var.cidr_blocks
  enable_nat_gateway   = var.enable_nat_gateway
  multi_az             = var.multi_az
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
}

module "cluster" {
  source                                      = "./modules/control-plane"
  cluster_version                             = var.cluster_version
  eni_subnet_ids                              = module.vpc.eni_subnet_ids
  vpc_id                                      = module.vpc.vpc_id
  endpoint_private_access                     = var.endpoint_private_access
  endpoint_public_access                      = var.endpoint_public_access
  authentication_mode                         = var.authentication_mode
  bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
}