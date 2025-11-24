# Simple VMSS Deployment Script
# This script deploys the Azure Vote application to all VMSS instances

param(
    [string]$ResourceGroup = "acdnd-c4-project",
    [string]$VmssName = "udacity-vmss"
)

Write-Host "=== Azure Vote App - VMSS Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Get VMSS instances
Write-Host "Getting VMSS instances..." -ForegroundColor Yellow
$instances = az vmss list-instances --resource-group $ResourceGroup --name $VmssName --query "[].{id:instanceId, name:name}" -o json | ConvertFrom-Json

if ($instances.Count -eq 0) {
    Write-Host "ERROR: No VMSS instances found!" -ForegroundColor Red
    exit 1
}

Write-Host "Found $($instances.Count) instance(s):" -ForegroundColor Green
$instances | ForEach-Object { Write-Host "  - Instance $($_.id): $($_.name)" }
Write-Host ""

# Deployment script content
$deployScript = @'
#!/bin/bash
set -e

echo "=== Starting Deployment ==="

# Update and install prerequisites
echo "Installing prerequisites..."
sudo apt update -qq
sudo apt install -y python3-pip redis-server git

# Start Redis
echo "Starting Redis..."
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Clone/update repository
cd /home/udacityadmin
if [ -d "nd081-c4-azure-performance-project-starter" ]; then
    echo "Updating existing repository..."
    cd nd081-c4-azure-performance-project-starter
    git pull
else
    echo "Cloning repository..."
    git clone https://github.com/kborkowski/nd081-c4-azure-performance-project-starter.git
    cd nd081-c4-azure-performance-project-starter
fi

# Install Python dependencies
echo "Installing Python packages..."
pip3 install --break-system-packages -r requirements.txt

# Stop any existing app process
echo "Stopping existing application..."
pkill -f "python3 main.py" || true
sleep 2

# Start the application
echo "Starting application..."
cd azure-vote
nohup python3 main.py > /home/udacityadmin/app.log 2>&1 &

# Wait and verify
sleep 3
if pgrep -f "python3 main.py" > /dev/null; then
    echo "Success: Application started"
    echo "Process: $(pgrep -f 'python3 main.py')"
else
    echo "Error: Application failed to start"
    echo "Log tail:"
    tail -20 /home/udacityadmin/app.log
    exit 1
fi

echo "=== Deployment Complete ==="
'@

Write-Host "Deploying to instances..." -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$failCount = 0

foreach ($instance in $instances) {
    Write-Host "--- Instance $($instance.id) ($($instance.name)) ---" -ForegroundColor Cyan
    
    try {
        Write-Host "  Executing deployment script..." -ForegroundColor Gray
        
        # Encode script for inline execution
        $scriptB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($deployScript))
        
        # Use run-command (if available) or extension
        $result = az vmss run-command invoke `
            --resource-group $ResourceGroup `
            --name $VmssName `
            --instance-id $instance.id `
            --command-id RunShellScript `
            --scripts $deployScript `
            2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Success: Deployment completed on instance $($instance.id)" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "  Warning: run-command not available, trying extension method..." -ForegroundColor Yellow
            
            # Try extension method
            az vmss extension set `
                --resource-group $ResourceGroup `
                --vmss-name $VmssName `
                --name CustomScript `
                --publisher Microsoft.Azure.Extensions `
                --version 2.1 `
                --protected-settings "{`"script`": `"$scriptB64`"}" `
                --instance-ids $instance.id
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Success: Extension deployment completed on instance $($instance.id)" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "  Error: Failed to deploy to instance $($instance.id)" -ForegroundColor Red
                $failCount++
            }
        }
        
    } catch {
        Write-Host "  Error deploying to instance $($instance.id): $_" -ForegroundColor Red
        $failCount++
    }
    
    Write-Host ""
}

Write-Host "=== Deployment Summary ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Results: $successCount succeeded, $failCount failed" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Yellow" })
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Wait 30-60 seconds for applications to start"
Write-Host "2. Test the application with: curl http://20.184.139.83"
Write-Host "3. Check logs in Azure Portal Serial Console"
Write-Host "   Command: tail -f /home/udacityadmin/app.log"
Write-Host ""
$loadBalancerUrl = "http://20.184.139.83"
Write-Host "Load Balancer: $loadBalancerUrl" -ForegroundColor Green
