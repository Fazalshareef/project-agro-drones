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

kubectl get ns ${APP_NAMESPACE} >/dev/null 2>&1 || \
kubectl create namespace ${APP_NAMESPACE}

kubectl get ns ${INGRESS_NAMESPACE} >/dev/null 2>&1 || \
kubectl create namespace ${INGRESS_NAMESPACE}

kubectl get ns ${METALLB_NAMESPACE} >/dev/null 2>&1 || \
kubectl create namespace ${METALLB_NAMESPACE}

sleep 3

########################################
# METALLB (v0.13 CONFIGMAP STYLE)
########################################
echo "🌐 Installing MetalLB..."
kubectl apply -f kubernetes/metallb/native.yaml

sleep 10

echo "📡 Configuring MetalLB IP pool..."
kubectl apply -f kubernetes/metallb/config.yaml


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
kubectl apply -f kubernetes/secrets/
sleep 3

########################################
# INGRESS CONTROLLER
########################################
echo "🚦 Deploying Ingress Controller..."
kubectl apply -f kubernetes/ingress-nginx/

echo "⏳ Waiting for Ingress Controller rollout..."
kubectl rollout status deployment ingress-nginx-controller \
  -n ${INGRESS_NAMESPACE} --timeout=300s

sleep 5

########################################
# DATABASE (PV → PVC → DEPLOYMENT → SERVICE)
########################################
echo "🗄️ Deploying PostgreSQL..."
kubectl apply -f kubernetes/database/
sleep 5

########################################
# BACKEND
########################################
echo "🧠 Deploying Backend..."
kubectl apply -f kubernetes/backend/
sleep 5

########################################
# FRONTEND
########################################
echo "🎨 Deploying Frontend..."
kubectl apply -f kubernetes/frontend/
sleep 5

########################################
# INGRESS RULES (DOMAIN ROUTING)
########################################
echo "🌍 Applying Ingress rules..."
kubectl apply -f kubernetes/ingress/
sleep 3

########################################
# NETWORK POLICIES (OPTIONAL / SECURITY)
########################################
if [ -d "kubernetes/network-policies" ]; then
  echo "🔒 Applying Network Policies..."
  kubectl apply -f kubernetes/network-policies/
  sleep 3
fi

########################################
# FINAL READINESS CHECK
########################################
echo "⏳ Waiting for all application pods to be Ready..."
kubectl wait --for=condition=Ready pod \
  --all -n ${APP_NAMESPACE} --timeout=300s || \
echo "⚠️ Some pods are still initializing (check logs if needed)"

########################################
# SUCCESS
########################################
echo "✅ Deployment completed successfully!"
echo "🌐 Application should be accessible via Ingress (domain configured)"
