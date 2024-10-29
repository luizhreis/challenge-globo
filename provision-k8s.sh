#!/bin/bash

minikube start

eval $(minikube -p minikube docker-env)

docker build -t comments-api ./app/

minikube addons enable ingress

kubectl apply -f k8s/api-config.yml
kubectl apply -f k8s/api-deployment.yml
kubectl apply -f k8s/api-service.yml
kubectl apply -f k8s/ingress.yml