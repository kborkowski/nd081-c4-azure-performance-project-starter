# Auto Scaling VMSS Screenshots

Please place the required screenshots for Auto Scaling VMSS in this directory.

## ✅ Autoscaling Configuration Complete

### Autoscale Settings
- **Name**: udacity-vmss-autoscale
- **Resource**: udacity-vmss
- **Minimum Instances**: 2
- **Maximum Instances**: 4
- **Default Instances**: 2

### Scaling Rules

#### Scale-Out Rule (Increase Instances)
- **Condition**: Percentage CPU > 70%
- **Time Window**: Average over 5 minutes
- **Action**: Increase instance count by 1
- **Cooldown**: 5 minutes

#### Scale-In Rule (Decrease Instances)
- **Condition**: Percentage CPU < 30%
- **Time Window**: Average over 5 minutes
- **Action**: Decrease instance count by 1
- **Cooldown**: 5 minutes

---

## 📸 Screenshot Requirements

### Screenshot 1: Autoscaling Conditions
**Location**: Azure Portal → VM Scale Set → Settings → Scaling

**Steps**:
1. Navigate to: Portal → udacity-vmss → Settings → **Scaling**
2. You should see:
   - Autoscaling is **Enabled**
   - **Minimum instances**: 2
   - **Maximum instances**: 4
   - **Scale out** rule: CPU > 70% (Average over 5 minutes)
   - **Scale in** rule: CPU < 30% (Average over 5 minutes)
3. Take a screenshot showing all these conditions

### Screenshot 2: Activity Log - Scaling Event
**Location**: Azure Portal → VM Scale Set → Activity log

**Steps**:
1. Navigate to: Portal → udacity-vmss → **Activity log**
2. Filter by:
   - **Timespan**: Last 4 hours
   - Look for "Autoscale scale up completed" or "Update Virtual Machine Scale Set"
3. Click on the scaling event to see details
4. Take a screenshot showing:
   - The scaling operation
   - **Timestamp** of when it occurred
   - Status: Succeeded
   - Number of instances (e.g., "Scaled from 2 to 3")

### Screenshot 3: New Instances Creating
**Location**: Azure Portal → VM Scale Set → Instances

**Steps**:
1. Navigate to: Portal → udacity-vmss → **Instances**
2. During/immediately after the scale-out event, you should see:
   - New instance(s) with status **"Creating"** or **"Starting"**
   - Instance name (e.g., udacity-vmss_xxxxx)
3. **Take screenshot QUICKLY** - this status only lasts 1-3 minutes!

**⚠️ Important**: This screenshot must be taken during the scaling process. Be ready!

### Screenshot 4: Metrics Graph - Load Pattern
**Location**: Azure Portal → VM Scale Set → Metrics

**Steps**:
1. Navigate to: Portal → udacity-vmss → Monitoring → **Metrics**
2. Add metric: **Percentage CPU**
3. Set time range to show the scaling event (e.g., "Last hour")
4. The graph should clearly show:
   - CPU increasing above 70% (triggering scale-out)
   - CPU decreasing after scaling (due to additional instances handling load)
   - **Timestamp** visible on the X-axis
5. Take a screenshot showing this pattern

**✅ Verification**: The timestamp on this metrics screenshot should be within 10 minutes of the Activity Log timestamp.

---

## 🚀 How to Trigger Autoscaling

### Method 1: Stress Test on Both Instances (Recommended)

SSH into both instances and generate CPU load:

```bash
# Connect to Instance 1 (port 50000)
ssh -p 50000 udacityadmin@20.184.139.83

# Install stress tool if not present
sudo apt-get update && sudo apt-get install -y stress

# Generate 90% CPU load on all cores for 10 minutes
stress --cpu $(nproc) --timeout 600 &

# Exit and repeat for Instance 2 (port 50001)
```

### Method 2: PowerShell Script to Generate Load

Use this script to generate high web traffic:

```powershell
# Generate continuous load on the application
$jobs = @()
for ($i = 1; $i -le 200; $i++) {
    $jobs += Start-Job -ScriptBlock {
        param($url)
        for ($j = 1; $j -le 50; $j++) {
            try {
                Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5 | Out-Null
                Start-Sleep -Milliseconds 50
            } catch {
                # Continue on errors
            }
        }
    } -ArgumentList "http://20.184.139.83"
    
    if ($i % 20 -eq 0) {
        Write-Host "Started $i jobs..."
    }
}

Write-Host "All 200 jobs started. Generating load for ~5 minutes..."
Write-Host "Monitor CPU in Azure Portal: udacity-vmss -> Metrics -> Percentage CPU"

# Wait for jobs to complete
$jobs | Wait-Job | Out-Null
$jobs | Remove-Job
Write-Host "Load test complete!"
```

### Method 3: Using Apache Bench (if available)

```bash
# Install Apache Bench
sudo apt-get install -y apache2-utils

# Generate high concurrent load
ab -n 100000 -c 100 http://20.184.139.83/
```

---

## 📋 Complete Testing Process

### Phase 1: Preparation (5 minutes)
1. ✅ Go to Azure Portal → udacity-vmss → **Scaling**
2. ✅ Take **Screenshot 1** of autoscaling conditions
3. ✅ Go to **Instances** - confirm you have 2 instances running
4. ✅ Go to **Metrics** - confirm current CPU is low (< 30%)

### Phase 2: Trigger Load (10 minutes)
1. ✅ Use Method 1 or Method 2 above to generate CPU load
2. ✅ Go to **Metrics** → Add "Percentage CPU" metric
3. ✅ Watch the CPU climb above 70%
4. ✅ Wait 5-7 minutes for the metric to aggregate

### Phase 3: Capture Scaling (Critical - Fast!)
1. ✅ When CPU stays > 70% for 5 minutes, scaling will trigger
2. ✅ **IMMEDIATELY** go to **Instances** → Take **Screenshot 3** (Creating status)
3. ✅ Go to **Activity log** → Find scale event → Take **Screenshot 2** (with timestamp)
4. ✅ Go to **Metrics** → Take **Screenshot 4** (CPU graph with timestamp)

### Phase 4: Verification
1. ✅ Verify Activity Log timestamp matches Metrics timestamp (within 10 min)
2. ✅ Confirm instance count increased (2 → 3 or 3 → 4)
3. ✅ Verify CPU decreased after scaling

---

## 🔍 Verification Commands

### Check Current Instance Count
```bash
az vmss list-instances --resource-group acdnd-c4-project --name udacity-vmss --query "length([*])"
```

### Check Current CPU (from metrics)
```bash
az monitor metrics list --resource /subscriptions/cfc0ea39-da83-4ce1-90be-6d9a72135dc1/resourceGroups/acdnd-c4-project/providers/Microsoft.Compute/virtualMachineScaleSets/udacity-vmss --metric "Percentage CPU" --start-time 2025-11-24T17:00:00Z --interval PT1M --query "value[0].timeseries[0].data[-5:]"
```

### View Autoscale Settings
```bash
az monitor autoscale show --resource-group acdnd-c4-project --name udacity-vmss-autoscale --output table
```

### Check Recent Autoscale Activity
```bash
az monitor activity-log list --resource-group acdnd-c4-project --offset 2h --query "[?contains(operationName.value, 'Autoscale') || contains(operationName.value, 'virtualMachineScaleSets')].{Time:eventTimestamp, Operation:operationName.localizedValue, Status:status.localizedValue}" --output table
```

---

## ⚠️ Important Timing Notes

1. **Metric Aggregation**: Azure evaluates CPU average over 5 minutes. Scaling won't happen instantly.

2. **Cooldown Period**: After scaling, wait 5 minutes before another scale action can occur.

3. **Creating Status**: Only visible for 1-3 minutes. Have Azure Portal open and ready!

4. **Instance Startup**: New instances take 2-3 minutes to provision and start.

5. **Screenshot Coordination**: 
   - Take Activity Log + Metrics screenshots after scaling completes
   - Take "Creating" screenshot DURING the scaling process

---

## 📝 Troubleshooting

### Autoscaling Not Triggering?
- ✅ Verify CPU exceeds 70% for full 5 minutes (check Metrics graph)
- ✅ Ensure autoscale is enabled (not manual mode)
- ✅ Confirm you're at minimum capacity (2 instances)
- ✅ Check Activity Log for errors
- ✅ Verify no recent scaling (within cooldown period)

### Missed the "Creating" Status?
- Trigger another scale-out by generating more load
- Manually scale down to 2 instances, then generate load again
- The status progression is: Creating → Starting → Running (each ~1-2 min)

### CPU Not Increasing?
- Ensure stress is running on BOTH instances
- Use `top` or `htop` to verify CPU usage on instances
- Try increasing concurrent jobs/requests in load test

---

## 📊 Expected Results

### Before Scaling
- **Instances**: 2
- **CPU**: < 30% (idle)

### During Load
- **CPU**: > 70% for 5+ minutes
- **Trigger**: Autoscale evaluates condition

### After Scaling
- **Instances**: 3 (or 4 if load continues)
- **CPU**: < 50% (load distributed across more instances)
- **Activity Log**: "Autoscale scale up completed"

---

## Resource Details
- **Resource Group**: acdnd-c4-project
- **VMSS Name**: udacity-vmss
- **Autoscale Name**: udacity-vmss-autoscale
- **Location**: westus
- **Min Instances**: 2
- **Max Instances**: 4
- **Public IP**: 20.184.139.83
- **SSH Ports**: 50000 (Instance 1), 50001 (Instance 2)
