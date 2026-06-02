# Complete Deployment Runbook: 3-Tier Application on AWS EC2 with Monitoring and CI/CD

**Last Updated**: June 1, 2026  
**Status**: Production Ready  
**Audience**: DevOps Engineers, System Administrators

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Phase 1: Infrastructure Setup](#phase-1-infrastructure-setup)
4. [Phase 2: Application Deployment](#phase-2-application-deployment)
5. [Phase 3: Database Setup](#phase-3-database-setup)
6. [Phase 4: Monitoring Stack Deployment](#phase-4-monitoring-stack-deployment)
7. [Phase 5: GitHub Actions CI/CD Configuration](#phase-5-github-actions-cicd-configuration)
8. [Phase 6: Email Alert Configuration](#phase-6-email-alert-configuration)
9. [Phase 7: Verification and Testing](#phase-7-verification-and-testing)
10. [Troubleshooting](#troubleshooting)
11. [Rollback Procedures](#rollback-procedures)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet (0.0.0.0/0)                     │
└────────────────────────┬────────────────────────────────────────┘
                         │ HTTPS
                         ▼
        ┌────────────────────────────────┐
        │   Application Load Balancer    │
        │   (Public Subnets: Multi-AZ)   │
        └────────────────┬───────────────┘
                         │
        ┌────────────────┼───────────────┐
        ▼                ▼               ▼
    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │ App Srv  │   │ App Srv  │   │Bastion   │
    │ (t2.micro) │   │ (t2.micro) │   │(t2.micro)│
    │Private   │   │Private   │   │Public    │
    │Subnet-A  │   │Subnet-B  │   │Subnet    │
    └────┬─────┘   └────┬─────┘   └──────────┘
         │              │
         └──────┬───────┘
                │ Port 5432
                ▼
        ┌────────────────────┐
        │ RDS PostgreSQL DB  │
        │ (Multi-AZ: Private)│
        └────────────────────┘

Monitoring Stack:
┌─────────────────────────────────────┐
│ Prometheus (9090)                   │
│ ├─ Grafana (3000)                   │
│ ├─ AlertManager (9093)              │
│ ├─ Node Exporter (9100)             │
│ └─ CloudWatch Exporter (9106)       │
└─────────────────────────────────────┘
```

---

## Prerequisites

### AWS Account
- AWS account with administrative privileges
- EC2, RDS, VPC, IAM permissions
- AWS CLI v2 installed and configured
- Cost estimate: ~$50-100/month for dev environment

### Local Development Environment
- Terraform 1.5.0+
- Docker and Docker Compose
- Git and GitHub account
- Python 3.9+ (for backend)
- Node.js 18+ (for frontend)
- SSH client
- curl, wget, jq utilities

### Required Credentials
- AWS Access Key ID and Secret
- GitHub Personal Access Token (PAT)
- SMTP credentials (Gmail, SendGrid, or similar)
- SSH key pair for EC2 access

### DNS and Domain
- Domain name (optional, but recommended for email alerts)
- SSL/TLS certificate (AWS Certificate Manager)

---

## Phase 1: Infrastructure Setup

### Step 1.1: Clone Repository and Configure AWS

```bash
# Clone the repository
git clone https://github.com/your-username/your-repo.git
cd "Assignment on module 6 (Terraform)"

# Configure AWS credentials
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter default region: us-east-1
# Enter default output format: json

# Verify AWS access
aws sts get-caller-identity
```

### Step 1.2: Create Terraform Variables

```bash
# Navigate to Terraform directory
cd terraform/environments/dev

# Copy and customize terraform.tfvars
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
nano terraform.tfvars

# Required variables:
# - project_name: "3tier-app"
# - environment: "dev"
# - aws_region: "us-east-1"
# - instance_type: "t2.micro"
# - database_engine_version: "14.9"
```

### Step 1.3: Deploy Infrastructure with Terraform

```bash
# Initialize Terraform (first time only)
terraform init

# Generate and review the plan
terraform plan -out=tfplan

# Apply infrastructure changes
terraform apply tfplan

# Export outputs
terraform output -json > outputs.json

# Save important outputs
ALB_DNS=$(jq -r '.alb_dns_name.value' outputs.json)
BASTION_IP=$(jq -r '.bastion_public_ip.value' outputs.json)
RDS_ENDPOINT=$(jq -r '.rds_endpoint.value' outputs.json)

echo "ALB DNS: $ALB_DNS"
echo "Bastion IP: $BASTION_IP"
echo "RDS Endpoint: $RDS_ENDPOINT"
```

### Step 1.4: Create SSH Key Pair

```bash
# If not using existing key pair
aws ec2 create-key-pair --key-name 3tier-app-key \
  --query 'KeyMaterial' --output text > ~/.ssh/3tier-app-key.pem

chmod 600 ~/.ssh/3tier-app-key.pem

# Test SSH access to bastion
ssh -i ~/.ssh/3tier-app-key.pem ubuntu@$BASTION_IP
# Type 'exit' to close connection
```

---

## Phase 2: Application Deployment

### Step 2.1: Connect to Application Server via Bastion

```bash
# Get the private IP of one application server (from Terraform outputs)
APP_SERVER_IP=$(jq -r '.app_server_private_ips.value[0]' outputs.json)

# SSH into application server via bastion (ProxyJump)
ssh -i ~/.ssh/3tier-app-key.pem -J ubuntu@$BASTION_IP ubuntu@$APP_SERVER_IP
```

### Step 2.2: Install Application Dependencies

```bash
# On the application server
sudo apt update
sudo apt upgrade -y
sudo apt install -y git curl wget python3 python3-pip nodejs npm

# Install Docker
curl -fsSL https://get.docker.com | sudo bash
sudo usermod -aG docker ubuntu

# Clone application repository
cd /opt
sudo git clone https://github.com/your-username/your-repo.git
sudo chown -R ubuntu:ubuntu your-repo
```

### Step 2.3: Build and Deploy Application

```bash
# Navigate to application directory
cd /opt/your-repo/application/backend

# Install Python dependencies
pip install -r requirements.txt

# Set environment variables
export DB_HOST="$RDS_ENDPOINT"
export DB_USER="appuser"
export DB_PASSWORD="your-secure-password"
export DB_NAME="appdb"
export FLASK_ENV="production"

# Create systemd service for backend
sudo tee /etc/systemd/system/backend.service > /dev/null <<'EOF'
[Unit]
Description=3-Tier Application Backend
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/opt/your-repo/application/backend
Environment="DB_HOST=$RDS_ENDPOINT"
Environment="DB_USER=appuser"
Environment="DB_PASSWORD=your-secure-password"
Environment="DB_NAME=appdb"
ExecStart=/usr/bin/python3 app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable backend
sudo systemctl start backend
sudo systemctl status backend
```

---

## Phase 3: Database Setup

### Step 3.1: Connect to RDS Database

```bash
# Install PostgreSQL client tools
sudo apt install -y postgresql-client

# Connect to RDS database (from bastion or app server)
PGPASSWORD="your-secure-password" psql -h $RDS_ENDPOINT \
  -U appuser -d appdb -p 5432

# Test connection (you should see psql prompt)
\list
\dt
\q  # Exit psql
```

### Step 3.2: Initialize Database Schema

```bash
# Run database migrations
PGPASSWORD="your-secure-password" psql -h $RDS_ENDPOINT \
  -U appuser -d appdb -f /opt/your-repo/database/schema.sql

# Verify tables were created
PGPASSWORD="your-secure-password" psql -h $RDS_ENDPOINT \
  -U appuser -d appdb -c "\dt"
```

### Step 3.3: Create Database Backup

```bash
# Backup database
PGPASSWORD="your-secure-password" pg_dump \
  -h $RDS_ENDPOINT -U appuser appdb > ~/appdb_backup.sql

# Verify backup
file ~/appdb_backup.sql
wc -l ~/appdb_backup.sql
```

---

## Phase 4: Monitoring Stack Deployment

### Step 4.1: Deploy on Dedicated Monitoring Server

**Option A: Separate EC2 Instance (Recommended for Production)**

```bash
# Launch monitoring EC2 instance
aws ec2 run-instances --image-id ami-0c55b159cbfafe1f0 \
  --count 1 --instance-type t2.micro \
  --key-name 3tier-app-key \
  --security-groups monitoring-sg \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=monitoring-server}]'

# Get the monitoring server public IP
MONITORING_IP=$(aws ec2 describe-instances --filters \
  "Name=tag:Name,Values=monitoring-server" \
  "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "Monitoring Server IP: $MONITORING_IP"
```

**Option B: Docker on Application Server (For Testing/Small Deployments)**

```bash
# SSH into application server
ssh -i ~/.ssh/3tier-app-key.pem -J ubuntu@$BASTION_IP ubuntu@$APP_SERVER_IP

# Clone repository
git clone https://github.com/your-username/your-repo.git
cd your-repo/monitoring/grafana

# Create environment file
cp .env.example .env
nano .env  # Update with your SMTP credentials

# Run setup script
bash setup.sh
```

### Step 4.2: Configure Monitoring Stack

```bash
# SSH into monitoring server
ssh -i ~/.ssh/3tier-app-key.pem ubuntu@$MONITORING_IP

# Install Docker
curl -fsSL https://get.docker.com | sudo bash
sudo usermod -aG docker ubuntu

# Clone repository
mkdir -p ~/deployment
cd ~/deployment
git clone https://github.com/your-username/your-repo.git
cd your-repo/monitoring/grafana

# Setup environment
cp .env.example .env
nano .env  # Update with your SMTP credentials

# Run setup script
bash setup.sh

# Verify services
docker-compose logs -f

# Wait 30 seconds and verify access
curl http://localhost:9090/-/healthy  # Prometheus
curl http://localhost:3000/api/health  # Grafana
curl http://localhost:9093/-/healthy  # AlertManager
```

### Step 4.3: Configure Prometheus Targets

```bash
# Edit prometheus.yml to add application server targets
nano prometheus.yml

# Add to scrape_configs:
# - job_name: 'backend-api'
#   static_configs:
#     - targets: ['$APP_SERVER_IP:8080']
#       labels:
#         service: 'backend'
# - job_name: 'node'
#   static_configs:
#     - targets: ['$APP_SERVER_IP:9100']

# Restart Prometheus
docker-compose restart prometheus
```

### Step 4.4: Deploy Node Exporter on Application Servers

```bash
# On each application server
ssh -i ~/.ssh/3tier-app-key.pem -J ubuntu@$BASTION_IP ubuntu@$APP_SERVER_IP

cd /opt/your-repo
bash monitoring/grafana/install-node-exporter.sh

# Verify Node Exporter is running
curl http://localhost:9100/metrics | head -20
```

---

## Phase 5: GitHub Actions CI/CD Configuration

### Step 5.1: Create GitHub Repository

```bash
# Create repository on GitHub
# Then configure local repository

cd "Assignment on module 6 (Terraform)"
git init
git branch -M main
git remote add origin https://github.com/your-username/your-repo.git
git add .
git commit -m "Initial: Complete 3-tier application with monitoring"
git push -u origin main
```

### Step 5.2: Add GitHub Secrets

**Go to**: Repository → Settings → Secrets and Variables → Actions

Add the following secrets:

```
AWS_ACCESS_KEY_ID=<your-access-key>
AWS_SECRET_ACCESS_KEY=<your-secret-key>
MONITORING_HOST=<monitoring-server-ip>
MONITORING_SSH_KEY=<base64-encoded-private-key>
SMTP_USERNAME=<your-smtp-email>
SMTP_PASSWORD=<your-smtp-app-password>
ALERT_EMAIL_TO=<ops-team-email>
ALERT_CRITICAL_EMAIL_TO=<oncall-email>
SLACK_WEBHOOK_URL=<slack-webhook-url> (optional)
```

**To encode SSH key for GitHub:**

```bash
cat ~/.ssh/3tier-app-key.pem | base64 -w 0
# Copy the output to MONITORING_SSH_KEY secret
```

### Step 5.3: Verify Workflows

```bash
# Check GitHub Actions status
# Go to your repository → Actions

# You should see these workflows:
# - terraform-validate
# - terraform-apply
# - deploy
# - monitoring-deploy

# Push a test commit to trigger workflows
git commit --allow-empty -m "Test: Trigger workflows"
git push origin main

# Monitor in GitHub Actions tab
```

---

## Phase 6: Email Alert Configuration

### Step 6.1: Configure SMTP Provider

**For Gmail:**

1. Enable 2-Factor Authentication
2. Create App Password: https://myaccount.google.com/apppasswords
3. Copy the 16-character app password
4. Use as SMTP_PASSWORD

**For SendGrid:**

```bash
# Create API key at https://app.sendgrid.com/settings/api_keys
# Use: apikey as username and your key as password
```

**For AWS SES:**

```bash
# Verify email address
aws ses verify-email-identity --email-address alerts@yourdomain.com

# Create SMTP credentials via SES console
# Region: us-east-1
# Endpoint: email-smtp.us-east-1.amazonaws.com:587
```

### Step 6.2: Update AlertManager Configuration

```bash
# SSH into monitoring server
ssh -i ~/.ssh/3tier-app-key.pem ubuntu@$MONITORING_IP

cd ~/deployment/your-repo/monitoring/grafana

# Edit alertmanager-config.yml
nano alertmanager-config.yml

# Update email addresses and SMTP settings
# Replace:
# - {{ SMTP_HOST }}
# - {{ SMTP_PORT }}
# - {{ SMTP_USERNAME }}
# - {{ SMTP_PASSWORD }}
# - {{ ALERT_FROM_EMAIL }}
# - {{ ALERT_EMAIL_TO }}
# - {{ ALERT_CRITICAL_EMAIL_TO }}

# Restart AlertManager
docker-compose restart alertmanager

# Verify configuration
curl http://localhost:9093/-/healthy
```

### Step 6.3: Test Email Alerts

```bash
# SSH into monitoring server
ssh -i ~/.ssh/3tier-app-key.pem ubuntu@$MONITORING_IP

# Create a test alert
curl -X POST http://localhost:9093/api/v1/alerts \
  -H 'Content-Type: application/json' \
  -d '{
    "alerts": [
      {
        "status": "firing",
        "labels": {
          "alertname": "TestAlert",
          "severity": "critical",
          "service": "monitoring"
        },
        "annotations": {
          "summary": "This is a test alert",
          "description": "If you receive this email, email alerts are working correctly"
        }
      }
    ]
  }'

# Check email inbox (may take a few moments)
# If email is received, alerts are working correctly
```

---

## Phase 7: Verification and Testing

### Step 7.1: Test Application Health

```bash
# Test application endpoint
curl http://$ALB_DNS/health
# Expected response: {"status": "healthy", ...}

# Test API endpoint
curl http://$ALB_DNS/system-info
# Expected response: {"server_version": "1.0.0", ...}
```

### Step 7.2: Verify Prometheus Metrics

```bash
# Access Prometheus UI
# Open browser: http://$MONITORING_IP:9090

# Verify targets are "UP"
# Go to Status → Targets
# All targets should show "UP" in green

# Query metrics
# Go to Graph tab and enter:
# - up (shows all targets status)
# - http_requests_total (application requests)
# - node_cpu_seconds_total (system CPU)
# - node_memory_MemAvailable_bytes (system memory)
```

### Step 7.3: Verify Grafana Dashboards

```bash
# Access Grafana
# Open browser: http://$MONITORING_IP:3000
# Login: admin / (password from .env)

# Import dashboards
# Settings → Data Sources → Add Prometheus
# URL: http://prometheus:9090
# Save & Test

# Import dashboard:
# + → Import → Upload JSON file
# Select from: monitoring/grafana/dashboards/
```

### Step 7.4: Test Load and Monitoring

```bash
# Generate traffic to application
ab -n 1000 -c 10 http://$ALB_DNS/

# Monitor in real-time
# Watch Prometheus metrics update
# Watch Grafana dashboard update

# Trigger high CPU alert (optional)
# SSH into application server and run:
# stress-ng --cpu 4 --timeout 120s
```

### Step 7.5: Test CI/CD Workflow

```bash
# Make a test change to application code
echo "# Test" >> application/backend/app.py

# Commit and push
git add .
git commit -m "Test: CI/CD workflow"
git push origin main

# Monitor in GitHub Actions
# Verify: build → test → deploy succeeds
# Verify: New version deployed to production
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Application Server Can't Connect to Database

```bash
# Check RDS security group
aws ec2 describe-security-groups --group-ids $RDS_SG_ID

# Verify ingress rule for port 5432 from app servers
# Should allow: PostgreSQL (5432) from $APP_SUBNET_CIDR

# Test connection
PGPASSWORD="password" psql -h $RDS_ENDPOINT -U appuser -c "SELECT 1"
```

#### 2. AlertManager Not Sending Emails

```bash
# Check AlertManager logs
docker-compose logs alertmanager

# Verify SMTP credentials in .env
cat .env | grep SMTP

# Test SMTP connection manually
telnet $SMTP_HOST $SMTP_PORT
# Expected: 220 (connection successful)

# Verify email address format
# Common issue: Using wrong email format
```

#### 3. Prometheus Not Scraping Targets

```bash
# Check Prometheus logs
docker-compose logs prometheus

# Verify target configuration
curl http://localhost:9090/api/v1/targets

# Check target health
# Prometheus UI → Status → Targets → Look for "DOWN" targets

# Common causes:
# - Target service not running (curl $TARGET_IP:$TARGET_PORT/metrics)
# - Network connectivity (firewall/security group rules)
# - Incorrect port or DNS name
```

#### 4. Grafana Dashboards Not Showing Data

```bash
# Verify Prometheus datasource connection
# Settings → Data Sources → Prometheus → Test

# Check Prometheus has collected metrics
curl http://localhost:9090/api/v1/query?query=up

# If empty, wait for Prometheus scrape interval (default: 30s)

# Check dashboard JSON for correct metric names
nano grafana/dashboards/dashboard.json
# Look for metric names and verify they exist in Prometheus
```

#### 5. SSH Connection Timeout to Application Server

```bash
# Check bastion server connectivity
ssh -i ~/.ssh/3tier-app-key.pem ubuntu@$BASTION_IP

# If bastion fails, verify security group rules
# Should allow SSH (22) from your IP

# Check application server security group
aws ec2 describe-security-groups --group-ids $APP_SG_ID

# Should allow SSH (22) from bastion security group
```

---

## Rollback Procedures

### Rollback Application Deployment

```bash
# Option 1: Redeploy previous version
cd terraform/environments/dev
terraform plan -destroy
terraform apply  # This will keep infrastructure intact

# Option 2: Use Auto Scaling Group rollback
# AWS Console → Auto Scaling Groups → dev-app-asg
# Terminate instance(s) - ASG will launch new ones with previous AMI

# Option 3: Manual rollback via GitHub Actions
# Push to a previous commit
git revert HEAD
git push origin main
# GitHub Actions will redeploy previous version
```

### Rollback Infrastructure

```bash
# Option 1: Destroy and recreate
cd terraform/environments/dev
terraform destroy
# Review plan, then confirm destruction

# Option 2: Partial rollback - specific resources
terraform destroy -target=aws_instance.app_server[0]
# Resource will be recreated by next terraform apply
```

### Rollback Monitoring Stack

```bash
# SSH into monitoring server
ssh -i ~/.ssh/3tier-app-key.pem ubuntu@$MONITORING_IP

cd ~/deployment/your-repo/monitoring/grafana

# Stop services
docker-compose down

# Restore from backup
docker-compose up -d

# Or revert to previous configuration
git revert HEAD
git pull origin main
docker-compose restart
```

---

## Maintenance Tasks

### Daily
- Monitor Grafana dashboard for anomalies
- Check alert emails for any critical issues
- Verify application availability: `curl http://$ALB_DNS/health`

### Weekly
- Review Prometheus disk space usage
- Check RDS backup status
- Review CloudWatch logs for errors
- Update security patches if needed

### Monthly
- Test disaster recovery procedures
- Review and optimize alert thresholds
- Rotate access keys and credentials
- Clean up old data/logs

### Quarterly
- Major version updates to services
- Review and update monitoring dashboard
- Conduct full load testing
- Review AWS costs and optimize

---

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Prometheus Documentation](https://prometheus.io/docs)
- [Grafana Documentation](https://grafana.com/docs)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

## Support and Escalation

For issues not covered in troubleshooting:

1. Check CloudWatch Logs
2. Review application logs on EC2 instances
3. Check GitHub Actions workflow logs
4. Contact AWS support (if infrastructure issue)
5. Review Prometheus alerts for root cause
