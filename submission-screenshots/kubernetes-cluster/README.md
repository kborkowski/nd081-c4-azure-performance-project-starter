# Kubernetes Cluster Screenshots

## Required Screenshots for Section 4

### 1. Application Insights Enabled on AKS
**File:** `application-insights-enabled.png`

**How to capture:**
1. Go to Azure Portal: https://portal.azure.com
2. Navigate to Resource Groups → acdnd-c4-project → udacity-cluster (AKS)
3. In the left menu, click on "Insights" under Monitoring
4. You should see Container Insights dashboard showing monitoring is enabled
5. Capture screenshot showing the Insights page with cluster name visible

### 2. Azure Monitor Alert Configuration
**File:** `azure-alert-rule.png`

**How to capture:**
1. Go to Azure Portal
2. Navigate to Monitor → Alerts → Alert rules
3. Find the alert: `aks-pod-count-alert`
4. Click on it to see details
5. Capture screenshot showing:
   - Alert name: aks-pod-count-alert
   - Condition: avg kube_pod_status_ready > 2
   - Action group: aks-pod-alert-group (email: borkowski.kristof@outlook.hu)
   - Status: Enabled

### 3. Horizontal Pod Autoscaler Output
**File:** `hpa-output.png`

**Current HPA Status:**
```
NAME               REFERENCE                     TARGETS         MINPODS   MAXPODS   REPLICAS
azure-vote-front   Deployment/azure-vote-front   cpu: 169%/50%   1         10        7
```

**How to capture:**
Take a PowerShell screenshot showing:
```powershell
kubectl get hpa
kubectl get pods -l app=azure-vote-front
```
Should show REPLICAS = 7, CPU = 169%/50%, and multiple azure-vote-front pods

### 4. Application Insights - Pod Count Increase
**File:** `app-insights-pod-metrics.png`

**How to capture:**
1. Go to Azure Portal
2. Navigate to Monitor → Metrics
3. Select Scope: udacity-cluster
4. Add metric: "Number of pods by phase" or "kube_pod_status_ready"
5. Set time range to "Last 30 minutes"
6. You should see the increase from ~3 pods to 7+ pods
7. Capture screenshot showing the graph with increasing pod count

### 5. Alert Email Notification
**File:** `alert-email.png`

**Expected Email:**
- To: borkowski.kristof@outlook.hu
- Subject: Azure Monitor Alert: aks-pod-count-alert fired
- Body showing:
  - Alert name: aks-pod-count-alert
  - Resource: udacity-cluster
  - Condition: avg kube_pod_status_ready > 2
  - Timestamp of when alert fired

**Note:** Check your Outlook inbox (including spam folder). The email may take 1-5 minutes to arrive.

---

## Current Deployment Status

### AKS Cluster:
- Name: udacity-cluster
- Resource Group: acdnd-c4-project
- Location: westus
- Kubernetes Version: 1.32.9
- External IP: 20.245.134.120

### HPA Configuration:
- Target: azure-vote-front deployment
- Min Replicas: 1, Max Replicas: 10
- CPU Target: 50%
- **Current CPU: 169%**
- **Current Replicas: 7**

### Monitoring:
- Container Insights: **Enabled**
- Alert: aks-pod-count-alert
- Email: borkowski.kristof@outlook.hu

---

## Verification Commands

```powershell
# Check HPA status
kubectl get hpa

# Check frontend pods
kubectl get pods -l app=azure-vote-front

# Check alert
az monitor metrics alert show --name aks-pod-count-alert --resource-group acdnd-c4-project
```

Please the required screenshots for Kubernetes Cluster in this directory.
