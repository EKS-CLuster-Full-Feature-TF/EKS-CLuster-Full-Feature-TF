output "alb_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = aws_iam_role.alb_controller.arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "alb_controller_service_account_name" {
  description = "Name of the Kubernetes ServiceAccount for ALB Controller"
  value       = kubernetes_service_account.alb_controller.metadata[0].name
}

