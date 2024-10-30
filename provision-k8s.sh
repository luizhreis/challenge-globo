#!/bin/bash

minikube start

eval $(minikube -p minikube docker-env)

docker build -t comments-api ./app/

minikube addons enable ingress

kubectl apply -f k8s/api-config.yml
kubectl apply -f k8s/api-deployment.yml
kubectl apply -f k8s/api-service.yml
kubectl apply -f k8s/ingress.yml

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/prometheus

kubectl create namespace monitoring

kubectl apply -f k8s/prometheus-configmap.yml

kubectl apply -f k8s/prometheus-deployment.yml


helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install grafana grafana/grafana --set adminPassword='admin' --set service.type=LoadBalancer

minikube service prometheus --url
minikube service grafana --url
