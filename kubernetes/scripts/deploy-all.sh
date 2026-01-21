#!/bin/bash

kubectl apply -f namespace/
kubectl apply -f secrets/
kubectl apply -f database/
kubectl apply -f backend/
kubectl apply -f frontend/
kubectl apply -f network-policies/
