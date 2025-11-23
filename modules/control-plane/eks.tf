# EKS Additional security group for data plane ENIs
# We attach an additional security group to the cluster ENIs to secure communication between the control and the data planes. 
# The recommended rules restrict traffic to specific ports and ensure that managed and Fargate node groups can join the cluster. 
# EKS will attach the custom cluster security group to all cluster ENIs


# Additional security group is attached to only the cluster ENIs, while a cluster security group is attached to all ENIs within a cluster. 

resource "aws_security_group" "additional_security_group" {
  name   = "optional additional security group rules for ENIs"
  vpc_id = var.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Environment = var.env
    Application = var.app_name
    Terraform   = true
    Name = "additional_sg_for_eks_eni"
  }
}

# EKs CLUSTER with private endpoint configuration

resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster_role.arn

# vpc_config block of the control plane code is where Terraform creates the ENIs in the given customer’s VPC subnet(s). 
  #configure data plane subnets and eni
  vpc_config {
    # security_group_ids = [aws_security_group.additional_security_group.id]
    subnet_ids = concat(
      var.eni_subnet_ids  # var.private_subnet_ids
    )

    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    # public_access_cidrs = ["193.16.23.22/32"]   # restricts the endpoint to a given IP address block
  }

  access_config {
    authentication_mode = var.authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
  }

  depends_on = [aws_iam_role.cluster_role]

  tags = {
    Environment = var.env
    Application = var.app_name
    Terraform   = true
    name        = local.cluster_name
  }
}
