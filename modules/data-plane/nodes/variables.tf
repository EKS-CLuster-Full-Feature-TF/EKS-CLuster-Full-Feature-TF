

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
  default = "eu-west-1"
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
  }
}

variable "label" {
  default = "nodes"
}

variable "subnet_ids" {}
variable "nodes_instance_types" {
  default  = ["t3.small"]
}
variable "cluster_security_group_id" {
  
}

variable "cluster_name" {
  
}
variable "capacity_type" {
  default = "SPOT"
}
variable "desired_size" {
  
}
variable "max_size" {
  
}
variable "min_size" {
  
}
variable "max_unavailable" {
  
}

variable "ami_type" {
  default = "AL2_x86_64"
}
variable "disk_size" {
  default = 20
}