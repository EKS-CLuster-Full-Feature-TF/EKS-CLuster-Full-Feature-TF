

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
 