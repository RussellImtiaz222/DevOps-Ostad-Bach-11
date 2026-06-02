# Deployment Quick Checklist

**Estimated Time**: 2-3 hours for complete deployment  
**Prerequisites**: AWS account, GitHub account, domain/SMTP

---

## ✅ Phase 1: GitHub Secrets Configuration (5 minutes)

- [ ] Go to GitHub → Repository Settings → Secrets and Variables → Actions
- [ ] Add `AWS_ACCESS_KEY_ID`
- [ ] Add `AWS_SECRET_ACCESS_KEY`
- [ ] Add `MONITORING_HOST` (will update after infrastructure deployed)
- [ ] Add `MONITORING_SSH_KEY` (base64-encoded SSH private key)
- [ ] Add `SMTP_USERNAME` (your SMTP email)
- [ ] Add `SMTP_PASSWORD` (SMTP app password)
- [ ] Add `ALERT_EMAIL_TO` (operations team email)
- [ ] Add `ALERT_CRITICAL_EMAIL_TO` (oncall email)
- [ ] Add `SLACK_WEBHOOK_URL` (optional)

---

## ✅ Phase 2: Customize Terraform Variables (10 minutes)

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Update values:
- [ ] `project_name` → "your-project"
- [ ] `environment` → "dev" (or staging/prod)
- [ ] `aws_region` → "us-east-1"
- [ ] `instance_type` → "t2.micro" (or t3.small for better performance)
- [ ] `key_pair_name` → "your-ec2-keypair"
- [ ] `database_password` → Generate secure password

---

## ✅ Phase 3: Deploy Infrastructure with Terraform (30 minutes)

```bash
# Initialize Terraform
terraform init

# Review plan
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Save outputs
terraform output -json > outputs.json
cat outputs.json
```

Verify:
- [ ] VPC created
- [ ] Subnets created (public/private)
- [ ] Security groups created
- [ ] EC2 instances launching
- [ ] RDS database launching
- [ ] ALB created
- [ ] Bastion host created

Expected time: 20-30 minutes

---

## ✅ Phase 4: Initialize Database (10 minutes)

```bash
# Get values from Terraform outputs
ALB_DNS=$(jq -r '.alb_dns_name.value' outputs.json)
RDS_ENDPOINT=$(jq -r '.rds_endpoint.value' outputs.json)
BASTION_IP=$(jq -r '.bastion_public_ip.value' outputs.json)

# Connect to database
PGPASSWORD="your_password" psql -h $RDS_ENDPOINT \
  -U postgres -d postgres

# Run initialization script
\i ../../../database/schema.sql

# Create application user
CREATE USER appuser WITH PASSWORD 'your-secure-password';
GRANT ALL PRIVILEGES ON DATABASE appdb TO appuser;

# Exit
\q
```

Verify:
- [ ] Database tables created
- [ ] Application user created
- [ ] Connection test successful

---

## ✅ Phase 5: Deploy Application (15 minutes)

```bash
# Deploy via GitHub Actions (automatic)
git commit --allow-empty -m "Deploy: Initial application"
git push origin main

# Monitor in GitHub Actions tab
# Expected: build → test → deploy
```

Verify:
- [ ] GitHub Actions workflow completes
- [ ] Application Docker image built
- [ ] Application deployed to EC2
- [ ] ALB showing healthy targets

Expected time: 10-15 minutes

---

## ✅ Phase 6: Deploy Monitoring Stack (20 minutes)

### Option A: Docker Compose (Recommended for testing)

```bash
cd monitoring/grafana

# Setup environment
cp .env.example .env
nano .env  # Update SMTP credentials

# Run setup script
bash setup.sh
```

Verify after 30 seconds:
- [ ] Prometheus: `curl http://localhost:9090/-/healthy`
- [ ] Grafana: `curl http://localhost:3000/api/health`
- [ ] AlertManager: `curl http://localhost:9093/-/healthy`
- [ ] Node Exporter: `curl http://localhost:9100/metrics`

### Option B: Terraform (Recommended for production)

```bash
cd terraform/environments/dev

# Add monitoring module to main.tf
# Edit main.tf and uncomment monitoring module
# Or add:
module "monitoring" {
  source = "../modules/monitoring"
  
  project_name            = var.project_name
  environment             = var.environment
  key_pair_name           = var.key_pair_name
  alert_email_to          = "ops@yourdomain.com"
  alert_critical_email_to = "oncall@yourdomain.com"
  smtp_username           = var.smtp_username
  grafana_password        = var.grafana_password
}

# Deploy
terraform apply
```

---

## ✅ Phase 7: Configure Prometheus Targets (10 minutes)

```bash
# SSH into monitoring server
MONITORING_IP=$(jq -r '.monitoring_instance_public_ip.value' outputs.json)
ssh -i ~/.ssh/3tier-app-key.pem ubuntu@$MONITORING_IP

# Update Prometheus configuration
cd ~/deployment/monitoring/grafana
nano prometheus.yml

# Add application server targets:
# - job_name: 'backend-api'
#   static_configs:
#     - targets: ['APP_SERVER_IP:8080']
#       labels:
#         service: 'backend'

# Restart Prometheus
docker-compose restart prometheus
```

Verify in Prometheus UI:
- [ ] Go to http://MONITORING_IP:9090/targets
- [ ] All targets should show "UP" in green
- [ ] Check "Scraping interval" shows 15s or 30s

---

## ✅ Phase 8: Deploy Node Exporter on App Servers (10 minutes)

```bash
# SSH into application server via Bastion
BASTION_IP=$(jq -r '.bastion_public_ip.value' outputs.json)
APP_SERVER_IP=$(jq -r '.app_server_private_ips.value[0]' outputs.json)

ssh -i ~/.ssh/3tier-app-key.pem \
  -J ubuntu@$BASTION_IP ubuntu@$APP_SERVER_IP

# Download and run Node Exporter installer
curl -O https://raw.githubusercontent.com/your-repo/monitoring/grafana/install-node-exporter.sh
sudo bash install-node-exporter.sh

# Verify
curl http://localhost:9100/metrics | head -10
```

Verify:
- [ ] Node Exporter running: `curl http://APP_SERVER_IP:9100/metrics`
- [ ] Prometheus scraping: Check targets in Prometheus UI
- [ ] Metrics appearing: `node_cpu_seconds_total` in Prometheus

---

## ✅ Phase 9: Configure Email Alerts (5 minutes)

```bash
# SSH into monitoring server
ssh -i ~/.ssh/3tier-app-key.pem ubuntu@$MONITORING_IP

cd ~/deployment/monitoring/grafana

# Update .env with SMTP credentials
nano .env
# Update:
# SMTP_HOST=smtp.gmail.com
# SMTP_PORT=587
# SMTP_USERNAME=your-email@gmail.com
# SMTP_PASSWORD=your-app-password

# Restart AlertManager
docker-compose restart alertmanager

# Test alert
curl -X POST http://localhost:9093/api/v1/alerts \
  -H 'Content-Type: application/json' \
  -d '{
    "alerts": [{
      "status": "firing",
      "labels": {"alertname": "TestAlert", "severity": "critical"},
      "annotations": {"summary": "Test alert from monitoring"}
    }]
  }'
```

Verify:
- [ ] Test email received in inbox
- [ ] Email contains alert details
- [ ] Check alertmanager logs: `docker-compose logs alertmanager`

---

## ✅ Phase 10: Access and Configure Grafana (10 minutes)

```bash
# Get Grafana URL
MONITORING_IP=$(jq -r '.monitoring_instance_public_ip.value' outputs.json)
echo "Grafana: http://$MONITORING_IP:3000"
```

In browser:
1. [ ] Open http://MONITORING_IP:3000
2. [ ] Login: admin / (password from .env)
3. [ ] Go to Data Sources → Prometheus
4. [ ] URL: http://prometheus:9090
5. [ ] Click "Save & Test" → "Data source is working"
6. [ ] Go to Dashboards → Import
7. [ ] Upload from `monitoring/grafana/dashboards/`

---

## ✅ Phase 11: Test Application Endpoints (5 minutes)

```bash
# Get ALB DNS
ALB_DNS=$(jq -r '.alb_dns_name.value' outputs.json)

# Test health endpoint
curl http://$ALB_DNS/health

# Test system info endpoint
curl http://$ALB_DNS/system-info

# Test metrics endpoint
curl http://$ALB_DNS/metrics | head -20
```

Expected responses:
- [ ] /health: `{"status": "healthy", ...}`
- [ ] /system-info: `{"server_version": "1.0.0", ...}`
- [ ] /metrics: Prometheus format metrics

---

## ✅ Phase 12: Verify Monitoring (5 minutes)

```bash
# Check Prometheus targets
curl http://$MONITORING_IP:9090/api/v1/targets | jq .

# Check collected metrics
curl "http://$MONITORING_IP:9090/api/v1/query?query=up" | jq .

# Check Grafana data source
curl http://$MONITORING_IP:3000/api/datasources | jq .
```

Verify:
- [ ] All targets showing "UP" state
- [ ] Metrics being collected and stored
- [ ] Grafana showing data in dashboards
- [ ] Alerts evaluating (check Prometheus alerts tab)

---

## ✅ Phase 13: Test CI/CD Workflow (10 minutes)

```bash
# Make a small change to trigger workflow
echo "# Test deployment" >> application/backend/README.md

# Commit and push
git add .
git commit -m "Test: Trigger CI/CD workflow"
git push origin main

# Monitor workflow
# Go to GitHub → Actions tab
# Watch: validate → build → deploy
```

Verify:
- [ ] Workflow starts automatically
- [ ] Build job completes
- [ ] Deploy job completes
- [ ] Application remains healthy
- [ ] Slack notification received (if configured)

---

## ✅ Phase 14: Load Testing & Validation (15 minutes)

```bash
# Install Apache Bench
sudo apt-get install apache2-utils

# Run load test
ALB_DNS=$(jq -r '.alb_dns_name.value' outputs.json)
ab -n 1000 -c 10 http://$ALB_DNS/

# Monitor during load test
# Open Grafana dashboard in another terminal
# Watch: CPU, Memory, Request Rate, Response Time
```

Verify:
- [ ] Application handles 1000 requests
- [ ] Response times remain under 2s
- [ ] No 5xx errors
- [ ] Metrics updated in real-time on Grafana
- [ ] Alerts triggered if thresholds exceeded

---

## ✅ Final Verification Checklist

### Application Layer:
- [ ] Application responding to requests
- [ ] Database queries working
- [ ] Response times acceptable (<2s)
- [ ] No 5xx errors in logs

### Infrastructure Layer:
- [ ] EC2 instances running and healthy
- [ ] RDS database operational and backed up
- [ ] ALB routing traffic correctly
- [ ] Auto-scaling group functioning

### Monitoring Layer:
- [ ] Prometheus collecting metrics
- [ ] Grafana dashboards showing data
- [ ] AlertManager routing alerts
- [ ] Email alerts being sent

### CI/CD Layer:
- [ ] GitHub workflows executing
- [ ] Deployments completing successfully
- [ ] Artifacts being stored
- [ ] Notifications being sent

### Security:
- [ ] SSH access restricted
- [ ] Database accessible only from app servers
- [ ] HTTPS configured (if domain available)
- [ ] Sensitive data in GitHub Secrets

---

## 🚀 Go Live Checklist

Before going to production:

- [ ] Load testing completed (1000+ req/s)
- [ ] Alert thresholds calibrated to baseline
- [ ] Team trained on runbook procedures
- [ ] Backup/recovery procedures tested
- [ ] Monitoring dashboards reviewed
- [ ] Escalation procedures documented
- [ ] Incident response plan prepared
- [ ] Cost monitoring alerts configured
- [ ] DNS records updated (if using domain)
- [ ] SSL/TLS certificate configured

---

## 📞 Troubleshooting Quick Links

If something fails, check:

1. **GitHub Actions fails**:
   - Check GitHub Actions logs
   - Verify AWS credentials in secrets
   - Verify Terraform syntax: `terraform validate`

2. **Application not responding**:
   - Check ALB target health in AWS console
   - Check EC2 instance logs
   - Check security group rules

3. **Monitoring not collecting metrics**:
   - Check Prometheus targets: `http://prometheus:9090/targets`
   - Check Node Exporter running: `curl APP_IP:9100/metrics`
   - Check Prometheus scrape config

4. **Alerts not sending emails**:
   - Check SMTP credentials in .env
   - Check AlertManager logs
   - Test SMTP: `telnet SMTP_HOST SMTP_PORT`

5. **Database connection issues**:
   - Check RDS security group rules
   - Verify database credentials
   - Test connection: `psql -h RDS_ENDPOINT -U appuser`

For detailed help, see **DEPLOYMENT_RUNBOOK.md** → Troubleshooting section.

---

**⏱️ Total Estimated Time**: 2-3 hours  
**✅ Status**: All steps ready for execution  
**🎯 Next Step**: Start with Phase 1 - GitHub Secrets Configuration
