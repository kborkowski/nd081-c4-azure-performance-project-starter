<#
.SYNOPSIS
    Remediation runbook to scale up VMSS when CPU threshold is exceeded

.DESCRIPTION
    This runbook is triggered by an Azure Monitor alert when VMSS CPU exceeds threshold.
    It will scale up the VMSS by increasing the instance count to handle the load.

.NOTES
    Requires: Az.Compute module
    Uses: System-assigned Managed Identity for authentication
#>

param(
    [Parameter(Mandatory=$false)]
    [object] $WebhookData
)

# Connect using Managed Identity
Write-Output "Connecting to Azure using Managed Identity..."
try {
    Connect-AzAccount -Identity
    Write-Output "Successfully connected to Azure"
} catch {
    Write-Error "Failed to connect to Azure: $_"
    exit
}

# Parse webhook data if provided (from alert)
$resourceGroup = "acdnd-c4-project"
$vmssName = "udacity-vmss"
$maxCapacity = 6

if ($WebhookData) {
    Write-Output "Alert triggered from Azure Monitor"
    $WebhookBody = ConvertFrom-Json -InputObject $WebhookData.RequestBody
    Write-Output "Alert Context: $($WebhookBody | ConvertTo-Json -Depth 10)"
}

# Get current VMSS configuration
Write-Output "Getting current VMSS configuration..."
try {
    $vmss = Get-AzVmss -ResourceGroupName $resourceGroup -VMScaleSetName $vmssName
    $currentCapacity = $vmss.Sku.Capacity
    Write-Output "Current VMSS capacity: $currentCapacity instances"
    
    if ($currentCapacity -lt $maxCapacity) {
        # Calculate new capacity (add 1 instance)
        $newCapacity = $currentCapacity + 1
        Write-Output "Scaling up VMSS from $currentCapacity to $newCapacity instances..."
        
        # Update VMSS capacity
        $vmss.Sku.Capacity = $newCapacity
        Update-AzVmss -ResourceGroupName $resourceGroup -Name $vmssName -VirtualMachineScaleSet $vmss
        
        Write-Output "Successfully scaled VMSS to $newCapacity instances"
        
        # Log the action
        Write-Output "Remediation completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    } else {
        Write-Output "VMSS is already at maximum capacity ($maxCapacity instances). No scaling performed."
    }
    
} catch {
    Write-Error "Failed to scale VMSS: $_"
    exit
}

Write-Output "Runbook execution completed successfully"
