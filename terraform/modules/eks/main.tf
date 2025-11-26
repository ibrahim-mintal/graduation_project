# --------------------------------
# Creating Cluster (Control Plane)
# --------------------------------

resource "aws_eks_cluster" "cluster" {
  name     = var.project_name
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.control_plane_sg_id]
  }
}

# -----------------------------------
# Creating Jenkins Node group
# -----------------------------------

resource "aws_eks_node_group" "jenkins" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.project_name}-ng-jenkins"
  node_role_arn   = var.node_role_arn
  subnet_ids      = [var.subnet_ids[0]]

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = 2
    min_size     = 1
  }

  instance_types = [var.node_instance_type]
  ami_type       = var.node_ami_type

  labels = {
    role = "jenkins-ng"
  }

  tags = {
    Name = "${var.project_name}-ng-jenkins"
  }
}

# -----------------------------------
# Creating App Node group
# -----------------------------------

resource "aws_eks_node_group" "app" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.project_name}-ng-app"
  node_role_arn   = var.node_role_arn
  subnet_ids      = [var.subnet_ids[1]]

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = 2
    min_size     = 1
  }

  instance_types = [var.node_instance_type]
  ami_type       = var.node_ami_type

  labels = {
    role = "app-ng"
  }

  tags = {
    Name = "${var.project_name}-ng-app"
  }
}
