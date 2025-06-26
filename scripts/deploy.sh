#!/bin/bash
set -e

# 設定參數
AWS_ACCOUNT_ID=832976099588
AWS_REGION=ap-northeast-1
ECR_REPOSITORY=my-springboot-app
IMAGE_TAG=latest
REMOTE_SSH=user@your-server-ip
KUBE_NAMESPACE=default

echo "登入 AWS ECR"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

echo "建置 Docker 映像"
docker build -t $ECR_REPOSITORY:$IMAGE_TAG .

echo "標記映像"
docker tag $ECR_REPOSITORY:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG

echo "推送映像到 ECR"
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG

echo "在遠端伺服器更新 Kubernetes 部署"
ssh $REMOTE_SSH << EOF
kubectl set image deployment/$ECR_REPOSITORY $ECR_REPOSITORY=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG -n $KUBE_NAMESPACE
kubectl rollout status deployment/$ECR_REPOSITORY -n $KUBE_NAMESPACE
EOF

echo "部署完成！"
