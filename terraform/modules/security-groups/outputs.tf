output "eks_control_plane_sg_id" {
  description = "ID of the EKS control plane security group"
  value       = aws_security_group.eks_control_plane.id
}

# output "nodes_sg_id" {
#   description = "ID of the worker nodes security group"
#   value       = aws_security_group.nodes.id
# }

# output "lb_sg_id" {
#   description = "ID of the load balancer security group"
#   value       = aws_security_group.lb.id
# }
