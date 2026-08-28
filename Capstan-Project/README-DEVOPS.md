# Simple Chat Platform - Complete DevOps Pipeline

A production-ready DevOps implementation for a real-time chat application with three-tier environment management, automated CI/CD pipelines, Kubernetes orchestration, and GitOps delivery.

## 📋 Overview

This repository contains the complete DevOps infrastructure for the Simple Chat Platform:

- **Frontend**: React/Vite single-page application
- **Backend**: Express.js/Socket.IO real-time chat server

### Key Features

✅ **Git-Based Workflow**
- Three long-lived branches: `dev`, `stage`, `prod`
- Clear promotion path with enforced review processes
- Traceable deployment history

✅ **Automated CI/CD**
- GitHub Actions workflows for frontend and backend
- Build, test, and containerization automation
- Manual triggers for dev/stage, automatic for production

✅ **Container Versioning**
- Unique semantic versioning with commit SHA
- Separate dev and prod Docker images
- Push to GitHub Container Registry (GHCR)

✅ **Kubernetes Management**
- Separate namespaces for dev/stage/prod
- Deployment and Service resources per environment
- ConfigMap-based configuration management
- Health checks and resource limits

✅ **GitOps with Argo CD**
- Git as the single source of truth
- Automatic reconciliation of cluster state
- Manual sync for dev/stage, automatic for prod
- Full audit trail of changes

---

## 📁 Directory Structure

```
.
├── simpleChatui/                    # React/Vite Frontend
│   ├── Dockerfile.dev              # Development image with HMR
│   ├── Dockerfile.prod             # Production image
│   ├── src/
│   └── package.json
│
├── simpleChatserver/                # Express/Socket.IO Backend
│   ├── Dockerfile.dev              # Development image
│   ├── Dockerfile                  # Production image
│   ├── src/
│   └── package.json
│
├── .github/workflows/               # GitHub Actions CI/CD
│   ├── frontend-cicd.yml           # Frontend pipeline
│   └── backend-cicd.yml            # Backend pipeline
│
├── k8s/                             # Kubernetes Manifests
│   ├── dev/                         # Development environment
│   │   ├── namespace.yaml
│   │   ├── frontend-*.yaml
│   │   └── backend-*.yaml
│   ├── stage/                       # Staging environment
│   │   └── [same structure]
│   └── prod/                        # Production environment
│       └── [same structure]
│
├── argocd/                          # Argo CD Applications
│   ├── frontend-dev-app.yaml
│   ├── frontend-stage-app.yaml
│   ├── frontend-prod-app.yaml
│   ├── backend-dev-app.yaml
│   ├── backend-stage-app.yaml
│   └── backend-prod-app.yaml
│
├── docker-compose.yml               # Local development setup
├── DEVOPS-GUIDE.md                 # Comprehensive implementation guide
├── IMPLEMENTATION-CHECKLIST.md     # Step-by-step setup instructions
└── README.md                        # This file
```

---

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Kubernetes cluster (local or remote)
- kubectl configured
- Git with SSH keys or GitHub PAT
- Argo CD installed on cluster

### Local Development

```bash
# Start all services with hot reloading
docker-compose up -d

# Frontend: http://localhost:5173
# Backend API: http://localhost:5000

# View logs
docker-compose logs -f frontend-dev
docker-compose logs -f backend-dev

# Stop services
docker-compose down
```

### Deploy to Kubernetes (Dev)

```bash
# Create namespaces and deploy
kubectl apply -f k8s/dev/

# Port-forward for testing
kubectl port-forward svc/frontend-dev 3000:3000 -n simple-chat-dev &
kubectl port-forward svc/backend-dev 5000:5000 -n simple-chat-dev

# Access: http://localhost:3000
```

---

## 🌳 Git Branching Strategy

```
main/master (archived history)
    ↓
├─→ dev (active development)
│     ↓ (PR + CI/CD passes)
│
├─→ stage (QA testing)
│     ↓ (2 approvals + manual deploy)
│
└─→ prod (production)
      ↓ (2 approvals + auto-deploy)
```

### Branch Roles

| Branch | Replicas | Trigger | Deploy | Audience |
|--------|----------|---------|--------|----------|
| `dev` | 1 | Push | Manual | Developers |
| `stage` | 2 | Push | Manual | QA Team |
| `prod` | 3 | Push | **Auto** | End Users |

---

## 📦 Container Images

### Image Naming

```
ghcr.io/{owner}/simple-chat-{component}:{environment}-{version}
```

Examples:
```
ghcr.io/mdarifahammedreza/simple-chat-frontend:dev-v1.0.0-abc1234
ghcr.io/mdarifahammedreza/simple-chat-frontend:stage-v1.0.0-def5678
ghcr.io/mdarifahammedreza/simple-chat-frontend:prod-v1.0.0-ghi9012
```

### Building Locally

```bash
# Frontend development
docker build -f simpleChatui/Dockerfile.dev -t simple-chat-frontend:dev-local .

# Frontend production
docker build -f simpleChatui/Dockerfile.prod -t simple-chat-frontend:prod-local ./simpleChatui

# Backend development
docker build -f simpleChatserver/Dockerfile.dev -t simple-chat-backend:dev-local ./simpleChatserver

# Backend production
docker build -f simpleChatserver/Dockerfile -t simple-chat-backend:prod-local ./simpleChatserver
```

---

## 🔄 Promotion Workflow

### Feature → Development

```bash
# Create feature branch
git checkout -b feature/my-feature dev

# Make changes and commit
git push origin feature/my-feature

# Create PR on GitHub: feature/my-feature → dev
# 1 approval required
# GitHub Actions runs tests + builds image
# Merge to dev
```

**Result**: Dev image tagged `dev-{version}` pushed to GHCR

### Development → Staging

```bash
# Create PR: dev → stage
# 2 approvals required (code review)
# GitHub Actions runs tests + builds stage image
# Merge to stage
```

**Result**: Stage image tagged `stage-{version}` pushed to GHCR

**Manual**: Sync staging apps in Argo CD dashboard

### Staging → Production

```bash
# Create PR: stage → prod
# 2 approvals required (code review)
# GitHub Actions runs tests + builds prod image
# Merge to prod
```

**Result**: 
- Prod image tagged `prod-{version}` and `{version}` pushed
- **Automatic**: Argo CD syncs all production apps
- Rolling update begins immediately

---

## ⚙️ GitHub Actions Workflows

### Frontend CI/CD Pipeline

**Triggers**: Push/PR to dev, stage, prod branches

**Steps**:
1. Install dependencies (yarn)
2. Run TypeScript compiler
3. Run ESLint
4. Generate version (semantic + commit SHA)
5. Build and push Docker image to GHCR
6. Trigger Argo CD sync (dev/stage manual, prod automatic)

**Image tags**: `{env}-{version}`, `{env}-latest`

### Backend CI/CD Pipeline

**Triggers**: Push/PR to dev, stage, prod branches

**Steps**:
1. Install dependencies (npm)
2. Build TypeScript
3. Run type checking
4. Generate version
5. Build and push Docker image
6. Trigger Argo CD sync

---

## ☸️ Kubernetes Manifests

### Namespace Isolation

Each environment in separate namespace:
- `simple-chat-dev`
- `simple-chat-stage`
- `simple-chat-prod`

### Resources per Environment

**Development**:
- Frontend: 1 replica, 100m CPU, 128Mi memory
- Backend: 1 replica, 100m CPU, 128Mi memory

**Staging**:
- Frontend: 2 replicas, 200m CPU, 256Mi memory each
- Backend: 2 replicas, 200m CPU, 256Mi memory each

**Production**:
- Frontend: 3 replicas, 500m CPU, 512Mi memory each
- Backend: 3 replicas, 500m CPU, 512Mi memory each
- Pod anti-affinity: Spread across nodes
- Security context: Non-root, read-only filesystem
- Probes: Liveness and readiness

### Accessing Services

```bash
# Port-forward frontend
kubectl port-forward svc/frontend-prod 3000:3000 -n simple-chat-prod

# Port-forward backend
kubectl port-forward svc/backend-prod 5000:5000 -n simple-chat-prod

# Check logs
kubectl logs deployment/frontend-prod -n simple-chat-prod -f

# Check events
kubectl get events -n simple-chat-prod --sort-by='.lastTimestamp'
```

---

## 🔐 Argo CD GitOps

### Installation

```bash
# Create namespace
kubectl create namespace argocd

# Install Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Port-forward to UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Access: https://localhost:8080

### Application Manifests

Six Argo CD Applications declared in `argocd/`:
- `frontend-dev-app.yaml` - Development frontend
- `frontend-stage-app.yaml` - Staging frontend
- `frontend-prod-app.yaml` - Production frontend
- `backend-dev-app.yaml` - Development backend
- `backend-stage-app.yaml` - Staging backend
- `backend-prod-app.yaml` - Production backend

Each tracks corresponding Git branch and syncs with Kubernetes manifests.

### Sync Policy

**Dev & Stage**: `automated: {prune: false, selfHeal: true}`
- Auto-syncs when Git state changes
- Does NOT prune removed resources
- Self-heals if cluster drifts

**Production**: Same as above
- **Automatic sync on merge** (no manual step needed)

### Manual Operations

```bash
# Sync dev application
argocd app sync backend-dev

# Wait for sync to complete
argocd app wait backend-dev --sync

# View sync history
argocd app history backend-prod

# Rollback to previous sync
argocd app rollback backend-prod 0
```

---

## 📊 Monitoring & Debugging

### Pod Status

```bash
# Get all pods across environments
kubectl get pods -A

# Check specific pod status
kubectl describe pod <pod-name> -n simple-chat-prod

# View pod logs
kubectl logs <pod-name> -n simple-chat-prod -f

# Previous logs (if crashed)
kubectl logs <pod-name> -n simple-chat-prod --previous
```

### Deployments

```bash
# Check deployment status
kubectl get deployment -n simple-chat-prod

# Monitor rollout
kubectl rollout status deployment/frontend-prod -n simple-chat-prod

# Check rollout history
kubectl rollout history deployment/frontend-prod -n simple-chat-prod

# Undo rollout
kubectl rollout undo deployment/frontend-prod -n simple-chat-prod
```

### Argo CD Health

```bash
# View application status
argocd app get frontend-prod

# Get detailed sync info
argocd app get frontend-prod --show-operation

# Check git repo sync status
argocd repo list

# Refresh app to check latest Git state
argocd app refresh frontend-prod
```

---

## 🔧 Configuration

### Frontend Environment Variables

Defined in `k8s/{env}/frontend-configmap.yaml`:

```yaml
VITE_API_URL: "http://backend-{env}:5000"
VITE_SOCKET_URL: "http://backend-{env}:5000"
```

### Backend Environment Variables

Defined in `k8s/{env}/backend-configmap.yaml`:

```yaml
NODE_ENV: "development|staging|production"
PORT: "5000"
CLIENT_URL: "http://frontend-{env}:3000"
CHAT_PRIMARY_COLOR: "#2563EB"
CHAT_SECONDARY_COLOR: "#EFF6FF"
CHAT_USER_MESSAGE_COLOR: "#2563EB"
```

### Secrets Management

Currently uses ConfigMaps for non-sensitive data.

For sensitive secrets, create Kubernetes Secret:

```bash
kubectl create secret generic backend-secrets \
  -n simple-chat-prod \
  --from-literal=DB_PASSWORD=xxx \
  --from-literal=API_KEY=yyy
```

Reference in deployment:
```yaml
envFrom:
- secretRef:
    name: backend-secrets
```

---

## 📚 Documentation

- **[DEVOPS-GUIDE.md](DEVOPS-GUIDE.md)**: Comprehensive 12-section guide
  - Branching strategy details
  - CI/CD pipeline architecture
  - Containerization approach
  - Kubernetes setup guide
  - Argo CD configuration
  - Debugging procedures
  - Security considerations
  - Monitoring & observability
  - Scaling & optimization
  - Cost management

- **[IMPLEMENTATION-CHECKLIST.md](IMPLEMENTATION-CHECKLIST.md)**: Step-by-step setup
  - GitHub repository setup
  - Branch protection configuration
  - GitHub Actions secrets
  - Kubernetes cluster preparation
  - Argo CD installation
  - Testing each promotion step
  - Production readiness checklist

---

## 🔐 Security

### Container Security

✅ Non-root user execution
✅ Read-only root filesystem (prod)
✅ Dropped Linux capabilities
✅ Private container registry (GHCR)
✅ Image scanning (GitHub Actions)

### Network Security

✅ ClusterIP services (internal only)
✅ Namespace isolation via RBAC
✅ No external ingress (explicit out of scope)

### Access Control

✅ GitHub branch protections
✅ Required code reviews per environment
✅ Admin enforcement on prod
✅ Argo CD RBAC configuration
✅ Kubernetes RBAC per role

### Secrets

Currently: ConfigMaps (non-sensitive data)

Consider:
- HashiCorp Vault
- Sealed Secrets
- External Secrets Operator
- Cloud provider key management

---

## 🚦 Troubleshooting

### Workflows Not Running

```bash
# Check workflow syntax
yamllint .github/workflows/*.yml

# View workflow run logs in GitHub Actions tab
# Verify branch protection rules not blocking
```

### Images Not Pushing

```bash
# Verify Docker login
docker login ghcr.io

# Check image builds locally
docker build -f Dockerfile.dev -t test:latest .
```

### Pods Not Starting

```bash
# Check pod details
kubectl describe pod <name> -n simple-chat-prod

# Check image pull
docker pull ghcr.io/mdarifahammedreza/simple-chat-frontend:prod-latest

# Verify secrets/configmaps
kubectl get configmap -n simple-chat-prod
kubectl get secrets -n simple-chat-prod
```

### Argo CD Sync Issues

```bash
# Verify Git connection
argocd repo list

# Check manifests syntax
kubectl apply -f k8s/prod/ --dry-run=client

# Refresh Argo CD cache
argocd app refresh frontend-prod
```

---

## 📞 Support

For issues:
1. Check [DEVOPS-GUIDE.md](DEVOPS-GUIDE.md) troubleshooting section
2. Review workflow logs in GitHub Actions
3. Check pod events: `kubectl get events -A --sort-by=.lastTimestamp`
4. Check Argo CD UI and logs: `kubectl logs -f -n argocd deployment/argocd-application-controller`

---

## 📋 Success Criteria

- ✅ Feature branches merge to dev automatically
- ✅ Dev/stage require manual Argo CD sync
- ✅ Prod deploys automatically on merge
- ✅ Each image has traceable version (commit SHA)
- ✅ Three namespaces with separate configurations
- ✅ Git is single source of truth (Argo CD)
- ✅ Complete audit trail of all changes

---

## 📄 License

This DevOps implementation is provided as-is for the Simple Chat Platform project.

---

## 🤝 Contributing

When making changes:
1. Follow Git branching strategy (dev → stage → prod)
2. All changes must pass CI/CD (tests, build, lint)
3. Production changes require 2 approvals
4. Update DEVOPS-GUIDE.md if workflow changes

---

**Ready to deploy? Start with [IMPLEMENTATION-CHECKLIST.md](IMPLEMENTATION-CHECKLIST.md)**
