# Kubernetes ServiceAccount for AWS Load Balancer Controller
# Uses IRSA (IAM Roles for Service Accounts) - IAM role is in iam.tf
resource "kubernetes_service_account" "alb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
    }
    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/component"  = "controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  depends_on = [
    aws_iam_role.alb_controller
  ]
}

# Install AWS Load Balancer Controller using Helm
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = var.alb_controller_version

  # Using values argument instead of set blocks for compatibility
  values = [
    yamlencode({
      clusterName = var.cluster_name
      serviceAccount = {
        create = false
        name   = "aws-load-balancer-controller"
      }
      region                      = var.region
      vpcId                       = var.vpc_id
      enableServiceMutatorWebhook = false
    })
  ]

  depends_on = [
    kubernetes_service_account.alb_controller,
    aws_iam_role.alb_controller
  ]
}

