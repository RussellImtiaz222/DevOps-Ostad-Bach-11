# Kubernetes Assignment - Command Reference Guide

## Part 2: Cluster Setup & Verification

### Start Minikube Cluster
```bash
minikube start --driver=docker
minikube status
```

### Check Cluster Status
```bash
kubectl cluster-info
kubectl get nodes
kubectl get nodes -o wide
```

### Check System Pods
```bash
kubectl get pods -n kube-system
kubectl get pods -n kube-system -o wide
kubectl describe pod <pod-name> -n kube-system
```

---

## Part 3: Multi-Resource Deployment

### Apply Initial Deployment & Service
```bash
kubectl apply -f 01-nginx-deployment.yaml
kubectl apply -f 02-nginx-service.yaml
```

### Verify Deployment
```bash
kubectl get deployments
kubectl get pods
kubectl get services
kubectl describe deployment nginx-deployment
kubectl describe service nginx-service
```

### Access Application
```bash
# Get Minikube IP
minikube ip

# Method 1: Direct NodePort access (requires host-to-VM connectivity)
curl http://<MINIKUBE_IP>:30080
# or visit in browser: http://<MINIKUBE_IP>:30080

# Method 2: Port Forwarding (Recommended for Windows Docker Desktop)
kubectl port-forward service/nginx-service 8080:80
# Then access: http://localhost:8080 in browser
# Keep the terminal open while accessing the service
```

---

## Part 4: ConfigMap & Secret

### Create ConfigMap and Secret
```bash
kubectl apply -f 03-configmap.yaml
kubectl apply -f 04-secret.yaml
```

### Verify ConfigMap and Secret
```bash
kubectl get configmaps
kubectl get secrets
kubectl describe configmap app-config
kubectl describe secret app-secret
```

### Update Deployment with ConfigMap/Secret
```bash
kubectl apply -f 05-updated-deployment.yaml
```

### Verify Environment Variables Inside Container
```bash
# Get a pod name
kubectl get pods

# Execute commands in pod
kubectl exec -it <pod-name> -- env
kubectl exec -it <pod-name> -- sh -c 'echo $APP_MODE'
kubectl exec -it <pod-name> -- sh -c 'echo $DB_USERNAME'
kubectl exec -it <pod-name> -- sh -c 'echo $DB_PASSWORD'
```

---

## Part 5: Scaling & Rolling Updates

### Scale Deployment to 4 Replicas
```bash
kubectl scale deployment nginx-deployment --replicas=4
kubectl get pods -w  # Watch pods being created
```

### Check Rollout Status
```bash
kubectl rollout status deployment/nginx-deployment
kubectl get deployment nginx-deployment
```

### Perform Rolling Update (Change Image Version)
```bash
kubectl set image deployment/nginx-deployment nginx=nginx:1.25 --record
# or
kubectl edit deployment nginx-deployment  # Then change image version
```

### Watch Rollout Progress
```bash
kubectl rollout status deployment/nginx-deployment
kubectl get pods -w
```

### Check Rollout History
```bash
kubectl rollout history deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment --revision=1
```

### Rollback to Previous Version
```bash
kubectl rollout undo deployment/nginx-deployment
# or specific revision:
kubectl rollout undo deployment/nginx-deployment --to-revision=1
```

### Verify Rollback
```bash
kubectl rollout status deployment/nginx-deployment
kubectl describe deployment nginx-deployment
```

---

## Part 6: Troubleshooting

### Deploy Broken Deployment
```bash
kubectl apply -f 07-broken-deployment.yaml
```

### Check Pod Status
```bash
kubectl get pods
kubectl get pods -o wide
```

### Describe Pod (Shows Events)
```bash
kubectl describe pod <broken-pod-name>
```

### Check Logs
```bash
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # If pod crashed
```

### Get Pod Events
```bash
kubectl get events --sort-by='.lastTimestamp'
```

### Fix the Deployment
```bash
# Edit the deployment to fix the image
kubectl edit deployment nginx-broken
# Change: image: nginx:invalid-version-xyz
# To: image: nginx:1.24
```

### Verify Fix
```bash
kubectl get pods -w
kubectl describe pod <pod-name>
```

---

## Part 7: Namespaces

### Create Namespace
```bash
kubectl apply -f 06-namespace.yaml
# or
kubectl create namespace dev-env
```

### Verify Namespace
```bash
kubectl get namespaces
kubectl describe namespace dev-env
```

### Deploy to Custom Namespace
```bash
# Method 1: Update YAML files with namespace: dev-env and reapply
# Method 2: Use kubectl -n flag
kubectl apply -f 01-nginx-deployment.yaml -n dev-env
kubectl apply -f 02-nginx-service.yaml -n dev-env
kubectl apply -f 03-configmap.yaml -n dev-env
kubectl apply -f 04-secret.yaml -n dev-env
```

### Verify Isolation
```bash
# Show resources in default namespace
kubectl get all -n default

# Show resources in dev-env namespace
kubectl get all -n dev-env

# Try to access dev-env resources from default (should fail)
kubectl get pods -n default
```

### Compare Namespaces
```bash
kubectl get pods --all-namespaces
kubectl get pods -A  # Short form
```

---

## Useful Debugging Commands

```bash
# Get detailed info about a pod
kubectl describe pod <pod-name>

# Stream logs from a pod
kubectl logs -f <pod-name>

# Execute a command in a pod
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec <pod-name> -- printenv

# Get pod YAML
kubectl get pod <pod-name> -o yaml

# List all resources
kubectl get all

# Get resources with more details
kubectl get pods -o wide
kubectl get services -o wide
kubectl get deployments -o wide

# Delete resources
kubectl delete deployment <name>
kubectl delete service <name>
kubectl delete configmap <name>
kubectl delete secret <name>
```

