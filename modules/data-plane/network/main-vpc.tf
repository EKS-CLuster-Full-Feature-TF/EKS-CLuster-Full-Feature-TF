############################################

# Data sources

############################################
data "aws_availability_zones" "azs" {
  state = "available"
}

############################################

# Locals

############################################
locals {
  subnet_count = var.multi_az ? 2 : 1
}

############################################
# VPC
############################################
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_blocks["cluster-network"]
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.vpc_tags, { Name = local.vpc_name })
}

############################################
# Subnets
############################################
resource "aws_subnet" "eni_subnets" {
  count             = local.subnet_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = count.index == 0 ? var.cidr_blocks["eni-subnet-1"] : var.cidr_blocks["eni-subnet-2"] # Assign CIDR blocks based on index
  availability_zone = data.aws_availability_zones.azs.names[count.index] # Use AZs based on index

  tags = merge(local.vpc_tags, { Name = "${local.vpc_name}-eni-subnet-${count.index + 1}" }) # output like vpc-region-env-app-eni-subnet-1
}

resource "aws_subnet" "private_subnets" {
  count             = local.subnet_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = count.index == 0 ? var.cidr_blocks["private-subnet-1"] : var.cidr_blocks["private-subnet-2"]
  availability_zone = data.aws_availability_zones.azs.names[count.index]

  tags = merge(local.private_subnet_tags, { Name = "${local.vpc_name}-private-subnet-${count.index + 1}" }) # output like vpc-region-env-app-private-subnet-1
}

resource "aws_subnet" "public_subnets" {
  count             = local.subnet_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = count.index == 0 ? var.cidr_blocks["public-subnet-1"] : var.cidr_blocks["public-subnet-2"]
  availability_zone = data.aws_availability_zones.azs.names[count.index]

  tags = merge(local.public_subnet_tags, { Name = "${local.vpc_name}-public-subnet-${count.index + 1}" }) # output like vpc-region-env-app-public-subnet-1
}

resource "aws_subnet" "database_subnets" {
  count             = local.subnet_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = count.index == 0 ? var.cidr_blocks["database-subnet-1"] : var.cidr_blocks["database-subnet-2"]
  availability_zone = data.aws_availability_zones.azs.names[count.index]

  tags = merge(local.database_subnet_tags, { Name = "${local.vpc_name}-database-subnet-${count.index + 1}" }) # output like vpc-region-env-app-database-subnet-1
}

############################################
# Internet Gateway
############################################
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.vpc_tags, { Name = "${local.vpc_name}-igw" }) # output like vpc-region-env-app-igw
}

############################################
# Public Route Table
############################################
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id

# routing to internet 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.vpc_tags, { Name = "${local.vpc_name}-public-rt" })
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public_rt_assoc" {
  count          = local.subnet_count
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

############################################
# NAT Gateway (conditional)
############################################


resource "aws_eip" "nat_eip" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(local.vpc_tags, { Name = "${local.vpc_name}-nat-eip" })
}

# Create NAT Gateway only if enabled
resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = aws_subnet.public_subnets[0].id
  depends_on    = [aws_internet_gateway.this]

  tags = merge(local.vpc_tags, { Name = "${local.vpc_name}-nat-gateway" })
}

############################################
# Private/Database Route Table
############################################

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[0].id
    }
  }
  tags = merge(local.vpc_tags, { Name = "${local.vpc_name}-private_rt" })
}

resource "aws_route_table_association" "private_rt_assoc" {
  count          = local.subnet_count
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "database_rt_assoc" {
  count          = local.subnet_count
  subnet_id      = aws_subnet.database_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}
