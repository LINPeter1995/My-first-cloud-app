variable "region" {
  default = "ap-northeast-1"
}

variable "db_password" {
  description = "Password for the RDS PostgreSQL"
  type        = string
  sensitive   = true
}
