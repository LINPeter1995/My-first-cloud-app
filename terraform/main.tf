terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "<= 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "<= 2.37.1"
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

data "aws_caller_identity" "current" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-1a", "ap-northeast-1c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway = false
  private_subnets = []
  enable_dns_hostnames = true
  enable_dns_support   = true

  map_public_ip_on_launch = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.1"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.31"
  vpc_id          = module.vpc.vpc_id

  cluster_endpoint_public_access = true
  subnet_ids = module.vpc.public_subnets

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
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = "https://A6827D77BBBB6E696C879AD881A5C409.sk1.ap-northeast-1.eks.amazonaws.com"           # EKS cluster endpoint
  cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJTDZxaldaS1lGOWN3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBM01EUXdOVFE0TXpOYUZ3MHpOVEEzTURJd05UVXpNek5hTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUN3bkNZL2lxc2IxemRETWUrNDU5MHFUVk5TR2JnS3dPK3pyVTBOcTd0VjZGL01aUmEyNXJkVGdtRWgKMUozR0Qya1o0Z245UGdWRTNtaEpoWVJJMm80YkNCeENCcGpLS0h1aFNaMHlESEk1RFN5YnlaZVNyZDFhbFFRNwpIWlJ0TTgxdm9VSkF3U3BSc28veHFNQ2pvdGhTRjVORkx2MGkxRFFoSy9DQUdybWNvUkdLTEdiU21zUXU3OVlQCkpWSCtYcWNHaVMzOHBPVDhqNnN3YkRQY3p3M2dwYjRmeno5dEFZQ3ZJMzR2SngyeHoyODZPdE5xUHdKQWFJc3cKUDExTUxiNEEybnZjVURkekhVNTY4QXlCT1FhQXJWVzRCVEkvbFE3dG9TaTNKTVM1b251eEViR3dKNGJtV0hLYQpiSGJlWTRmSTZqWjZwMGFCQXg3Rms0MldHVG9IQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJUZXc3ZW1MQkh3ZWpzOHA0bm90VXhQRzZmT2x6QVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQlVyL2FPN1ZxagorWkZnOXVHY0pLdXdiRVZmMTlJVWxlSGZoOVJ2RnlPN3RmN3lTaWdVWWpBRmdaUUFWY1hyMHpTSkRJSE02RDFSCkF0VmlDT29TRW9UWGRCK1p4NjFybzNrOFFXV2ovR2tscExoMG1LQ0VPZy9jbnZrVEtnNUhyZ0tVT3ZsOWkxaWkKV3JVR3NYdzl3ZS8vMEtIbzNITzRiZDdBUTZxcHZ6NElJZUFxYjB3dmVKZ0ZJTUNwWHFva3FhVm5OWk15ZjhBeAo4RHNMcGpiMGEvSmduN2FUR0xqa0VGbjFxYXBlNFU0cFhWZEJnNXpzR1laQm5TeCtrYjNERlpvQmc1SXVDSHJ6CjV6NlNDdTZkV2QzOW5vNkdWenVZbWtFSlczREdnZ0JyK05RUkhndFVmV0ZlS0wrWnhLZTNxM1d0YTNMME1yd0cKK3JzaDN2bU1DMEp4Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", "my-eks-cluster"]
  }
}

resource "aws_ecr_repository" "my_app_repo" {
  name = "my-app-repo"
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "my_bucket" {
  bucket        = "my-static-assets-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name = "MyStaticAssets"
  }
}

resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = "db.t3.micro"
  db_name              = "your_db_name"
  username             = "your_username"
  password             = "your_password"
  parameter_group_name = "default.postgres15"
  skip_final_snapshot  = true
}

resource "kubernetes_deployment" "my_app" {
  depends_on = [module.eks]

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

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapUsers = yamlencode([
      {
        userarn  = "arn:aws:iam::123456789012:user/TerraformUser"
        username = "TerraformUser"
        groups   = ["system:masters"]
      }
    ])
  }
}