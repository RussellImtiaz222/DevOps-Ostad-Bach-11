#!/bin/bash
################################################################################
# Testing and Validation Script
# Tests HTTPS, HTTP redirect, and reverse proxy functionality
################################################################################

echo "=========================================="
echo "Nginx Configuration Testing"
echo "=========================================="

echo ""
echo "[*] Testing Nginx configuration syntax..."
sudo nginx -t

echo ""
echo "=========================================="
echo "[*] Checking Nginx service status..."
echo "=========================================="
sudo systemctl status nginx --no-pager

echo ""
echo "=========================================="
echo "[*] Testing HTTP → HTTPS Redirect"
echo "=========================================="
echo "Testing: curl -I http://localhost"
curl -I http://localhost 2>/dev/null | head -5

echo ""
echo "=========================================="
echo "[*] Testing HTTPS Connection (with self-signed cert)"
echo "=========================================="
echo "Testing: curl -k -I https://localhost"
curl -k -I https://localhost 2>/dev/null | head -10

echo ""
echo "=========================================="
echo "[*] Testing Static Website Content"
echo "=========================================="
echo "Testing: curl -k https://localhost"
curl -k https://localhost 2>/dev/null | grep -o "<title>.*</title>"

echo ""
echo "=========================================="
echo "[*] Testing Health Check Endpoint"
echo "=========================================="
echo "Testing: curl -k https://localhost/health"
curl -k https://localhost/health 2>/dev/null

echo ""
echo "=========================================="
echo "[*] Testing Reverse Proxy (requires backend on port 3000)"
echo "=========================================="
if nc -z 127.0.0.1 3000 2>/dev/null; then
    echo "[✓] Backend service detected on port 3000"
    echo "Testing: curl -k https://localhost/api/"
    curl -k https://localhost/api/ 2>/dev/null
else
    echo "[!] Backend service not running on port 3000"
    echo "    To test reverse proxy, run backend with: python3 backend/app.py"
fi

echo ""
echo "=========================================="
echo "[*] Nginx Configuration File"
echo "=========================================="
echo "Location: /etc/nginx/sites-available/secure-app.conf"
echo "Symlink: /etc/nginx/sites-enabled/secure-app.conf"

echo ""
echo "=========================================="
echo "[*] SSL Certificate Information"
echo "=========================================="
echo "Certificate: /etc/nginx/ssl/secure-app.crt"
echo "Private Key: /etc/nginx/ssl/secure-app.key"
echo ""
sudo openssl x509 -in /etc/nginx/ssl/secure-app.crt -text -noout | grep -A 1 "Subject:\|Issuer:\|Not Before\|Not After\|Public-Key"

echo ""
echo "=========================================="
echo "Testing Complete!"
echo "=========================================="
