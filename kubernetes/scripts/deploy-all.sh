#!/bin/bash
set -euo pipefail

NAMESPACE="agro-drones"
AWS_REGION="us-east-1"
ECR_REGISTRY="996417348665.dkr.ecr.us-east-1.amazonaws.com"
ECR_SECRET="ecr-secret"

echo "🔍 Verifying kubectl access..."
kubectl version --client > /dev/null

echo "🔍 Verifying AWS access..."
aws sts get-caller-identity > /dev/null

echo "📦 Creating namespace (if not exists)..."
kubectl get ns $NAMESPACE >/dev/null 2>&1 || \
kubectl create namespace $NAMESPACE

echo "🔐 Creating ECR imagePullSecret (if not exists)..."
kubectl get secret $ECR_SECRET -n $NAMESPACE >/dev/null 2>&1 || \
kubectl create secret docker-registry $ECR_SECRET \
  --docker-server=$ECR_REGISTRY \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region $AWS_REGION) \
  -n $NAMESPACE

echo "📂 Applying secrets..."
kubectl apply -f secrets/ -n $NAMESPACE

echo "💾 Applying database resources..."
kubectl apply -f database/ -n $NAMESPACE

echo "🧠 Deploying backend..."
kubectl apply -f backend/ -n $NAMESPACE

echo "🎨 Deploying frontend..."
kubectl apply -f frontend/ -n $NAMESPACE

echo "🔐 Applying network policies..."
kubectl apply -f network-policies/ -n $NAMESPACE

echo "⏳ Waiting for pods to become ready..."
kubectl wait --for=condition=Ready pod \
  --all -n $NAMESPACE --timeout=180s

echo "✅ Deployment completed successfully!"
