###############################################
# EKS CONTROL PLANE SECURITY GROUP
###############################################
resource "aws_security_group" "eks_control_plane" {
  name        = "${var.project_name}-eks-control-plane-sg"
  description = "Security group for EKS control plane"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-eks-control-plane-sg"
  }
}

###############################################
# WORKER NODES SECURITY GROUP
###############################################
resource "aws_security_group" "nodes" {
  name        = "${var.project_name}-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  # SSH 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  # Allow node-to-node communication
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "Node to node"
  }

  # Allow outbound internet access (pull images, updates)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-nodes-sg"
  }
}

###############################################
# LOAD BALANCER SECURITY GROUP
###############################################
resource "aws_security_group" "lb" {
  name        = "${var.project_name}-lb-sg"
  description = "Security group for external LoadBalancer"
  vpc_id      = var.vpc_id

  # Allow HTTP from Internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  }

  # Allow outbound (needed by LB health checks)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-lb-sg"
  }
}

###############################################
# MANDATORY RULE: CONTROL PLANE → NODES (10250)
###############################################
resource "aws_security_group_rule" "cp_to_nodes_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  description              = "Allow EKS control plane to worker kubelet"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.eks_control_plane.id
}

###############################################
# MANDATORY RULE: LB → NODES (HTTP 80)
###############################################
resource "aws_security_group_rule" "lb_to_nodes_http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  description              = "Allow LoadBalancer to reach nodes on HTTP"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.lb.id
}

###############################################
# MANDATORY RULE: LB → NODES (NodePort 30000–32767)
###############################################
resource "aws_security_group_rule" "lb_to_nodes_nodeport" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  description              = "Allow LoadBalancer to reach NodePort range"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.lb.id
}
