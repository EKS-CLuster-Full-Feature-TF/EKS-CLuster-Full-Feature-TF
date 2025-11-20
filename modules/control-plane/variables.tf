

########################################
# Metadata
########################################

variable "env" {
  description = "The name of the environment."
  type        = string
  default     = "prod"
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "role_name" {
  type    = string
  default = "admin"
}

variable "profile_name" {
  type    = string
  default = "tester"
}

variable "application_name" {
  description = "The name of the application."
  type        = string
  default     = "eks-demo"
}

variable "app_name" {
  description = "The name of the application."
  type        = string
  default     = "eks-demo"
}

variable "region_tag" {
  type = map(any)

  default = {
    "us-east-1"      = "ue1"
    "us-west-1"      = "uw1"
    "eu-west-1"      = "ew1"
    "eu-central-1"   = "ec1"
    "ap-northeast-1" = "apne1"
     "ap-south-1" = "ap1"
  }
}
########################################
# EKS Cluster
########################################


variable "cluster_version" {
  default = "1.31"
}
variable "eni_subnet_ids" {}
variable "vpc_id" {}

variable "endpoint_private_access" {
}

variable "endpoint_public_access" {
}

variable "authentication_mode" {
  description = "Auth Mode"
  default = "API_AND_CONFIG_MAP"
}
variable "bootstrap_cluster_creator_admin_permissions" {
  default = true
}