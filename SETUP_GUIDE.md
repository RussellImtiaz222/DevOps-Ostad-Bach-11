# Module 11: Kubernetes Assignment - Complete Guide

## Prerequisites
- `kubectl` (v1.34.1) ✓ Already installed
- Minikube (v1.38.1) ✓ Installed and Running
- Docker (required by Minikube) ✓ Running

## Part 1: Cluster Setup

### Option A: Using Minikube (Recommended - Already Installed)
```powershell
# Minikube v1.38.1 is installed

# Verify installation:
minikube version
minikube status

# Start cluster:
minikube start --driver=docker
```

### Option B: Using K3s
```powershell
# Download K3s installer
# Visit: https://k3s.io/
```

## Quick Start (Once Cluster is Running)

1. **Verify cluster is running**
   ```bash
   minikube status
   kubectl cluster-info
   kubectl get nodes
   kubectl get pods -n kube-system
   ```

2. **Deploy all resources in order**
   ```bash
   # ConfigMap
   kubectl apply -f 03-configmap.yaml
   
   # Secret
   kubectl apply -f 04-secret.yaml
   
   # Deployment
   kubectl apply -f 01-nginx-deployment.yaml
   
   # Service
   kubectl apply -f 02-nginx-service.yaml
   ```

3. **Verify deployment**
   ```bash
   kubectl get all
   kubectl get pods -o wide
   kubectl get svc nginx-service
   ```

4. **Access application via port-forward**
   ```bash
   kubectl port-forward service/nginx-service 8080:80
   # Then open: http://localhost:8080 in your browser
   ```

5. **Perform scaling and rollout tests** (see COMMANDS_REFERENCE.md)

## Files in This Assignment

- `SETUP_GUIDE.md` - This file
- `01-nginx-deployment.yaml` - Nginx Deployment with 2 replicas
- `02-nginx-service.yaml` - NodePort Service
- `03-configmap.yaml` - Application configuration
- `04-secret.yaml` - Credentials secret
- `05-updated-deployment.yaml` - Deployment with ConfigMap/Secret injection
- `06-namespace.yaml` - Custom namespace
- `07-broken-deployment.yaml` - Example of a broken deployment for troubleshooting
- `SUBMISSION.md` - Document your findings here
- `COMMANDS_REFERENCE.md` - Complete command reference guide

## Current Deployment Status

### Cluster Information
- **Minikube Version**: v1.38.1
- **Kubernetes Version**: v1.31.0
- **Driver**: Docker Desktop
- **Status**: ✅ Running and Ready

### Deployed Resources
- **ConfigMap (app-config)**: ✅ Created
- **Secret (app-secret)**: ✅ Created
- **Deployment (nginx-deployment)**: ✅ 2 replicas running
- **Service (nginx-service)**: ✅ NodePort 30080 configured

### Pod Status
- **nginx-deployment-fd944774d-4xd2l**: 1/1 Running
- **nginx-deployment-fd944774d-n562x**: 1/1 Running

### Service Access
- **Service Type**: NodePort
- **Service Port**: 80
- **Node Port**: 30080
- **Access Method**: http://localhost:8080 (via port-forward)
- **Status**: ✅ Successfully Accessible

### Next Steps
1. Run additional tests from COMMANDS_REFERENCE.md
2. Test scaling to 4 replicas
3. Perform rolling updates and rollbacks
4. Deploy to custom namespaces
5. Create and troubleshoot broken deployments

