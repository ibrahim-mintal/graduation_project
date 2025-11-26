variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role for EKS cluster"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role for EKS nodes"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "control_plane_sg_id" {
  description = "Security group ID for EKS control plane"
  type        = string
}

variable "node_instance_type" {
  description = "Instance type for EKS nodes"
  type        = string
}

variable "node_ami_type" {
  description = "AMI type for EKS nodes"
  type        = string
}

variable "desired_capacity" {
  description = "Desired number of nodes in each node group"
  type        = number
}
