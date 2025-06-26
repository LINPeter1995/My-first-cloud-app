provider "aws" {
  region = var.region
}

# 建立 VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "main-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

# 建立 ECR
resource "aws_ecr_repository" "app_repo" {
  name = "my-app-repo"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Environment = "dev"
  }
}

# 建立 EKS
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.8.4"
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.29"
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 3
    }
  }

  tags = {
    Environment = "dev"
  }
}

# 建立 RDS
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_db_instance" "postgres" {
  identifier         = "my-postgres-db"
  engine             = "postgres"
  instance_class     = "db.t3.micro"
  allocated_storage  = 20
  username           = "postgres"
  password           = var.db_password
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [module.vpc.default_security_group_id]
}

# 建立 S3
resource "aws_s3_bucket" "app_bucket" {
  bucket = "my-app-static-assets-${random_id.bucket_id.hex}"

  tags = {
    Environment = "dev"
  }
}

resource "random_id" "bucket_id" {
  byte_length = 4
}
