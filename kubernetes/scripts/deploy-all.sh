#!/bin/bash
set -euo pipefail

########################################
# VARIABLES
########################################
APP_NAMESPACE="agro-drones"
INGRESS_NAMESPACE="ingress-nginx"
METALLB_NAMESPACE="metallb-system"

AWS_REGION="us-east-1"
ECR_REGISTRY="996417348665.dkr.ecr.us-east-1.amazonaws.com"
ECR_SECRET="ecr-secret"

echo "🚀 Starting full Kubernetes deployment..."

########################################
# PRE-FLIGHT CHECKS
########################################
echo "🔍 Verifying tools access..."
kubectl version --client >/dev/null
aws sts get-caller-identity >/dev/null

########################################
# NAMESPACES
########################################
echo "📦 Ensuring namespaces..."

kubectl get ns ${APP_NAMESPACE} >/dev/null 2>&1 || kubectl create namespace ${APP_NAMESPACE}
kubectl get ns ${INGRESS_NAMESPACE} >/dev/null 2>&1 || kubectl create namespace ${INGRESS_NAMESPACE}
kubectl get ns ${METALLB_NAMESPACE} >/dev/null 2>&1 || kubectl create namespace ${METALLB_NAMESPACE}

sleep 3

########################################
# METALLB (STABLE OLD VERSION - NO WEBHOOK)
########################################
echo "🌐 Installing MetalLB (stable)..."

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

sleep 15

echo "📡 Configuring MetalLB address pool..."
kubectl apply -f metallb/config.yaml

sleep 5



########################################
# ECR IMAGE PULL SECRET
########################################
echo "🔐 Ensuring ECR imagePullSecret..."

kubectl get secret ${ECR_SECRET} -n ${APP_NAMESPACE} >/dev/null 2>&1 || \
kubectl create secret docker-registry ${ECR_SECRET} \
  --docker-server=${ECR_REGISTRY} \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region ${AWS_REGION}) \
  -n ${APP_NAMESPACE}

sleep 3

########################################
# APPLICATION SECRETS
########################################
echo "🗝️ Applying application secrets..."
kubectl apply -f secrets/
sleep 3

########################################
# INGRESS CONTROLLER
########################################
echo "🚦 Deploying Ingress Controller..."
kubectl apply -f ingress-nginx/

echo "⏳ Waiting for Ingress Controller rollout..."
kubectl rollout status deployment ingress-nginx-controller \
  -n ${INGRESS_NAMESPACE} --timeout=300s

sleep 5

########################################
# DATABASE
########################################
echo "🗄️ Deploying PostgreSQL..."
kubectl apply -f database/
sleep 5

########################################
# BACKEND
########################################
echo "🧠 Deploying Backend..."
kubectl apply -f backend/
sleep 5

########################################
# FRONTEND
########################################
echo "🎨 Deploying Frontend..."
kubectl apply -f frontend/
sleep 5

########################################
# INGRESS RULES
########################################
echo "🌍 Applying Ingress rules..."
kubectl apply -f ingress/
sleep 3

########################################
# NETWORK POLICIES
########################################
if [ -d "network-policies" ]; then
  echo "🔒 Applying Network Policies..."
  kubectl apply -f network-policies/
  sleep 3
fi

########################################
# FINAL READINESS CHECK
########################################
echo "⏳ Waiting for application pods..."
kubectl wait --for=condition=Ready pod \
  --all -n ${APP_NAMESPACE} --timeout=300s || \
echo "⚠️ Some pods still initializing — check logs"

########################################
# SUCCESS
########################################
echo "✅ Deployment completed successfully!"
echo "🌐 Application should now be reachable via Ingress"
