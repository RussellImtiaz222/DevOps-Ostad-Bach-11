# Application Deployment - Step by Step

## Prerequisites
✅ Master node setup complete (MicroK8s v1.35.6 running)
✅ Worker node MicroK8s installed and configured
✅ Docker image pushed to Docker Hub: `irussell1807/devops_module_12_assignment:latest`
✅ **Status:** ✅ DEPLOYMENT COMPLETE - Application is running!

---

## STEP 1: Create Kubernetes Manifests on Master

### SSH into master node:
```powershell
ssh -i "C:\Users\iruss\.pem" ubuntu@34.200.249.8
```

### Create namespace manifest:
```bash
cat > k8s-namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: production
EOF
```

### Create deployment manifest:
```bash
cat > k8s-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
  namespace: production
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app
                      operator: In
                      values:
                        - myapp
                topologyKey: kubernetes.io/hostname
      containers:
        - name: app
          image: irussell1807/devops_module_12_assignment:latest
          imagePullPolicy: Always
          ports:
            - containerPort: 5000
          livenessProbe:
            httpGet:
              path: /api
              port: 5000
            initialDelaySeconds: 10
            periodSeconds: 20
          readinessProbe:
            httpGet:
              path: /api
              port: 5000
            initialDelaySeconds: 5
            periodSeconds: 10
          resources:
            limits:
              memory: 256Mi
              cpu: 500m
            requests:
              memory: 64Mi
              cpu: 100m
          securityContext:
            runAsNonRoot: true
            runAsUser: 1000
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
EOF
```

### Create service manifest:
```bash
cat > k8s-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: app-service
  namespace: production
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 5000
      nodePort: 30080
  selector:
    app: myapp
EOF
```

---

## STEP 2: Apply Manifests

### Apply all manifests to the cluster:
```bash
sudo microk8s kubectl apply -f k8s-namespace.yaml
sudo microk8s kubectl apply -f k8s-deployment.yaml
sudo microk8s kubectl apply -f k8s-service.yaml
```

### Expected output:
```
namespace/production created
deployment.apps/app-deployment created
service/app-service created
```

## STEP 3: Verify Deployment

### Check pods:
```bash
sudo microk8s kubectl get pods -n production
```

### Expected output:
```
NAME                          READY   STATUS    RESTARTS   AGE
app-deployment-xxxxxx-xxxxx   1/1     Running   0          2m
app-deployment-xxxxxx-xxxxx   1/1     Running   0          2m
app-deployment-xxxxxx-xxxxx   1/1     Running   0          2m
```

✅ All 3 pods should show READY: 1/1 and STATUS: Running

---

## STEP 4: Verify Service

```bash
sudo microk8s kubectl get svc -n production
```

### Expected output:
```
NAME          TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
app-service   NodePort   10.152.183.206   <none>        80:30080/TCP   1m
```

✅ Service is exposed on port 30080

---

## STEP 5: Test Your Application

### Test API endpoint:
```bash
curl -s http://localhost:30080/api
```

### Expected response:
```json
{"message":"Hello World changes"}
```

### Test web interface:
```bash
curl -s http://localhost:30080/ | head -20
```

### Expected response:
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Hello World</title>
</head>
<body>
    <h1>Roy</h1>
```

✅ Application is working correctly!

---

## STEP 6: Access from External Network

### Use the master node's public IP:
```bash
curl http://34.200.249.8:30080/api
```

### Or open in browser:
```
http://34.200.249.8:30080/
http://34.200.249.8:30080/api
```

✅ Your application is now accessible from the internet!

### From local machine (PowerShell):

```powershell
curl http://34.200.249.8:30080/api
```

### What to expect:
```json
{"message":"Hello World changes"}
```

### Or access in browser:
Visit: `http://34.200.249.8:30080/`

---

## STEP 6: Verify Detailed Deployment

Run these commands to verify everything:

```bash
# Check deployment status
kubectl get deployment -n production
kubectl describe deployment node-express-app -n production

# Check pods in detail
kubectl get pods -n production -o wide

# Check service endpoints
kubectl get endpoints -n production

# Check pod logs
kubectl logs -n production <pod-name>
```

---

## ✅ Application Deployment Complete!

Your application is now running on Kubernetes!

---

## Application Details

| Component | Details |
|-----------|---------|
| Namespace | production |
| Deployment Name | node-express-app |
| Replicas | 3 |
| Image | irussell1807/devops_module_12_assignment:latest |
| Service Type | NodePort |
| Service Port | 80 |
| Node Port | 30080 |
| Application Port | 5000 |
| Access URL | http://34.200.249.8:30080/ |
| API Endpoint | http://34.200.249.8:30080/api |

---

## Verification Commands

### Check everything is running:

```bash
# Check all resources in production namespace
kubectl get all -n production

# Check if pods can reach each other
kubectl exec -n production <pod-name> -- curl localhost:5000/api

# Check pod resource usage
kubectl top pods -n production
```

### View application logs:

```bash
# View logs from one pod
kubectl logs -n production <pod-name>

# Follow logs in real-time
kubectl logs -n production <pod-name> -f

# View logs from all pods in deployment
kubectl logs -n production -l app=node-express-app
```

### Check health:

```bash
# Describe deployment for health info
kubectl describe deployment node-express-app -n production

# Check readiness/liveness probe status
kubectl get pods -n production -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")]}'
```

---

## Scaling the Application

### Increase replicas:

```bash
# Scale to 5 replicas
kubectl scale deployment node-express-app --replicas=5 -n production

# Check scaling progress
kubectl get pods -n production
```

### Scale back down:

```bash
kubectl scale deployment node-express-app --replicas=3 -n production
```

---

## Troubleshooting

### Pods stuck in "Pending"
```bash
# Check node resources
kubectl describe nodes

# Check pod events
kubectl describe pod -n production <pod-name>

# Check if image can be pulled
kubectl get events -n production
```

### Cannot access application
```bash
# Verify service
kubectl get svc -n production

# Check service endpoints
kubectl get endpoints -n production

# Test from master node
curl http://localhost:30080/api

# Check if security group allows port 30080
# AWS Console → Security Groups → Check inbound rules
```

### Pods in "CrashLoopBackOff"
```bash
# Check pod logs
kubectl logs -n production <pod-name>

# Describe pod for error details
kubectl describe pod -n production <pod-name>

# Check if Docker image exists
docker pull irussell1807/devops_module_12_assignment:latest
```

### Application not responding
```bash
# Exec into pod and test locally
kubectl exec -it -n production <pod-name> -- sh

# Inside pod, test:
curl localhost:5000/api

# Check network connectivity
ping 10.0.0.1
```

---

## Next Steps

### Monitor the deployment:
```bash
# Watch pods in real-time
kubectl get pods -n production -w
```

### Update application:
1. Make code changes
2. Build new Docker image: `docker build -t devops_module_12_assignment:v1.1 .`
3. Push to Docker Hub: `docker push irussell1807/devops_module_12_assignment:v1.1`
4. Update deployment: `kubectl set image deployment/node-express-app node-express-app=irussell1807/devops_module_12_assignment:v1.1 -n production`

### Delete deployment (if needed):
```bash
# Delete everything
kubectl delete -f k8s-service.yaml
kubectl delete -f k8s-deployment.yaml
kubectl delete -f k8s-namespace.yaml

# Or just the namespace
kubectl delete namespace production
```

---

## Summary

Your Node.js Express application is now:
✅ Containerized in Docker
✅ Running on Kubernetes (3 replicas)
✅ Accessible at http://34.200.249.8:30080
✅ Loadbalanced across 2 EC2 instances
✅ Production-ready with health checks

Congratulations! 🎉
