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

# EKS Addons
resource "aws_eks_addon" "vpc_cni_addon" {
  cluster_name    = aws_eks_cluster.this.name
  addon_name      = "vpc-cni"
  # addon_version   = var.vpc_cni_version
  configuration_values = jsonencode({
     env = {
     ENABLE_PREFIX_DELEGATION = "true"
     WARM_PREFIX_TARGET = "1"
    }
  })

  depends_on = [aws_eks_cluster.this]
    tags = {
    Environment = var.env
    Application = var.app_name
    Terraform   = true}
}

resource "aws_eks_addon" "eks_kube_proxy_addon" {
  cluster_name    = aws_eks_cluster.this.name
  addon_name      = "kube-proxy"
  # addon_version   = var.kube_proxy_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on = [aws_eks_cluster.this]
    tags = {
    Environment = var.env
    Application = var.app_name
    Terraform   = true}
}

resource "aws_eks_addon" "coredns_addon" {
  cluster_name    = aws_eks_cluster.this.name
  addon_name      = "coredns"
  # addon_version   = var.coredns_version
  addon_version =  "v1.11.3-eksbuild.1" # This is the latest version of coredns as of 2025-11-25
  depends_on = [aws_eks_cluster.this]
    tags = {
    Environment = var.env
    Application = var.app_name
    Terraform   = true}
}