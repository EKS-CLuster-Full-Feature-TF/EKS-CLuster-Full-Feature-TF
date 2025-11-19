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
  
}

variable "app_name" {
  description = "The name of the application."
  type        = string
  default     = "EKS-squad-1"
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




variable "vpc_tag" {
  default = "private-endpoint-cluster-vpc"
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway for private and database subnets"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Whether to create resources in multiple availability zones"
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {

}

variable "enable_dns_support" {

}