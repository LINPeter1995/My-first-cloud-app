output "ecr_repo_url" {
  value = aws_ecr_repository.my_app_repo.repository_url
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "s3_bucket_name" {
  value = aws_s3_bucket.my_bucket.bucket
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_oidc_provider" {
  value = module.eks.oidc_provider
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "node_group_role_arn" {
  value = module.eks.eks_managed_node_groups["default"].iam_role_arn
}


