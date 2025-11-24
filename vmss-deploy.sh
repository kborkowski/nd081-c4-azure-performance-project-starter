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
