variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "192.168.0.0/16"
}

variable "public_subnet_a_cidr" {
  description = "Public Subnet A CIDR block"
  type        = string
  default     = "192.168.1.0/24"
}

variable "public_subnet_c_cidr" {
  description = "Public Subnet C CIDR block"
  type        = string
  default     = "192.168.2.0/24"
}


variable "private_subnet_a_cidr" {
  description = "Private Subnet A CIDR block"
  type        = string
  default     = "192.168.3.0/24"
}

variable "private_subnet_c_cidr" {
  description = "Private Subnet C CIDR block"
  type        = string
  default     = "192.168.4.0/24"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "instance_type" {
  description = "EKS instance type"
  type        = string
  default     = "t3.medium"
}

variable "eks_cluster_name" {
  description = "EKS Cluster name"
  type        = string
  default     = "allcle-eks-cluster"
}

variable "node_group_name" {
  description = "EKS Node Group name"
  type        = string
  default     = "allcle-eks-ng"
}

variable "alb_name" {
  description = "ALB Name"
  type        = string
  default     = "FP-ALB"
}

variable "nat_gateway_name" {
  description = "NAT Gateway Name"
  type        = string
  default     = "ALLCLE-NATGW"
}

variable "eks_key_pair" {
    description = "Private Key Pair"
    type = string
    default = "FPT2-Private-key"
}

variable "public_key_pair" {
    description = "Public Key Pair for Bastion"
    type = string
    default = "FPT2-key"
}

# Public Key Pair File path for Linux
variable "public_key_file" {
  description = "Path to the public key file"
  type        = string
  default     = "/mnt/c/Users/ebone/Desktop/T2_Final/FPT2-key.pem"
}
# Private Key Pair File Path for Linux
variable "private_key_file" {
  description = "Path to the private key file"
  type        = string
  default     = "/mnt/c/Users/ebone/Desktop/T2_Final/FPT2-Private-key.pem"
}

variable "eks_ingress_name" {
  description = "K8S Ingress Name"
  type = string
  default = "allcle-ingress"
}