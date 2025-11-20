

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

#add policy to cluster role
resource "aws_iam_role_policy_attachment" "amazon_eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}
