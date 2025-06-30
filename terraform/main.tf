terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.95, < 6.0.0"
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
  name    = "my-vpc"
  cidr    = "10.0.0.0/16"

  azs                = ["ap-northeast-1a", "ap-northeast-1c"]
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  enable_dns_hostnames = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.1"  # 最新版

  cluster = {
    name    = "my-eks-cluster"
    version = "1.29"
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  vpc_config = {
    subnet_ids = module.vpc.public_subnets
  }

  node_groups = {
    default = {
      desired_capacity = 1
      max_capacity     = 2
      min_capacity     = 1
      instance_types   = ["t3.medium"]
    }
  }
}

