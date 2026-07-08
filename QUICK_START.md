# Quick Start: Kubernetes Cluster Setup

## Your Instances
- **Master Node:** 34.200.249.8 (172.31.7.113) - ✅ OPERATIONAL
- **Worker Node:** 32.197.218.119 (172.31.8.168) - ✅ CONFIGURED
- **.pem file:** C:\Users\iruss\.pem ✅ (Permissions configured)
- **Kubernetes:** MicroK8s v1.35.6 (snap-based)
- **Docker Image:** irussell1807/devops_module_12_assignment:latest

---

## Phase 1: Prepare SSH (Windows PowerShell)

```powershell
# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser

# Fix .pem file permissions
icacls "C:\Users\iruss\.pem" /inheritance:r /grant:r "%USERNAME%:(F)"
```

---

## Phase 2: Setup Master Node

### Terminal 1 - SSH to Master
```powershell
ssh -i "C:\Users\iruss\.pem" ubuntu@34.200.249.8
```

### Once connected - Run setup script
Copy entire contents of `master-setup.sh` and paste into SSH terminal.

### After setup completes - Initialize cluster
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --advertise-address=172.31.7.113
```

### 🎉 Cluster is now READY!
```bash
# Verify cluster status
sudo microk8s kubectl get nodes
# Output: Master node should show Ready

# Get join token for worker nodes
sudo microk8s add-node
# Save the join command for worker node setup
```

---

## Phase 3: Setup Worker Node

### Terminal 2 - SSH to Worker (New PowerShell window)
```powershell
ssh -i "C:\Users\iruss\.pem" ubuntu@32.197.218.119
```

### Once connected - Run setup script
Copy entire contents of `worker-setup.sh` and paste into SSH terminal.

### After setup completes - Join cluster
```bash
# Run the microk8s join command from master node (with --worker flag)
sudo microk8s join 172.31.7.113:25000/TOKEN/HASH --worker
```

---

## Phase 4: Deploy Application

### On Master Node terminal
```bash
# Create directories for manifest files
mkdir -p ~/k8s-manifests

# Copy manifests (see below for SCP from local machine)
```

### From Local Machine - Copy manifests to Master
```powershell
# In PowerShell, navigate to project directory
cd "C:\Users\iruss\Module 12 Assignment\Module-3-deployment"

# Copy files to master
scp -i "C:\Users\iruss\.pem" k8s-namespace.yaml ubuntu@34.200.249.8:/home/ubuntu/
scp -i "C:\Users\iruss\.pem" k8s-deployment.yaml ubuntu@34.200.249.8:/home/ubuntu/
scp -i "C:\Users\iruss\.pem" k8s-service.yaml ubuntu@34.200.249.8:/home/ubuntu/

# ✅ NOTE: Manifests already deployed and application is OPERATIONAL
```

### Back on Master Node terminal
```bash
# Apply manifests
kubectl apply -f k8s-namespace.yaml
kubectl apply -f k8s-deployment.yaml
kubectl apply -f k8s-service.yaml

# Verify deployment
kubectl get pods -n production
kubectl get svc -n production
```

---

## Phase 5: Verify & Access

### On Master Node
```bash
# Check nodes are Ready
kubectl get nodes

# Check all pods in production namespace
kubectl get pods -n production -o wide

# Watch deployment progress
kubectl get pods -n production -w

# Check service endpoint
kubectl get svc -n production
```

### From Local Machine - Access application
```powershell
# Test API endpoint
curl http://34.200.249.8:30080/api

# Expected response:
# {"message":"Hello World changes"}
```

### View in browser
Navigate to: `http://34.200.249.8:30080/`

---

## Troubleshooting Commands

### SSH Issues
```powershell
# Test connection
Test-Connection 34.200.249.8

# List .pem file
Get-Item "C:\Users\iruss\.pem"
```

### Node Issues
```bash
# Check node status
kubectl get nodes

# Describe specific node
kubectl describe node <node-name>

# Check node logs
sudo journalctl -u kubelet -f
```

### Pod Issues
```bash
# Check pod status
kubectl get pods -n production

# Describe pod
kubectl describe pod -n production <pod-name>

# View pod logs
kubectl logs -n production <pod-name>

# Check events
kubectl get events -n production
```

### Cluster Issues
```bash
# Check cluster info
kubectl cluster-info

# Check all namespaces
kubectl get namespaces

# Check all pods across cluster
kubectl get pods --all-namespaces
```

---

## Common Issues & Solutions

### Issue: Nodes show "NotReady"
**Solution:** Wait for Flannel to start and check:
```bash
kubectl get pods -n kube-flannel
kubectl logs -n kube-flannel <pod-name>
```

### Issue: Pods stuck in "Pending"
**Solution:** Check node resources:
```bash
kubectl describe node <node-name>
kubectl top nodes  # Shows CPU/memory usage
```

### Issue: Cannot access application
**Solution:** Verify service:
```bash
kubectl get svc -n production
kubectl get endpoints -n production
# Port should be 30080, check if open in security group
```

### Issue: Image pull errors
**Solution:** Verify image exists:
```bash
docker pull irussell1807/devops_module_12_assignment:latest
# If fails, check Docker Hub: https://hub.docker.com/r/irussell1807/devops_module_12_assignment
```

---

## Success Indicators

✅ Master Node setup script runs without errors
✅ `kubectl get nodes` shows both nodes with "Ready" status
✅ `kubectl get pods -n production` shows 3 running pods
✅ `curl http://34.200.249.8:30080/api` returns JSON response
✅ `kubectl get svc -n production` shows service on port 30080

---

## File Reference

| File | Purpose |
|------|---------|
| `master-setup.sh` | Setup script for master node |
| `worker-setup.sh` | Setup script for worker node |
| `k8s-namespace.yaml` | Production namespace manifest |
| `k8s-deployment.yaml` | Application deployment manifest |
| `k8s-service.yaml` | Service exposure manifest |
| `EC2_SETUP_GUIDE.md` | Detailed guide with explanations |
| `DEPLOYMENT_GUIDE.md` | Complete deployment documentation |

---

## Timeline

- Setup master node: ~5-10 minutes
- Setup worker node: ~5-10 minutes
- Join cluster: ~1 minute
- Deploy application: ~2-3 minutes
- **Total: ~15-25 minutes**

Pods may take 1-2 minutes to become fully ready after deployment.
