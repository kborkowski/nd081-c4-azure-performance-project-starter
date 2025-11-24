# VMSS Autoscale Load Test Script
# This script generates HTTP load to trigger CPU-based autoscaling

param(
    [int]$DurationMinutes = 10,
    [int]$ConcurrentJobs = 200,
    [string]$TargetUrl = "http://20.184.139.83"
)

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "VMSS Autoscale Load Test" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Target URL: $TargetUrl" -ForegroundColor Yellow
Write-Host "Duration: $DurationMinutes minutes" -ForegroundColor Yellow
Write-Host "Concurrent Jobs: $ConcurrentJobs" -ForegroundColor Yellow
Write-Host ""
Write-Host "This will generate high load to trigger autoscaling..." -ForegroundColor Green
Write-Host ""

# Confirm before starting
$confirm = Read-Host "Ready to start load test? (Y/N)"
if ($confirm -ne 'Y' -and $confirm -ne 'y') {
    Write-Host "Load test cancelled." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "Starting load test..." -ForegroundColor Green
Write-Host "Monitor in Azure Portal:" -ForegroundColor Cyan
Write-Host "  1. VM Scale Set -> Metrics -> Percentage CPU" -ForegroundColor White
Write-Host "  2. VM Scale Set -> Instances (watch for 'Creating' status)" -ForegroundColor White
Write-Host "  3. VM Scale Set -> Activity log (for scaling events)" -ForegroundColor White
Write-Host ""

$startTime = Get-Date
$endTime = $startTime.AddMinutes($DurationMinutes)

# Create jobs that continuously hit the endpoint
$jobs = @()
for ($i = 1; $i -le $ConcurrentJobs; $i++) {
    $jobs += Start-Job -ScriptBlock {
        param($url, $endTime)
        
        $requestCount = 0
        while ((Get-Date) -lt $endTime) {
            try {
                # Vote for Cats (generates more work on server)
                Invoke-WebRequest -Uri $url -Method POST -Body @{vote="Cats"} -UseBasicParsing -TimeoutSec 5 | Out-Null
                $requestCount++
                
                # Small delay to avoid overwhelming
                Start-Sleep -Milliseconds 100
            } catch {
                # Continue on errors
            }
        }
        
        return $requestCount
    } -ArgumentList $TargetUrl, $endTime
    
    if ($i % 20 -eq 0) {
        Write-Host "  Started $i/$ConcurrentJobs jobs..." -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "All $ConcurrentJobs jobs started!" -ForegroundColor Green
Write-Host ""
Write-Host "⏱️  Load test running for $DurationMinutes minutes..." -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANT: Go to Azure Portal NOW to monitor:" -ForegroundColor Magenta
Write-Host "  - Watch CPU climb above 70%" -ForegroundColor White
Write-Host "  - Wait 5-7 minutes for autoscale to trigger" -ForegroundColor White
Write-Host "  - Be ready to capture 'Creating' status quickly!" -ForegroundColor White
Write-Host ""

# Monitor progress
$progressInterval = 30 # seconds
$iterations = ($DurationMinutes * 60) / $progressInterval

for ($i = 1; $i -le $iterations; $i++) {
    Start-Sleep -Seconds $progressInterval
    
    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)
    $remaining = [math]::Round(($endTime - (Get-Date)).TotalMinutes, 1)
    
    Write-Host "[$elapsed min elapsed, $remaining min remaining] Load test in progress..." -ForegroundColor Cyan
    
    # Check job status
    $runningJobs = ($jobs | Where-Object { $_.State -eq 'Running' }).Count
    if ($runningJobs -lt ($ConcurrentJobs * 0.5)) {
        Write-Host "  Warning: Only $runningJobs/$ConcurrentJobs jobs still running" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Load test duration complete. Waiting for jobs to finish..." -ForegroundColor Green

# Wait for all jobs to complete
$jobs | Wait-Job -Timeout 60 | Out-Null

# Collect results
$totalRequests = 0
foreach ($job in $jobs) {
    $result = Receive-Job -Job $job -ErrorAction SilentlyContinue
    if ($result) {
        $totalRequests += $result
    }
}

# Clean up jobs
$jobs | Remove-Job -Force

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Load Test Complete!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Requests Sent: $totalRequests" -ForegroundColor Yellow
Write-Host "Duration: $DurationMinutes minutes" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Check Azure Portal -> Metrics for CPU spike" -ForegroundColor White
Write-Host "  2. Check Activity Log for scaling events" -ForegroundColor White
Write-Host "  3. Check Instances for new instances (or 'Creating' status if caught it)" -ForegroundColor White
Write-Host "  4. Take screenshots with matching timestamps" -ForegroundColor White
Write-Host ""
Write-Host "Note: If autoscaling hasn't triggered yet, wait a few more minutes." -ForegroundColor Yellow
Write-Host "Azure evaluates CPU average over 5 minutes before scaling." -ForegroundColor Yellow
Write-Host ""
