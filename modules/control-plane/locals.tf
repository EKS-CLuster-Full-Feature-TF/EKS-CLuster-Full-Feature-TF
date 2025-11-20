locals {
  tags = {
    Environment = var.env
    Application = var.app_name
    Terraform   = true
  }

  ########################################
  # EKS Cluster
  ########################################

  cluster_name = "eks-${var.region_tag[var.region]}-${var.env}-${var.app_name}"

  eks_tags = {
    Environment = var.env
    Application = var.app_name
  }

}

  