variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "subnet_ids" {
  description = "List of subnet IDs where EKS cluster control plane (ENIs) will be provisioned"
  type        = list(string)
  default     = []
}
