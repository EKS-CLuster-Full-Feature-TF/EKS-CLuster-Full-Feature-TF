########################################
# Provider to connect to AWS
########################################

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9"
    }
  }

  # backend "s3" {} # use backend.config for remote backend
}

provider "aws" {
  region  = var.region
  profile = var.profile_name
  /*
  assume_role {
    role_arn = "arn:aws:iam::980305500578:role/EKSClusterCreatorRole"
    session_name = "TerraformRoleSession"
  }
  */
}

# Kubernetes provider configuration
# Note: This will be configured after cluster creation
# The exec block allows dynamic authentication
provider "kubernetes" {
  host                   = length(module.cluster.cluster_object) > 0 ? module.cluster.cluster_object.endpoint : null
  cluster_ca_certificate = length(module.cluster.cluster_object) > 0 && length(module.cluster.cluster_object.certificate_authority) > 0 ? base64decode(module.cluster.cluster_object.certificate_authority[0].data) : null
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.cluster.cluster_name,
      "--region",
      var.region,
      "--profile",
      var.profile_name
    ]
  }
}

# Helm provider configuration
# For Helm provider 3.x, it automatically uses the Kubernetes provider configuration
# No explicit provider block needed - it inherits from kubernetes provider
