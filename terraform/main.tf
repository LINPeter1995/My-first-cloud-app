terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.26.0"
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

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name                    = "my-eks-cluster"
  cluster_version                 = "1.29"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  vpc_id                          = module.vpc.vpc_id

  eks_managed_node_groups = {
    default = {
      desired_size   = 1
      max_size       = 2
      min_size       = 1
      instance_types = ["t3.medium"]
      subnet_ids     = module.vpc.public_subnets
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "kubernetes_deployment" "my_app" {
  metadata {
    name = "myapp"
    labels = {
      app = "myapp"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "myapp"
      }
    }

    template {
      metadata {
        labels = {
          app = "myapp"
        }
      }

      spec {
        container {
          name  = "myapp"
          image = "${aws_ecr_repository.my_app_repo.repository_url}:latest"
          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "my_app_service" {
  metadata {
    name = "myapp-service"
  }

  spec {
    selector = {
      app = kubernetes_deployment.my_app.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 8080
    }
    type = "LoadBalancer"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name                 = "my-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = ["ap-northeast-1a", "ap-northeast-1c"]
  public_subnets       = ["10.0.1.0/24", "10.0.2.0/24"]
  enable_dns_hostnames = true
}

resource "aws_ecr_repository" "my_app_repo" {
  name = "my-app-repo"
}

resource "aws_s3_bucket" "static_assets" {
  bucket        = "my-static-assets-${random_id.suffix.hex}"
  force_destroy = true
}

