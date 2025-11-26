output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "nodegroup_jenkins" {
  description = "Name of the Jenkins node group"
  value       = module.eks.jenkins_node_group_name
}

output "nodegroup_app" {
  description = "Name of the App node group"
  value       = module.eks.app_node_group_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "ebs_csi_role_arn" {
  description = "ARN of the EBS CSI driver IAM role"
  value       = module.ebs_csi.ebs_csi_role_arn
}
