#!/bin/bash
set -euo pipefail

NAMESPACE="agro-drones"
INGRESS_NS="ingress-nginx"
AWS_REGION="us-east-1"
ECR_REGISTRY="996417348665.dkr.ecr.us-east-1.amazonaws.com"
ECR_SECRET="ecr-secret"

echo "🔍 Validating tools access..."
kubectl version --client > /dev/null
aws sts get-caller-identity > /dev/null

# --- App namespace ---
echo "📦 Ensuring namespace: $NAMESPACE"
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create namespace $NAMESPACE
sleep 3

# --- Ingress namespace ---
echo "🌐 Ensuring namespace: $INGRESS_NS"
kubectl get ns $INGRESS_NS >/dev/null 2>&1 || kubectl create namespace $INGRESS_NS
sleep 5

# --- ECR secret ---
echo "🔐 Ensuring ECR secret..."
kubectl get secret $ECR_SECRET -n $NAMESPACE >/dev/null 2>&1 || \
kubectl create secret docker-registry $ECR_SECRET \
  --docker-server=$ECR_REGISTRY \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region $AWS_REGION) \
  -n $NAMESPACE
sleep 3

# --- Core configs ---
echo "⚙️ Applying namespaces & secrets..."
kubectl apply -f namespace/
sleep 2
kubectl apply -f secrets/
sleep 3

# 🔥 Infrastructure first
echo "🚀 Deploying Ingress Controller..."
kubectl apply -f ingress-controller/

echo "⏳ Waiting for Ingress Controller to be ready..."
kubectl rollout status deployment ingress-nginx-controller \
  -n $INGRESS_NS --timeout=180s
sleep 5

# --- App stack ---
echo "🗄️ Deploying database..."
kubectl apply -f database/
sleep 5

echo "🧠 Deploying backend..."
kubectl apply -f backend/
sleep 5

echo "🎨 Deploying frontend..."
kubectl apply -f frontend/
sleep 5

# --- Routing & security ---
echo "🛣️ Applying ingress rules..."
kubectl apply -f ingress/
sleep 3

echo "🔒 Applying network policies..."
kubectl apply -f network-policies/
sleep 3

# --- Final readiness check ---
echo "⏳ Waiting for all application pods..."
kubectl wait --for=condition=Ready pod \
  --all -n $NAMESPACE --timeout=300s

echo "✅ Deployment completed successfully!"
