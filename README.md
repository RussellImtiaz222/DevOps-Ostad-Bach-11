# Three-Tier Kubernetes Deployment

A complete production-ready three-tier application deployed on Kubernetes v1.29.0 using Kind (Kubernetes in Docker).

## 🎯 Quick Start

### Prerequisites
- Docker Desktop installed and running
- kubectl installed
- Kind installed

### Deploy Everything
```bash
# From c:\Users\iruss\Module 14 Assignment\
./deploy.sh
```

Or manually:
```bash
kubectl apply -f storage.yaml
kubectl apply -f secrets.yaml
kubectl apply -f configmap.yaml
kubectl apply -f database-deployment.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f services.yaml
```

### Verify Deployment
```bash
kubectl get all -o wide
kubectl get pv,pvc
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Kubernetes Cluster                     │
│                    (Kind v1.29.0)                        │
└─────────────────────────────────────────────────────────┘
         │                    │                   │
    ┌────▼────┐         ┌─────▼──────┐      ┌────▼────┐
    │ Frontend │         │  Backend   │      │ Database │
    │  (React) │         │ (Node.js)  │      │ (PostgreSQL)
    │ 2 Pods   │         │ 3 Pods     │      │ 1 Pod    │
    └────┬────┘         └─────┬──────┘      └────┬────┘
         │ NodePort           │ ClusterIP        │ ClusterIP
         │ :31190             │ :5000            │ :5432
         │                    │                  │
    ┌────▼──────────────────┬─────────────────┬─┴────────┐
    │   Ingress/External    │  Pod Networking │ PersistentVolume
    │   Access              │  (Internal)     │ (/mnt/data/postgres)
    └───────────────────────┴─────────────────┴──────────┘
```

## 📊 Component Details

### Database Tier
- **Image**: postgres:15-alpine
- **Replicas**: 1
- **Storage**: 5Gi PersistentVolume with HostPath
- **Port**: 5432 (ClusterIP)
- **Credentials**: app-secrets (DB_USER, DB_PASSWORD)

### Backend Tier
- **Image**: sarowaralam/3-tier-backend:latest
- **Replicas**: 3 (scalable)
- **Language**: Node.js 18
- **Framework**: Express.js
- **Port**: 5000 (ClusterIP)
- **Resources**: 200m CPU request / 400m limit, 128Mi memory request / 256Mi limit
- **Health Checks**: Liveness & Readiness probes
- **Configuration**: DATABASE_URL from ConfigMap

### Frontend Tier
- **Image**: sarowaralam/3-tier-frontend:latest
- **Replicas**: 2 (scalable)
- **Framework**: React with Nginx
- **Port**: 3000 (NodePort 31190)
- **Resources**: 200m CPU request / 400m limit, 128Mi memory request / 256Mi limit
- **Configuration**: REACT_APP_API_URL from ConfigMap

## 🌐 Access Points

| Service | URL | Type |
|---------|-----|------|
| Frontend | `http://localhost:31190` | External (NodePort) |
| Backend API | `http://backend-service:5000/api` | Internal (ClusterIP) |
| Database | `database-service:5432` | Internal (ClusterIP) |

## 🔧 Common Commands

### View Resources
```bash
# All pods
kubectl get pods -o wide

# All deployments
kubectl get deployments -o wide

# All services
kubectl get svc -o wide

# Storage
kubectl get pv,pvc

# Configuration
kubectl get configmaps,secrets
```

### Debug & Troubleshoot
```bash
# Pod logs
kubectl logs -l app=backend --tail=50

# Describe pod
kubectl describe pod <pod-name>

# Exec into pod
kubectl exec -it <pod-name> -- /bin/sh

# Check service connectivity
kubectl run --rm -i --image=curlimages/curl --restart=Never -- \
  curl http://backend-service:5000/health
```

### Scale Deployments
```bash
# Scale backend to 5 replicas
kubectl scale deployment backend --replicas=5

# Scale frontend to 3 replicas
kubectl scale deployment frontend --replicas=3
```

### Update Configuration
```bash
# Edit ConfigMap
kubectl edit configmap app-config

# Edit Secrets
kubectl edit secret app-secrets

# Apply changes
kubectl rollout restart deployment backend
```

## 📁 Files

| File | Purpose |
|------|---------|
| `kind-cluster.yaml` | Kind cluster configuration |
| `storage.yaml` | PersistentVolume & PersistentVolumeClaim |
| `secrets.yaml` | Database credentials & JWT secrets |
| `configmap.yaml` | Environment variables & configuration |
| `database-deployment.yaml` | PostgreSQL deployment |
| `backend-deployment.yaml` | Node.js backend deployment (3 replicas) |
| `frontend-deployment.yaml` | React frontend deployment (2 replicas) |
| `services.yaml` | Kubernetes services (database, backend, frontend) |
| `deploy.sh` | Automated deployment script |
| `DEPLOYMENT_SUMMARY.md` | Detailed deployment documentation |
| `README.md` | This file |

## 🚀 Getting Started

### 1. Start Kind Cluster
```bash
kind create cluster --name three-tier-cluster --image kindest/node:v1.29.0
kubectl cluster-info
```

### 2. Build Docker Images
```bash
cd 3-tier-app-terraform-jenkins

# Build backend
cd backend
docker build -t sarowaralam/3-tier-backend:latest .
cd ..

# Build frontend
cd frontend
docker build -t sarowaralam/3-tier-frontend:latest .
cd ..

# Load images into Kind
kind load docker-image sarowaralam/3-tier-backend:latest --name three-tier-cluster
kind load docker-image sarowaralam/3-tier-frontend:latest --name three-tier-cluster
```

### 3. Deploy Application
```bash
cd ..
./deploy.sh
```

### 4. Verify
```bash
kubectl get pods -o wide
kubectl get svc -o wide
kubectl get pv,pvc
```

### 5. Access Application
Open browser: `http://localhost:31190`

## 🔐 Security

- **Credentials**: Stored in `app-secrets` Secret (base64 encoded)
- **Configuration**: Non-sensitive data in `app-config` ConfigMap
- **Database**: PostgreSQL with password authentication
- **Network**: Service-to-service via ClusterIP, frontend exposed via NodePort

## 📊 Monitoring & Logs

### View Logs
```bash
# Backend logs
kubectl logs -l app=backend -f

# Frontend logs
kubectl logs -l app=frontend -f

# Database logs
kubectl logs -l app=postgresql -f
```

### Check Resource Usage
```bash
kubectl top pods
kubectl top nodes
```

## 🛠️ Troubleshooting

### Pods Not Running
```bash
# Check pod status
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### Database Connection Issues
```bash
# Verify database service
kubectl get svc database-service
kubectl exec -it <backend-pod> -- env | grep DATABASE_URL

# Test connectivity
kubectl run --rm -it --image=postgres:15-alpine --restart=Never -- \
  psql -h database-service -U mysqluser -d myapp
```

### Frontend Not Loading
```bash
# Check frontend service
kubectl get svc frontend-service
kubectl logs -l app=frontend
```

### Image Pull Errors
```bash
# Ensure imagePullPolicy: Never is set for local images
# Reload images if needed
kind load docker-image sarowaralam/3-tier-backend:latest --name three-tier-cluster
kind load docker-image sarowaralam/3-tier-frontend:latest --name three-tier-cluster

# Restart deployments
kubectl rollout restart deployment backend
kubectl rollout restart deployment frontend
```

## 📈 Scaling

All components are designed for horizontal scaling:

```bash
# Scale backend to handle more traffic
kubectl scale deployment backend --replicas=5

# Scale frontend replicas
kubectl scale deployment frontend --replicas=4

# View scaling status
kubectl get deployment -w
```

## 🔄 Updates & Rollouts

### Update Image
```bash
kubectl set image deployment/backend backend=sarowaralam/3-tier-backend:v2
kubectl rollout status deployment/backend
kubectl rollout undo deployment/backend  # Rollback if needed
```

## 🧹 Cleanup

### Remove All Resources
```bash
kubectl delete -f storage.yaml
kubectl delete -f secrets.yaml
kubectl delete -f configmap.yaml
kubectl delete -f database-deployment.yaml
kubectl delete -f backend-deployment.yaml
kubectl delete -f frontend-deployment.yaml
kubectl delete -f services.yaml
```

### Delete Kind Cluster
```bash
kind delete cluster --name three-tier-cluster
```

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Express.js Documentation](https://expressjs.com/)
- [React Documentation](https://react.dev/)

## 📝 Notes

- All pods are running on a single control-plane node (Kind single-node cluster)
- Database uses HostPath storage; suitable for development/testing
- For production, use managed storage solutions (EBS, GCP Persistent Disk, etc.)
- PersistentVolume data is stored at `/mnt/data/postgres` on the Kind node
- Backend and frontend images have `imagePullPolicy: Never` (local images only)

## ✅ Verified Status

- ✅ Kubernetes 1.29.0 cluster running
- ✅ All 6 pods running (3 backend, 2 frontend, 1 database)
- ✅ All services created and operational
- ✅ Persistent volume bound and functional
- ✅ Database connectivity verified
- ✅ Backend API responding to health checks
- ✅ Frontend returning HTTP 200
- ✅ Inter-pod DNS resolution working

---

For more detailed information, see [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)
