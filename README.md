
# Module 12: DevOps Kubernetes Deployment

## ✅ Deployment Status: COMPLETE

This project demonstrates a complete DevOps deployment pipeline from local development to production Kubernetes cluster.

### 📊 Deployment Summary

| Component | Status | Details |
|-----------|--------|---------|
| **Docker** | ✅ | Image built, tested, pushed to Docker Hub |
| **AWS Infrastructure** | ✅ | 2× EC2 t3.medium instances (us-east-1) |
| **Kubernetes** | ✅ | MicroK8s v1.35.6 cluster operational |
| **Application** | ✅ | 3-replica deployment with RollingUpdate |
| **Service** | ✅ | NodePort exposed on port 30080 |
| **Testing** | ✅ | Application verified and responding |

---

## 🚀 Quick Access

**Application URLs:**
```
API Endpoint:  http://34.200.249.8:30080/api
Web Interface: http://34.200.249.8:30080/
```

**Expected Responses:**
- API: `{"message":"Hello World changes"}`
- Web: HTML page with "Roy" title

---

## 📋 Infrastructure

### Master Node
- **Public IP:** 34.200.249.8
- **Private IP:** 172.31.7.113
- **Instance Type:** t3.medium
- **OS:** Ubuntu 24.04.4 LTS
- **Kubernetes:** MicroK8s v1.35.6 ✅

### Worker Node
- **Public IP:** 32.197.218.119
- **Private IP:** 172.31.8.168
- **Instance Type:** t3.medium
- **OS:** Ubuntu 24.04.4 LTS
- **Kubernetes:** MicroK8s v1.35.6 ✅

---

## 🐳 Docker Image

**Repository:** irussell1807/devops_module_12_assignment
- **Tag:** latest
- **Size:** 50MB (compressed) / 215MB (uncompressed)
- **Status:** ✅ Pushed to Docker Hub
- **View:** https://hub.docker.com/r/irussell1807/devops_module_12_assignment

---

## 📱 Application Details

### Routes
- **GET /** → Returns HTML page with "Roy" title
- **GET /api** → Returns JSON: `{"message":"Hello World changes"}`

### Configuration
- **Port:** 5000 (internal), 30080 (NodePort)
- **Replicas:** 3 (distributed across cluster)
- **Memory Limit:** 256Mi per pod
- **CPU Limit:** 500m per pod

### Health Checks
- **Liveness Probe:** HTTP GET /api (10s delay, 20s interval)
- **Readiness Probe:** HTTP GET /api (5s delay, 10s interval)

### Security
- **Non-root User:** UID 1000
- **Read-only Filesystem:** Enabled
- **Privilege Escalation:** Disabled
- **Pod Anti-affinity:** Preferred (spreads pods across nodes)

---

## 📚 Documentation

### Getting Started
1. **START_HERE.md** - Overview and project structure
2. **QUICK_START.md** - Fast setup reference

### Setup Guides
3. **EC2_SETUP_GUIDE.md** - AWS infrastructure setup
4. **MASTER_NODE_SETUP.md** - Master node Kubernetes configuration
5. **WORKER_NODE_SETUP.md** - Worker node setup and cluster join
6. **APPLICATION_DEPLOYMENT.md** - Kubernetes manifests and deployment

### Reference
7. **DEPLOYMENT_GUIDE.md** - Complete deployment walkthrough

---

## 🔧 Local Development

### Prerequisites
- Node.js v22
- Docker Desktop

### Running Locally
```bash
# Install dependencies
npm install

# Run development server
npm start
# Application available at http://localhost:5000

# Run tests
npm test
```

### Building Docker Image
```bash
# Build locally
docker build -t devops_module_12_assignment:latest .

# Test locally
docker run -p 5000:5000 devops_module_12_assignment:latest

# Tag for Docker Hub
docker tag devops_module_12_assignment:latest irussell1807/devops_module_12_assignment:latest

# Push to Docker Hub
docker push irussell1807/devops_module_12_assignment:latest
```

---

## 🔑 Key Technologies

- **Container Runtime:** Docker (containerd v2.2.5)
- **Orchestration:** MicroK8s v1.35.6 (Kubernetes)
- **Application:** Node.js Express server
- **Infrastructure:** AWS EC2 (t3.medium)
- **Base OS:** Ubuntu 24.04.4 LTS
- **Networking:** Calico (MicroK8s default)

---

## 📝 Project Structure

```
Module-3-deployment/
├── Dockerfile                    # Multi-stage build configuration
├── index.html                    # Static assets
├── package.json                  # Node.js dependencies
├── src/
│   ├── server.js                # Express application
│   ├── main.tsx                 # Frontend entry
│   └── public/
│       ├── index.html           # Web UI
│       └── styles.css           # Styling
├── test/
│   └── server.test.js           # Application tests
├── k8s-namespace.yaml           # Production namespace
├── k8s-deployment.yaml          # 3-replica deployment
├── k8s-service.yaml             # NodePort service (30080)
└── Documentation/
    ├── README.md                # This file
    ├── START_HERE.md            # Quick overview
    ├── QUICK_START.md           # Reference guide
    ├── EC2_SETUP_GUIDE.md       # AWS setup
    ├── MASTER_NODE_SETUP.md     # Master configuration
    ├── WORKER_NODE_SETUP.md     # Worker configuration
    ├── APPLICATION_DEPLOYMENT.md # K8s deployment
    └── DEPLOYMENT_GUIDE.md      # Full walkthrough
```

---

## ⚙️ Kubernetes Manifests

All manifests are in the root directory:
- **k8s-namespace.yaml** - Creates `production` namespace
- **k8s-deployment.yaml** - Deploys 3 app replicas with security policies
- **k8s-service.yaml** - Exposes app via NodePort on port 30080

Apply all at once:
```bash
sudo microk8s kubectl apply -f k8s-namespace.yaml
sudo microk8s kubectl apply -f k8s-deployment.yaml
sudo microk8s kubectl apply -f k8s-service.yaml
```

---

## 🧪 Testing & Verification

### SSH into Master Node
```powershell
ssh -i "C:\Users\iruss\.pem" ubuntu@34.200.249.8
```

### Verify Cluster
```bash
sudo microk8s kubectl get nodes
sudo microk8s kubectl get pods -n production
sudo microk8s kubectl get svc -n production
```

### Test Application
```bash
# Internal test (on master node)
curl http://localhost:30080/api

# External test (from any network)
curl http://34.200.249.8:30080/api
```

---

## 📦 Prerequisites

- Node.js v22 (for local development)
- Docker Desktop (for local testing)
- AWS account with EC2 access
- SSH client (built-in on Windows 10+)
- `.pem` file for EC2 key pair



