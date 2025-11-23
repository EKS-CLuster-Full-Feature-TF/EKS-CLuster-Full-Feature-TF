resource "aws_eks_node_group" "nodes" {
    cluster_name    = local.cluster_name
    node_group_name = "${local.cluster_name}-node-group"
    node_role_arn   =  aws_iam_role.worker_nodes_role.arn
    subnet_ids = var.subnet_ids
    capacity_type  = var.capacity_type
  instance_types = var.nodes_instance_types
  # ami_type       = var.ami_type
  # disk_size      = var.disk_size

  launch_template {
  id = aws_launch_template.launch_template.id
  version = "$Latest"
  }
   
  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }
  update_config {
    max_unavailable = var.max_unavailable
  }
  labels = {
    name = var.label
  }
  # These tags will be passed to the EC2 instances created by this node group
  tags = {
    Environment = var.env
    Application = var.app_name
    Terraform   = true
    # ensure each EC2 instance created by the EKS node group gets a proper Name tag like mycluster-worker-node
    Name        = "${local.cluster_name}-worker-node"
  }
  depends_on = [ aws_iam_role.worker_nodes_role ]
}