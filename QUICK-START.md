# Quick Start Reference

## 🎉 Current Status: FULLY OPERATIONAL

Your multi-environment chat application is now **deployed and running**!

---

## ✅ What's Working

### Local Development (localhost)
- **Frontend**: http://localhost:3000
- **Backend**: http://localhost:5000/api/health
- **Status**: Both containers Running and Ready (1/1)

### GitHub Actions CI/CD
- **All pipelines**: ✅ PASSING
- **Latest builds**: Available at ghcr.io/russellimtiaz222/
- **Automatic**: Triggered on push to dev/stage/prod branches

### Kubernetes Infrastructure
- **Cluster**: kind (local) + 3 namespaces (dev/stage/prod)
- **CNI**: Calico networking
- **Secrets**: GHCR authentication configured

---

## 🚀 Access Points

### Option 1: Local Frontend (Currently Running)
```
http://localhost:3000
```
**Port-forward is active in terminal**. Browser tab should already be open!

### Option 2: Access Backend Health
```powershell
# Terminal 1: Port-forward backend
$env:KUBECONFIG = "$env:USERPROFILE\.kube\config"
kubectl port-forward -n simple-chat-dev svc/backend-dev 5000:5000

# Terminal 2: Test health endpoint
Invoke-WebRequest http://localhost:5000/api/health
```

### Option 3: Inspect Running Pods
```powershell
$env:KUBECONFIG = "$env:USERPROFILE\.kube\config"

# View all pods
kubectl get pods -n simple-chat-dev -o wide

# View pod logs
kubectl logs -n simple-chat-dev -l app=backend -f
kubectl logs -n simple-chat-dev -l app=frontend -f

# SSH into a pod
kubectl exec -it -n simple-chat-dev pod/backend-dev-xxxxx -- /bin/sh
```

---

## 🏗️ Kubernetes Cluster Management

### Check Node Status
```powershell
$env:KUBECONFIG = "$env:USERPROFILE\.kube\config"
kubectl get nodes
kubectl get nodes -o wide
```

### View All Resources
```powershell
$env:KUBECONFIG = "$env:USERPROFILE\.kube\config"
kubectl get all -n simple-chat-dev
kubectl get configmaps -n simple-chat-dev
kubectl get secrets -n simple-chat-dev
```

### Monitor in Real-Time
```powershell
# Watch pod status changes
kubectl get pods -n simple-chat-dev --watch

# View resource usage
kubectl top pods -n simple-chat-dev
kubectl top nodes
```

---

## 📦 Docker & Images

### View Local Images
```powershell
# List all images
docker images | Select-String "backend|frontend"

# Check image details
docker image inspect ghcr.io/russellimtiaz222/backend:dev-latest
```

### Pull Latest Images
```powershell
# Backend
docker pull ghcr.io/russellimtiaz222/backend:dev-latest
docker pull ghcr.io/russellimtiaz222/backend:stage-latest
docker pull ghcr.io/russellimtiaz222/backend:prod-latest

# Frontend
docker pull ghcr.io/russellimtiaz222/frontend:dev-latest
docker pull ghcr.io/russellimtiaz222/frontend:stage-latest
docker pull ghcr.io/russellimtiaz222/frontend:prod-latest
```

---

## 🔄 Deployment Workflow

### Make Code Changes
```powershell
# Edit source files in:
# - Capstan-Project/simpleChatserver/ (backend)
# - Capstan-Project/simpleChatui/ (frontend)
```

### Push to GitHub
```powershell
git add .
git commit -m "feat: your changes"
git push origin dev  # or stage/prod
```

### GitHub Actions Automatically
1. ✅ Builds Docker images
2. ✅ Pushes to GHCR
3. ✅ Available for deployment

### Deploy to Kubernetes (Manual)
```powershell
# Option 1: Recreate pods to pull latest image
kubectl rollout restart deployment/backend-dev -n simple-chat-dev
kubectl rollout restart deployment/frontend-dev -n simple-chat-dev

# Option 2: Change image tag
kubectl set image deployment/backend-dev backend=ghcr.io/russellimtiaz222/backend:dev-latest -n simple-chat-dev
```

---

## 📊 Environment Namespaces

### Dev Environment
- **Namespace**: simple-chat-dev
- **Node replicas**: 1
- **Image pull policy**: IfNotPresent
- **Use case**: Local development & testing

### Stage Environment
- **Namespace**: simple-chat-stage
- **Node replicas**: 2
- **Image pull policy**: IfNotPresent
- **Use case**: Pre-production testing

### Prod Environment
- **Namespace**: simple-chat-prod
- **Node replicas**: 2
- **Image pull policy**: Always
- **Use case**: Production deployment

### Deploy to Other Environments
```powershell
$env:KUBECONFIG = "$env:USERPROFILE\.kube\config"

# Create imagePullSecret
$PAT = "your_github_pat"
kubectl create secret docker-registry ghcr-secret `
  --docker-server=ghcr.io `
  --docker-username=russellimtiaz222 `
  --docker-password=$PAT `
  --docker-email=russellimtiaz222@example.com `
  -n simple-chat-stage

# Deploy
kubectl apply -f Capstan-Project/k8s/stage/ -n simple-chat-stage

# Verify
kubectl get pods -n simple-chat-stage
```

---

## 🐛 Troubleshooting Common Issues

### Pods Not Starting
```powershell
$env:KUBECONFIG = "$env:USERPROFILE\.kube\config"

# Check pod status
kubectl describe pod -n simple-chat-dev backend-dev-xxxxx

# View recent events
kubectl get events -n simple-chat-dev --sort-by='.lastTimestamp' | tail -20

# Check pod logs
kubectl logs -n simple-chat-dev backend-dev-xxxxx
```

### Port-Forward Not Working
```powershell
# Kill existing port-forward processes
Get-Process | Where-Object {$_.ProcessName -like "*kubectl*"} | Stop-Process -Force

# Verify new port-forward
$env:KUBECONFIG = "$env:USERPROFILE\.kube\config"
kubectl port-forward -n simple-chat-dev svc/frontend-dev 3000:3000

# Test connection
Invoke-WebRequest http://localhost:3000 -UseBasicParsing
```

### Images Not Pulling from GHCR
```powershell
$env:KUBECONFIG = "$env:USERPROFILE\.kube\config"

# Check secret exists
kubectl get secret ghcr-secret -n simple-chat-dev

# Verify secret is valid
kubectl get secret ghcr-secret -n simple-chat-dev -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d

# Check pod events for ImagePullBackOff
kubectl describe pod -n simple-chat-dev backend-dev-xxxxx

# Verify image exists in GHCR
# Visit: https://github.com/russellimtiaz222?tab=packages
```

### Backend Health Check Failing
```powershell
# Port-forward to backend
$env:KUBECONFIG = "$env:USERPROFILE\.kube\config"
kubectl port-forward -n simple-chat-dev svc/backend-dev 5000:5000

# In another terminal, test endpoint
Invoke-WebRequest http://localhost:5000/api/health -UseBasicParsing

# Check backend logs
kubectl logs -n simple-chat-dev -l app=backend -f
```

### Frontend Not Loading
```powershell
# Check frontend pod logs
$env:KUBECONFIG = "$env:USERPROFILE\.kube\config"
kubectl logs -n simple-chat-dev -l app=frontend -f

# Port-forward and test directly
kubectl port-forward -n simple-chat-dev svc/frontend-dev 3000:3000

# Test with curl
curl http://localhost:3000
```

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| [README.md](README.md) | Project overview |
| [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md) | Cloud provider deployment instructions |
| [DEVOPS-GUIDE.md](DEVOPS-GUIDE.md) | DevOps architecture & design |
| [IMPLEMENTATION-CHECKLIST.md](IMPLEMENTATION-CHECKLIST.md) | Feature checklist |
| [docker-compose.yml](docker-compose.yml) | Local development with Docker Compose |

---

## 🔐 Important Files & Secrets

### GitHub Actions Workflows
```
.github/workflows/
├── backend-dev-stage.yml      # Backend build for dev/stage
├── backend-prod.yml           # Backend build for prod
├── frontend-dev-stage.yml     # Frontend build for dev/stage
└── frontend-prod.yml          # Frontend build for prod
```

### Kubernetes Manifests
```
Capstan-Project/k8s/
├── dev/                       # Dev environment configs
├── stage/                      # Stage environment configs
└── prod/                       # Prod environment configs
```

### kubeconfig Location
```
C:\Users\iruss\.kube\config    # Local cluster configuration
```

---

## 🚀 Next Steps

### 1. Verify Frontend Works
- ✅ Open browser: http://localhost:3000
- ✅ Should see React application

### 2. Test Backend Connectivity
```powershell
$env:KUBECONFIG = "$env:USERPROFILE\.kube\config"
kubectl port-forward -n simple-chat-dev svc/backend-dev 5000:5000

# Test in another terminal
Invoke-WebRequest http://localhost:5000/api/health
```

### 3. Deploy to Cloud (When Ready)
Follow instructions in [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md):
- AWS EKS
- Azure AKS
- Google GKE
- Or any Kubernetes cluster

### 4. Enable CI/CD Monitoring
- Visit: https://github.com/RussellImtiaz222/DevOps-Ostad-Bach-11/actions
- Watch automatic builds on every push

### 5. Scale to Production
- Repeat deployment process for `prod` namespace
- Update frontend service type to LoadBalancer
- Configure custom domain via Ingress

---

## 📞 Support Commands

```powershell
# Set kubeconfig in every new terminal
$env:KUBECONFIG = "$env:USERPROFILE\.kube\config"

# Essential one-liners
kubectl get all -n simple-chat-dev              # See everything
kubectl delete pods -n simple-chat-dev --all    # Reset pods
kubectl logs -n simple-chat-dev -l app=backend -f    # Watch logs
kubectl port-forward -n simple-chat-dev svc/frontend-dev 3000:3000    # Access frontend
kubectl port-forward -n simple-chat-dev svc/backend-dev 5000:5000     # Access backend
```

---

## 🎓 Learning Resources

- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [GHCR Documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

---


