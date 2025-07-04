variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "subnet_ids" {
  description = "List of subnet IDs where EKS cluster control plane (ENIs) will be provisioned"
  type        = list(string)
}

variable "iam_user" {
  description = "I AM user name to be granted admin access to the EKS cluster"
  type        = string
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

