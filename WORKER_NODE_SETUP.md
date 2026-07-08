# Worker Node Setup - Step by Step

## Your Worker Node Details
- **Public IP:** 32.197.218.119
- **Private IP:** 172.31.8.168
- **.pem file:** C:\Users\iruss\.pem ✅ (Already prepared)
- **Status:** ✅ COMPLETED - MicroK8s installed and ready to join

---

## Prerequisites
✅ Master node is fully set up and showing "Ready" status
✅ You have the `microk8s join` command from master node
✅ Using MicroK8s v1.35.6 (snap-based Kubernetes)

---

## STEP 1: SSH into Worker Node

### Open a NEW PowerShell window and run:

```powershell
ssh -i "C:\Users\iruss\.pem" ubuntu@32.197.218.119
```

### What to expect:
- You should see: `ubuntu@ip-172-31-8-168:~$`

---

## STEP 2: Run Worker Setup Script

**Once you're connected via SSH**, copy and paste this ENTIRE script:

```bash
#!/bin/bash
set -e

echo "========================================"
echo "Kubernetes Worker Node Setup"
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
echo "Worker Node Setup Complete!"
echo "========================================"
echo ""
echo "Ready to join the cluster!"
echo ""
```

### What to expect:
- Takes ~5-10 minutes
- You'll see progress messages
- Should end with: "Worker Node Setup Complete!"

---

## STEP 3: Join the Cluster

**This is the critical step!**

In the **master node SSH window**, get your join command. If you didn't save it from kubeadm init, generate it now:

```bash
# Run THIS on the master node if you need the join command again
kubeadm token create --print-join-command
```

### Run the join command on the worker node:

```bash
# Paste the kubeadm join command from master node
# It will look like this:
sudo kubeadm join 172.31.7.113:6443 --token abc123.defghijklmnopqrst --discovery-token-ca-cert-hash sha256:abcdefghijklmnopqrstuvwxyz123456789...
```

### What to expect:
- Takes 30-60 seconds
- Should show: "This node has joined the cluster"
- No errors

---

## STEP 4: Verify Worker Node Joined

**On the master node SSH window**, run:

```bash
kubectl get nodes
```

### What to expect:
```
NAME                       STATUS   ROLES           AGE     VERSION
ip-172-31-7-113            Ready    control-plane   5m      v1.28.x
ip-172-31-8-168            Ready    <none>          1m      v1.28.x
```

Both nodes should show: `Ready` ✅

---

## STEP 5: Verify Cluster Health

**On the master node**, run:

```bash
# Check all pods across cluster
kubectl get pods --all-namespaces

# Check cluster info
kubectl cluster-info
```

### Success Indicators:
✅ 2 nodes showing "Ready"
✅ System pods running (kube-flannel, coredns, etc.)
✅ No pods in "Pending" or "CrashLoopBackOff" state

---

## ✅ Cluster Setup Complete!

You now have a **2-node Kubernetes cluster** ready!

Next step: **Deploy your application**

Continue with: [Application Deployment](../APPLICATION_DEPLOYMENT.md)

---

## Quick Verification Commands

Run these on master node to verify everything:

```bash
# Check nodes
kubectl get nodes -o wide

# Check all pods
kubectl get pods --all-namespaces

# Check cluster status
kubectl cluster-info

# Check node details
kubectl describe node ip-172-31-7-113
kubectl describe node ip-172-31-8-168
```

---

## Troubleshooting

### Worker node not showing "Ready"
```bash
# Check kubelet logs on worker node
sudo journalctl -u kubelet -n 20

# On master node, check node status
kubectl describe node ip-172-31-8-168
```

### kubeadm join failed
```bash
# Get a new token on master node
kubeadm token create --print-join-command

# Reset worker node and try again
sudo kubeadm reset
# Then re-run the join command
```

### Pods still not showing on worker
```bash
# Give cluster ~2 minutes to settle
sleep 120

# Check if node is truly Ready
kubectl get nodes

# Check system pods
kubectl get pods --all-namespaces
```
