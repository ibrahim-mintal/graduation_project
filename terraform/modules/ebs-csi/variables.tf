variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_issuer" {
  description = "OIDC issuer URL of the EKS cluster"
  type        = string
}

variable "jenkins_node_group_id" {
  description = "ID of the Jenkins node group (for dependency)"
  type        = string
}

variable "app_node_group_id" {
  description = "ID of the App node group (for dependency)"
  type        = string
}
