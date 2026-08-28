
# Simple Chat Application - DevOps Deployment

## ✅ Status: FULLY OPERATIONAL

A fully containerized, multi-environment real-time chat application deployed to Kubernetes with complete CI/CD automation via GitHub Actions.

**Current Setup**: Local Kubernetes (kind) with Docker Desktop  
**Production Ready**: Deploy to AWS EKS, Azure AKS, Google GKE, or any Kubernetes cluster

---

## 🎯 Quick Start

### Local Development (Current)
```bash
# Frontend
http://localhost:3000

# Backend API & WebSocket
http://localhost:5000
http://localhost:5000/api/health  # Health check

# View logs
kubectl logs -n simple-chat-dev -l app=backend -f
kubectl logs -n simple-chat-dev -l app=frontend -f
```

### Deploy to Production
Follow the [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md) for:
- AWS EKS
- Azure AKS  
- Google GKE
- Generic Kubernetes

---

## 🏗️ Architecture

### Components
- **Backend**: Node.js 20 LTS + Express + TypeScript + Socket.io
- **Frontend**: React 19 + TypeScript + Vite 8.2.2
- **Registry**: GitHub Container Registry (GHCR)
- **Orchestration**: Kubernetes (local: kind, cloud: managed)
- **CI/CD**: GitHub Actions automated builds & deployments

### Supported Environments
| Environment | Status | Description |
|------------|--------|-------------|
| **dev** | ✅ Running | Hot-reload, local testing |
| **stage** | ✅ Ready | Production-like, QA testing |
| **prod** | ✅ Ready | High-availability, auto-scaling |

---

## 📁 Project Structure

```
Capstan-Project/
├── simpleChatserver/              # Backend (Node.js/Express)
│   ├── Dockerfile                 # Production build
│   ├── Dockerfile.dev             # Development with hot-reload  
│   ├── package.json
│   └── src/
│       ├── app.ts
│       ├── server.ts
│       ├── config/                # Configuration
│       ├── controllers/           # Request handlers
│       ├── middleware/            # Express middleware
│       ├── routes/                # API endpoints
│       ├── services/              # Business logic
│       ├── socket/                # WebSocket handlers
│       ├── types/                 # TypeScript types
│       ├── utils/                 # Utilities
│       └── validation/            # Input validation
│
├── simpleChatui/                  # Frontend (React/Vite)
│   ├── Dockerfile.dev             # Vite dev server
│   ├── Dockerfile.prod            # Production Nginx
│   ├── package.json
│   ├── vite.config.ts
│   └── src/
│       ├── App.tsx
│       ├── components/            # React components
│       ├── hooks/                 # Custom hooks
│       ├── services/              # API & Socket services
│       ├── types/                 # TypeScript types
│       └── utils/                 # Utilities
│
├── k8s/                           # Kubernetes manifests
│   ├── dev/                       # Development environment
│   │   ├── namespace.yaml
│   │   ├── backend-deployment.yaml
│   │   ├── backend-configmap.yaml
│   │   ├── backend-service.yaml
│   │   ├── frontend-deployment.yaml
│   │   ├── frontend-configmap.yaml
│   │   └── frontend-service.yaml
│   ├── stage/                     # Staging (same structure)
│   └── prod/                      # Production (same structure)
│
├── .github/workflows/             # GitHub Actions CI/CD
│   ├── backend-dev-stage.yml
│   ├── backend-prod.yml
│   ├── frontend-dev-stage.yml
│   └── frontend-prod.yml
│
├── docker-compose.yml             # Local development
└── README.md                      # This file
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflows

**backend-dev-stage.yml** (Trigger: push to `dev` or `stage`)
- Builds TypeScript backend
- Pushes to GHCR: `ghcr.io/russellimtiaz222/backend:{env}-{version}`
- Status: ✅ All builds passing

**frontend-dev-stage.yml** (Trigger: push to `dev` or `stage`)
- Installs dependencies with Yarn
- Builds React application
- Pushes to GHCR: `ghcr.io/russellimtiaz222/frontend:{env}-{version}`
- Status: ✅ All builds passing

**backend-prod.yml & frontend-prod.yml** (Trigger: push to `prod`)
- Production-optimized builds
- Deploys production-tagged images
- Status: ✅ Ready for production use

### Published Images
```
# Development
ghcr.io/russellimtiaz222/backend:dev-latest
ghcr.io/russellimtiaz222/frontend:dev-latest

# Staging  
ghcr.io/russellimtiaz222/backend:stage-latest
ghcr.io/russellimtiaz222/frontend:stage-latest

# Production
ghcr.io/russellimtiaz222/backend:prod-latest
ghcr.io/russellimtiaz222/frontend:prod-latest
```

---

## 🔧 Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| **Backend Runtime** | Node.js | 20 LTS |
| **Backend Framework** | Express.js | Latest |
| **Backend Language** | TypeScript | 5+ |
| **Real-time** | Socket.io | Latest |
| **Frontend Framework** | React | 19 |
| **Frontend Build** | Vite | 8.2.2 |
| **Package Manager** | Yarn | 1.22.22 |
| **Container Runtime** | Docker | 20+ |
| **Orchestration** | Kubernetes | 1.27+ |
| **Container Registry** | GHCR | Public |
| **CI/CD** | GitHub Actions | - |

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Project overview (this file) |
| [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md) | Cloud deployment instructions |
| [QUICK-START.md](QUICK-START.md) | Daily operations & commands |
| [SESSION-SUMMARY.md](SESSION-SUMMARY.md) | Session achievements & details |
| [Capstan-Project/DEVOPS-GUIDE.md](Capstan-Project/DEVOPS-GUIDE.md) | Architecture & design |

---

## 🚀 Getting Started

### Prerequisites
- Docker Desktop (with Kubernetes enabled)
- kubectl CLI
- Git
- Bash or PowerShell

### Local Setup (Already Deployed)
```bash
# Verify cluster
kubectl get nodes
kubectl get pods -n simple-chat-dev

# Access application
# Frontend: http://localhost:3000
# Backend:  http://localhost:5000

# View logs
kubectl logs -n simple-chat-dev -l app=backend -f
kubectl logs -n simple-chat-dev -l app=frontend -f
```

### Port-Forward Setup
```bash
# Backend (5000)
kubectl port-forward -n simple-chat-dev svc/backend-dev 5000:5000

# Frontend (3000)  
kubectl port-forward -n simple-chat-dev svc/frontend-dev 3000:3000
```

---

## 🛠️ Common Tasks

### View Logs
```bash
# Backend logs
kubectl logs -n simple-chat-dev -l app=backend -f --timestamps

# Frontend logs
kubectl logs -n simple-chat-dev -l app=frontend -f --timestamps

# All events
kubectl describe events -n simple-chat-dev
```

### Scale Deployment
```bash
# Scale backend (dev has 1, stage/prod have 2)
kubectl scale deployment backend-dev --replicas=3 -n simple-chat-dev
```

### Update Configuration
```bash
# Edit environment variables
kubectl edit configmap backend-config -n simple-chat-dev

# Restart pods to apply
kubectl rollout restart deployment backend-dev -n simple-chat-dev
```

### Access Pod Shell
```bash
# Backend shell
kubectl exec -it deployment/backend-dev -n simple-chat-dev -- sh

# Frontend shell
kubectl exec -it deployment/frontend-dev -n simple-chat-dev -- sh
```

---

## 🚨 Troubleshooting

### WebSocket Connection Issues
```bash
# Symptom: "Reconnecting..." message
# Fix: Verify port-forwards and CORS configuration
kubectl edit configmap backend-config -n simple-chat-dev
# Ensure CLIENT_URL includes http://localhost:3000
```

### Pods Not Starting
```bash
# Check pod status
kubectl describe pod <pod-name> -n simple-chat-dev

# Check image pull secret exists
kubectl get secrets -n simple-chat-dev

# Verify image in GHCR
docker pull ghcr.io/russellimtiaz222/backend:dev-latest
```

### Connection Timeouts
```bash
# Verify services are running
kubectl get svc -n simple-chat-dev

# Check service endpoints
kubectl get endpoints -n simple-chat-dev

# Port-forward for direct access
kubectl port-forward svc/backend-dev 5000:5000 -n simple-chat-dev
```

---

## 📊 Current Status

### Local Kubernetes
- **Cluster**: kind (Kubernetes in Docker)
- **Version**: v1.27.3
- **CNI**: Calico
- **Nodes**: 1 (control-plane)
- **Status**: ✅ Running

### Namespaces
```
✅ simple-chat-dev   (1/1 pods ready)
✅ simple-chat-stage (ready to deploy)
✅ simple-chat-prod  (ready to deploy)
```

### Access Points
- Frontend: http://localhost:3000 ✅
- Backend: http://localhost:5000 ✅
- Health: http://localhost:5000/api/health ✅

---

## 📝 Environment Configuration

### Backend (.env / ConfigMap)
```bash
NODE_ENV=development
PORT=5000
CLIENT_URL=http://localhost:3000,http://localhost:5173,http://frontend-dev:3000
CHAT_PRIMARY_COLOR=#2563EB
CHAT_SECONDARY_COLOR=#EFF6FF
```

### Frontend (.env / ConfigMap)
```bash
VITE_API_URL=http://localhost:5000
VITE_SOCKET_URL=http://localhost:5000
```

---

## 🔐 Security

- **Image Registry**: Public (GHCR)
- **Pull Secrets**: Created in each namespace
- **CORS**: Configured per environment
- **Health Checks**: Liveness & Readiness probes enabled
- **Resource Limits**: CPU & Memory defined per pod

---

## ✅ Deployment Checklist

- [x] Local Kubernetes cluster running
- [x] Backend pod deployed and healthy
- [x] Frontend pod deployed and healthy
- [x] WebSocket connection working
- [x] GitHub Actions CI/CD passing
- [x] Images published to GHCR
- [x] Documentation completed

---

## 📞 Support

- Check [QUICK-START.md](QUICK-START.md) for quick reference
- Review [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md) for your target platform
- View pod logs: `kubectl logs -n simple-chat-dev <pod-name>`
- Describe pod: `kubectl describe pod -n simple-chat-dev <pod-name>`

---

**Last Updated**: August 28, 2026   
**Environments**: 3 (dev, stage, prod)




