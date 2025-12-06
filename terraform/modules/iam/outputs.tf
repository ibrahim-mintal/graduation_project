output "eks_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_role.arn
}

output "eks_node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = aws_iam_role.eks_node_role.arn
}
