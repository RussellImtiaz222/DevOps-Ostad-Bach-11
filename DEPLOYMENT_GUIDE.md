# Kubernetes Deployment Guide

## ✅ DEPLOYMENT STATUS: COMPLETE!

**All phases completed successfully:**
- ✅ Docker image built, tested, and pushed to Docker Hub
- ✅ AWS EC2 infrastructure configured (Master & Worker nodes)
- ✅ MicroK8s v1.35.6 cluster operational
- ✅ Application deployed with 3 replicas
- ✅ Service exposed on NodePort 30080
- ✅ Application verified and responding

**Access your application:**
```
API:  http://34.200.249.8:30080/api
Web:  http://34.200.249.8:30080/
```

---

## Note: MicroK8s vs kubeadm

This deployment uses **MicroK8s** instead of kubeadm because:
- MicroK8s is a lightweight, fully integrated Kubernetes solution
- Automatic configuration with snap package management
- No CRI (Container Runtime Interface) configuration required
- Better suited for Ubuntu 24.04
- Faster cluster initialization
- Includes built-in DNS and storage support

---

## Prerequisites
- Docker installed and running
- Docker Hub account
- AWS account with EC2 access
- kubectl installed locally (optional, for remote management)
- `kubeadm`, `kubectl`, and `kubelet` will be installed on the EC2 instance

---

## Phase 1: Docker Setup & Testing (Local Machine)

### Step 1: Build Docker Image Locally

**Ensure Docker Desktop is running**, then execute:

```bash
cd Module-3-deployment
docker build -t node-express-app:latest .
```

**Expected Output:**
```
Successfully tagged node-express-app:latest
```

### Step 2: Test Docker Container Locally

Run the container to verify it works:

```bash
docker run -d \
  --name test-app \
  -p 5000:5000 \
  -e PORT=5000 \
  node-express-app:latest
```

**Verify the container is running:**
```bash
docker ps
```

**Test the API endpoint:**
```bash
curl http://localhost:5000/api
```

**Expected Response:**
```json
{"message":"Hello World changes"}
```

**Test the health check:**
```bash
curl http://localhost:5000/
```

**Stop and remove the test container:**
```bash
docker stop test-app
docker rm test-app
```

**View container logs if needed:**
```bash
docker logs test-app
```

---

## Phase 2: Docker Hub Setup

### Step 1: Create Docker Hub Account (if needed)
1. Go to https://hub.docker.com/
2. Sign up for a free account
3. Verify your email
4. Create a repository:
   - Click **Create Repository**
   - Repository name: `node-express-app`
   - Description: "Node Express application deployed to Kubernetes"
   - Visibility: Public (for this assignment)
   - Click **Create**

### Step 2: Tag Docker Image for Docker Hub

Tag the image with your Docker Hub username:

```bash
docker tag devops_module_12_assignment:latest irussell1807/devops_module_12_assignment:latest
docker tag devops_module_12_assignment:latest irussell1807/devops_module_12_assignment:v1.0
```

### Step 3: Push to Docker Hub

**Login to Docker Hub:**
```bash
docker login
```
Enter your Docker Hub credentials when prompted.

**Push images:**
```bash
docker push irussell1807/devops_module_12_assignment:latest
docker push irussell1807/devops_module_12_assignment:v1.0
```

**Verify on Docker Hub:** Visit https://hub.docker.com/r/irussell1807/devops_module_12_assignment

---

## Phase 3: AWS EC2 Instance Setup

### Step 1: Launch EC2 Instance

1. Log into AWS Console: https://console.aws.amazon.com/
2. Navigate to **EC2 Dashboard** → **Instances**
3. Click **Launch Instances**
4. Configure:
   - **Name:** `k8s-master-node`
   - **AMI:** Ubuntu Server 22.04 LTS (free tier eligible)
   - **Instance Type:** `t3.medium`
   - **Key Pair:** Create new or use existing (download .pem file)
   - **Network:** Default VPC
   - **Storage:** 20 GB (default)

### Step 2: Configure Security Group

Create or modify security group with these inbound rules:

| Type              | Protocol | Port Range | Source       |
|------------------|----------|-----------|--------------|
| SSH               | TCP      | 22        | 0.0.0.0/0 or Your IP |
| Custom TCP        | TCP      | 6443      | 0.0.0.0/0    |
| Custom TCP        | TCP      | 30000-32767 | 0.0.0.0/0  |
| HTTP              | TCP      | 80        | 0.0.0.0/0    |
| HTTPS             | TCP      | 443       | 0.0.0.0/0    |

Click **Launch Instance** and wait for the instance to be **Running**.

### Step 3: Connect to EC2 Instance via SSH

**On Windows (PowerShell):**
```bash
# Navigate to your .pem file directory
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser

# Set correct permissions on the key file
icacls "path-to-your-key-file.pem" /inheritance:r /grant:r "%USERNAME%:(F)"

# SSH into the instance
ssh -i "path-to-your-key-file.pem" ubuntu@<EC2_PUBLIC_IP>
```

**Replace `<EC2_PUBLIC_IP>` with your actual EC2 instance public IP**

---

## Phase 4: Install Kubernetes & Docker on EC2

Once connected via SSH to your EC2 instance, run these commands:

### Step 1: Update System
```bash
sudo apt update && sudo apt upgrade -y
```

### Step 2: Install Docker
```bash
sudo apt install -y curl gnupg2 lsb-release ubuntu-keyring

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Enable Docker to start on boot
sudo systemctl enable docker
sudo systemctl start docker
```

### Step 3: Install Kubernetes Components

```bash
# Disable swap (required for Kubernetes)
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Load kernel modules
sudo tee /etc/modules-load.d/containerd.conf <<EOF
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

# Install kubelet, kubectl, kubeadm
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubeadm kubectl kubelet

# Mark packages as hold to prevent automatic updates
sudo apt-mark hold kubeadm kubectl kubelet

# Enable kubelet
sudo systemctl enable kubelet
```

### Step 4: Initialize Kubernetes Cluster

```bash
# Initialize the control plane (master node)
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# After initialization completes, you'll see a command to set up kubeconfig
# Run the provided command (usually something like):
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verify cluster is running
kubectl get nodes
```

**Note:** The output will show your node as `NotReady` until the network plugin is installed.

### Step 5: Install Flannel Network Plugin

```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Wait a minute for the network plugin to start
sleep 60

# Verify all nodes are Ready
kubectl get nodes
# Should show: STATUS = Ready
```

### Step 6: Verify Cluster Health

```bash
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces
```

---

## Phase 5: Create Production Namespace

```bash
kubectl apply -f k8s-namespace.yaml

# Verify namespace created
kubectl get namespaces
kubectl get ns production
```

---

## Phase 6: Update and Deploy Application

### Step 1: Update Kubernetes Manifests

The deployment manifest is already configured with your Docker Hub username:

```yaml
image: irussell1807/devops_module_12_assignment:latest
```

### Step 2: Apply Kubernetes Manifests

```bash
# Create namespace (already done above, but included for completeness)
kubectl apply -f k8s-namespace.yaml

# Deploy the application
kubectl apply -f k8s-deployment.yaml

# Create the service
kubectl apply -f k8s-service.yaml
```

### Step 3: Verify Deployment

```bash
# Check deployment status
kubectl get deployments -n production
kubectl describe deployment node-express-app -n production

# Check pods
kubectl get pods -n production
kubectl logs -n production <pod-name>

# Check service
kubectl get svc -n production
kubectl describe svc node-express-app -n production
```

Wait for all 3 pods to show `Running` status and `1/1` ready.

---

## Phase 7: Verification & Access

### Step 1: Verify Pods Are Running

```bash
kubectl get pods -n production

# Expected output (all should show Running):
# NAME                               READY   STATUS    RESTARTS   AGE
# node-express-app-xxxxx-xxxxx       1/1     Running   0          2m
# node-express-app-xxxxx-xxxxx       1/1     Running   0          2m
# node-express-app-xxxxx-xxxxx       1/1     Running   0          2m
```

### Step 2: Check Service Status

```bash
kubectl get svc -n production

# Note the NodePort (30080) from the output
```

### Step 3: Access the Application

The application is exposed on port 30080 via NodePort.

**From your EC2 instance:**
```bash
curl http://localhost:30080/api
```

**From your local machine:**
```bash
curl http://<EC2_PUBLIC_IP>:30080/api
```

(Replace `<EC2_PUBLIC_IP>` with your EC2 instance's public IP address)

**In a web browser:**
Navigate to: `http://<EC2_PUBLIC_IP>:30080/`

### Step 4: Check Application Health

```bash
# Check if pods are healthy (should show Running)
kubectl get pods -n production

# Get pod details
kubectl describe pod -n production <pod-name>

# View pod logs
kubectl logs -n production <pod-name>

# Check service endpoints
kubectl get endpoints -n production
```

### Step 5: Verify Rolling Updates

The deployment is configured with:
- 3 replicas
- Rolling update strategy (maxSurge: 1, maxUnavailable: 0)
- Liveness and readiness probes

To test update capability:
```bash
# Update the image (requires new image pushed to Docker Hub)
kubectl set image deployment/node-express-app \
  node-express-app=irussell1807/devops_module_12_assignment:v1.1 \
  -n production

# Watch the rollout
kubectl rollout status deployment/node-express-app -n production
```

---

## Troubleshooting

### Pods not starting
```bash
# Describe the pod to see events
kubectl describe pod <pod-name> -n production

# Check logs
kubectl logs <pod-name> -n production

# Check events
kubectl get events -n production
```

### Cannot connect to service
```bash
# Verify service is created
kubectl get svc -n production

# Verify endpoints
kubectl get endpoints -n production

# Verify network policies don't block traffic
kubectl get networkpolicies -n production
```

### Image pull errors
```bash
# Verify image exists in Docker Hub
# Verify Kubernetes can pull the image
kubectl run test --image=irussell1807/devops_module_12_assignment:latest -n production
```

### Node is NotReady
```bash
# Ensure network plugin is installed
kubectl get pods --all-namespaces | grep flannel

# Reinstall Flannel if needed
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

---

## Scaling the Deployment

### Increase Replicas
```bash
kubectl scale deployment node-express-app --replicas=5 -n production
```

### Autoscaling (requires metrics server)
```bash
# Install metrics server (if not installed)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Set up horizontal pod autoscaling
kubectl autoscale deployment node-express-app \
  --min=3 --max=10 --cpu-percent=80 \
  -n production
```

---

## Cleanup (if needed)

### Remove Everything
```bash
# Delete the application
kubectl delete -f k8s-service.yaml
kubectl delete -f k8s-deployment.yaml
kubectl delete -f k8s-namespace.yaml

# Remove the entire namespace
kubectl delete namespace production
```

### Remove EC2 Instance
1. In AWS Console, select your instance
2. Click **Instance State** → **Terminate**
3. Confirm termination

---

## Summary of Key Endpoints

| Service | URL | Port |
|---------|-----|------|
| Application Home | `http://<EC2_IP>:30080/` | 30080 |
| API Endpoint | `http://<EC2_IP>:30080/api` | 30080 |
| Kubernetes API | `https://<EC2_IP>:6443` | 6443 |

---

## Files Reference

- `Dockerfile` - Multi-stage build with health checks
- `k8s-namespace.yaml` - Production namespace
- `k8s-deployment.yaml` - 3-replica deployment with auto-scaling ready
- `k8s-service.yaml` - NodePort service on port 30080
