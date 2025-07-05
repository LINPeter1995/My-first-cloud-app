variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "my-eks-cluster"
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "iam_role" {
  description = "IAM role name to be granted admin access to the EKS cluster"
  type        = string
}
