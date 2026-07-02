# Kubernetes Cluster Installation Guide

## Prerequisites Check

- ✓ `kubectl` is installed (v1.34.1)
- ? Docker or other container runtime
- ? Minikube or K3s

## Installation Options

### Option 1: Minikube (Recommended for Learning)

#### Prerequisites:
- Windows 10/11
- At least 2GB RAM
- Docker or Hyper-V

#### Installation Steps:

1. **Check Docker Installation:**
   ```powershell
   docker --version
   ```
   If Docker is not installed, download from: https://www.docker.com/products/docker-desktop

2. **Download Minikube Installer:**
   - Visit: https://github.com/kubernetes/minikube/releases/latest
   - Download: `minikube-windows-amd64.exe`
   - Save to: `C:\Program Files\Minikube\` (create folder if needed)
   - Add to PATH

3. **Verify Installation:**
   ```powershell
   minikube version
   ```

4. **Start Minikube Cluster:**
   ```powershell
   minikube start --driver=docker
   ```
   
   First run takes a few minutes to download and configure the cluster image.

5. **Verify Cluster is Running:**
   ```powershell
   minikube status
   kubectl cluster-info
   ```

---

### Option 2: Docker Desktop with Kubernetes

If you already have Docker Desktop installed:

1. Open **Docker Desktop Settings**
2. Go to **Kubernetes** tab
3. Check **Enable Kubernetes**
4. Click **Apply & Restart**
5. Wait for Kubernetes to initialize (check system tray)
6. Verify:
   ```powershell
   kubectl cluster-info
   ```

---

### Option 3: K3s (Lightweight Alternative)

K3s is a lightweight Kubernetes distribution.

1. **Download K3s installer:**
   - Visit: https://k3s.io/
   - Follow Windows installation instructions

2. **Verify installation:**
   ```powershell
   k3s --version
   kubectl cluster-info
   ```

---

## Troubleshooting

### Problem: `kubectl` can't connect to cluster
**Solution:** Make sure Minikube is running with `minikube start` before running kubectl commands

### Problem: Minikube won't start
**Solution:** 
- Ensure Docker is running
- Check available disk space (needs ~2GB)
- Try: `minikube start --driver=hyperv` (if you have Hyper-V)

### Problem: Pods are stuck in Pending state
**Solution:**
- Check cluster has enough resources
- Run: `kubectl describe node` to see resource availability
- Try: `minikube delete` and `minikube start` to reset

### Problem: ImagePullBackOff errors
**Solution:**
- Ensure you have internet connection (Minikube needs to pull images)
- Check image names are correct
- Try: `minikube ssh` to access cluster and debug

---

## Quick Validation Checklist

Once Minikube is running, execute these commands:

```powershell
# 1. Cluster info
kubectl cluster-info

# 2. Nodes
kubectl get nodes

# 3. System pods
kubectl get pods -n kube-system

# 4. All namespaces
kubectl get namespaces

# 5. Create test pod
kubectl run test --image=nginx
kubectl get pods
kubectl delete pod test

# 6. Minikube specific
minikube status
minikube ip
```

If all these work, your cluster is ready for the assignment!

---

## Next Steps

Once cluster is confirmed running:

1. Navigate to this directory: `C:\Users\iruss\Module 11 Assignment\`
2. Follow the commands in `COMMANDS_REFERENCE.md`
3. Apply YAML files in order: 01, 02, 03, 04, 05...
4. Document findings in `SUBMISSION.md`

