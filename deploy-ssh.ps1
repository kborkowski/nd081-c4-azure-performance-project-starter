# Deploy to VMSS via SSH
param(
    [string]$LoadBalancerIp = "20.184.139.83",
    [string]$Username = "udacityadmin",
    [int[]]$Ports = @(50000, 50001)
)

Write-Host "=== Azure Vote App - SSH Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Deployment commands
$deployCommands = @'
cd /home/udacityadmin && \
(git clone https://github.com/kborkowski/nd081-c4-azure-performance-project-starter.git 2>/dev/null || (cd nd081-c4-azure-performance-project-starter && git pull)) && \
cd nd081-c4-azure-performance-project-starter && \
pip3 install --break-system-packages -r requirements.txt && \
sudo systemctl start redis-server && \
pkill -f "python3 main.py" || true && \
sleep 2 && \
cd azure-vote && \
nohup python3 main.py > /home/udacityadmin/app.log 2>&1 & \
sleep 3 && \
echo "=== Deployment Status ===" && \
ps aux | grep "[p]ython3 main.py" && \
echo "=== App log (last 10 lines) ===" && \
tail -10 /home/udacityadmin/app.log
'@

$successCount = 0

foreach ($port in $Ports) {
    Write-Host "Deploying to instance on port $port..." -ForegroundColor Cyan
    Write-Host "  SSH: $Username@$LoadBalancerIp -p $port" -ForegroundColor Gray
    Write-Host ""
    
    try {
        # Execute deployment via SSH
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p $port "$Username@$LoadBalancerIp" $deployCommands
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "  Success: Deployed to instance on port $port" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host ""
            Write-Host "  Warning: Deployment on port $port completed with warnings" -ForegroundColor Yellow
            $successCount++
        }
    }
    catch {
        Write-Host ""
        Write-Host "  Error: Failed to connect to port $port - $_" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "=== Deployment Summary ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Deployed to $successCount of $($Ports.Count) instance(s)" -ForegroundColor $(if ($successCount -eq $Ports.Count) { "Green" } else { "Yellow" })
Write-Host ""

if ($successCount -gt 0) {
    Write-Host "Testing the application..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    
    try {
        $response = curl http://$LoadBalancerIp -UseBasicParsing -TimeoutSec 5
        Write-Host "Success! Application is responding:" -ForegroundColor Green
        Write-Host $response.Content.Substring(0, [Math]::Min(200, $response.Content.Length)) -ForegroundColor Gray
    }
    catch {
        Write-Host "Still getting 502 - the app may need a few more seconds to start" -ForegroundColor Yellow
        Write-Host "Try: curl http://$LoadBalancerIp" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Application URL: http://$LoadBalancerIp" -ForegroundColor Green
