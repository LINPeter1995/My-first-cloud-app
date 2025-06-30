terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.33, < 7.0"
    }
  }

  backend "s3" {
    bucket  = "my-terraform-state-linpeter1995"
    key     = "terraform.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}

provider "aws" {
  region = "ap-northeast-1"
}


resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_ecr_repository" "my_app_repo" {
  name = "my-app-repo"
}

resource "aws_s3_bucket" "static_assets" {
  bucket        = "my-static-assets-${random_id.suffix.hex}"
  force_destroy = true
}

# 從 Secrets Manager 讀取 RDS 機密
data "aws_secretsmanager_secret_version" "rds_secret" {
  secret_id = "My-first-cloud-app_RDS_Postgres"
}

locals {
  rds_secret = jsondecode(data.aws_secretsmanager_secret_version.rds_secret.secret_string)
}

resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = "db.t3.micro"
  name                 = local.rds_secret.dbname
  username             = local.rds_secret.username
  password             = local.rds_secret.password
  parameter_group_name = "default.postgres17"
  skip_final_snapshot  = true
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  name                 = "my-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = ["ap-northeast-1a", "ap-northeast-1c"]
  public_subnets       = ["10.0.1.0/24", "10.0.2.0/24"]
  enable_dns_hostnames = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.32.0"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.29"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id = module.vpc.vpc_id

  # 這裡改用 public_subnets 指定叢集的公有子網
  public_subnets = module.vpc.public_subnets

  eks_managed_node_groups = {
    default = {
      desired_size   = 1
      max_size       = 2
      min_size       = 1
      instance_types = ["t3.medium"]

      # node group 指定使用的子網 ID
      subnet_ids = module.vpc.public_subnets
    }
  }
}




