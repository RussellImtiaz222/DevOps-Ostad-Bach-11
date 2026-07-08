#!/bin/bash
################################################################################
# Complete Setup Script for Nginx Secure App
# Installs Nginx, OpenSSL, generates SSL, and configures everything
################################################################################

set -e

echo "=========================================="
echo "Nginx Secure App - Complete Setup"
echo "=========================================="

# Check if running as root (WSL2 may not enforce this strictly)
if [[ $EUID -ne 0 ]]; then
   echo "[!] This script must be run as root (use: sudo ./setup.sh)"
   exit 1
fi

# Part 1: Install Dependencies
echo ""
echo "[1/5] Installing dependencies..."
apt-get update
apt-get install -y nginx openssl curl

# Part 2: Create application directory
echo ""
echo "[2/5] Creating application directory..."
mkdir -p /var/www/secure-app
chmod 755 /var/www/secure-app

# Part 3: Copy HTML file
echo ""
echo "[3/5] Setting up static website..."
cp html/index.html /var/www/secure-app/
chmod 644 /var/www/secure-app/index.html

# Part 4: Generate SSL Certificate
echo ""
echo "[4/5] Generating SSL certificate..."
mkdir -p /etc/nginx/ssl

# Generate private key (2048-bit)
openssl genrsa -out /etc/nginx/ssl/secure-app.key 2048

# Generate self-signed certificate (365 days)
openssl req -new -x509 \
    -key /etc/nginx/ssl/secure-app.key \
    -out /etc/nginx/ssl/secure-app.crt \
    -days 365 \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Set proper permissions
chmod 600 /etc/nginx/ssl/secure-app.key
chmod 644 /etc/nginx/ssl/secure-app.crt

echo "[✓] SSL Certificate created successfully"
echo "    Certificate: /etc/nginx/ssl/secure-app.crt"
echo "    Private Key: /etc/nginx/ssl/secure-app.key"

# Part 5: Install Nginx Configuration
echo ""
echo "[5/5] Configuring Nginx..."

# Backup original nginx config if it exists
if [ -f /etc/nginx/nginx.conf ]; then
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
    echo "[✓] Backed up original nginx.conf"
fi

# Copy secure app configuration to nginx sites-available
cp nginx-config/secure-app.conf /etc/nginx/sites-available/secure-app.conf
chmod 644 /etc/nginx/sites-available/secure-app.conf

# Enable the configuration (create symlink in sites-enabled)
if [ ! -L /etc/nginx/sites-enabled/secure-app.conf ]; then
    ln -s /etc/nginx/sites-available/secure-app.conf /etc/nginx/sites-enabled/secure-app.conf
    echo "[✓] Enabled secure-app configuration"
fi

# Disable default configuration if it exists
if [ -L /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
    echo "[✓] Disabled default configuration"
fi

# Test Nginx configuration
echo ""
echo "[*] Testing Nginx configuration..."
nginx -t

# Enable and start Nginx
echo ""
echo "[*] Starting Nginx service..."
systemctl enable nginx
systemctl start nginx

# Verify Nginx is running
if systemctl is-active --quiet nginx; then
    echo "[✓] Nginx is running"
else
    echo "[!] Nginx failed to start. Check logs with: journalctl -u nginx -e"
    exit 1
fi

# Display summary
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "🔐 HTTPS Configuration:"
echo "   URL: https://localhost"
echo "   Certificate: /etc/nginx/ssl/secure-app.crt"
echo ""
echo "🔄 HTTP Redirect:"
echo "   HTTP (port 80) → HTTPS (port 443)"
echo ""
echo "🔌 Reverse Proxy:"
echo "   /api/ → http://127.0.0.1:3000/"
echo ""
echo "📁 Directories:"
echo "   Static Files: /var/www/secure-app"
echo "   Config: /etc/nginx/sites-available/secure-app.conf"
echo ""
echo "📝 Useful Commands:"
echo "   Check status: sudo systemctl status nginx"
echo "   View logs: sudo journalctl -u nginx -f"
echo "   Reload config: sudo nginx -s reload"
echo "   Restart: sudo systemctl restart nginx"
echo ""
echo "=========================================="
