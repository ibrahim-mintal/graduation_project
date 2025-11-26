output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.cluster.id
}

output "oidc_issuer" {
  description = "OIDC issuer URL of the EKS cluster"
  value       = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

output "jenkins_node_group_name" {
  description = "Name of the Jenkins node group"
  value       = aws_eks_node_group.jenkins.node_group_name
}

output "app_node_group_name" {
  description = "Name of the App node group"
  value       = aws_eks_node_group.app.node_group_name
}
