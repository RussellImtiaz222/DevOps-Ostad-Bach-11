# Documentation Index

**Last Updated**: August 28, 2026  
**Project**: Simple Chat Application - DevOps Deployment

---

## 📌 Quick Navigation

### 🚀 Getting Started (Start Here!)
- **[README.md](README.md)** - Project overview, quick start, architecture
- **[QUICK-START.md](QUICK-START.md)** - Common commands and operations

### ☁️ Cloud Deployment
- **[DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)** - Step-by-step cloud deployment
  - AWS EKS
  - Azure AKS
  - Google GKE
  - Generic Kubernetes

### 📊 Reference & History
- **[SESSION-SUMMARY.md](SESSION-SUMMARY.md)** - Session achievements, technical details
- **[CLEANUP-SUMMARY.md](CLEANUP-SUMMARY.md)** - Workspace cleanup summary

### 📁 Backend (Node.js/Express)
- **[Capstan-Project/simpleChatserver/README.md](Capstan-Project/simpleChatserver/README.md)** - Backend documentation
- **[Capstan-Project/simpleChatserver/Dockerfile](Capstan-Project/simpleChatserver/Dockerfile)** - Production build
- **[Capstan-Project/simpleChatserver/Dockerfile.dev](Capstan-Project/simpleChatserver/Dockerfile.dev)** - Development build

### 🎨 Frontend (React/Vite)
- **[Capstan-Project/simpleChatui/README.md](Capstan-Project/simpleChatui/README.md)** - Frontend documentation
- **[Capstan-Project/simpleChatui/Dockerfile.dev](Capstan-Project/simpleChatui/Dockerfile.dev)** - Development server
- **[Capstan-Project/simpleChatui/Dockerfile.prod](Capstan-Project/simpleChatui/Dockerfile.prod)** - Production build

### ⚙️ Infrastructure & DevOps
- **[Capstan-Project/DEVOPS-GUIDE.md](Capstan-Project/DEVOPS-GUIDE.md)** - DevOps architecture and design
- **[Capstan-Project/docker-compose.yml](Capstan-Project/docker-compose.yml)** - Local development setup
- **Kubernetes Manifests**:
  - [Capstan-Project/k8s/dev/](Capstan-Project/k8s/dev/) - Development environment
  - [Capstan-Project/k8s/stage/](Capstan-Project/k8s/stage/) - Staging environment
  - [Capstan-Project/k8s/prod/](Capstan-Project/k8s/prod/) - Production environment

### 🔄 CI/CD
- **GitHub Actions Workflows**:
  - [.github/workflows/backend-dev-stage.yml](.github/workflows/backend-dev-stage.yml)
  - [.github/workflows/backend-prod.yml](.github/workflows/backend-prod.yml)
  - [.github/workflows/frontend-dev-stage.yml](.github/workflows/frontend-dev-stage.yml)
  - [.github/workflows/frontend-prod.yml](.github/workflows/frontend-prod.yml)

---

## 🎯 Typical Workflows

### Local Development
1. Read: [README.md](README.md) - Overview
2. Read: [QUICK-START.md](QUICK-START.md) - Common commands
3. Access: http://localhost:3000 (frontend)

### Troubleshooting
1. Check: [QUICK-START.md](QUICK-START.md) - Troubleshooting section
2. Check: Backend logs via kubectl
3. Check: [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md) - Advanced issues

### Deploying to Cloud
1. Choose your cloud provider
2. Read: [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md) - Relevant section
3. Follow step-by-step instructions

### Understanding the Architecture
1. Read: [README.md](README.md) - Overview
2. Read: [Capstan-Project/DEVOPS-GUIDE.md](Capstan-Project/DEVOPS-GUIDE.md) - Detailed design

---

## 📊 Current Status

| Component | Status | Details |
|-----------|--------|---------|
| **Frontend** | ✅ Running | React on localhost:3000 |
| **Backend** | ✅ Running | Node.js on localhost:5000 |
| **Kubernetes** | ✅ Ready | kind cluster, 3 namespaces |
| **CI/CD** | ✅ Active | GitHub Actions, all passing |
| **Images** | ✅ Published | GHCR registry updated |

---

## 🔗 External Resources

- **Docker Desktop**: https://www.docker.com/products/docker-desktop
- **Kubernetes Docs**: https://kubernetes.io/docs/
- **GitHub Actions**: https://github.com/features/actions
- **GHCR Docs**: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry

---

## 📞 Quick Commands Reference

```bash
# View frontend
http://localhost:3000

# View backend health
http://localhost:5000/api/health

# Check cluster status
kubectl get nodes
kubectl get pods -A

# View logs
kubectl logs -n simple-chat-dev -l app=backend -f
kubectl logs -n simple-chat-dev -l app=frontend -f

# Port-forward services
kubectl port-forward -n simple-chat-dev svc/backend-dev 5000:5000
kubectl port-forward -n simple-chat-dev svc/frontend-dev 3000:3000

# Deploy to cloud
# Follow DEPLOYMENT-GUIDE.md
```

---

**Status**: ✅ Production Ready  
**Last Verified**: August 28, 2026  
**Environments**: 3 (dev, stage, prod)
