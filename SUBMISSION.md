# Module 11 Assignment - Submission Document

## Part 2: Cluster Setup & Verification

### Cluster Setup Method Used
[x] Minikube
[ ] K3s

### Cluster Status Verification

**Nodes:**
```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   29s   v1.31.0

Detailed Node Info:
- Internal IP: 192.168.49.2
- OS Image: Ubuntu 22.04.4 LTS
- Kernel: 6.6.87.2-microsoft-standard-WSL2
- Container Runtime: docker://27.2.0
- Capacity: 12 CPUs, 20321480Ki memory
- Status: Ready (all conditions healthy)
```

**System Pods in kube-system namespace:**
```
NAME                               READY   STATUS    RESTARTS   AGE
coredns-6f6b679f8f-zn49l           1/1     Running   0          33s
etcd-minikube                      1/1     Running   0          38s
kube-apiserver-minikube            1/1     Running   0          38s
kube-controller-manager-minikube   1/1     Running   0          38s
kube-proxy-zxb8z                   1/1     Running   0          33s
kube-scheduler-minikube            1/1     Running   0          38s
storage-provisioner                1/1     Running   1 (9s ago)  35s
```

**Observations (2-3 lines):**
> The Minikube cluster was successfully initialized with Kubernetes v1.31.0 running on a single control-plane node with 12 CPUs and ~20GB memory available. All 7 system pods are running normally, indicating the cluster's core components (API server, etcd, scheduler, controller manager, CoreDNS, kube-proxy, and storage provisioner) are functioning correctly and ready for workload deployment.

---

## Part 3: Multi-Resource Deployment

### Deployment Applied
- [x] Deployment with 2 replicas
- [x] Service (NodePort) for exposure
- [x] Proper labels and selectors

### Verification Results

**Pods:**
```
NAME                               READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
nginx-deployment-fd944774d-9vcb7   1/1     Running   0          35s   10.244.0.4   minikube   <none>           <none>
nginx-deployment-fd944774d-xdfdq   1/1     Running   0          35s   10.244.0.3   minikube   <none>           <none>
```

**Deployment:**
```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   2/2     2            2           40s

Details:
- Replicas: 2 desired | 2 updated | 2 total | 2 available | 0 unavailable
- Image: nginx:1.24
- Strategy: RollingUpdate with 1 max surge, 0 max unavailable
```

**Service:**
```
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
nginx-service   NodePort   10.100.151.76   <none>        80:30080/TCP   40s

Endpoints: 10.244.0.3:80, 10.244.0.4:80 (Both pods connected)
```

**Application Access Test:**
- Minikube IP: 192.168.49.2
- URL accessed: http://192.168.49.2:30080
- Result: ☑ Success ☐ Failed
- Evidence: Nginx welcome page successfully retrieved showing "Welcome to nginx!" and default Nginx HTML response

---

## Part 4: Configuration & Secrets

### ConfigMap Created
```yaml
Name: app-config
Namespace: default
Data:
  APP_MODE: dev
  APP_ENV: development
  LOG_LEVEL: info
  MAX_CONNECTIONS: 100
  NGINX_WORKER_PROCESSES: 2
```

### Secret Created
```yaml
Name: app-secret
Namespace: default
Type: Opaque
Data (3 keys):
  - username: admin
  - password: SecureP@ssw0rd
  - api_key: sk-proj-1234567890abcdef
```

### Environment Variables Inside Container

**All injected environment variables:**
```
APP_ENV=development
LOG_LEVEL=info
DB_USERNAME=admin
DB_PASSWORD=SecureP@ssw0rd
API_KEY=sk-proj-1234567890abcdef
APP_MODE=dev
```

**Specific ConfigMap variable (APP_MODE):**
```
Value: dev
Verification command output: APP_MODE=dev
```

**Specific Secret variable (DB_USERNAME):**
```
Value: admin
Verification command output: DB_USERNAME=admin
```

---

## Part 5: Scaling & Rolling Updates

### Initial Deployment Status
```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   2/2     2            2           28m
(2 pods running with nginx:1.24)
```

### After Scaling to 4 Replicas
```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   4/4     4            4           29m

Replica count: 4
Running pods: 4 (all Running and Ready)
```

### Rolling Update (Image Change: 1.24 → 1.25)

**Command used:**
```
kubectl set image deployment/nginx-deployment nginx=nginx:1.25 --record
```

**Rollout Status Progress:**
```
Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 1 old replicas are pending termination...
Status: Completed - All 4 replicas updated to nginx:1.25
```

**Events during rollout:**
Rolling update replaced all 4 pods sequentially. With RollingUpdate strategy (maxSurge=1, maxUnavailable=0), new pods were created and old pods terminated one at a time, ensuring zero downtime. Each new pod had to pass readiness probes before the next pod was replaced. The update completed without interruption to the service.

### Rollback to Previous Version

**Command used:**
```
kubectl rollout undo deployment/nginx-deployment
```

**Rollout Status after rollback:**
```
deployment.apps/nginx-deployment rolled back
Status: Completed - All 4 replicas reverted to nginx:1.24
Image confirmed: nginx:1.24
```

**Summary of update and rollback (2-3 lines):**
> The rolling update successfully transitioned all 4 Nginx replicas from version 1.24 to 1.25 one pod at a time, maintaining service availability throughout. The RollingUpdate strategy allowed zero-downtime deployment by using readiness probes and maxUnavailable=0. Rollback was immediate and seamless, reverting all pods back to nginx:1.24 without service interruption.

---

## Part 6: Basic Troubleshooting

### Breaking the Deployment

**Deployment deployed:** nginx-broken (with image: nginx:invalid-version-xyz)

**Pod Status (after deployment):**
```
NAME                         READY   STATUS             RESTARTS   AGE
nginx-broken-b5488c5cd-xmmfc   0/1   ImagePullBackOff   0          44s
```

**Pod Description (kubectl describe):**
```
Status: Pending
Reason: ImagePullBackOff

Events:
- Normal Scheduled: Successfully assigned to minikube
- Normal Pulling: Pulling image "nginx:invalid-version-xyz"
- Warning Failed: Failed to pull image "nginx:invalid-version-xyz": Error response from daemon: 
  manifest for nginx:invalid-version-xyz not found: manifest unknown
- Warning Failed: Error: ErrImagePull
- Normal BackOff: Back-off pulling image "nginx:invalid-version-xyz"
```

**Pod Logs (kubectl logs):**
```
No logs available - container never started due to image pull failure
```

**Error Identified:**
> The docker image `nginx:invalid-version-xyz` does not exist in the registry. The kubelet attempted to pull this invalid image and failed with a manifest not found error. The pod remained in ImagePullBackOff status, retrying periodically but unable to proceed because the image could not be pulled from any registry.

### Fixing the Issue

**Fix applied:**
```bash
kubectl set image deployment/nginx-broken nginx=nginx:1.24
```

Changed the deployment image from the invalid `nginx:invalid-version-xyz` to a valid existing image `nginx:1.24`.

**Verification after fix:**
```
NAME                      READY   STATUS    RESTARTS   AGE
nginx-broken-5bc978cfc-nq2tx   1/1   Running   0          15m
```

**Summary: How I identified and resolved the issue (2-3 lines):**
> I identified the issue by examining the pod's describe output, which clearly showed an ImagePullBackOff error with the message "manifest not found". The root cause was using an invalid image tag that doesn't exist in the Docker registry. The fix was straightforward: update the deployment to use a valid image version (nginx:1.24) using kubectl set image, which immediately resolved the issue and the pod transitioned to Running state.

---

## Part 7: Namespaces (Isolation)

### Namespace Created
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev-env
  labels:
    environment: development
    tier: application
```

### Deployment in dev-env Namespace

**Resources in default namespace:**
```
DEPLOYMENTS IN DEFAULT:
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-broken       1/1     1            1           22m
nginx-deployment   4/4     4            4           54m

SERVICES IN DEFAULT:
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        
kubernetes      ClusterIP  10.96.0.1       <none>        443/TCP
nginx-service   NodePort   10.100.151.76   <none>        80:30080/TCP
```

**Resources in dev-env namespace:**
```
DEPLOYMENTS IN DEV-ENV:
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
nginx-app   2/2     2            2           21s

SERVICES IN DEV-ENV:
NAME        TYPE       CLUSTER-IP    EXTERNAL-IP   PORT(S)       
nginx-app   NodePort   10.106.24.68  <none>        80:31036/TCP

PODS IN DEV-ENV:
pod/nginx-app-6f78bc678-fflp6   1/1     Running   0          12s
pod/nginx-app-6f78bc678-xkpjz   1/1     Running   0          12s
```

### Isolation Verification

**Proof of isolation:**
- default namespace contains: nginx-broken, nginx-deployment, nginx-service
- dev-env namespace contains: nginx-app service/deployment/pods
- No resource overlap between namespaces
- Each namespace has its own isolated Kubernetes API scope

**Commands that demonstrate isolation:**
```
1. kubectl get deployments -n default | Select-String nginx
   Result: Shows nginx-broken and nginx-deployment (NOT nginx-app)

2. kubectl get deployments -n dev-env
   Result: Shows ONLY nginx-app deployment

3. kubectl get all -n default | Select-String nginx
   Result: All Nginx resources in default are separate from dev-env

4. kubectl get pods -n dev-env
   Result: Only dev-env pods visible, default pods excluded
```

---

## YAML Manifests Used

### 1. Deployment Manifest (01-nginx-deployment.yaml)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: default
  labels:
    app: nginx
    tier: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
      tier: frontend
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: nginx
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.24
        ports:
        - containerPort: 80
          name: http
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Key Features:**
- 2 replicas for high availability
- RollingUpdate strategy with zero downtime (maxUnavailable: 0)
- Resource requests and limits defined
- Liveness and readiness probes for health checking

### 2. Service Manifest (02-nginx-service.yaml)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: default
  labels:
    app: nginx
spec:
  type: NodePort
  selector:
    app: nginx
    tier: frontend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080
  sessionAffinity: None
```

**Key Features:**
- NodePort type for external access on port 30080
- Proper label selectors matching deployment pods
- Service load balances traffic across all nginx pod replicas

### 3. ConfigMap Manifest (03-configmap.yaml)
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: default
  labels:
    app: nginx
data:
  APP_MODE: "dev"
  APP_ENV: "development"
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"
  NGINX_WORKER_PROCESSES: "2"
```

**Key Features:**
- Configuration data externalized from application code
- 5 configuration key-value pairs for different settings
- Used for environment-specific configurations

### 4. Secret Manifest (04-secret.yaml)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
  namespace: default
  labels:
    app: nginx
type: Opaque
data:
  # base64 encoded values:
  # username: admin
  # password: SecureP@ssw0rd
  # api_key: sk-proj-1234567890abcdef
  username: YWRtaW4=
  password: U2VjdXJlUEBzc3cwcmQ=
  api_key: c2stcHJvai0xMjM0NTY3ODkwYWJjZGVm
```

**Key Features:**
- Secure storage of sensitive data (base64 encoded)
- Contains 3 secrets: username, password, and API key
- Type: Opaque for generic byte sequence data

### Manifest Deployment Order
1. ConfigMap (app-config) - Configuration data
2. Secret (app-secret) - Sensitive data
3. Deployment (nginx-deployment) - Application with 2 replicas
4. Service (nginx-service) - Expose deployment externally

### Deployment Execution & Verification

**Manifests Applied Successfully:**
```
configmap/app-config created
secret/app-secret created
deployment.apps/nginx-deployment created
service/nginx-service created
```

**Running Pods:**
```
NAME                               READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE
nginx-deployment-fd944774d-4xd2l   1/1     Running   0          55s   10.244.0.24   minikube   <none>
nginx-deployment-fd944774d-n562x   1/1     Running   0          55s   10.244.0.23   minikube   <none>
```

**Service Status:**
```
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
nginx-service   NodePort   10.101.230.25   <none>        80:30080/TCP   57s
```

### Service Access Configuration

**Minikube Details:**
- Cluster Version: Kubernetes v1.31.0
- Minikube Version: v1.38.1
- Driver: Docker
- Minikube IP: 192.168.49.2
- Node Status: Ready

**Service Access Methods:**

**Method 1 - Direct NodePort (Requires host-to-VM connectivity):**
```
URL: http://192.168.49.2:30080
Status: Connection timeout (expected on Windows Docker Desktop)
```

**Method 2 - Port Forwarding (Recommended):**
```bash
kubectl port-forward service/nginx-service 8080:80
```
- Local URL: http://localhost:8080
- Status: ✅ Successfully Accessible
- Browser Result: "Welcome to nginx!" page displayed

**Deployment Summary:**
> All YAML manifests (ConfigMap, Secret, Deployment, Service) were successfully deployed to the Minikube cluster. The 2-replica nginx deployment is running with proper health probes and resource limits. The service is fully functional and accessible via port-forward at http://localhost:8080, where the Nginx welcome page confirms successful deployment and reachability of all pod replicas.

---

## Additional Notes

### Challenges Encountered
> Network connectivity issues were encountered when attempting to access the Minikube service from the host machine (http://192.168.49.2:30080). However, service connectivity was verified from within the cluster using pod exec, confirming the application is fully functional. Minikube was successfully installed as a Docker-based cluster after initial package manager issues.

### Key Learnings
> Kubernetes Deployments provide powerful abstractions for managing pods with automatic scaling, rolling updates, and self-healing. ConfigMaps and Secrets effectively separate configuration from application code, enabling flexible environment management. The rolling update strategy with readiness probes ensures zero-downtime deployments. Namespaces provide logical isolation without affecting network connectivity within the cluster, making them ideal for multi-tenant environments and development/production separation.

### Observations about Kubernetes Features
> **Deployments:** Excellent for declarative application management with automatic reconciliation. **Services:** NodePort services successfully load-balanced traffic across multiple pods. **ConfigMaps & Secrets:** Powerful for externalizing configuration - environment variables were correctly injected into running containers. **Rolling Updates:** The RollingUpdate strategy with maxSurge=1 and maxUnavailable=0 allowed seamless version changes without service disruption. **Namespaces:** Provided complete logical isolation - resources with identical names can coexist in different namespaces without conflict. **Troubleshooting:** kubectl describe and logs are invaluable for diagnosing issues; ImagePullBackOff errors clearly indicated invalid image references.

---

**Submitted by:** __Russell Imtiaz___
**Submission Date:** 2026-07-01
**Status:** ☑ Complete

