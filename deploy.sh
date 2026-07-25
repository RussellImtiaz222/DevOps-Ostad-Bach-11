#!/bin/bash

set -e

echo "🚀 Starting deployment..."

# Apply storage first
echo "📦 Creating Persistent Volume..."
kubectl apply -f storage.yaml

# Apply secrets and configmap
echo "🔐 Applying secrets and configmap..."
kubectl apply -f secrets.yaml
kubectl apply -f configmap.yaml

# Deploy database
echo "🗄️ Deploying database..."
kubectl apply -f database-deployment.yaml

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql --timeout=120s

# Deploy backend
echo "⚙️ Deploying backend..."
kubectl apply -f backend-deployment.yaml

# Wait for backend to be ready
echo "⏳ Waiting for backend to be ready..."
kubectl wait --for=condition=ready pod -l app=backend --timeout=120s

# Deploy frontend
echo "🎨 Deploying frontend..."
kubectl apply -f frontend-deployment.yaml

# Wait for frontend to be ready
echo "⏳ Waiting for frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend --timeout=120s

# Deploy services
echo "🌐 Deploying services..."
kubectl apply -f services.yaml

# Deploy ingress if available
if kubectl get ingressclass nginx > /dev/null 2>&1; then
    echo "🔀 Installing NGINX Ingress Controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/kind/deploy.yaml
    sleep 30
    echo "🔀 Applying ingress rules..."
    kubectl apply -f ingress.yaml
fi

echo "✅ Deployment complete!"
echo ""
echo "📊 Pod status:"
kubectl get pods -o wide
echo ""
echo "🔍 Services:"
kubectl get svc
echo ""
echo "📝 Node status:"
kubectl get nodes -o wide