variable "aws_region" {
  type    = string
}

variable "project_name" {
  type    = string
}

variable "vpc_cidr" {
  type    = string
}

variable "public_subnet_cidrs" {
  type    = list(string)
}

variable "node_instance_type" {
  type    = string
}

variable "node_ami_type" {
  type    = string
}

variable "desired_capacity" {
  type    = number
}
