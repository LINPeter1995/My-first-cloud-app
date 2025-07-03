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

