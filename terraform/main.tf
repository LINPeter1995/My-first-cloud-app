terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "my-terraform-state-linpeter1995"
    key            = "terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

# 建立 ECR
resource "aws_ecr_repository" "my_app_repo" {
  name = "my-app-repo"
}

# 建立 S3
resource "aws_s3_bucket" "static_assets" {
  bucket = "my-static-assets-${random_id.suffix.hex}"
  force_destroy = true
}

resource "random_id" "suffix" {
  byte_length = 4
}

# 建立 RDS PostgreSQL
resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = "db.t3.micro"
  name                 = "myappdb"
  username             = "admin"
  password             = "YourPassword123"
  parameter_group_name = "default.postgres15"
  skip_final_snapshot  = true
}

# 建立 EKS Cluster（簡化版）
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.29"
  subnets         = ["${module.vpc.public_subnets}"]
  vpc_id          = module.vpc.vpc_id

  eks_managed_node_groups = {
    default = {
      desired_size = 1
      max_size     = 2
      min_size     = 1
      instance_types = ["t3.medium"]
    }
  }
}

# 建立 VPC（供 EKS 使用）
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  name    = "my-vpc"
  cidr    = "10.0.0.0/16"

  azs             = ["ap-northeast-1a", "ap-northeast-1c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  enable_dns_hostnames = true
}
