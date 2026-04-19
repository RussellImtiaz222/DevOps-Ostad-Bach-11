#!/bin/bash
################################################################################
# SSL Certificate Generation Script for Nginx
# This script generates a self-signed SSL certificate valid for 365 days
################################################################################

set -e

echo "=========================================="
echo "SSL Certificate Generation Script"
echo "=========================================="

# Create SSL directory if it doesn't exist
echo "[*] Creating SSL directory..."
sudo mkdir -p /etc/nginx/ssl
cd /etc/nginx/ssl

# Check if certificate already exists
if [ -f secure-app.crt ] && [ -f secure-app.key ]; then
    echo "[!] Certificate already exists!"
    read -p "Do you want to regenerate it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "[✓] Skipping certificate generation"
        exit 0
    fi
    echo "[*] Removing old certificate..."
    sudo rm -f secure-app.crt secure-app.key
fi

# Generate private key and certificate
echo "[*] Generating private key (2048-bit RSA)..."
sudo openssl genrsa -out secure-app.key 2048

echo "[*] Generating self-signed certificate (365 days)..."
sudo openssl req -new -x509 -key secure-app.key -out secure-app.crt -days 365 \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

# Set proper permissions
echo "[*] Setting permissions..."
sudo chmod 600 secure-app.key
sudo chmod 644 secure-app.crt

# Verify certificate
echo ""
echo "=========================================="
echo "Certificate Information"
echo "=========================================="
echo "[*] Certificate Details:"
sudo openssl x509 -in secure-app.crt -text -noout | grep -A 2 "Subject:\|Issuer:\|Valid\|Public-Key"

echo ""
echo "=========================================="
echo "[✓] SSL Certificate Generation Complete!"
echo "=========================================="
echo "Certificate: /etc/nginx/ssl/secure-app.crt"
echo "Private Key: /etc/nginx/ssl/secure-app.key"
echo ""
