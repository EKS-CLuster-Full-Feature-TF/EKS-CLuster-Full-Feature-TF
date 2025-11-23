
#necessary roles for worker nodes
resource "aws_iam_role" "worker_nodes_role" {
  name = "${local.cluster_name}-nodes"
  tags = {
    Environment = var.env
    Application = var.app_name
    Terraform   = true
    name        = "${local.cluster_name}-nodes"
  }
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

#attach node role
# The Amazon EKS Worker Node permission is for the node to describe Amazon EC2 resources in the VPC and also provides permissions for the Amazon EKS Pod Identity Agent

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker_nodes_role.name
}

#EKS CNI policy provides the cluster network interface plugin with the needed permissions to modify the IP address configuration of the cluster nodes.
#This permission set allows the CNI to list, describe, and modify Elastic Network Interfaces (ENIs) on your behalf. 

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker_nodes_role.name
}

#for the nodes to access the elastic container registry access

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker_nodes_role.name
}

# Optional, only if you want to "SSH" to your EKS nodes.
# enables the SSM (AWS Systems Manager) agent on the nodes. The SSM agent allows users to access the cluster nodes without SSH but with the AWS SSM agent.
resource "aws_iam_role_policy_attachment" "amazon_ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.worker_nodes_role.name
}
