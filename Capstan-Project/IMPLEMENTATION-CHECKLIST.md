# DevOps Pipeline Implementation Checklist

## Phase 1: Repository Setup (GitHub)

### Frontend Repository (simpleChatui)
- [ ] Fork repository or transfer to your GitHub account
- [ ] Clone to local machine
- [ ] Create `dev` branch from main: `git checkout -b dev`
- [ ] Create `stage` branch: `git checkout -b stage`
- [ ] Create `prod` branch: `git checkout -b prod`
- [ ] Push all branches: `git push origin dev stage prod`

### Backend Repository (simpleChatserver)
- [ ] Fork repository or transfer to your GitHub account
- [ ] Clone to local machine
- [ ] Create `dev` branch from main
- [ ] Create `stage` branch
- [ ] Create `prod` branch
- [ ] Push all branches: `git push origin dev stage prod`

### Branch Protection Rules (per repository)

**Development branch (`dev`):**
- [ ] Require pull request reviews: 1
- [ ] Require status checks to pass
- [ ] Require branches to be up to date

**Staging branch (`stage`):**
- [ ] Require pull request reviews: 2
- [ ] Require status checks to pass
- [ ] Require branches to be up to date
- [ ] Dismiss stale reviews

**Production branch (`prod`):**
- [ ] Require pull request reviews: 2
- [ ] Require status checks to pass
- [ ] Require branches to be up to date
- [ ] Dismiss stale reviews
- [ ] Require approvals from code owners
- [ ] Include admins in restrictions

---

## Phase 2: GitHub Actions Setup

### Secrets Configuration

In each repository (Frontend & Backend) Settings → Secrets and variables → Actions:

- [ ] GitHub token already available as `GITHUB_TOKEN` (automatic)
- [ ] `ARGOCD_AUTH_TOKEN` - For production auto-deployment (optional initially)

### Workflow Files

- [ ] Copy `.github/workflows/frontend-cicd.yml` to frontend repository
- [ ] Copy `.github/workflows/backend-cicd.yml` to backend repository
- [ ] Test workflows by pushing to `dev` branch
- [ ] Verify images appear in GitHub Container Registry (GHCR)

### Container Registry Access

- [ ] Create GitHub Personal Access Token (PAT) with `write:packages` scope
- [ ] Test: `docker login ghcr.io -u <username> -p <PAT>`
- [ ] Verify workflows can push images automatically

---

## Phase 3: Kubernetes Setup

### Local Kubernetes Cluster

- [ ] Install Docker Desktop or Kubernetes alternative
- [ ] Enable Kubernetes in Docker Desktop (Settings → Kubernetes → Enable)
- [ ] Verify: `kubectl cluster-info`

### Namespaces

- [ ] Create dev namespace: `kubectl apply -f k8s/dev/namespace.yaml`
- [ ] Create stage namespace: `kubectl apply -f k8s/stage/namespace.yaml`
- [ ] Create prod namespace: `kubectl apply -f k8s/prod/namespace.yaml`
- [ ] Verify: `kubectl get namespaces`

### ConfigMaps and Deployments

- [ ] Deploy dev environment: `kubectl apply -f k8s/dev/`
- [ ] Deploy stage environment: `kubectl apply -f k8s/stage/`
- [ ] Deploy prod environment: `kubectl apply -f k8s/prod/`
- [ ] Verify all pods are running: `kubectl get pods -A`

### Service Access

- [ ] Test frontend dev: `kubectl port-forward svc/frontend-dev 3000:5173 -n simple-chat-dev`
- [ ] Test backend dev: `kubectl port-forward svc/backend-dev 5000:5000 -n simple-chat-dev`
- [ ] Verify frontend connects to backend API

---

## Phase 4: Argo CD Installation

### Argo CD Deployment

- [ ] Create argocd namespace: `kubectl create namespace argocd`
- [ ] Install Argo CD: `kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`
- [ ] Verify: `kubectl get pods -n argocd`

### Initial Access

- [ ] Port-forward to Argo CD UI: `kubectl port-forward svc/argocd-server -n argocd 8080:443`
- [ ] Get admin password: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
- [ ] Login at https://localhost:8080 with user `admin`
- [ ] Change admin password (recommended)

### Repository Configuration

- [ ] In Argo CD UI: Settings → Repositories → Connect Repo
- [ ] Add frontend repository URL (HTTPS)
- [ ] Add authentication (GitHub PAT or deploy key)
- [ ] Add backend repository URL
- [ ] Verify connection status

### Application Creation

- [ ] Create application from manifest: `kubectl apply -f argocd/frontend-dev-app.yaml`
- [ ] Create: `kubectl apply -f argocd/frontend-stage-app.yaml`
- [ ] Create: `kubectl apply -f argocd/frontend-prod-app.yaml`
- [ ] Create: `kubectl apply -f argocd/backend-dev-app.yaml`
- [ ] Create: `kubectl apply -f argocd/backend-stage-app.yaml`
- [ ] Create: `kubectl apply -f argocd/backend-prod-app.yaml`

### Verify Applications

- [ ] All apps visible in Argo CD UI
- [ ] Apps show "OutOfSync" (expected - manifests in k8s/ dirs)
- [ ] Sync each dev app manually first
- [ ] Check pod status after sync

---

## Phase 5: Testing Pipelines

### Feature Development Flow

- [ ] Create feature branch: `git checkout -b test/feature dev`
- [ ] Make a small change (e.g., update README)
- [ ] Push: `git push origin test/feature`
- [ ] Create PR: `test/feature` → `dev`
- [ ] Verify GitHub Actions runs
- [ ] Check workflow logs for build/test success
- [ ] Merge PR

### Dev → Stage Promotion

- [ ] Create PR: `dev` → `stage`
- [ ] Require 2 approvals (test with multiple users if possible)
- [ ] Merge PR
- [ ] Verify stage image appears in GHCR
- [ ] In Argo CD: Manually sync `frontend-stage` and `backend-stage` apps
- [ ] Verify stage environment is updated

### Stage → Production Deployment

- [ ] Create PR: `stage` → `prod`
- [ ] Merge PR (triggers automatic GitHub Actions)
- [ ] Verify prod images pushed to GHCR
- [ ] Observe Argo CD automatically syncs prod apps
- [ ] Verify prod environment has new image versions
- [ ] Check rollout status: `kubectl rollout status deployment/frontend-prod -n simple-chat-prod`

---

## Phase 6: Documentation & Training

- [ ] Distribute DEVOPS-GUIDE.md to team
- [ ] Train developers on branching strategy
- [ ] Train ops team on Argo CD operations
- [ ] Document any customizations made
- [ ] Create runbooks for common operations:
  - [ ] How to manually sync dev/stage
  - [ ] How to rollback a deployment
  - [ ] How to debug pod issues
  - [ ] How to view logs across environments

---

## Phase 7: Production Readiness

### Security

- [ ] Review container security contexts (read-only, non-root)
- [ ] Implement secrets management (Vault, Sealed Secrets, or ASO)
- [ ] Configure network policies (optional)
- [ ] Setup RBAC for team members
- [ ] Rotate GitHub PAT tokens regularly

### Monitoring & Alerting

- [ ] Setup Prometheus (optional but recommended)
- [ ] Configure AlertManager for critical issues
- [ ] Create dashboards for environment health
- [ ] Setup alerts for:
  - [ ] Pod restart loops
  - [ ] Deployment failures
  - [ ] Image pull errors
  - [ ] Argo CD sync failures

### Backup & Disaster Recovery

- [ ] Document disaster recovery procedure
- [ ] Test backup/restore process
- [ ] Define RTO/RPO for each environment
- [ ] Document how to restore from backups

### Performance Tuning

- [ ] Monitor resource usage across environments
- [ ] Adjust resource requests/limits based on actual usage
- [ ] Consider HPA (Horizontal Pod Autoscaler) for prod
- [ ] Test high-load scenarios before production

---

## Troubleshooting Reference

### Workflows Not Triggering
- [ ] Verify branch exists and has correct name
- [ ] Check workflow file is in `.github/workflows/` directory
- [ ] Verify workflow syntax (run `yamllint`)
- [ ] Restart workflow from GitHub Actions UI

### Images Not Building
- [ ] Check Dockerfile syntax
- [ ] Verify all dependencies in package.json/package-lock.json
- [ ] Check build stage logs in GitHub Actions
- [ ] Test build locally: `docker build -f Dockerfile.dev .`

### Argo CD Apps Not Syncing
- [ ] Verify Git repository connection in Argo CD
- [ ] Check branch exists in repository
- [ ] Check path exists in k8s/ directory
- [ ] Verify syntax of manifest files
- [ ] Check Argo CD application configuration

### Pods Not Running
- [ ] Check image pull secrets configured
- [ ] Verify image exists in registry
- [ ] Check resource limits not too restrictive
- [ ] Review pod events: `kubectl describe pod <name>`
- [ ] Check logs: `kubectl logs <pod-name>`

---

## Success Criteria

- ✅ Feature branches merge to `dev` automatically via CI/CD
- ✅ Dev and stage require manual approval in Argo CD
- ✅ Prod deployments are automatic upon PR merge
- ✅ Each container image has traceable version (commit SHA)
- ✅ All three namespaces running separate environments
- ✅ Argo CD GitOps workflow functioning end-to-end
- ✅ Team can demonstrate promotion: dev → stage → prod
