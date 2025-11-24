# Manual Deployment Guide for VMSS

## Option 1: Use Azure Portal Serial Console (EASIEST)

1. Go to Azure Portal: https://portal.azure.com
2. Navigate to: Resource Groups → acdnd-c4-project → udacity-vmss → Instances
3. Click on instance `udacity-vmss_117874f0`
4. In the left menu, click "Serial Console"
5. Login with: udacityadmin / (your password)
6. Run these commands:

```bash
# Clone the repository
cd /home/udacityadmin
git clone https://github.com/kborkowski/nd081-c4-azure-performance-project-starter.git
cd nd081-c4-azure-performance-project-starter

# Install dependencies
pip3 install --break-system-packages -r requirements.txt

# Start Redis (should already be running from cloud-init)
sudo systemctl start redis-server
sudo systemctl status redis-server

# Start the application
cd azure-vote
nohup python3 main.py > ~/app.log 2>&1 &

# Verify it's running
sleep 3
ps aux | grep main.py
curl http://localhost:5000
```

7. Repeat for the second instance `udacity-vmss_d6167dc0`

## Option 2: SSH from Local Machine

```powershell
# SSH to first instance (port 50000)
ssh -p 50000 udacityadmin@20.184.139.83

# Then run the same commands as above

# SSH to second instance (port 50001)
ssh -p 50001 udacityadmin@20.184.139.83
```

## Option 3: Automated Script (if SSH works)

Save this as `deploy-via-ssh.ps1`:

```powershell
$loadBalancerIp = "20.184.139.83"
$username = "udacityadmin"
$ports = @(50000, 50001)

foreach ($port in $ports) {
    Write-Host "Deploying to instance on port $port..." -ForegroundColor Cyan
    
    # Create deployment commands
    $commands = @"
cd /home/udacityadmin && \
git clone https://github.com/kborkowski/nd081-c4-azure-performance-project-starter.git || (cd nd081-c4-azure-performance-project-starter && git pull) && \
cd nd081-c4-azure-performance-project-starter && \
pip3 install --break-system-packages -r requirements.txt && \
sudo systemctl start redis-server && \
pkill -f 'python3 main.py' || true && \
cd azure-vote && \
nohup python3 main.py > ~/app.log 2>&1 &
"@
    
    # Execute via SSH
    ssh -p $port "$username@$loadBalancerIp" $commands
    
    Write-Host "Deployed to instance on port $port" -ForegroundColor Green
}

Write-Host ""
Write-Host "Deployment complete! Test with: curl http://20.184.139.83" -ForegroundColor Green
```

## Verification Commands

After deployment, verify the app is running:

```bash
# Check process
ps aux | grep main.py

# Check logs
tail -f ~/app.log

# Test locally on the VM
curl http://localhost:5000

# Check what's listening on port 5000
sudo netstat -tlnp | grep 5000
```

## Troubleshooting

If you see "502 Bad Gateway":
- The app is not running on port 5000
- Check: `ps aux | grep main.py`
- Check logs: `tail -50 ~/app.log`
- Check Redis: `sudo systemctl status redis-server`

If Python packages fail to install:
- Use: `pip3 install --break-system-packages -r requirements.txt`
- Or use virtual environment: `python3 -m venv venv && source venv/bin/activate`
