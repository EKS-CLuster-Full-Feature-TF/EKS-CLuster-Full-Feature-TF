locals {
  tags = {
    Environment = var.env
    Application = var.app_name
    Terraform   = true
  }
  ## VPC ##
  vpc_name = "vpc-${var.region_tag[var.region]}-${var.env}-${var.app_name}"
  vpc_tags = merge(
    local.tags,
    tomap({
      "VPC-Name" = local.vpc_name
    })
  )

  public_subnet_tags = merge(
    local.tags,
    tomap({
      "Subnet-Type" = "public"
    })
  )
  private_subnet_tags = merge(
    local.tags,
    tomap({
      "Subnet-Type" = "private"
    })
  )
  database_subnet_tags = merge(
    local.tags,
    tomap({
      "Subnet-Type" = "database"
    })
  )
}