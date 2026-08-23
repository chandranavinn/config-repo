output "cluster_name" {
  description = "Name of the Argo control-plane EKS cluster."
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for the Argo control-plane EKS cluster."
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificate authority data for the Argo control-plane EKS cluster."
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "kubectl_update_kubeconfig_command" {
  description = "Command to configure kubectl for the Argo control-plane cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "argocd_namespace" {
  description = "Namespace where Argo CD is installed."
  value       = var.argocd_namespace
}

output "argocd_password_command" {
  description = "Command to retrieve the Argo CD initial admin password."
  value       = "kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
}
