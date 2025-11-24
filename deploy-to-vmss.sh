#!/bin/bash
# Manual Deployment Script for VMSS

echo "=== Azure Vote App Deployment Script ==="
echo ""

# Update system
sudo apt update

# Install Python 3.11 if not present
python3 --version

# Install Redis if not running
sudo systemctl status redis-server || sudo apt install -y redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Navigate to home directory
cd ~

# Clone or pull latest code
if [ -d "nd081-c4-azure-performance-project-starter" ]; then
    cd nd081-c4-azure-performance-project-starter
    git pull
else
    git clone https://github.com/kborkowski/nd081-c4-azure-performance-project-starter.git
    cd nd081-c4-azure-performance-project-starter
fi

# Install Python dependencies
pip3 install --upgrade pip
pip3 install -r requirements.txt

# Navigate to app directory
cd azure-vote

# Stop any running instance
pkill -f "python3 main.py" || true

# Start the application in background
nohup python3 main.py > app.log 2>&1 &

echo ""
echo "Application deployed successfully!"
echo "Check status: ps aux | grep main.py"
echo "View logs: tail -f ~/nd081-c4-azure-performance-project-starter/azure-vote/app.log"
