# Quick Start Guide

## For WSL2 Windows Users (Recommended)

### Prerequisites
- Windows 10/11 with WSL2 installed
- Ubuntu 20.04 or 22.04 in WSL2

### Step 1: Open WSL2 Terminal
```powershell
wsl
```

### Step 2: Navigate to Project
```bash
cd /mnt/c/Users/iruss/DevOps-Ostad-Bach-11/nginx-secure-app
```

### Step 3: Run Setup
```bash
sudo bash scripts/setup.sh
```

### Step 4: Test
```bash
sudo bash scripts/test.sh
```

---

## For Docker Users (Easiest)

### Prerequisites
- Docker and Docker Compose installed

### One-Command Setup
```bash
docker-compose up -d
```

### View Logs
```bash
docker-compose logs -f
```

### Test (Optional - happens automatically)
```bash
docker-compose exec nginx-secure-app curl -k https://localhost
```

---

## For Linux Users (Native Installation)

### Prerequisites
- Ubuntu/Debian system with sudo access
- 500MB disk space

### One-Command Setup
```bash
sudo bash scripts/setup.sh
```

---

## Testing Your Setup

### Quick Test
```bash
# Test HTTPS
curl -k https://localhost

# Test API
curl -k https://localhost/api/
```

### Full Test Suite
```bash
sudo bash scripts/test.sh
```

---

## Accessing the Server

### In Browser
- HTTPS: https://localhost
  - **Note:** You'll see a certificate warning (expected for self-signed cert)
  - Click "Advanced" → "Proceed to localhost (unsafe)"

### Via Command Line
```bash
# Get HTML
curl -k https://localhost

# Get with headers
curl -k -i https://localhost

# Follow redirects
curl -k -L http://localhost
```

---

## Backend Service (Optional)

### Start Backend
```bash
python3 backend/app.py
```

### Test Backend
```bash
# In another terminal:
curl -k https://localhost/api/
```

### Expected Response
```json
{
  "status": "Backend service running",
  "message": "Connected via Nginx reverse proxy",
  "headers": { ... }
}
```

---

## Troubleshooting Quick Fixes

### Port Already in Use
```bash
# Find what's using port 80
sudo lsof -i :80

# Stop the process
sudo kill -9 <PID>
```

### Permission Issues
```bash
# Fix SSL permissions
sudo chmod 600 /etc/nginx/ssl/secure-app.key
sudo chmod 644 /etc/nginx/ssl/secure-app.crt
```

### Nginx Won't Start
```bash
# Check config
sudo nginx -t

# View errors
sudo journalctl -u nginx -e
```

---

## File Locations (Linux/WSL2)

```
/var/www/secure-app/          - Static files
/etc/nginx/ssl/               - SSL certificates
/etc/nginx/sites-available/   - Nginx configs
/var/log/nginx/               - Logs
```

---

## Important Commands

```bash
# Reload config without restart
sudo systemctl reload nginx

# Restart completely
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx

# View logs in real-time
sudo journalctl -u nginx -f

# Test config
sudo nginx -t
```

---

## Success Indicators ✓

You'll know it's working when you see:

- ✅ No errors from `sudo nginx -t`
- ✅ `systemctl status nginx` shows "active (running)"
- ✅ `curl -k https://localhost` returns HTML
- ✅ HTTP requests redirect to HTTPS (301 status)
- ✅ Backend responds at `curl -k https://localhost/api/` (if running)

---

## Next Steps

1. Run the setup script
2. Run the test script
3. Capture screenshots for assignment
4. Commit to GitHub
5. Submit GitHub link with README

For detailed instructions, see **README.md**
