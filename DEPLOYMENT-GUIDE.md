# DevOps Deployment Guide

## Overview

This guide explains how to deploy the multi-environment chat application to production Kubernetes clusters (AWS EKS, Azure AKS, Google GKE, or any Kubernetes cluster).

**Current Status:**
- ✅ Docker images automatically built and pushed to GHCR via GitHub Actions
- ✅ All Kubernetes manifests created and configured
- ✅ Dev environment successfully deployed locally

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [AWS EKS Deployment](#aws-eks-deployment)
3. [Azure AKS Deployment](#azure-aks-deployment)
4. [Google GKE Deployment](#google-gke-deployment)
5. [Generic Kubernetes Deployment](#generic-kubernetes-deployment)
6. [Post-Deployment Verification](#post-deployment-verification)

---

## Prerequisites

Before deploying to any cloud provider, ensure you have:

### Required Tools
```powershell
# Kubernetes CLI
kubectl version --client

# Cloud CLI (choose one)
aws --version              # For AWS EKS
az --version               # For Azure AKS  
gcloud --version           # For Google GKE
```

### GitHub Container Registry (GHCR) Setup
All images are stored at: `ghcr.io/russellimtiaz222/`

**Create a GitHub Personal Access Token (PAT):**
1. Go to https://github.com/settings/tokens
2. Generate new token with scopes:
   - `read:packages` (pull images)
   - `write:packages` (push images)
3. Save the token securely

---

## AWS EKS Deployment

### 1. Create EKS Cluster

```powershell
# Set variables
$CLUSTER_NAME = "simple-chat-prod"
$REGION = "us-east-1"
$NODE_COUNT = 3

# Create cluster using AWS CLI
aws eks create-cluster `
  --name $CLUSTER_NAME `
  --region $REGION `
  --version 1.27 `
  --roleArn arn:aws:iam::YOUR_ACCOUNT_ID:role/eks-service-role `
  --resourcesVpcConfig subnetIds=subnet-xxxxx,subnet-xxxxx

# Add node group
aws eks create-nodegroup `
  --cluster-name $CLUSTER_NAME `
  --nodegroup-name primary-nodes `
  --region $REGION `
  --subnets subnet-xxxxx subnet-xxxxx `
  --node-role arn:aws:iam::YOUR_ACCOUNT_ID:role/eks-node-role `
  --scaling-config minSize=3,maxSize=6,desiredSize=3

# Get kubeconfig
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
```

### 2. Create Docker Registry Secret

```powershell
$PAT = "your_github_pat_token_here"
$NAMESPACE = "simple-chat-prod"

# Create namespace
kubectl create namespace $NAMESPACE

# Create GHCR secret
kubectl create secret docker-registry ghcr-secret `
  --docker-server=ghcr.io `
  --docker-username=russellimtiaz222 `
  --docker-password=$PAT `
  --docker-email=russellimtiaz222@example.com `
  -n $NAMESPACE
```

### 3. Apply Kubernetes Manifests

```powershell
# Deploy prod environment
kubectl apply -f Capstan-Project/k8s/prod/ -n simple-chat-prod

# Verify deployment
kubectl get all -n simple-chat-prod
kubectl get pods -n simple-chat-prod -o wide
```

### 4. Set Up Load Balancer

```powershell
# Change service type to LoadBalancer
kubectl patch svc frontend-prod -n simple-chat-prod -p '{"spec":{"type":"LoadBalancer"}}'

# Get external IP
kubectl get svc frontend-prod -n simple-chat-prod --watch
```

---

## Azure AKS Deployment

### 1. Create AKS Cluster

```powershell
# Set variables
$RESOURCE_GROUP = "simple-chat-prod"
$CLUSTER_NAME = "simple-chat-aks"
$LOCATION = "eastus"
$NODE_COUNT = 3

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create AKS cluster
az aks create `
  --resource-group $RESOURCE_GROUP `
  --name $CLUSTER_NAME `
  --node-count $NODE_COUNT `
  --vm-set-type VirtualMachineScaleSets `
  --load-balancer-sku standard `
  --enable-managed-identity `
  --network-plugin azure `
  --docker-bridge-address 172.17.0.1/16 `
  --service-cidr 10.0.0.0/16 `
  --dns-service-ip 10.0.0.10 `
  --kubernetes-version 1.27

# Get kubeconfig
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing
```

### 2. Create Docker Registry Secret (Same as EKS)

```powershell
$PAT = "your_github_pat_token_here"
$NAMESPACE = "simple-chat-prod"

kubectl create namespace $NAMESPACE

kubectl create secret docker-registry ghcr-secret `
  --docker-server=ghcr.io `
  --docker-username=russellimtiaz222 `
  --docker-password=$PAT `
  --docker-email=russellimtiaz222@example.com `
  -n $NAMESPACE
```

### 3. Apply Manifests and Expose Service

```powershell
kubectl apply -f Capstan-Project/k8s/prod/ -n simple-chat-prod

# Change service to LoadBalancer
kubectl patch svc frontend-prod -n simple-chat-prod -p '{"spec":{"type":"LoadBalancer"}}'

# Get public IP
kubectl get svc frontend-prod -n simple-chat-prod --watch
```

---

## Google GKE Deployment

### 1. Create GKE Cluster

```powershell
# Set variables
$PROJECT_ID = "your-gcp-project"
$CLUSTER_NAME = "simple-chat-prod"
$REGION = "us-central1"
$ZONE = "us-central1-a"
$NODE_COUNT = 3

# Create cluster
gcloud container clusters create $CLUSTER_NAME `
  --project=$PROJECT_ID `
  --zone=$ZONE `
  --num-nodes=$NODE_COUNT `
  --machine-type=n1-standard-2 `
  --enable-ip-alias `
  --network="default" `
  --addons=HttpLoadBalancing `
  --workload-pool=$PROJECT_ID`.svc.id.goog

# Get kubeconfig
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID
```

### 2. Create Docker Registry Secret

```powershell
$PAT = "your_github_pat_token_here"
$NAMESPACE = "simple-chat-prod"

kubectl create namespace $NAMESPACE

kubectl create secret docker-registry ghcr-secret `
  --docker-server=ghcr.io `
  --docker-username=russellimtiaz222 `
  --docker-password=$PAT `
  --docker-email=russellimtiaz222@example.com `
  -n $NAMESPACE
```

### 3. Deploy and Expose

```powershell
kubectl apply -f Capstan-Project/k8s/prod/ -n simple-chat-prod

kubectl patch svc frontend-prod -n simple-chat-prod -p '{"spec":{"type":"LoadBalancer"}}'

# Get external IP
kubectl get svc frontend-prod -n simple-chat-prod --watch
```

---

## Generic Kubernetes Deployment

For any Kubernetes cluster (on-premises, DigitalOcean, Linode, etc.):

### 1. Verify Cluster Access

```powershell
kubectl get nodes
kubectl get pods --all-namespaces
```

### 2. Create Namespaces and Secrets

```powershell
# Create all three namespaces
kubectl create namespace simple-chat-dev
kubectl create namespace simple-chat-stage
kubectl create namespace simple-chat-prod

# Create GHCR secret in each namespace
$PAT = "your_github_pat_token_here"

@("dev", "stage", "prod") | ForEach-Object {
    $ns = "simple-chat-$_"
    kubectl create secret docker-registry ghcr-secret `
      --docker-server=ghcr.io `
      --docker-username=russellimtiaz222 `
      --docker-password=$PAT `
      --docker-email=russellimtiaz222@example.com `
      -n $ns
}
```

### 3. Deploy Each Environment

```powershell
# Deploy dev
kubectl apply -f Capstan-Project/k8s/dev/ -n simple-chat-dev

# Deploy stage
kubectl apply -f Capstan-Project/k8s/stage/ -n simple-chat-stage

# Deploy prod
kubectl apply -f Capstan-Project/k8s/prod/ -n simple-chat-prod
```

### 4. Verify Deployments

```powershell
# Check all environments
@("dev", "stage", "prod") | ForEach-Object {
    $ns = "simple-chat-$_"
    Write-Host "`n=== Environment: $_ ==="
    kubectl get pods -n $ns
    kubectl get svc -n $ns
}
```

---

## Post-Deployment Verification

### 1. Check Pod Status

```powershell
$NAMESPACE = "simple-chat-prod"

# All pods should be 1/1 Ready
kubectl get pods -n $NAMESPACE -o wide

# Expected output:
# NAME                              READY   STATUS    RESTARTS   AGE
# backend-prod-xxxxx                1/1     Running   0          5m
# frontend-prod-xxxxx               1/1     Running   0          5m
```

### 2. Verify Health Endpoints

```powershell
# Backend health check
kubectl port-forward -n $NAMESPACE svc/backend-prod 5000:5000 &
$HealthCheck = Invoke-WebRequest -Uri "http://localhost:5000/api/health" -UseBasicParsing
Write-Host $HealthCheck.Content  # Should return {"status":"ok"}

# Stop port-forward
Get-Job | Stop-Job -PassThru | Remove-Job
```

### 3. Access Frontend

**Option 1: Port-Forward (Temporary)**
```powershell
kubectl port-forward -n $NAMESPACE svc/frontend-prod 3000:3000

# Visit: http://localhost:3000
```

**Option 2: Expose with LoadBalancer**
```powershell
kubectl patch svc frontend-prod -n $NAMESPACE -p '{"spec":{"type":"LoadBalancer"}}'
kubectl get svc frontend-prod -n $NAMESPACE

# Use the EXTERNAL-IP value (wait 1-5 minutes for cloud provider to assign)
```

**Option 3: Set Up Ingress**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-ingress
  namespace: simple-chat-prod
spec:
  rules:
  - host: chat.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-prod
            port:
              number: 3000
```

### 4. View Logs

```powershell
$NAMESPACE = "simple-chat-prod"

# Backend logs
kubectl logs -n $NAMESPACE -l app=backend -f

# Frontend logs
kubectl logs -n $NAMESPACE -l app=frontend -f

# All pod events
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'
```

### 5. Monitor Resources

```powershell
# Watch pod status
kubectl get pods -n $NAMESPACE --watch

# View resource usage
kubectl top pods -n $NAMESPACE

# Describe a pod for detailed info
kubectl describe pod -n $NAMESPACE backend-prod-xxxxx
```

---

## Updating Deployments

When you push new code to GitHub, the CI/CD pipeline automatically:

1. Builds new Docker images
2. Pushes images to GHCR with tags: `{env}-latest` and `{env}-{version}`
3. Images are ready for deployment

### Manual Update

```powershell
$NAMESPACE = "simple-chat-prod"

# Force image pull (if using "latest" tag)
kubectl rollout restart deployment/backend-prod -n $NAMESPACE
kubectl rollout restart deployment/frontend-prod -n $NAMESPACE

# Monitor rollout
kubectl rollout status deployment/backend-prod -n $NAMESPACE
kubectl rollout status deployment/frontend-prod -n $NAMESPACE
```

### Automatic Updates

To enable automatic image updates when new images are pushed to GHCR, configure ArgoCD in your cluster (optional).

---

## Troubleshooting

### Pods in ImagePullBackOff

```powershell
$NAMESPACE = "simple-chat-prod"

# Check events
kubectl describe pod -n $NAMESPACE backend-prod-xxxxx

# Verify secret exists
kubectl get secret ghcr-secret -n $NAMESPACE

# Check secret content
kubectl get secret ghcr-secret -n $NAMESPACE -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d
```

### Backend Pods Crashing (CrashLoopBackOff)

```powershell
# Check logs
kubectl logs -n $NAMESPACE -l app=backend --tail=50

# Common issues:
# - NODE_ENV must be "production" (not "staging")
# - CLIENT_URL must contain valid CORS origins
# - Health check failing: backend might not be fully started
```

### Frontend Pods Not Ready

```powershell
# Check Nginx logs
kubectl logs -n $NAMESPACE -l app=frontend

# Check port (should be 3000)
kubectl port-forward -n $NAMESPACE svc/frontend-prod 3000:3000

# Try curl from pod
kubectl exec -it -n $NAMESPACE pod/frontend-prod-xxxxx -- curl localhost:3000
```

### Services Not Accessible

```powershell
# Verify service exists and has endpoints
kubectl get svc -n $NAMESPACE
kubectl describe svc frontend-prod -n $NAMESPACE

# Check if pods are in correct namespace and running
kubectl get pods -n $NAMESPACE -o wide

# Test connectivity from another pod
kubectl run -it --rm debug --image=busybox:1.28 --restart=Never -- /bin/sh
# Inside container: wget -O- http://frontend-prod:3000
```

---

## Scaling

### Horizontal Scaling (More Pod Replicas)

```powershell
$NAMESPACE = "simple-chat-prod"

# Scale backend
kubectl scale deployment backend-prod --replicas=5 -n $NAMESPACE

# Scale frontend
kubectl scale deployment frontend-prod --replicas=5 -n $NAMESPACE

# Verify scaling
kubectl get pods -n $NAMESPACE
```

### Vertical Scaling (More CPU/Memory per Pod)

Edit the resource requests/limits in the respective deployment YAML files:

```yaml
resources:
  requests:
    cpu: 200m        # Increase from 100m
    memory: 256Mi    # Increase from 128Mi
  limits:
    cpu: 1000m       # Increase from 500m
    memory: 1Gi      # Increase from 512Mi
```

---

## Backup & Disaster Recovery

### Backup Manifests
```powershell
# Export current deployments
kubectl get deployment -n simple-chat-prod -o yaml > prod-deployment-backup.yaml
kubectl get configmap -n simple-chat-prod -o yaml > prod-configmap-backup.yaml
kubectl get svc -n simple-chat-prod -o yaml > prod-services-backup.yaml
```

### Restore from Manifests
```powershell
kubectl apply -f prod-deployment-backup.yaml
kubectl apply -f prod-configmap-backup.yaml
kubectl apply -f prod-services-backup.yaml
```

---

## Next Steps

1. **Choose your cloud provider** (AWS/Azure/GKE or any K8s cluster)
2. **Follow the specific section** for your platform
3. **Create GHCR secret** with your GitHub PAT
4. **Apply manifests** to deploy the application
5. **Verify** using the post-deployment checklist
6. **Monitor** logs and resource usage

---

## Support & Questions

For detailed troubleshooting:
- Check pod events: `kubectl describe pod <pod-name> -n <namespace>`
- View logs: `kubectl logs <pod-name> -n <namespace>`
- Check service endpoints: `kubectl get endpoints <service-name> -n <namespace>`
- Test connectivity: `kubectl port-forward svc/<service-name> <port>:<port> -n <namespace>`

