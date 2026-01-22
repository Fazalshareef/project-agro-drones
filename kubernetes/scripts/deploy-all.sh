#!/bin/bash
set -euo pipefail

NAMESPACE="agro-drones"
AWS_REGION="us-east-1"
ECR_REGISTRY="996417348665.dkr.ecr.us-east-1.amazonaws.com"
ECR_SECRET="ecr-secret"

kubectl version --client > /dev/null
aws sts get-caller-identity > /dev/null

kubectl get ns $NAMESPACE >/dev/null 2>&1 || \
kubectl create namespace $NAMESPACE

kubectl get secret $ECR_SECRET -n $NAMESPACE >/dev/null 2>&1 || \
kubectl create secret docker-registry $ECR_SECRET \
  --docker-server=$ECR_REGISTRY \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region $AWS_REGION) \
  -n $NAMESPACE

kubectl apply -f namespace/
kubectl apply -f secrets/

# 🔥 Infrastructure first
kubectl apply -f ingress-controller/

# App stack
kubectl apply -f database/
kubectl apply -f backend/
kubectl apply -f frontend/

# Routing rules
kubectl apply -f ingress/

kubectl apply -f network-policies/

kubectl wait --for=condition=Ready pod \
  --all -n $NAMESPACE --timeout=180s

echo "✅ Deployment completed successfully!"
