output "vpc_id" {
  description = "VPC ID"
  value       = data.aws_vpc.allcle_vpc.id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = [data.aws_subnet.public_a.id, data.aws_subnet.public_c.id]
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = [data.aws_subnet.private_a.id, data.aws_subnet.private_c.id]
}

output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_id
}
