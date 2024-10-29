#!/bin/bash

minikube start

eval $(minikube -p minikube docker-env)

docker build -t comments-api ./app/

minikube addons enable ingress

kubectl apply -f k8s/api-config.yml
kubectl apply -f k8s/api-deployment.yml
kubectl apply -f k8s/api-service.yml
kubectl apply -f k8s/ingress.yml

# Adiciona o repositório Helm do Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Instala Prometheus
helm install prometheus prometheus-community/prometheus

# Adiciona o repositório Helm do Grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Instala Grafana
helm install grafana grafana/grafana --set adminPassword='admin' --set service.type=LoadBalancer

minikube service grafana --url
