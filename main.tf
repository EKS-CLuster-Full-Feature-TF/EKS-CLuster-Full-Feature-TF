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
  
  # deployed the ENIs in the "10.0.1.0/28" and "10.0.2.0/28" subnets if we were to follow the best practices.
  eni_subnet_ids                              = module.vpc.eni_subnet_ids  ## ENI subnet = private subnet
  vpc_id                                      = module.vpc.vpc_id
  endpoint_private_access                     = var.endpoint_private_access
  endpoint_public_access                      = var.endpoint_public_access
  authentication_mode                         = var.authentication_mode
  bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
  
  # Pass metadata variables
  env      = var.env
  app_name = var.app_name
  region   = var.region
  region_tag = var.region_tag
}

# Create EKS Worker Nodes
module "nodes" {
  source = "./modules/data-plane/nodes"
  
  # Cluster information
  cluster_name              = module.cluster.cluster_name
  cluster_security_group_id = module.cluster.cluster_security_group_id
  
  # Network configuration
  subnet_ids = module.vpc.private_subnet_ids
  
  # Node configuration
  nodes_instance_types = var.nodes_instance_types
  capacity_type        = var.capacity_type
  desired_size         = var.desired_size
  max_size             = var.max_size
  min_size             = var.min_size
  max_unavailable      = var.max_unavailable
  label                = var.label
  
  # Metadata
  env      = var.env
  app_name = var.app_name
  region   = var.region
  region_tag = var.region_tag
  
  depends_on = [module.cluster]
}

# AWS Load Balancer Controller Module
module "alb_controller" {
  source = "./modules/alb-controller"

  # Cluster information
  cluster_name            = module.cluster.cluster_name
  cluster_oidc_issuer_url = module.cluster.cluster_object.identity[0].oidc[0].issuer
  cluster_object          = module.cluster.cluster_object

  # Network configuration
  vpc_id = module.vpc.vpc_id

  # Configuration
  region                = var.region
  alb_controller_version = var.alb_controller_version

  # Metadata
  env      = var.env
  app_name = var.app_name

  depends_on = [
    module.cluster,
    module.nodes
  ]
}