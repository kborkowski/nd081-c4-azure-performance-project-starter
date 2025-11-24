# Application Insights Screenshots

Please place the required screenshots for Application Insights in this directory.

## How to View VMSS Metrics in Application Insights

### Diagnostic Settings Configured ✅

**Status**: Diagnostic settings enabled on VMSS
- **Name**: vmss-diagnostics
- **Workspace**: udacity-loganalytics (Application Insights)
- **Metrics**: AllMetrics enabled
- **Time Grain**: PT1M (1 minute)
- **Monitoring Agent**: AzureMonitorLinuxAgent (v1.38) - Already Installed

### Steps to View and Screenshot VMSS Metrics

#### Method 1: VMSS Metrics (Recommended - Easiest)

1. **Navigate to Azure Portal**: https://portal.azure.com

2. **Find your VMSS**:
   - Search for "udacity-vmss" in the top search bar
   - Click on the "udacity-vmss" Virtual machine scale set

3. **Open Metrics**:
   - In the left menu under **Monitoring**, click **"Metrics"**

4. **View Multiple Metrics** (Create 5-7 charts):
   - Click **"+ New chart"** to add metric visualizations
   - For each chart, select from these metrics:
     1. **Percentage CPU** - Shows CPU utilization %
     2. **Available Memory Bytes** - Shows available RAM
     3. **Disk Read Bytes** - Disk read throughput
     4. **Disk Write Bytes** - Disk write throughput
     5. **Network In Total** - Bytes received
     6. **Network Out Total** - Bytes sent
     7. **OS Disk IOPS Consumed Percentage** - Disk performance

5. **Adjust Time Range**:
   - Set to "Last 30 minutes" or "Last hour" to see recent activity

6. **Take Screenshot**:
   - Capture the full page showing 5-7 metric graphs with data

#### Method 2: Log Analytics Workspace (KQL Queries)

**Note**: With AzureMonitorLinuxAgent, metrics are primarily available in Azure Monitor Metrics (Method 1 above). For log-based queries, you need to query the Log Analytics workspace directly, not Application Insights.

1. **Navigate to Log Analytics Workspace**:
   - Portal → Log Analytics workspaces → "udacity-loganalytics"
   
2. **Open Logs**:
   - Left menu → "Logs"
   
3. **Check Available Tables**:
   ```kql
   // First, see what tables are available
   search *
   | distinct $table
   | sort by $table asc
   ```

4. **Query Application Traces** (Vote tracking):
   ```kql
   traces
   | where timestamp > ago(1h)
   | where message in ("Cats Vote", "Dogs Vote")
   | extend VoteType = message
   | extend VoteCount = toint(customDimensions[message])
   | where isnotnull(VoteCount)
   | summarize CurrentVotes = max(VoteCount) by VoteType
   | render columnchart with (
       title="Current Vote Totals: Cats vs Dogs",
       xtitle="Vote Type",
       ytitle="Total Votes"
   )
   ```

5. **Query Request Metrics**:
   ```kql
   requests
   | where timestamp > ago(1h)
   | summarize Count = count(), AvgDuration = avg(duration) by bin(timestamp, 5m)
   | render timechart with (title="Request Rate and Duration")
   ```

**Recommendation**: Use **Method 1 (VMSS Metrics)** for VM performance metrics (CPU, Memory, Disk, Network) as it's the most straightforward approach.

### Screenshot Requirements

Your screenshot should display **5-7 graphs** showing:
- ✅ **CPU %** (Percentage CPU)
- ✅ **Available Memory %** or MB
- ✅ **Disk Read** Bytes/Operations
- ✅ **Disk Write** Bytes/Operations  
- ✅ **Network In** (Bytes Sent)
- ✅ **Network Out** (Bytes Received)
- ✅ **Additional metrics** (Disk IOPS, Queue Depth, etc.)

### Resource Details

- **Resource Group**: acdnd-c4-project
- **VMSS Name**: udacity-vmss
- **Location**: westus
- **Application Insights**: udacity-appinsights
- **Log Analytics**: udacity-loganalytics
- **Public IP**: 20.184.139.83
