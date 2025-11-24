# Azure Automation Runbook Setup Guide

## Overview
This runbook automatically scales up the VMSS when CPU utilization exceeds a threshold, providing automatic remediation for high-load scenarios.

## Automation Account Created
- **Name:** udacity-automation
- **Resource Group:** acdnd-c4-project
- **Location:** westus
- **SKU:** Basic
- **Runbook:** Scale-VMSS-Runbook (PowerShell)

## Setup Steps (Azure Portal Required)

### Step 1: Enable Managed Identity

1. Go to Azure Portal: https://portal.azure.com
2. Navigate to: Resource Groups → acdnd-c4-project → udacity-automation
3. In the left menu, under "Account Settings", click **Identity**
4. Under "System assigned" tab:
   - Toggle **Status** to **On**
   - Click **Save**
   - Click **Yes** to confirm
5. Copy the **Object (principal) ID** (you'll need it for permissions)

### Step 2: Grant VMSS Permissions to Managed Identity

1. Navigate to: Resource Groups → acdnd-c4-project → udacity-vmss
2. Click **Access control (IAM)** in the left menu
3. Click **+ Add** → **Add role assignment**
4. Role tab:
   - Select **Virtual Machine Contributor** role
   - Click **Next**
5. Members tab:
   - Select **Managed identity**
   - Click **+ Select members**
   - Subscription: (your subscription)
   - Managed identity: **Automation Account**
   - Select: **udacity-automation**
   - Click **Select**
   - Click **Next**
6. Review + assign tab:
   - Click **Review + assign**

### Step 3: Import Required Modules

1. Go to: udacity-automation → Modules (under Shared Resources)
2. Click **+ Add a module**
3. Click **Browse from gallery**
4. Search for and import: **Az.Accounts**
   - Click on Az.Accounts
   - Select Runtime version: **5.1**
   - Click **Import**
   - Wait for import to complete (may take 2-3 minutes)
5. Repeat for: **Az.Compute**
   - Click **+ Add a module** → **Browse from gallery**
   - Search for Az.Compute
   - Select Runtime version: **5.1**
   - Click **Import**
   - Wait for import to complete

**Important:** Az.Compute depends on Az.Accounts, so import Az.Accounts first!

### Step 4: Verify and Edit Runbook

1. Go to: udacity-automation → Runbooks
2. Click **Scale-VMSS-Runbook**
3. Click **Edit** to view/modify the script
4. Review the script parameters:
   - `$resourceGroup = "acdnd-c4-project"`
   - `$vmssName = "udacity-vmss"`
   - `$maxCapacity = 6` (adjust if needed)
5. Click **Save**
6. Click **Publish** (if not already published)
7. Click **Yes** to confirm

### Step 5: Test the Runbook

1. From the runbook page, click **Start**
2. Click **OK** to start the runbook
3. Monitor the job output:
   - You should see "Connecting to Azure using Managed Identity..."
   - "Successfully connected to Azure"
   - "Current VMSS capacity: X instances"
   - "Scaling up VMSS from X to Y instances..." (if below max)
   - "Successfully scaled VMSS to Y instances"
4. Verify VMSS was scaled:
   ```powershell
   az vmss show --resource-group acdnd-c4-project --name udacity-vmss --query "sku.capacity"
   ```

### Step 6: Create Action Group for Runbook

1. Go to: Azure Monitor → Alerts → Action groups
2. Click **+ Create**
3. Basics:
   - Resource group: **acdnd-c4-project**
   - Action group name: **vmss-remediation-group**
   - Display name: **VMSS Scale**
   - Click **Next: Notifications**
4. Notifications (optional):
   - Add email notification if desired
   - Click **Next: Actions**
5. Actions:
   - Action type: **Automation Runbook**
   - Name: **Scale-VMSS**
   - Click the pencil icon to configure:
     - Runbook source: **User**
     - Subscription: (your subscription)
     - Automation account: **udacity-automation**
     - Runbook: **Scale-VMSS-Runbook**
     - Enable common alert schema: **Yes**
     - Click **OK**
   - Click **Next: Tags** (skip)
   - Click **Review + create**
   - Click **Create**

### Step 7: Create Alert Rule for VMSS CPU

1. Go to: Azure Monitor → Alerts → Alert rules
2. Click **+ Create** → **Alert rule**
3. Scope:
   - Click **Select scope**
   - Filter by resource type: **Virtual machine scale sets**
   - Select: **udacity-vmss**
   - Click **Done**
4. Condition:
   - Click **Add condition**
   - Search for: **Percentage CPU**
   - Select: **Percentage CPU**
   - Configure:
     - Threshold: **Static**
     - Aggregation type: **Average**
     - Operator: **Greater than**
     - Threshold value: **75** (or your preferred threshold)
     - Check every: **1 minute**
     - Lookback period: **5 minutes**
   - Click **Done**
5. Actions:
   - Click **Add action groups**
   - Select: **vmss-remediation-group**
   - Click **Select**
6. Details:
   - Alert rule name: **vmss-high-cpu-remediation**
   - Description: **Automatically scale VMSS when CPU exceeds 75%**
   - Severity: **2 - Warning**
   - Enable upon creation: **Yes**
   - Click **Review + create**
   - Click **Create**

### Step 8: Test the Alert and Remediation

**Option A: Using existing load test script**
```powershell
# Navigate to project directory
cd C:\Users\v-krbork\nd081-c4-azure-performance-project-starter

# Run the load test (generates high CPU on VMSS)
.\trigger-autoscale.ps1
```

**Option B: SSH to VMSS instances and generate load**
```powershell
# Instance 1
ssh -p 50000 udacityadmin@20.184.139.83 "stress --cpu 2 --timeout 600 &"

# Instance 2  
ssh -p 50001 udacityadmin@20.184.139.83 "stress --cpu 2 --timeout 600 &"
```

**Monitor the process:**

1. Watch VMSS CPU metrics:
   ```powershell
   # Check current instance count
   az vmss show --resource-group acdnd-c4-project --name udacity-vmss --query "sku.capacity"
   
   # Monitor in portal
   # Go to: udacity-vmss → Metrics → Percentage CPU
   ```

2. Watch for alert to trigger:
   - Go to: Azure Monitor → Alerts
   - You should see the alert fire when CPU > 75%

3. Verify runbook execution:
   - Go to: udacity-automation → Jobs
   - You should see a new job for Scale-VMSS-Runbook
   - Click on the job to see output
   - Verify it shows scaling from N to N+1 instances

4. Verify VMSS scaled:
   ```powershell
   az vmss list-instances --resource-group acdnd-c4-project --name udacity-vmss --query "[].{Name:name, State:provisioningState}" -o table
   ```

## Screenshots Required for Submission

Create a folder: `submission-screenshots/runbook/`

Capture the following:

1. **automation-account-identity.png**
   - Automation Account → Identity page showing system-assigned identity enabled

2. **runbook-code.png**
   - Scale-VMSS-Runbook → Edit view showing the PowerShell script

3. **runbook-test-output.png**
   - Runbook job output showing successful scaling action

4. **alert-rule-runbook.png**
   - Alert rule configuration showing:
     - Condition: CPU > 75%
     - Action: Execute Scale-VMSS-Runbook

5. **alert-fired-runbook.png**
   - Azure Monitor → Alerts showing the alert fired

6. **vmss-scaled-by-runbook.png**
   - VMSS instances view showing increased capacity after runbook execution
   - Or Azure Monitor metrics showing instance count increase

7. **runbook-job-history.png**
   - Automation Account → Jobs showing successful runbook executions triggered by alerts

## Verification Commands

```powershell
# Check automation account
az automation account show --resource-group acdnd-c4-project --name udacity-automation

# List runbooks
az automation runbook list --resource-group acdnd-c4-project --automation-account-name udacity-automation -o table

# Check runbook status
az automation runbook show --resource-group acdnd-c4-project --automation-account-name udacity-automation --name Scale-VMSS-Runbook

# List runbook jobs
az automation job list --resource-group acdnd-c4-project --automation-account-name udacity-automation --runbook-name Scale-VMSS-Runbook -o table

# Check alert rules
az monitor metrics alert list --resource-group acdnd-c4-project -o table

# Monitor VMSS capacity changes
az vmss show --resource-group acdnd-c4-project --name udacity-vmss --query "{Name:name, Capacity:sku.capacity, Instances:sku.name}" -o table
```

## Troubleshooting

### Runbook fails with authentication error
- Ensure Managed Identity is enabled on the Automation Account
- Verify the Managed Identity has "Virtual Machine Contributor" role on the VMSS
- Check that Az.Accounts and Az.Compute modules are imported

### Alert doesn't trigger runbook
- Verify action group is properly configured with the runbook
- Check that alert rule is enabled
- Ensure CPU threshold is being exceeded
- Review alert rule evaluation frequency (may take up to 5 minutes)

### Runbook runs but doesn't scale VMSS
- Check job output for error messages
- Verify VMSS name and resource group in the script are correct
- Ensure current capacity is below maxCapacity (6)
- Check if autoscale settings conflict with manual scaling

## Cleanup (Optional)

```powershell
# Delete alert rule
az monitor metrics alert delete --name vmss-high-cpu-remediation --resource-group acdnd-c4-project

# Delete action group
az monitor action-group delete --name vmss-remediation-group --resource-group acdnd-c4-project

# Delete runbook (keep automation account if needed)
az automation runbook delete --resource-group acdnd-c4-project --automation-account-name udacity-automation --name Scale-VMSS-Runbook --yes

# Delete automation account
az automation account delete --resource-group acdnd-c4-project --name udacity-automation --yes
```

## Summary

This solution provides automatic remediation for VMSS performance issues:

- **Problem Detection:** Azure Monitor alert detects CPU > 75%
- **Automatic Remediation:** Runbook scales VMSS by adding 1 instance
- **Authentication:** Managed Identity (no stored credentials)
- **Max Capacity:** Limited to 6 instances to control costs
- **Execution Time:** ~2-3 minutes from alert to scaled VMSS

The runbook can be modified to perform other remediation actions such as:
- Vertical scaling (change VM size)
- Start additional VMs
- Send notifications
- Restart services
- Clear caches
