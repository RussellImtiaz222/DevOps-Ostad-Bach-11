# Simple Chat Platform - DevOps Implementation Guide

## Overview

This document describes the complete DevOps pipeline for the Simple Chat platform, which consists of:
- **Frontend**: React/Vite single-page application
- **Backend**: Express.js/Socket.IO real-time chat server

The pipeline implements a three-environment deployment strategy (Development, Staging, Production) with Git-based source control, automated CI/CD, containerization, Kubernetes orchestration, and GitOps delivery via Argo CD.

---

## 1. Git Branching Strategy

### Branch Structure

```
main/master
├── dev          (Development environment)
├── stage        (Staging environment)
└── prod         (Production environment)
```

### Branching Rules

| Branch | Environment | Deployment Trigger | Replicas | Auto-Deploy |
|--------|------------|-------------------|----------|------------|
| `dev` | Development | Push to branch | 1 | Manual (Argo CD) |
| `stage` | Staging | Push to branch | 2 | Manual (Argo CD) |
| `prod` | Production | Push to branch | 3 | Automatic (Argo CD) |

### Recommended Workflow

1. **Feature Development**: Create feature branches from `dev`
   ```bash
   git checkout dev
   git pull origin dev
   git checkout -b feature/my-feature
   ```

2. **Testing in Development**: Merge to `dev` via pull request
   ```bash
   git push origin feature/my-feature
   # Create PR: feature/my-feature → dev
   # Merge when CI/CD passes
   ```

3. **Promotion to Staging**: Create PR from `dev` to `stage`
   ```bash
   # After testing in dev, create PR: dev → stage
   # Manually trigger deployment via Argo CD dashboard
   ```

4. **Release to Production**: Create PR from `stage` to `prod`
   ```bash
   # After QA in staging, create PR: stage → prod
   # Deployment is automatic upon merge
   ```

### Branch Protection Rules (GitHub)

Configure these protections on each branch:

**Development (`dev`)**
- Require pull request reviews before merging: 1
- Require status checks to pass (CI/CD pipelines)
- Require branches to be up to date before merging
- Include administrators in restrictions: No

**Staging (`stage`)**
- Require pull request reviews before merging: 2
- Require status checks to pass (CI/CD pipelines)
- Require branches to be up to date before merging
- Include administrators in restrictions: No

**Production (`prod`)**
- Require pull request reviews before merging: 2
- Require status checks to pass (CI/CD pipelines)
- Require branches to be up to date before merging
- Dismiss stale pull request approvals
- Include administrators in restrictions: Yes (enforce for admins too)
- Restrict who can push: Admin team only

---

## 2. Continuous Integration & Delivery Pipeline

### Pipeline Overview

The CI/CD pipeline is implemented with GitHub Actions and consists of two main workflows:
- `frontend-cicd.yml` - Frontend build, test, and deployment
- `backend-cicd.yml` - Backend build, test, and deployment

### Frontend Pipeline

**Triggers:**
- On push to dev/stage/prod branches
- On pull requests to dev/stage/prod branches

**Stages:**

1. **Build & Test**
   - Install dependencies (yarn)
   - TypeScript type checking
   - ESLint code linting
   - Version generation (semantic + commit SHA)

2. **Docker Image Build & Push**
   - **Dev branch**: Builds `Dockerfile.dev`, tags as `dev-{version}`
   - **Stage branch**: Builds `Dockerfile.prod`, tags as `stage-{version}`
   - **Prod branch**: Builds `Dockerfile.prod`, tags as `prod-{version}` and `{version}`

3. **Deployment Trigger**
   - **Dev/Stage**: Manual trigger via Argo CD (environment approval required)
   - **Prod**: Automatic sync via Argo CD

### Backend Pipeline

**Triggers:**
- On push to dev/stage/prod branches
- On pull requests to dev/stage/prod branches

**Stages:**

1. **Build & Test**
   - Install dependencies (npm)
   - Build TypeScript
   - Type checking
   - Version generation

2. **Docker Image Build & Push**
   - **Dev branch**: Builds `Dockerfile.dev`, tags as `dev-{version}`
   - **Stage/Prod branches**: Uses existing multi-stage `Dockerfile`

3. **Deployment Trigger**
   - **Dev/Stage**: Manual trigger via Argo CD
   - **Prod**: Automatic sync via Argo CD

### Container Registry

Images are pushed to GitHub Container Registry (GHCR):
```
ghcr.io/{owner}/simple-chat-frontend:{environment}-{version}
ghcr.io/{owner}/simple-chat-backend:{environment}-{version}
```

### Versioning Scheme

```
{environment}-v{package-version}-{commit-sha}
```

Example: `dev-v1.0.0-abc1234`

This scheme ensures:
- ✅ **Traceability**: Commit SHA identifies exact source code
- ✅ **Uniqueness**: Each build is uniquely identifiable
- ✅ **Auditability**: Can determine environment from tag
- ✅ **Promotion Path**: Visible in image history

---

## 3. Containerization

### Dockerfile Strategy

#### Development Dockerfiles (`Dockerfile.dev`)

**Purpose**: Optimized for developer experience with hot reloading

**Frontend** (`simpleChatui/Dockerfile.dev`):
- Based on `node:20-alpine`
- Installs all dependencies (including devDependencies)
- Runs Vite dev server with host binding
- Enables HMR (Hot Module Reloading)
- Port: 5173

**Backend** (`simpleChatserver/Dockerfile.dev`):
- Based on `node:20-alpine`
- Installs all dependencies
- Runs `tsx watch` for hot reloading
- Port: 5000

#### Production Dockerfile (`Dockerfile.prod` and `Dockerfile`)

**Purpose**: Optimized for performance, security, and minimal size

**Frontend**:
- Multi-stage build:
  1. **Build stage**: Node.js compiles React/Vite → static assets
  2. **Runtime stage**: Uses Node.js + `serve` to run production build
- Security context: Non-root user, read-only filesystem
- Health checks included
- Port: 3000

**Backend** (existing `Dockerfile`):
- Multi-stage build:
  1. **Build stage**: Compiles TypeScript to JavaScript
  2. **Runtime stage**: Runs optimized Node.js with production dependencies only
- Security context: Non-root user
- Environment: NODE_ENV=production
- Port: 5000

### Building Images Locally

```bash
# Frontend - Development
docker build -f simpleChatui/Dockerfile.dev -t simple-chat-frontend:dev-local .

# Frontend - Production
docker build -f simpleChatui/Dockerfile.prod -t simple-chat-frontend:prod-local ./simpleChatui

# Backend - Development
docker build -f simpleChatserver/Dockerfile.dev -t simple-chat-backend:dev-local ./simpleChatserver

# Backend - Production
docker build -f simpleChatserver/Dockerfile -t simple-chat-backend:prod-local ./simpleChatserver
```

### Local Testing with Docker Compose

Create `docker-compose.yml` in project root:

```yaml
version: '3.8'

services:
  backend-dev:
    build:
      context: ./simpleChatserver
      dockerfile: Dockerfile.dev
    ports:
      - "5000:5000"
    environment:
      NODE_ENV: development
      PORT: 5000
      CLIENT_URL: "http://localhost:5173"
      CHAT_PRIMARY_COLOR: "#2563EB"
      CHAT_SECONDARY_COLOR: "#EFF6FF"
      CHAT_USER_MESSAGE_COLOR: "#2563EB"

  frontend-dev:
    build:
      context: ./simpleChatui
      dockerfile: Dockerfile.dev
    ports:
      - "5173:5173"
    environment:
      VITE_API_URL: "http://localhost:5000"
      VITE_SOCKET_URL: "http://localhost:5000"
    depends_on:
      - backend-dev
```

Run: `docker-compose up`

---

## 4. Kubernetes Manifests

### Directory Structure

```
k8s/
├── dev/          # Development environment
│   ├── namespace.yaml
│   ├── frontend-configmap.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   ├── backend-configmap.yaml
│   ├── backend-deployment.yaml
│   └── backend-service.yaml
├── stage/        # Staging environment
│   └── (same structure)
└── prod/         # Production environment
    └── (same structure)
```

### Namespace Isolation

Each environment runs in its own namespace for:
- **Resource isolation**: Separate quotas and limits
- **Network isolation**: Services scoped to namespace
- **RBAC separation**: Different permissions per namespace
- **Clear visibility**: Easy to identify environment

### Resources

#### Deployments
- **Frontend**:
  - Dev: 1 replica, 100m CPU / 128Mi memory request
  - Stage: 2 replicas, 200m CPU / 256Mi memory request
  - Prod: 3 replicas, 500m CPU / 512Mi memory request

- **Backend**:
  - Same replica and resource scaling as frontend
  - Includes security context (non-root, read-only)
  - Pod anti-affinity (prefer spread across nodes)

#### Services
- **Type**: ClusterIP (internal networking only)
- **Ports**: 
  - Frontend: 3000 (dev) or 3000 (stage/prod)
  - Backend: 5000

#### ConfigMaps
- **Frontend**: API and Socket.IO URLs for backend connectivity
- **Backend**: Environment-specific configuration
  - NODE_ENV (development/staging/production)
  - Client CORS origins
  - Chat UI colors

### Deploying Manifests

```bash
# Apply dev environment
kubectl apply -f k8s/dev/

# Apply staging environment
kubectl apply -f k8s/stage/

# Apply production environment
kubectl apply -f k8s/prod/
```

### Verification

```bash
# List all namespaces
kubectl get ns

# Check deployments
kubectl get deployments -n simple-chat-dev
kubectl get deployments -n simple-chat-stage
kubectl get deployments -n simple-chat-prod

# Check pods
kubectl get pods -n simple-chat-prod

# Check services
kubectl get svc -n simple-chat-prod

# Port-forward for local testing
kubectl port-forward svc/frontend-prod 3000:3000 -n simple-chat-prod
kubectl port-forward svc/backend-prod 5000:5000 -n simple-chat-prod
```

---

## 5. Argo CD GitOps Setup

### Architecture

Argo CD synchronizes the desired state from Git to the running Kubernetes cluster:

```
Git Repository (dev/stage/prod branches)
           ↓
      Argo CD (watches branches)
           ↓
    Kubernetes Cluster
  (dev/stage/prod namespaces)
```

### Installation

```bash
# Create argocd namespace
kubectl create namespace argocd

# Install Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Access Argo CD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Configuration

#### Add Git Repositories to Argo CD

```bash
# Add frontend repository
argocd repo add https://github.com/mdarifahammedreza/simpleChatui.git \
  --username <github-user> \
  --password <github-token>

# Add backend repository
argocd repo add https://github.com/mdarifahammedreza/simpleChatserver.git \
  --username <github-user> \
  --password <github-token>
```

#### Create Applications

Apply Argo CD Application manifests:

```bash
kubectl apply -f argocd/frontend-dev-app.yaml
kubectl apply -f argocd/frontend-stage-app.yaml
kubectl apply -f argocd/frontend-prod-app.yaml
kubectl apply -f argocd/backend-dev-app.yaml
kubectl apply -f argocd/backend-stage-app.yaml
kubectl apply -f argocd/backend-prod-app.yaml
```

### Application Configuration

**Manual Sync (Dev & Stage)**:
```yaml
syncPolicy:
  automated:
    prune: false
    selfHeal: true
```
- `prune: false` - Do not auto-delete resources removed from Git
- `selfHeal: true` - Auto-sync if cluster state drifts from Git

**Automatic Sync (Production)**:
Same as above, but deployment is triggered immediately on PR merge

### Monitoring Sync Status

```bash
# Check application status
argocd app get frontend-dev
argocd app get backend-prod

# Watch applications
argocd app wait frontend-prod --sync

# Get diff before sync
argocd app diff frontend-stage
```

### Manual Deployment (Dev & Stage)

```bash
# Via Argo CD CLI
argocd app sync frontend-dev
argocd app sync backend-stage

# Via Kubernetes manifest
kubectl patch application frontend-dev -n argocd \
  -p '{"metadata":{"finalizers":["resources-finalizer.argocd.argoproj.io"]}}' \
  --type merge
```

### Production Deployment Workflow

1. **Developer pushes code** → `stage` branch
   - GitHub Actions builds and pushes `stage-{version}` image
   - Manual approval needed via Argo CD dashboard

2. **Code reviewed and tested** in staging environment

3. **Create PR** from `stage` → `prod`
   - Code review required (2 approvals)
   - GitHub Actions CI/CD passes

4. **Merge PR** to `prod`
   - GitHub Actions builds and pushes `prod-{version}` image
   - **Automatic**: Argo CD detects new image tag
   - Argo CD syncs `prod` namespace with new deployment
   - Rolling update begins immediately

5. **Monitor deployment**
   ```bash
   argocd app watch frontend-prod
   ```

---

## 6. Complete Promotion Workflow

### Example: Promoting a Feature to Production

#### Step 1: Development

```bash
# Create feature branch
git checkout dev
git checkout -b feature/chat-notifications

# Make changes, commit
git add .
git commit -m "Add chat notifications"

# Push to GitHub
git push origin feature/chat-notifications

# Create PR: feature/chat-notifications → dev
# Review & merge when CI passes
```

**Result**: 
- Dev image tagged: `dev-v1.0.0-abc1234` pushed to GHCR
- Developers can manually deploy to dev namespace

#### Step 2: Staging

```bash
# Create PR: dev → stage
git checkout stage
git pull origin stage
git merge origin/dev
git push origin stage

# Or via GitHub UI: Create PR dev → stage
# Review & merge (requires 2 approvals)
```

**Result**:
- Stage image tagged: `stage-v1.0.0-abc1234` pushed to GHCR
- Staging Argo CD Application shows OutOfSync
- Manual approval required via Argo CD dashboard
- QA team tests in staging environment

#### Step 3: Production

```bash
# After staging QA passes, create PR: stage → prod
# Review & merge (requires 2 approvals + admin review)
```

**Result**:
- Prod image tagged: `prod-v1.0.0-abc1234` and `v1.0.0-abc1234`
- **Automatic**: Argo CD syncs all 3 prod deployments
- Rolling update with 0-downtime (maxUnavailable: 1)
- Service immediately handles new traffic

#### Step 4: Verification

```bash
# Check rollout status
kubectl rollout status deployment/frontend-prod -n simple-chat-prod

# Check pod events
kubectl describe pods -n simple-chat-prod

# Check Argo CD sync
argocd app get frontend-prod
```

---

## 7. Debugging & Troubleshooting

### Common Issues

#### Pods not starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n simple-chat-prod

# Check logs
kubectl logs <pod-name> -n simple-chat-prod

# Check events
kubectl get events -n simple-chat-prod --sort-by='.lastTimestamp'
```

#### Images not pulling

```bash
# Check image pull secrets
kubectl get secrets -n simple-chat-prod

# Verify image exists in registry
docker pull ghcr.io/mdarifahammedreza/simple-chat-frontend:prod-latest

# Check imagePullBackOff
kubectl describe pod <pod-name> -n simple-chat-prod | grep -A 5 Events
```

#### Argo CD out of sync

```bash
# Refresh Argo CD cache
argocd app refresh frontend-prod

# Check git repo connection
argocd repo list

# See sync status detail
argocd app get frontend-prod
```

### Health Checks

Frontend and backend expose health check endpoints:

```bash
# Frontend (served by serve CLI)
kubectl port-forward svc/frontend-prod 3000:3000 -n simple-chat-prod
curl http://localhost:3000/

# Backend
kubectl port-forward svc/backend-prod 5000:5000 -n simple-chat-prod
curl http://localhost:5000/health
```

---

## 8. Security Considerations

### Container Security

- ✅ **Non-root user**: Containers run as user 1000
- ✅ **Read-only filesystem**: Prevents runtime modifications (prod only)
- ✅ **Capability dropping**: No unnecessary Linux capabilities
- ✅ **Image scanning**: GitHub Actions can scan images with Trivy
- ✅ **Private registry**: Images in GHCR with authentication

### Network Security

- ✅ **ClusterIP services**: No external exposure by default
- ✅ **Namespace isolation**: RBAC can restrict cross-namespace access
- ✅ **Service mesh optional**: Can add Istio for mTLS and observability
- ✅ **No Ingress**: External access must be configured separately

### Access Control

- ✅ **GitHub branch protection**: Enforces review process
- ✅ **Argo CD RBAC**: Can restrict who can sync production
- ✅ **Kubernetes RBAC**: Different roles per environment
- ✅ **Token rotation**: Argo CD auth tokens and GitHub PATs

### Secrets Management

Current setup uses ConfigMaps for non-sensitive data. For secrets:

```bash
# Create secret for backend
kubectl create secret generic backend-secrets \
  -n simple-chat-prod \
  --from-literal=API_KEY=xxx \
  --from-literal=DB_URL=yyy

# Reference in deployment
envFrom:
- secretRef:
    name: backend-secrets
```

Consider:
- HashiCorp Vault for centralized secret management
- Sealed Secrets or External Secrets Operator for GitOps-friendly secrets
- AWS Secrets Manager or Azure Key Vault integration

---

## 9. Monitoring & Observability

### Logs

```bash
# Follow logs from all frontend pods
kubectl logs -f deployment/frontend-prod -n simple-chat-prod

# Previous logs from crashed pod
kubectl logs <pod-name> --previous -n simple-chat-prod
```

### Metrics

Pods expose Prometheus metrics (annotations in deployments):
```yaml
prometheus.io/scrape: "true"
prometheus.io/port: "3000"
prometheus.io/path: "/metrics"
```

### Alerting

Consider adding:
- Pod restart alerts
- Deployment replica mismatch
- Image pull failures
- High CPU/memory usage
- Argo CD sync failures

---

## 10. Rollback Procedures

### Argo CD Rollback

```bash
# List revision history
argocd app history frontend-prod

# Rollback to specific revision
argocd app rollback frontend-prod <revision-number>
```

### Manual Rollback

```bash
# Revert commit that caused issue
git revert <commit-hash>
git push origin prod

# Argo CD automatically syncs to reverted state
argocd app wait frontend-prod --sync
```

### Kubectl Rollback (Direct)

```bash
# Rollback deployment
kubectl rollout undo deployment/frontend-prod -n simple-chat-prod

# See rollout history
kubectl rollout history deployment/frontend-prod -n simple-chat-prod
```

---

## 11. Scaling & Resource Management

### Horizontal Pod Autoscaling

Optional: Add HPA to production deployments

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: frontend-prod-hpa
  namespace: simple-chat-prod
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: frontend-prod
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Resource Limits

Current limits (configurable):

| Environment | CPU Request | Memory Request | CPU Limit | Memory Limit |
|------------|------------|----------------|-----------|--------------|
| Dev        | 100m       | 128Mi          | 500m      | 512Mi        |
| Stage      | 200m       | 256Mi          | 1000m     | 1Gi          |
| Prod       | 500m       | 512Mi          | 2000m     | 2Gi          |

---

## 12. Cost Optimization

- **Dev**: Single replica, minimal resources - cheap development
- **Stage**: 2 replicas for testing HA scenarios
- **Prod**: 3+ replicas for HA, pod disruption budgets
- **Scaling down**: Can scale dev to 0 during off-hours
- **Reserved instances**: Use for prod nodes
- **Spot instances**: Use for dev/stage non-critical workloads

---

## Appendix: Quick Start

### Prerequisites

- GitHub account with forked repositories
- kubectl configured for Kubernetes cluster
- Argo CD installed on cluster
- Docker installed locally

### One-time Setup

```bash
# 1. Clone this repository
git clone <your-fork-url>
cd simple-chat-platform

# 2. Create branches
git checkout -b dev origin/dev
git checkout -b stage origin/stage
git checkout -b prod origin/prod

# 3. Setup Argo CD repositories
argocd repo add <frontend-repo-url>
argocd repo add <backend-repo-url>

# 4. Create Argo CD applications
kubectl apply -f argocd/

# 5. Verify installations
kubectl get namespaces
argocd app list
```

### Deployment Workflow

```bash
# Feature → Dev
git checkout feature/xyz
git push origin feature/xyz
# Create PR: feature/xyz → dev, merge

# Dev → Staging
git checkout dev && git pull
git checkout stage && git merge dev && git push
# Create PR: dev → stage, approve & merge
# Manually sync in Argo CD

# Staging → Production
# Create PR: stage → prod
# Require reviews, merge
# Auto-deployment via Argo CD
```

---

## References

- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)
