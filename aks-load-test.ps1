# AKS Load Test Script
# This script generates load on the AKS application to trigger autoscaling

$externalIP = "20.245.134.120"
$duration = 300  # 5 minutes
$concurrentRequests = 50

Write-Host "Starting load test on AKS application at http://${externalIP}"
Write-Host "Duration: $duration seconds"
Write-Host "Concurrent requests: $concurrentRequests"
Write-Host "`nPress Ctrl+C to stop early.`n"

$endTime = (Get-Date).AddSeconds($duration)

# Create background jobs for concurrent requests
$jobs = 1..$concurrentRequests | ForEach-Object {
    Start-Job -ScriptBlock {
        param($url, $endTime)
        while ((Get-Date) -lt $endTime) {
            try {
                Invoke-WebRequest -Uri $url -Method POST -Body @{vote="Cats"} -UseBasicParsing -TimeoutSec 5 | Out-Null
                Start-Sleep -Milliseconds 100
            } catch {
                # Continue on errors
            }
        }
    } -ArgumentList "http://${externalIP}", $endTime
}

Write-Host "Load test running with $($jobs.Count) concurrent jobs..."
Write-Host "Monitor autoscaling with: kubectl get hpa --watch"
Write-Host "Monitor pods with: kubectl get pods --watch`n"

# Wait for all jobs to complete
$jobs | Wait-Job | Out-Null

# Clean up jobs
$jobs | Remove-Job

Write-Host "`nLoad test completed!"
Write-Host "Check the results with: kubectl get hpa"
