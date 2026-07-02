# Module 11: Kubernetes Deployment Assignment

A comprehensive Kubernetes cluster setup and application deployment using Minikube on Docker Desktop.

## 📋 Overview

This assignment demonstrates core Kubernetes concepts including:
- **Cluster Setup**: Minikube with Docker driver for local development
- **Multi-Resource Deployment**: Deployment, Service, ConfigMap, and Secret resources
- **Application Isolation**: Namespace-based resource organization
- **Service Exposure**: NodePort and port-forwarding configuration
- **Scaling**: Horizontal Pod Autoscaling demonstration
- **Configuration Management**: Externalized configs via ConfigMap and Secret

## 🚀 Quick Start

### Prerequisites
- Docker Desktop installed and running
- kubectl installed locally
- Minikube installed (or `choco install minikube` on Windows)

### 1. Start Minikube Cluster
```bash
minikube start --driver=docker
minikube status
kubectl cluster-info
```

### 2. Deploy Application
```bash
# Navigate to project directory
cd "c:\Users\iruss\Module 11 Assignment"

# Apply all manifests
kubectl apply -f 06-namespace.yaml
kubectl apply -f 03-configmap.yaml
kubectl apply -f 04-secret.yaml
kubectl apply -f 01-nginx-deployment.yaml
kubectl apply -f 02-nginx-service.yaml
```

### 3. Verify Deployment
```bash
# Check namespace
kubectl get namespace dev-env

# Check pods
kubectl get pods -n dev-env -o wide

# Check service
kubectl get svc -n dev-env

# Check deployment
kubectl get deployment -n dev-env
```

### 4. Access the Application

**Method 1: Port Forwarding (Recommended)**
```bash
kubectl port-forward svc/nginx-service 8080:80 -n dev-env
# Open browser: http://localhost:8080
```

**Method 2: Minikube Service URL**
```bash
minikube service nginx-service -n dev-env
# Automatically opens in default browser
```

**Method 3: Direct NodePort**
```bash
minikube ip
# Access: http://192.168.49.2:30080
```

## 📦 Deployment Files

| File | Purpose | Status |
|------|---------|--------|
| `06-namespace.yaml` | Creates isolated namespace (dev-env) | ✅ Deployed |
| `03-configmap.yaml` | Application configuration (5 parameters) | ✅ Deployed |
| `04-secret.yaml` | Credentials (username, password, API key) | ✅ Deployed |
| `01-nginx-deployment.yaml` | Nginx app (2 replicas, scalable) | ✅ Deployed |
| `02-nginx-service.yaml` | NodePort service (port 30080) | ✅ Deployed |
| `05-updated-deployment.yaml` | Example: Image update scenario | Reference |
| `07-broken-deployment.yaml` | Example: Broken deployment (for learning) | Reference |

## 🔧 Common Commands

### View Resources
```bash
# List all pods in dev-env namespace
kubectl get pods -n dev-env -o wide

# Describe specific pod
kubectl describe pod <pod-name> -n dev-env

# View pod logs
kubectl logs <pod-name> -n dev-env

# View ConfigMap
kubectl get configmap -n dev-env
kubectl describe configmap app-config -n dev-env

# View Secret
kubectl get secret -n dev-env
kubectl describe secret app-secret -n dev-env
```

### Scaling
```bash
# Scale to 3 replicas
kubectl scale deployment nginx-deployment -n dev-env --replicas=3

# Scale to 4 replicas
kubectl scale deployment nginx-deployment -n dev-env --replicas=4

# Check scaling status
kubectl get deployment nginx-deployment -n dev-env
kubectl get pods -n dev-env -o wide
```

### Troubleshooting
```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes

# View events
kubectl get events -n dev-env

# Execute command in pod
kubectl exec -it <pod-name> -n dev-env -- bash

# Port-forward to specific pod
kubectl port-forward pod/<pod-name> 8080:80 -n dev-env
```

## 📊 Cluster Information

**Minikube Setup:**
- Cluster Type: Minikube v1.38.1 (Docker driver)
- Kubernetes Version: v1.31.0
- Container Runtime: Docker Desktop
- Cluster IP: 192.168.49.2
- Node Status: minikube (Ready)

**Application Deployment:**
- Namespace: `dev-env`
- Replicas: 2+ (scalable to 4+)
- Service Type: NodePort
- Service Port: 30080
- Container Image: nginx:1.24

## 📁 Project Structure
```
Module 11 Assignment/
├── README.md                    # This file
├── SUBMISSION.md                # Detailed assignment submission
├── SETUP_GUIDE.md               # Installation & setup instructions
├── INSTALLATION_GUIDE.md        # Detailed installation guide
├── COMMANDS_REFERENCE.md        # kubectl commands reference
├── POD_SCALING_RESULTS.md       # Pod status & scaling screenshots
├── 01-nginx-deployment.yaml     # Nginx deployment manifest
├── 02-nginx-service.yaml        # Service exposure manifest
├── 03-configmap.yaml            # Configuration manifest
├── 04-secret.yaml               # Credentials manifest
├── 05-updated-deployment.yaml   # Rolling update example
├── 06-namespace.yaml            # Namespace manifest
├── 07-broken-deployment.yaml    # Broken deployment example
└── .pem/                        # SSH key storage (for AWS alternative)
```

## 🔍 Resource Details

### ConfigMap (app-config)
```yaml
APP_MODE: dev
APP_ENV: development
LOG_LEVEL: info
MAX_CONNECTIONS: 100
NGINX_WORKER_PROCESSES: 2
```

### Secret (app-secret)
```yaml
username: admin
password: SecureP@ssw0rd
api_key: sk-proj-1234567890abcdef
```

### Deployment Specifications
- **Replicas**: 2 (default, scalable)
- **Image**: nginx:1.24
- **CPU Request**: 100m | Limit: 200m
- **Memory Request**: 64Mi | Limit: 128Mi
- **Health Checks**: 
  - Liveness Probe: Every 10 seconds
  - Readiness Probe: Every 5 seconds
- **Update Strategy**: RollingUpdate (maxSurge=1, maxUnavailable=0)

## 🧪 Testing the Deployment

### Test Service Connectivity
```bash
# Port-forward the service
kubectl port-forward svc/nginx-service 8080:80 -n dev-env

# In another terminal, test with curl
curl http://localhost:8080

# Expected response: Nginx welcome page (HTTP 200)
```

### Test Scaling
```bash
# Scale from 2 to 4 replicas
kubectl scale deployment nginx-deployment -n dev-env --replicas=4

# Watch pods being created
kubectl get pods -n dev-env --watch

# Verify all are running
kubectl get pods -n dev-env -o wide
```

### Test Configuration
```bash
# Check ConfigMap mounted in pod
kubectl exec -it <pod-name> -n dev-env -- env | grep APP_

# Check Secret mounted in pod
kubectl exec -it <pod-name> -n dev-env -- cat /etc/secrets/username
```

## 🛑 Cleanup

### Stop Minikube
```bash
# Stop cluster (preserves state)
minikube stop

# Delete cluster (removes all resources)
minikube delete

# Verify deletion
minikube status
```

### Delete Namespace & Resources
```bash
# Delete entire namespace (removes all resources in it)
kubectl delete namespace dev-env

# Verify deletion
kubectl get namespace
```

## 📚 Documentation Files

- **[SUBMISSION.md](SUBMISSION.md)** - Complete assignment submission with detailed explanations
- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Step-by-step setup instructions
- **[INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md)** - Software installation guide
- **[COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md)** - kubectl commands reference
- **[POD_SCALING_RESULTS.md](POD_SCALING_RESULTS.md)** - Pod status and scaling results

## 🔗 Alternative: AWS EC2 Setup

This assignment also supports kubeadm on AWS EC2 instances. See [SUBMISSION.md](SUBMISSION.md#alternative-aws-ec2-setup-with-kubeadm) for details:
- Master Node: t3.medium instance
- Worker Node: t3.medium instance
- Container Runtime: containerd v2.2.5
- Kubernetes: v1.29.15

## ✅ Assignment Completion Checklist

- [x] Cluster setup (Minikube)
- [x] Namespace creation (dev-env)
- [x] ConfigMap deployment (app-config)
- [x] Secret deployment (app-secret)
- [x] Deployment creation (nginx, 2+ replicas)
- [x] Service configuration (NodePort)
- [x] Service accessibility verification
- [x] Horizontal scaling demonstration
- [x] Documentation complete

## 🎓 Learning Outcomes

After completing this assignment, you will understand:
1. Kubernetes cluster initialization and management
2. Multi-resource YAML manifest deployment
3. Namespace-based resource isolation
4. Configuration externalization via ConfigMap
5. Credential management via Secret
6. Service exposure and load balancing
7. Horizontal Pod Autoscaling
8. kubectl commands for management and troubleshooting

## 📖 References

- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [YAML Manifest Reference](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/)

## 👤 Author

Russell Imtiaz  
Submission Date: 2026-07-02  
Branch: `module-11-kubernetes-assignment`

---

**Status**: ✅ Complete and ready for submission

For detailed information, see [SUBMISSION.md](SUBMISSION.md)
