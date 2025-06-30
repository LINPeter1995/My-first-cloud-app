#!/bin/bash
set -e

echo "部署開始..."

# 切換到 Terraform 專案目錄
cd terraform

# 初始化 Terraform
terraform init

# 檢查 Terraform 設定
terraform validate

# 建立執行計劃（可選）
terraform plan

# 套用 Terraform 建立資源
terraform apply -auto-approve

echo "部署完成"


