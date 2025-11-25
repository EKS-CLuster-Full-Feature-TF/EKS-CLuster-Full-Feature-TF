

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "env" {
  description = "The name of the environment."
  type        = string
}

variable "app_name" {
  description = "The name of the application."
  type        = string
}

variable "region" {
  type = string
}

variable "region_tag" {
  type = map(any)
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