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