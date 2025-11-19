#create vpc

module "vpc" {
  source               = "./modules/data-plane/network/"
  application_name = var.application_name
  cidr_blocks          = var.cidr_blocks
  enable_nat_gateway   = var.enable_nat_gateway
  multi_az             = var.multi_az
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
}