variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-1"
}

# 如果你還有其他變數，也可以像下面這樣定義：
# variable "db_password" {
#   description = "Password for the RDS instance"
#   type        = string
#   sensitive   = true
# }
