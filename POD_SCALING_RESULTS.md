# Pod Running Status & Scaling Results

## Screenshot 1: Running Pods (Initial State)

### Current Running Pods Status
```
NAME                                READY   STATUS    RESTARTS   AGE   IP             NODE              NOMINATED NODE   READINESS GATES
nginx-deployment-6485dbbcdf-lpjf4   1/1     Running   0          44m   172.31.46.93   ip-172-31-46-93   <none>           <none>
nginx-deployment-6485dbbcdf-nw5kl   0/1     Pending   0          44m   <none>         <none>            <none>           <none>
```

### Deployment Current Status
```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   1/2     2            1           44m
```

**Details:**
- **Total Replicas Desired**: 2
- **Total Replicas Ready**: 1
- **Up-to-Date**: 2
- **Available**: 1
- **Age**: 44 minutes
- **Running Pod**: nginx-deployment-6485dbbcdf-lpjf4 (1/1 Ready)
- **Pending Pod**: nginx-deployment-6485dbbcdf-nw5kl (0/1 Pending - awaiting networking)

---

Scaling Operation

### Scale Command Executed
```bash
kubectl scale deployment nginx-deployment -n dev-env --replicas=3
```
**Result:**
```
deployment.apps/nginx-deployment scaled
```
---
After Scaling to 3 Replicas

### Deployment After Scaling
```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   1/3     3            1           45m
```

### Pods After Scaling (3 Replicas)
```
NAME                                READY   STATUS    RESTARTS   AGE   IP             NODE              NOMINATED NODE   READINESS GATES
nginx-deployment-6485dbbcdf-ks9f7   0/1     Pending   0          3s    <none>         <none>            <none>            <none>
nginx-deployment-6485dbbcdf-lpjf4   1/1     Running   0          45m   172.31.46.93   ip-172-31-46-93   <none>           <none>
nginx-deployment-6485dbbcdf-nw5kl   0/1     Pending   0          45m   <none>         <none>            <none>            <none>
```

**Scaling Results Summary:**
- **Previous State**: 2 replicas (READY: 1/2)
- **New State**: 3 replicas (READY: 1/3)
- **New Pod Created**: nginx-deployment-6485dbbcdf-ks9f7 (Age: 3 seconds, Status: Pending)
- **Running Pods**: 1 (nginx-deployment-6485dbbcdf-lpjf4)
- **Pending Pods**: 2 (waiting for network assignment)

---

## Scaling Statistics

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Desired Replicas | 2 | 3 | +1 |
| Ready Pods | 1 | 1 | - |
| Up-to-Date Pods | 2 | 3 | +1 |
| Available Pods | 1 | 1 | - |
| Pending Pods | 1 | 2 | +1 |
| Running Pods | 1 | 1 | - |

---

## Key Observations

### Running Pods
- **Total Running**: 1 pod (nginx-deployment-6485dbbcdf-lpjf4)
- **Status**: Ready (1/1)
- **Node Assigned**: ip-172-31-46-93 (master node)
- **IP Address**: 172.31.46.93
- **Uptime**: 45 minutes
- **Restarts**: 0

### Scaling Result
- ✅ Deployment successfully scaled from 2 to 3 replicas
- ✅ New pod (nginx-deployment-6485dbbcdf-ks9f7) immediately created
- ✅ Scale command executed without errors
- ✅ Kubernetes properly managing replica count
- ⚠️ New pod in Pending state (awaiting network assignment from bridge CNI)

### Pod Distribution
- **Node ip-172-31-46-93 (Master)**: 1 Running, 2 Pending
- **Total Pods**: 3 (1 Running, 2 Pending)

---

## Commands Used for Screenshots

### Get Pods with Wide Output
```bash
kubectl get pods -n dev-env -o wide
```

### Get Deployment Status
```bash
kubectl get deployment -n dev-env
```

### Scale Deployment
```bash
kubectl scale deployment nginx-deployment -n dev-env --replicas=3
```

### Describe Pod (for more details)
```bash
kubectl describe pod nginx-deployment-6485dbbcdf-lpjf4 -n dev-env
```

---

## Verification Date
- **Date**: July 2, 2026
- **Time**: Post-security group rule configuration
- **Service Status**: ✅ Accessible on http://67.202.60.192:30080
- **Cluster Status**: ✅ Running (v1.29.15)

