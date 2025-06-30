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

resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = "db.t3.micro"
  name                 = "myappdb"
  username             = "admin"
  password             = var.db_password  # 建議改用 variable
  parameter_group_name = "default.postgres15"
  skip_final_snapshot  = true
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  name    = "my-vpc"
  cidr    = "10.0.0.0/16"

  azs             = ["ap-northeast-1a", "ap-northeast-1c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  enable_dns_hostnames = true
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.29"
  subnets         = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id

  eks_managed_node_groups = {
    default = {
      desired_size   = 1
      max_size       = 2
      min_size       = 1
      instance_types = ["t3.medium"]
    }
  }
}

variable "db_password" {
  description = "The password for the RDS instance"
  type        = string
  sensitive   = true
}
