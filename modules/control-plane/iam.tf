
# Terraform instructs AWS to create a role for the EKS service with the aws_iam_role resource specification 
# The policy section of the code creates a role with a name that refers to the cluster’s name 
# This is followed by the trusted relationship policy allowing EKS service to assume the role ("Service": "eks.amazonaws.com")

#role required to create a cluster
resource "aws_iam_role" "cluster_role" {
  name               = "${local.cluster_name}-cluster-role"
  tags = {
    Environment = var.env
    Application = var.app_name
    Terraform   = true
    name        = "${local.cluster_name}-cluster-role"
  }
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

#Terraform attaches a policy to the role to grant EKS the permission to create the cluster:
# The AmazonEKSClusterPolicy is a mandatory policy for every EKS cluster.
#add policy to cluster role

resource "aws_iam_role_policy_attachment" "amazon_eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}
