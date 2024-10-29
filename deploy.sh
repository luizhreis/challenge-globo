#!/bin/bash

IMAGE_NAME="comments-api"
TAG="dev-$(git rev-parse --short HEAD)"

eval $(minikube -p minikube docker-env)

echo "Running code tests..."
# run tests like pytest
# if failed, abort


echo "Running security validation..."
# run tests like Trivy
# if failed, abort

echo "Building Docker image..."
docker build -t ${IMAGE_NAME}:${TAG} ./app/

echo "Updating api-deployment.yml with new image tag..."
sed -i "s|image: ${IMAGE_NAME}.*|image: ${IMAGE_NAME}:${TAG}|" api-deployment.yml

# Commit updated image tag to k8s file. Commented out only to keep repository clean
# echo "Committing updated api-deployment.yml to Git..."
# git add api-deployment.yml
# git commit -m "chore: Update image tag to ${TAG} in api-deployment.yml"
# git push

echo "Deploying..."
kubectl apply -f k8s/api-deployment.yml
kubectl set image deployment/comments-api comments-api=${IMAGE_NAME}:${TAG}

kubectl rollout status deployment/comments-api