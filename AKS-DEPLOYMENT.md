# AKS Deployment Guide

## ✅ Completed Steps

### 1. Code Preparation
- ✅ Created `Deploy_to_AKS` branch
- ✅ Updated `main.py` for AKS multi-container deployment
  - Redis connection supports `REDIS_PWD` environment variable
  - Container-to-container communication configured
- ✅ Updated `Dockerfile` in azure-vote folder
  - Base image: `tiangolo/uwsgi-nginx-flask:python3.6`
  - Installed: redis, opencensus, opencensus-ext-azure, opencensus-ext-flask, flask
- ✅ Tested locally with docker-compose
  - Frontend: `azure-vote-front:v1`
  - Backend: `redis:6.0.8`
  - Verified at http://localhost:8080
- ✅ Pushed to GitHub (Deploy_to_AKS branch)

### 2. AKS Cluster Creation (In Progress)
```bash
az aks create \
  --resource-group acdnd-c4-project \
  --name udacity-cluster \
  --node-count 1 \
  --node-vm-size Standard_B2s \
  --generate-ssh-keys \
  --enable-addons monitoring
```

**Status**: Creating (5-10 minutes)

---

## 📋 Next Steps (After AKS Cluster is Ready)

### 3. Create Azure Container Registry (ACR)

```bash
# Create ACR (choose a unique name)
az acr create \
  --resource-group acdnd-c4-project \
  --name myacr202411 \
  --sku Basic

# Log in to ACR
az acr login --name myacr202411

# Get ACR login server
az acr show --name myacr202411 --query loginServer --output table
```

### 4. Tag and Push Image to ACR

```bash
# Tag the local image with ACR path
docker tag azure-vote-front:v1 myacr202411.azurecr.io/azure-vote-front:v1

# Push to ACR
docker push myacr202411.azurecr.io/azure-vote-front:v1

# Verify image in ACR
az acr repository list --name myacr202411 --output table

# Attach ACR to AKS cluster
az aks update -n udacity-cluster -g acdnd-c4-project --attach-acr myacr202411
```

### 5. Get AKS Credentials

```bash
# Configure kubectl
az aks get-credentials \
  --resource-group acdnd-c4-project \
  --name udacity-cluster \
  --verbose

# Verify connection
kubectl get nodes
```

### 6. Update Kubernetes Manifest

Edit `azure-vote-all-in-one-redis.yaml`:
- Update image path: `myacr202411.azurecr.io/azure-vote-front:v1`

### 7. Deploy to AKS

```bash
# Deploy application
kubectl apply -f azure-vote-all-in-one-redis.yaml

# Update deployment with ACR image
kubectl set image deployment azure-vote-front azure-vote-front=myacr202411.azurecr.io/azure-vote-front:v1

# Get external IP (may take a few minutes)
kubectl get service azure-vote-front --watch

# Check pod status
kubectl get pods

# Check logs if needed
kubectl logs <pod-name>
```

### 8. Configure Autoscaling

```bash
# Create Horizontal Pod Autoscaler
kubectl autoscale deployment azure-vote-front --cpu-percent=50 --min=1 --max=10

# Check HPA status
kubectl get hpa
```

### 9. Test Autoscaling

```bash
# Run load generator
kubectl run -i --tty load-generator --image=busybox /bin/sh

# Inside the pod, run:
while true; do wget -q -O- http://azure-vote-front; done

# In another terminal, watch the HPA
kubectl get hpa --watch

# After testing, delete the load generator
kubectl delete pod load-generator

# Delete HPA when done
kubectl delete hpa azure-vote-front
```

---

## 🔍 Troubleshooting Commands

```bash
# Check AKS cluster status
az aks show --resource-group acdnd-c4-project --name udacity-cluster --query provisioningState

# View AKS activity logs
az monitor activity-log list --resource-group acdnd-c4-project

# Check pod logs
kubectl logs <pod-name>

# Describe pod for detailed info
kubectl describe pod <pod-name>

# Check service details
kubectl describe service azure-vote-front

# View ACR events
az acr repository show --name myacr202411 --repository azure-vote-front
```

---

## 📊 Expected Resources

### After Deployment:
- **AKS Cluster**: udacity-cluster (1 node, Standard_B2s)
- **ACR**: myacr202411 (Basic SKU)
- **Kubernetes Pods**: 
  - azure-vote-front (1-10 replicas with HPA)
  - azure-vote-back (1 replica - Redis)
- **Kubernetes Services**:
  - azure-vote-front (LoadBalancer with External IP)
  - azure-vote-back (ClusterIP)

### Screenshots Needed:
1. **Cluster Overview**: Insights showing container count and status
2. **HPA Configuration**: Autoscaler settings (CPU threshold, min/max replicas)
3. **Load Test**: Metrics showing pod count increasing during load
4. **Activity Log**: Scaling events with timestamps

---

## 🎯 Resource Details

- **Resource Group**: acdnd-c4-project
- **AKS Cluster**: udacity-cluster
- **ACR Name**: myacr202411 (change if needed)
- **Location**: westus
- **VM Size**: Standard_B2s
- **Node Count**: 1
- **Monitoring**: Enabled (Container Insights)
