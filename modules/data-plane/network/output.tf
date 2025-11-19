############################################
# VPC Outputs
############################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private_subnets[*].id
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = aws_subnet.database_subnets[*].id
}

output "eni_subnet_ids" {
  description = "IDs of the ENI subnets"
  value       = aws_subnet.eni_subnets[*].id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways (if any)"
  value       = [for nat in aws_nat_gateway.this : nat.id]
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public_rt.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table_association.private_rt_assoc[*].route_table_id
}
output "database_route_table_id" {
  description = "ID of the database route table"
  value       = aws_route_table_association.database_rt_assoc[*].route_table_id
}