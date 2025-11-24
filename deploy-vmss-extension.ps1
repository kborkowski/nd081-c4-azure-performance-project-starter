# Deploy to VMSS using file upload
param(
    [string]$ResourceGroup = "acdnd-c4-project",
    [string]$VmssName = "udacity-vmss",
    [string]$ScriptFile = "vmss-deploy.sh"
)

Write-Host "=== Azure Vote VMSS Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Check if script file exists
if (-not (Test-Path $ScriptFile)) {
    Write-Host "ERROR: Script file '$ScriptFile' not found!" -ForegroundColor Red
    exit 1
}

# Get VMSS instances
Write-Host "Getting VMSS instances..." -ForegroundColor Yellow
$instances = az vmss list-instances --resource-group $ResourceGroup --name $VmssName --query "[].instanceId" -o json | ConvertFrom-Json

if ($instances.Count -eq 0) {
    Write-Host "ERROR: No VMSS instances found!" -ForegroundColor Red
    exit 1
}

Write-Host "Found $($instances.Count) instance(s)" -ForegroundColor Green
Write-Host ""

$successCount = 0

foreach ($instanceId in $instances) {
    Write-Host "Deploying to instance $instanceId..." -ForegroundColor Cyan
    
    try {
        # Deploy using Custom Script Extension with file
        az vmss extension set `
            --resource-group $ResourceGroup `
            --vmss-name $VmssName `
            --name CustomScript `
            --publisher Microsoft.Azure.Extensions `
            --version 2.1 `
            --settings "{`"fileUris`": [`"https://raw.githubusercontent.com/kborkowski/nd081-c4-azure-performance-project-starter/master/vmss-deploy.sh`"], `"commandToExecute`": `"bash vmss-deploy.sh`"}" `
            --instance-ids $instanceId `
            --no-wait
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Success: Extension configured for instance $instanceId" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "  Error: Failed for instance $instanceId" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  Error: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Deployment Initiated ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Deployment started on $successCount instance(s)" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: Extensions run asynchronously. Please wait 2-3 minutes." -ForegroundColor Yellow
Write-Host ""
Write-Host "Then test with: curl http://20.184.139.83" -ForegroundColor Yellow
