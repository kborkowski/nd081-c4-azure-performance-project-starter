# Runbook Screenshot Checklist

## ✅ Setup Completed
- Automation Account: udacity-automation (westus)
- Runbook: Scale-VMSS-Runbook (PowerShell, Published)
- Managed Identity: Enabled with Virtual Machine Contributor role
- Test Execution: Successful (VMSS scaled from 2 → 3 instances)
- Current VMSS Capacity: 3 instances

## 📋 Required Screenshots (7 Total)

### 1. Resource Group Overview ✓
**File:** `resource-group-runbook.png`

**Capture:**
- Portal: Resource Groups → acdnd-c4-project
- Show all resources including:
  - udacity-automation (Automation Account)
  - udacity-vmss (Virtual Machine Scale Set)
  - udacity-cluster (AKS)
  - Other resources

---

### 2. Alert Rule - Overview ⏳
**File:** `alert-rule-runbook-overview.png`

**Capture:**
- Portal: Azure Monitor → Alerts → Alert rules → vmss-high-cpu-remediation
- Must show:
  - Alert name: vmss-high-cpu-remediation
  - Resource: udacity-vmss
  - Condition: Percentage CPU > 75%
  - Action group: vmss-remediation-group
  - Status: Enabled

**⚠️ MUST CREATE FIRST:**
```
Alert Rule Name: vmss-high-cpu-remediation
Resource: udacity-vmss
Condition: Percentage CPU > 75% (Average over 5 min)
Action Group: vmss-remediation-group (with runbook action)
```

---

### 3. Alert Rule - Detailed Condition ⏳
**File:** `alert-rule-condition-details.png`

**Capture:**
- From alert rule, show condition configuration
- Must show:
  - Signal: Percentage CPU
  - Operator: Greater than
  - Threshold: 75
  - Aggregation type: Average
  - Evaluation frequency: 1 minute
  - Lookback period: 5 minutes

---

### 4. Action Group Configuration ⏳
**File:** `action-group-runbook.png`

**Capture:**
- Portal: Azure Monitor → Action groups → vmss-remediation-group
- Show Actions tab with:
  - Action type: Automation Runbook
  - Runbook: Scale-VMSS-Runbook
  - Automation Account: udacity-automation

**⚠️ MUST CREATE FIRST:**
```
Action Group Name: vmss-remediation-group
Action Type: Automation Runbook
Runbook: Scale-VMSS-Runbook
Automation Account: udacity-automation
Enable common alert schema: Yes
```

---

### 5. Alert Email ⏳
**File:** `alert-email-runbook.png`

**Capture:**
- Email to: borkowski.kristof@outlook.hu
- Subject: "Azure Monitor Alert: vmss-high-cpu-remediation fired"
- Must show:
  - Email timestamp
  - Alert details (CPU exceeded 75%)
  - Resource: udacity-vmss

**⚠️ TIMING CRITICAL:** Email timestamp must be within 10 minutes of runbook execution

---

### 6. Runbook Execution Output ⏳
**File:** `runbook-job-output.png`

**Capture:**
- Portal: udacity-automation → Jobs → (select job triggered by alert)
- Must show:
  - Job status: Completed
  - Start time (within 10 min of email)
  - Output showing:
    - "Successfully connected to Azure"
    - "Current VMSS capacity: 3 instances"
    - "Scaling up VMSS from 3 to 4 instances"
    - "Successfully scaled VMSS to 4 instances"

---

### 7. VMSS Scaled Evidence ⏳
**File:** `vmss-scaled-evidence.png`

**Capture ONE of these:**

**Option A: Instance View**
- Portal: udacity-vmss → Instances
- Show 4 instances listed
- Include timestamp

**Option B: Metrics Chart**
- Portal: Azure Monitor → Metrics → udacity-vmss
- Metric: Instance Count
- Show increase from 3 → 4 instances
- Time range showing the scaling event
- Timestamp visible

**Option C: Activity Log**
- Portal: udacity-vmss → Activity log
- Filter: "Write Virtual Machine Scale Set"
- Show scaling operation with timestamp matching alert

---

## 🔧 Setup Steps (If Not Yet Completed)

### Step 1: Create Action Group
```powershell
# Via Portal is easier, but here's the CLI approach:
# Go to Azure Monitor → Action groups → + Create
# Configure runbook action as described above
```

### Step 2: Create Alert Rule
```powershell
# Via Portal:
# Azure Monitor → Alerts → + Create → Alert rule
# Follow configuration above
```

### Step 3: Generate Load to Trigger Alert
```powershell
# SSH to all 3 VMSS instances and run stress test
ssh -p 50000 udacityadmin@20.184.139.83 "stress --cpu 2 --timeout 600 &"
ssh -p 50001 udacityadmin@20.184.139.83 "stress --cpu 2 --timeout 600 &"
ssh -p 50002 udacityadmin@20.184.139.83 "stress --cpu 2 --timeout 600 &"

# Or use the existing load test script
.\trigger-autoscale.ps1
```

### Step 4: Monitor and Wait
1. Watch CPU metrics rise above 75%
2. Wait for alert to trigger (5-10 minutes)
3. Check email for alert notification
4. Verify runbook job executes
5. Confirm VMSS scales to 4 instances

### Step 5: Capture Screenshots
- Follow the checklist above
- Ensure timestamps correlate (within 10 minutes)
- Save all screenshots to this directory

---

## ⏱️ Timeline Expectations

```
T+0:00  - Start load test (stress on 3 instances)
T+2:00  - CPU rises above 75%
T+7:00  - Alert triggers (after 5 min lookback)
T+7:30  - Email notification sent
T+8:00  - Runbook starts execution
T+10:00 - VMSS completes scaling to 4 instances
```

**Critical:** Email timestamp and runbook job start time must be within ~10 minutes

---

## 📸 When Ready to Capture

Save screenshots from `C:\Users\v-krbork\Pictures\c4` to this directory:

```powershell
# After capturing screenshots, copy them
Copy-Item "C:\Users\v-krbork\Pictures\c4\*runbook*.png" -Destination "submission-screenshots\runbook\" -Verbose

# Then commit to Git
git add submission-screenshots/runbook/
git commit -m "Add runbook screenshots for alert-triggered auto-scaling"
git push
```

---

## ✅ Verification Commands

```powershell
# Check current VMSS capacity
az vmss show --resource-group acdnd-c4-project --name udacity-vmss --query "sku.capacity"

# List VMSS instances
az vmss list-instances --resource-group acdnd-c4-project --name udacity-vmss -o table

# Check alert rules
az monitor metrics alert list --resource-group acdnd-c4-project -o table

# List runbook jobs
az automation job list --resource-group acdnd-c4-project --automation-account-name udacity-automation --runbook-name Scale-VMSS-Runbook -o table
```
