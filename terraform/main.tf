# ======================================
# VPC Module
# ======================================
module "vpc" {
  source = "./modules/vpc"

  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
}

# ======================================
# Security Groups Module
# ======================================
module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}

# ======================================
# IAM Module
# ======================================
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
}

# ======================================
# EKS Module
# ======================================
module "eks" {
  source = "./modules/eks"

  project_name        = var.project_name
  cluster_role_arn    = module.iam.eks_role_arn
  node_role_arn       = module.iam.eks_node_role_arn
  subnet_ids          = module.vpc.public_subnet_ids
  control_plane_sg_id = module.security_groups.eks_control_plane_sg_id
  node_instance_type  = var.node_instance_type
  node_ami_type       = var.node_ami_type
  desired_capacity    = var.desired_capacity
}

# ======================================
# EBS CSI Module
# ======================================
module "ebs_csi" {
  source = "./modules/ebs-csi"

  project_name          = var.project_name
  cluster_name          = module.eks.cluster_name
  oidc_issuer           = module.eks.oidc_issuer
  jenkins_node_group_id = module.eks.jenkins_node_group_name
  app_node_group_id     = module.eks.app_node_group_name
}
