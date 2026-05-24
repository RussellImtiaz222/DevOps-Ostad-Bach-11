# BMI Health Tracker — Complete Deployment Guide

This guide provides step-by-step instructions to deploy the **BMI Health Tracker** application on a single Ubuntu 22.04 LTS EC2 instance.

## Prerequisites

### AWS Account Requirements
- EC2 launch permissions
- EC2 key pair (.pem file) on your local machine

### EC2 Instance Requirements
- **AMI:** Ubuntu Server 22.04 LTS
- **Instance Type:** t2.micro (or larger)
- **Storage:** 20 GB gp3
- **Security Group Rules:**
  | Type | Protocol | Port | Source |
  |------|----------|------|--------|
  | SSH | TCP | 22 | Your IP |
  | HTTP | TCP | 80 | 0.0.0.0/0 |
  | HTTPS | TCP | 443 | 0.0.0.0/0 |

## Part A — AWS Console Setup

### A.1 Launch EC2 Instance
1. Go to EC2 Dashboard → Instances → Launch Instances
2. **Image:** Ubuntu Server 22.04 LTS (ami-xxxxxxxxx)
3. **Instance Type:** t2.micro
4. **Storage:** 20 GB gp3
5. **Security Group:** Create/Select with rules from above
6. **Key Pair:** Select your .pem file
7. Launch and note the Public IP

### A.2 Configure Security Group
Apply the security group rules shown above to allow:
- SSH access from your IP
- HTTP/HTTPS access from everywhere

## Part B — Server Bootstrap

Connect to your EC2 instance:
```bash
ssh -i your-key.pem ubuntu@YOUR_PUBLIC_IP
```

Update system packages:
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget unzip build-essential
```

Clone the repository:
```bash
cd ~
git clone https://github.com/sarowar-alam/single-server-3tier-webapp.git
cd single-server-3tier-webapp
```

## Step 1 — Database Layer

### 1.1 Install PostgreSQL
```bash
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 1.2 Create Database and User
```bash
sudo -u postgres psql -c "CREATE USER bmi_user WITH PASSWORD 'your_password';"
sudo -u postgres psql -c "CREATE DATABASE bmidb;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bmidb TO bmi_user;"
sudo -u postgres psql -d bmidb -c "GRANT ALL ON SCHEMA public TO bmi_user;"
sudo -u postgres psql -d bmidb -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO bmi_user;"
```

### 1.3 Configure Authentication
```bash
PG_HBA=$(sudo -u postgres psql -t -P format=unaligned -c 'SHOW hba_file')
sudo cp "$PG_HBA" "${PG_HBA}.backup"
sudo sed -i "/^# IPv4 local connections:/a host    bmidb    bmi_user    127.0.0.1/32    md5" "$PG_HBA"
sudo systemctl reload postgresql
```

### 1.4 Test Connection
```bash
PGPASSWORD=your_password psql -U bmi_user -d bmidb -h localhost -c "SELECT 1;"
```

Expected output: `?column?` = 1

## Step 2 — Backend Layer

### 2.1 Install Node.js (System-wide) and PM2
```bash
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g pm2
node -v && npm -v && pm2 -v
```

Expected versions:
- Node.js: v20.x.x
- npm: 10.x.x
- PM2: 5.x.x

### 2.2 Create Directory and Environment
```bash
sudo mkdir -p /opt/bmi-app/backend
sudo chown -R $USER:$USER /opt/bmi-app

cat > /opt/bmi-app/backend/.env << EOF
DATABASE_URL=postgresql://bmi_user:your_password@localhost:5432/bmidb
DB_USER=bmi_user
DB_PASSWORD=your_password
DB_NAME=bmidb
DB_HOST=localhost
DB_PORT=5432
PORT=3000
NODE_ENV=production
CORS_ORIGIN=*
EOF

chmod 600 /opt/bmi-app/backend/.env
```

### 2.3 Deploy and Run Migrations
```bash
rsync -a --exclude 'node_modules' --exclude '.env' --exclude 'logs' \
  ~/single-server-3tier-webapp/backend/ /opt/bmi-app/backend/

cd /opt/bmi-app/backend
npm install --production

PGPASSWORD=your_password psql -U bmi_user -d bmidb -h localhost \
  -f migrations/001_create_measurements.sql

PGPASSWORD=your_password psql -U bmi_user -d bmidb -h localhost \
  -f migrations/002_add_measurement_date.sql
```

### 2.4 Start Backend with PM2
```bash
pm2 start src/server.js --name bmi-backend --env production
pm2 save
sudo env PATH=$PATH:$(which node) $(which pm2) startup systemd -u $USER --hp $HOME
pm2 save
```

Verify:
```bash
pm2 status
pm2 logs bmi-backend
```

## Step 3 — Frontend Layer

### 3.1 Install Nginx
```bash
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 3.2 Build and Deploy React App
```bash
cd ~/single-server-3tier-webapp/frontend
npm install
npm run build

sudo mkdir -p /var/www/bmi-health-tracker
sudo rm -rf /var/www/bmi-health-tracker/*
sudo cp -r dist/* /var/www/bmi-health-tracker/
sudo chown -R www-data:www-data /var/www/bmi-health-tracker
sudo chmod -R 755 /var/www/bmi-health-tracker
```

### 3.3 Configure Nginx

**Get EC2 IP:**
```bash
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
EC2_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
echo $EC2_IP
```

**Create Nginx virtual host config:**
```bash
sudo tee /etc/nginx/sites-available/bmi-health-tracker > /dev/null << 'EOF'
server {
    listen 80;
    server_name YOUR_SERVER_NAME;

    root /var/www/bmi-health-tracker;
    index index.html;

    # React SPA — serve index.html for all non-file routes
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Proxy API requests to Node.js backend
    location /api/ {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
}
EOF

# Enable site and reload
sudo ln -sf /etc/nginx/sites-available/bmi-health-tracker /etc/nginx/sites-enabled/bmi-health-tracker
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx
```

## Step 4 — SSL Layer (Optional)

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com --non-interactive --agree-tos --email your@email.com --redirect
sudo certbot renew --dry-run
```

## Step 5 — Final Health Checks

### Backend Health
```bash
curl -f http://localhost:3000/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2026-04-19T...",
  "uptime": 123.45,
  "environment": "production"
}
```

### Frontend Health (Nginx)
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost/
```

Expected: `200`

### PM2 Status
```bash
pm2 status
```

Expected: `bmi-backend` showing as `online`

### Database Health
```bash
PGPASSWORD=your_password psql -U bmi_user -d bmidb -h localhost -c "SELECT COUNT(*) FROM measurements;"
```

## Step 6 — Day-2 Commands

### Logs
```bash
pm2 logs bmi-backend
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Restart Services
```bash
# Restart backend
pm2 restart bmi-backend

# Restart frontend
sudo systemctl restart nginx
```

### Database Access
```bash
PGPASSWORD=your_password psql -U bmi_user -d bmidb -h localhost
```

## Step 7 — Troubleshooting

### Issue: 502 Bad Gateway
**Cause:** Backend is down

**Solution:**
```bash
pm2 status  # Check if bmi-backend is running
pm2 restart bmi-backend
pm2 logs bmi-backend  # Check logs for errors
```

### Issue: 404/500 on Frontend
**Cause:** React build or Nginx try_files issue

**Solution:**
```bash
# Check if dist exists
ls -la /var/www/bmi-health-tracker/

# Verify Nginx config
sudo nginx -t

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log
```

### Issue: Database Connection Error
**Cause:** PostgreSQL not running or incorrect credentials

**Solution:**
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Test connection
PGPASSWORD=your_password psql -U bmi_user -d bmidb -h localhost -c "SELECT 1;"
```

### Issue: Port Already in Use
**Cause:** Another process using port 3000 or 80

**Solution:**
```bash
# Check port usage
sudo lsof -i :3000
sudo lsof -i :80

# Kill process if needed
kill -9 <PID>
```

## 📌 Deployment Summary

| Layer | Technology | Service | Port | Status Check |
|-------|-----------|---------|------|------|
| Frontend | React + Vite | Nginx | 80 | `curl http://localhost/` |
| Backend | Node.js + Express | PM2 | 3000 | `curl http://localhost:3000/api/health` |
| Database | PostgreSQL | systemd | 5432 | `psql -c "SELECT 1;"` |

---

**Version:** 5.0  
**Last Updated:** April 19, 2026  
**Notes:** Single-server deployment with all layers on one EC2 instance
