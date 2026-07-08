# Master Node Setup - Step by Step

## Your Master Node Details
- **Public IP:** 34.200.249.8
- **Private IP:** 172.31.7.113
- **.pem file:** C:\Users\iruss\.pem ✅ (Permissions set)
- **Kubernetes:** MicroK8s v1.35.6 (snap-based, automatic configuration)
- **Status:** ✅ OPERATIONAL - Cluster initialized and ready

---

## STEP 1: SSH into Master Node

### Run this command in PowerShell:

```powershell
ssh -i "C:\Users\iruss\.pem" ubuntu@34.200.249.8
```

### What to expect:
- First time: You may see a security prompt asking about the host fingerprint
- Type: `yes` and press Enter
- You should see: `ubuntu@ip-172-31-7-113:~$`

---

## STEP 2: Install MicroK8s (Simplified Kubernetes)

### Run these commands in the SSH terminal:

```bash
# Install MicroK8s (single command - handles everything)
sudo snap install microk8s --classic

# Wait for startup
sleep 10

# Check status
sudo microk8s status --wait-ready

# Add current user to microk8s group (optional, allows kubectl without sudo)
sudo usermod -a -G microk8s ubuntu

# Verify cluster is running
sudo microk8s kubectl get nodes
```

### What to expect:
```
NAME              STATUS   ROLES    AGE   VERSION
ip-172-31-7-113   Ready    <none>   1m    v1.35.6
```

✅ Your master node is now operational!

---

## STEP 3: Enable Add-ons (Optional)

```bash
# Enable DNS (for pod-to-pod communication)
sudo microk8s enable dns

# Enable storage (for persistent volumes)
sudo microk8s enable storage

# Verify add-ons
sudo microk8s kubectl get pods --all-namespaces
```

```bash
#!/bin/bash
set -e

echo "========================================"
echo "Kubernetes Master Node Setup"
echo "========================================"

# Update system
echo "Updating system..."
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl gnupg2 lsb-release ubuntu-keyring apt-transport-https ca-certificates

# ============================================
# Install Docker
# ============================================
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker ubuntu
sudo systemctl enable docker
sudo systemctl start docker

echo "Docker installed successfully"

# ============================================
# Configure Kubernetes Prerequisites
# ============================================
echo "Configuring Kubernetes prerequisites..."

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

echo "Kubernetes prerequisites configured"

# ============================================
# Install Kubernetes Components
# ============================================
echo "Installing Kubernetes components..."

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl

sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable kubelet

echo "========================================"
echo "Setup complete!"
echo "========================================"
echo ""
echo "Next: Run kubeadm init command"
echo ""
```

### What to expect:
- Takes ~5-10 minutes to complete
- You'll see progress messages
- Should end with: "Setup complete!"
- Should NOT have any errors (some warnings are OK)

---

## STEP 3: Initialize Kubernetes Cluster

**After the script finishes**, run this command:

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --advertise-address=172.31.7.113
```

### What to expect:
- Takes 1-3 minutes
- Output will be long - that's normal
- **🔴 VERY IMPORTANT:** At the end, you'll see a command that looks like:

```
kubeadm join 172.31.7.113:6443 --token abc123.defghijklmnopqrst --discovery-token-ca-cert-hash sha256:abcdefghijklmnopqrstuvwxyz123456789...
```

### ⚠️ **SAVE THIS COMMAND** - You'll need it for the worker node!

---

## STEP 4: Setup kubeconfig

**Still in the same SSH terminal**, run these commands:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Verify it worked:
```bash
kubectl get nodes
```

### What to expect:
- Should show one node with status: `NotReady` (this is normal - Flannel not installed yet)

---

## STEP 5: Install Flannel Network Plugin

**Still in the same SSH terminal**, run:

```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
sleep 30
kubectl get nodes
```

### What to expect:
- After 30 seconds, run `kubectl get nodes` again
- Status should change to: `Ready` ✅

---

## STEP 6: Verify Master Node is Ready

Run these commands:

```bash
# Check cluster is ready
kubectl get nodes

# Check all system pods
kubectl get pods --all-namespaces

# Check cluster info
kubectl cluster-info
```

### Success Indicators:
✅ 1 node showing "Ready"
✅ Status shows `Ready` not `NotReady`
✅ Flannel pods are running

---

## ✅ Master Node Complete!

When you see your node showing **"Ready"** status, proceed to:

**[Worker Node Setup](../worker-node-setup.md)**

Next step: SSH into the **second instance** (32.197.218.119) and run the worker node setup script.

---

## Troubleshooting

### SSH Connection Refused
```
Check:
- Security group allows port 22
- .pem file permissions are correct
- Public IP is correct (34.200.249.8)
```

### kubeadm init failed
```bash
# Check for errors
sudo journalctl -u kubelet -n 20

# Try again with:
sudo kubeadm reset
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --advertise-address=172.31.7.113
```

### Nodes showing NotReady after 5 minutes
```bash
# Check Flannel status
kubectl get pods -n kube-flannel
kubectl logs -n kube-flannel -l app=flannel
```

### Cannot find kubeadm join command
Re-run kubeadm init, or generate a new token:
```bash
kubeadm token create --print-join-command
```
