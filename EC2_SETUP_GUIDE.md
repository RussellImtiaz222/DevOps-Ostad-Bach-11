# EC2 Kubernetes Setup Guide

## Your Instance Details

### Instance 1 (Master Node)
- **Public IP:** 34.200.249.8
- **Private IP:** 172.31.7.113
- **.pem file location:** `C:\Users\iruss\.pem`

### Instance 2 (Worker Node)
- **Public IP:** 32.197.218.119
- **Private IP:** 172.31.8.168
- **.pem file location:** `C:\Users\iruss\.pem`

---

## Step 1: Configure SSH Access (Windows PowerShell)

### Set Permission on .pem File
```powershell
# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser

# Set correct permissions on the key file
icacls "C:\Users\iruss\.pem" /inheritance:r /grant:r "%USERNAME%:(F)"
```

### Test SSH Connection to Instance 1 (Master)

```powershell
ssh -i "C:\Users\iruss\.pem" ubuntu@34.200.249.8
```

**If prompted about key format, convert it:**
```powershell
# If using PuTTY format, you may need to convert
# Alternatively, use the exact path and file name
```

---

## Step 2: Verify Security Group

Before proceeding, ensure your security group allows these inbound rules:

| Port Range | Protocol | Purpose |
|-----------|----------|---------|
| 22 | TCP | SSH Access |
| 6443 | TCP | Kubernetes API |
| 30000-32767 | TCP | NodePort Services |
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS |

**To check/modify:**
1. Go to AWS Console → EC2 → Security Groups
2. Find the security group for your instances
3. Click **Inbound rules** and verify the above rules exist

---

## Step 3: Setup Master Node (Instance 1)

### Connect via SSH
```powershell
ssh -i "C:\Users\iruss\.pem" ubuntu@34.200.249.8
```

### Run Setup Script

Once connected to the master node, copy and paste this entire script:

```bash
#!/bin/bash

# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl gnupg2 lsb-release ubuntu-keyring apt-transport-https ca-certificates

# ============================================
# Install Docker
# ============================================
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Enable Docker
sudo systemctl enable docker
sudo systemctl start docker

# ============================================
# Configure Kubernetes Prerequisites
# ============================================

# Disable swap (required for Kubernetes)
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Load required kernel modules
sudo tee /etc/modules-load.d/kubernetes.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set kernel parameters
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# ============================================
# Install Kubernetes Components
# ============================================

# Add Kubernetes GPG key
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

# Add Kubernetes repository
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install kubelet, kubectl, kubeadm
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

# Hold packages to prevent auto-updates
sudo apt-mark hold kubelet kubeadm kubectl

# Enable kubelet
sudo systemctl enable kubelet

echo "=================================="
echo "Setup complete! Ready for kubeadm init"
echo "=================================="
```

### After Script Completes

```bash
# Initialize Kubernetes cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --advertise-address=172.31.7.113

# When it completes, run these commands:
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verify cluster
kubectl get nodes
```

**SAVE THE OUTPUT!** It will show a `kubeadm join` command needed for the second node.

### Install Network Plugin

```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Wait for network plugin to start
sleep 30

# Verify nodes are Ready
kubectl get nodes
```

---

## Step 4: Setup Secondary Node (Instance 2)

### Connect via SSH (New Terminal)

```powershell
ssh -i "C:\Users\iruss\.pem" ubuntu@32.197.218.119
```

### Run Node Setup Script

```bash
#!/bin/bash

# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl gnupg2 lsb-release ubuntu-keyring apt-transport-https ca-certificates

# ============================================
# Install Docker
# ============================================
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker ubuntu
sudo systemctl enable docker
sudo systemctl start docker

# ============================================
# Configure Kubernetes Prerequisites
# ============================================

sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

sudo tee /etc/modules-load.d/kubernetes.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# ============================================
# Install Kubernetes Components
# ============================================

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable kubelet

echo "=================================="
echo "Ready to join the cluster!"
echo "=================================="
```

### Join the Cluster

After this node setup completes, use the `kubeadm join` command from Master Node output:

```bash
# Replace with the actual command from Master Node
sudo kubeadm join <MASTER_PRIVATE_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

---

## Step 5: Deploy Application to Kubernetes

### On Master Node - Copy Deployment Files

From your local machine, copy the Kubernetes manifests to the master node:

```powershell
# Copy files to master
scp -i "C:\Users\iruss\.pem" "C:\Users\iruss\Module 12 Assignment\Module-3-deployment\k8s-namespace.yaml" ubuntu@34.200.249.8:/home/ubuntu/

scp -i "C:\Users\iruss\.pem" "C:\Users\iruss\Module 12 Assignment\Module-3-deployment\k8s-deployment.yaml" ubuntu@34.200.249.8:/home/ubuntu/

scp -i "C:\Users\iruss\.pem" "C:\Users\iruss\Module 12 Assignment\Module-3-deployment\k8s-service.yaml" ubuntu@34.200.249.8:/home/ubuntu/
```

### Apply Kubernetes Manifests

On the Master Node:

```bash
# Create namespace
kubectl apply -f k8s-namespace.yaml

# Deploy application
kubectl apply -f k8s-deployment.yaml

# Create service
kubectl apply -f k8s-service.yaml

# Verify deployment
kubectl get pods -n production
kubectl get svc -n production
```

### Access Your Application

Once all pods are running:

```bash
# From master node terminal
curl http://localhost:30080/api

# From your Windows machine
curl http://34.200.249.8:30080/api
```

Expected response:
```json
{"message":"Hello World changes"}
```

---

## Step 6: Verify Everything

### On Master Node

```bash
# Check cluster status
kubectl cluster-info

# Check nodes
kubectl get nodes

# Check all pods
kubectl get pods --all-namespaces

# Check production namespace deployment
kubectl get pods -n production
kubectl get svc -n production
kubectl describe deployment node-express-app -n production
```

### View Application Logs

```bash
# Get pod name
kubectl get pods -n production

# View logs
kubectl logs -n production <pod-name>
```

---

## Troubleshooting

### SSH Connection Issues
```powershell
# Test connectivity
Test-Connection 34.200.249.8

# If key permission issues:
icacls "C:\Users\iruss\.pem" /inheritance:r /grant:r "%USERNAME%:(F)"
```

### Kubernetes Nodes Not Ready
```bash
# Check node status
kubectl get nodes

# Describe node for issues
kubectl describe node <node-name>

# Check flannel pods
kubectl get pods -n kube-flannel
```

### Pods Not Running
```bash
# Describe pod for errors
kubectl describe pod -n production <pod-name>

# View pod logs
kubectl logs -n production <pod-name>

# Check if image can be pulled
kubectl get events -n production
```

### Image Pull Issues
Ensure the Docker Hub image exists and is public:
- https://hub.docker.com/r/irussell1807/devops_module_12_assignment

---

## Next Steps Summary

1. ✅ SSH into Master Node (34.200.249.8)
2. Run Master Node setup script
3. Run `kubeadm init` and save output
4. SSH into Secondary Node (32.197.218.119)
5. Run Secondary Node setup script
6. Run `kubeadm join` on secondary node
7. Copy Kubernetes manifests to master
8. Apply manifests with `kubectl apply`
9. Verify deployment with `kubectl get pods -n production`
10. Access app at `http://34.200.249.8:30080`

---

## Quick Reference

| Task | Command |
|------|---------|
| SSH to Master | `ssh -i "C:\Users\iruss\.pem" ubuntu@34.200.249.8` |
| SSH to Secondary | `ssh -i "C:\Users\iruss\.pem" ubuntu@32.197.218.119` |
| Check cluster | `kubectl get nodes` |
| Check pods | `kubectl get pods -n production` |
| Check service | `kubectl get svc -n production` |
| View logs | `kubectl logs -n production <pod-name>` |
| Access app | `http://34.200.249.8:30080/api` |
