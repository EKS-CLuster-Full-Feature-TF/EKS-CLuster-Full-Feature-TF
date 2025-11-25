########################################
# Metadata
########################################

variable "env" {
  description = "The name of the environment."
  type        = string
}

variable "region" {
  type = string
}

variable "role_name" {
  type = string
}

variable "profile_name" {
  type = string
}

variable "application_name" {
  description = "The name of the application."
  type        = string
}

variable "app_name" {
  description = "The name of the application."
  type        = string
}

variable "region_tag" {
  type = map(any)

  default = {
    "us-east-1"  = "ue1"
    "ap-south-1" = "ap1"
  }
}

########################################
# VPC Variables
########################################

variable "cidr_blocks" {
  description = "cidr blocks"
  type        = map(any)
  default = {
    eni-subnet-1      = "10.0.1.0/28"
    eni-subnet-2      = "10.0.2.0/28"
    private-subnet-1  = "10.0.3.0/24"
    private-subnet-2  = "10.0.4.0/24"
    public-subnet-1   = "10.0.5.0/24"
    public-subnet-2   = "10.0.6.0/24"
    database-subnet-1 = "10.0.7.0/24"
    database-subnet-2 = "10.0.8.0/24"
    cluster-network   = "10.0.0.0/16"
    internet          = "0.0.0.0/0"
  }
}

variable "enable_nat_gateway" {
}

variable "multi_az" {

}
variable "enable_dns_hostnames" {

}

variable "enable_dns_support" {

}
########################################
# EKS Cluster Settings
########################################

variable "cluster_version" {
  description = "EKS Cluster version"
  type        = string
  default     = "1.31"
}

variable "endpoint_private_access" {
}

variable "endpoint_public_access" {
}
variable "authentication_mode" {
default = "API_AND_CONFIG_MAP"
}
variable "bootstrap_cluster_creator_admin_permissions" {
default = true
}
########################################
# EKS Nodes Settings
########################################

variable "nodes_instance_types" {

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
variable "label" {
  default = "nodes"
}

########################################
# ALB Controller Settings
########################################

variable "alb_controller_version" {
  description = "Version of AWS Load Balancer Controller Helm chart"
  type        = string
  default     = "1.8.0"
}

#variable "subnet_ids" {}