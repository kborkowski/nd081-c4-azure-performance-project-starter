#!/bin/bash
echo "=== VMSS Diagnostic Script ==="
echo ""
echo "1. Checking nginx status:"
sudo systemctl status nginx | grep Active
echo ""
echo "2. Checking if anything is listening on port 5000:"
sudo netstat -tlnp | grep 5000 || echo "Nothing listening on port 5000"
echo ""
echo "3. Checking Redis:"
sudo systemctl status redis-server | grep Active
echo ""
echo "4. Checking nginx config:"
sudo cat /etc/nginx/sites-available/default | grep proxy_pass
echo ""
echo "5. Checking for Python processes:"
ps aux | grep python3 | grep -v grep
echo ""
echo "6. Checking application directory:"
ls -la ~/nd081-c4-azure-performance-project-starter/ 2>/dev/null || echo "App not cloned yet"
