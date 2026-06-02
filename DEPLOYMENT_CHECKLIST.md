# Deployment Quick Checklist

**Estimated Time**: 1.5-2.5 hours for complete deployment  
**Prerequisites**: AWS account, GitHub account, EC2 key pair, SMTP credentials (optional)

---

## ✅ Phase 1: Environment Setup (10 minutes)

### Set Required Environment Variables

```bash
# CRITICAL: Set these before running terraform apply
export TF_VAR_grafana_password="YourSecureGrafanaPassword123!@"
export TF_VAR_master_password="YourSecurePassword123!@"

# Verify they are set
echo "Grafana: $TF_VAR_grafana_password"
echo "Database: $TF_VAR_master_password"
```

### Prepare Terraform Configuration

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Update in `terraform.tfvars`:
- [ ] `aws_region` → "us-east-1" (or your region)
- [ ] `key_pair_name` → "your-ec2-keypair"
- [ ] `alert_email_to` → "ops-team@company.com"
- [ ] `alert_critical_email_to` → "sre-oncall@company.com"
- [ ] `smtp_host` → "smtp.gmail.com"
- [ ] `smtp_port` → 587
- [ ] `smtp_username` → "your-email@gmail.com"

---

## ✅ Phase 2: Deploy Infrastructure with Terraform (30-40 minutes)

```bash
# Initialize Terraform
terraform init

# Verify configuration
terraform validate

# Review changes
terraform plan -out=tfplan

# Deploy all infrastructure (VPC, EC2, RDS, Monitoring)
terraform apply tfplan

# Save outputs
terraform output -json > outputs.json
```

**Deployment includes:**
- [ ] Main VPC (10.0.0.0/16) with public/private subnets
- [ ] Application Load Balancer
- [ ] Auto-Scaling Group with EC2 instances
- [ ] RDS PostgreSQL Multi-AZ database
- [ ] Bastion host for SSH access
- [ ] **Monitoring VPC (10.200.0.0/16) with separate infrastructure:**
  - [ ] t3.medium EC2 instance
  - [ ] Docker-based Prometheus, Grafana, AlertManager, Node Exporter
  - [ ] Security groups for public HTTP/HTTPS access
  - [ ] Elastic IP for consistent access

**Expected time:** 25-40 minutes (RDS Multi-AZ takes longest)

Verify all created:
- [ ] `terraform output | grep -E "alb_dns|bastion_public|monitoring_instance|grafana_url"`

---

## ✅ Phase 3: Wait for Monitoring Services (15-20 minutes)

**Docker services initialize automatically via user data script:**

```bash
# Get monitoring instance IP
MONITORING_IP=$(terraform output -raw monitoring_instance_public_ip)

# Check service status every 2 minutes
for i in {1..10}; do
  echo "Check $i..."
  curl -s -o /dev/null -w "%{http_code}" http://$MONITORING_IP:3000/api/health
  sleep 120
done
```

**Expected timeline:**
- Instance launch: ~2 minutes
- Docker installation: ~3 minutes
- Image pulls: ~10 minutes (600MB)
- Service startup: ~2 minutes

Services are ready when:
- [ ] Grafana responds: `curl -s http://$MONITORING_IP:3000/api/health`
- [ ] Prometheus responds: `curl -s http://$MONITORING_IP:9090/-/healthy`
- [ ] AlertManager responds: `curl -s http://$MONITORING_IP:9093/-/healthy`

---

## ✅ Phase 4: Access Monitoring Services (5 minutes)

```bash
# Get URLs from Terraform outputs
terraform output grafana_url
terraform output prometheus_url
terraform output alertmanager_url
```

**Access Services:**
- [ ] **Grafana**: http://<monitoring_ip>:3000
  - Username: `admin`
  - Password: `<Your TF_VAR_grafana_password>`
- [ ] **Prometheus**: http://<monitoring_ip>:9090
  - Check targets: http://<monitoring_ip>:9090/targets
  - Should show 4 targets (prometheus, node-exporter, alertmanager, grafana)
- [ ] **AlertManager**: http://<monitoring_ip>:9093
  - Check alerts and configuration

---

## ✅ Phase 5: Initialize Database (10 minutes)

```bash
# Get connection details
BASTION_IP=$(terraform output -raw bastion_public_ip)
RDS_ENDPOINT=$(terraform output -raw rds_address)

# Connect via bastion
ssh -i ~/.ssh/my-ec2-key.pem ec2-user@$BASTION_IP

# From bastion, connect to RDS
psql -h $RDS_ENDPOINT -U postgres -d appdb
# Enter password: <Your TF_VAR_master_password>
```

**Create database schema:**
- [ ] Create users table with appropriate columns
- [ ] Create logs table for application logging
- [ ] Insert sample data for testing
- [ ] Verify with `SELECT * FROM users;`

Exit with `\q`

---

## ✅ Phase 6: Verify Application Services (10 minutes)

```bash
# Get ALB DNS name
ALB_DNS=$(terraform output -raw alb_dns_name)

# Test health check
curl -s http://$ALB_DNS/health | jq .

# Check database connectivity
curl -s http://$ALB_DNS/db-status | jq .

# View application metrics
curl -s http://$ALB_DNS/metrics | head -20
```

Verify:
- [ ] Application is healthy
- [ ] Database is connected
- [ ] Metrics endpoint responding
- [ ] All instances in ALB target group are "healthy"

---

## ✅ Phase 7: Configure Grafana Dashboards (10 minutes)

### Add Prometheus Data Source

1. [ ] Login to Grafana: http://<monitoring_ip>:3000
2. [ ] Go to Settings (gear icon) → Data Sources
3. [ ] Click "Add data source" → Select "Prometheus"
4. [ ] URL: `http://localhost:9090` (or http://prometheus:9090)
5. [ ] Click "Save & Test" → Should see "Data source is working"

### Import Dashboards

1. [ ] Go to Dashboards → Import
2. [ ] Import from Grafana: Search for "Node Exporter Full" (ID: 1860)
3. [ ] Create custom dashboard for application metrics
4. [ ] Add panels for:
   - [ ] CPU usage
   - [ ] Memory usage
   - [ ] Network traffic
   - [ ] HTTP request rates

---

## ✅ Phase 8: Configure Alerts (Optional - 5 minutes)

```bash
# SSH into monitoring instance
MONITORING_IP=$(terraform output -raw monitoring_instance_public_ip)
ssh -i ~/.ssh/my-ec2-key.pem ubuntu@$MONITORING_IP

# Update AlertManager configuration with SMTP
nano /home/ubuntu/monitoring-deployment/alertmanager-config.yml

# Restart AlertManager
docker restart monitoring-deployment-alertmanager-1

# Test alert
curl -X POST http://localhost:9093/api/v1/alerts \
  -H 'Content-Type: application/json' \
  -d '{
    "alerts": [{
      "status": "firing",
      "labels": {"alertname": "TestAlert"},
      "annotations": {"summary": "Test alert"}
    }]
  }'
```

Verify:
- [ ] Test email received
- [ ] Alert appears in AlertManager UI: http://<monitoring_ip>:9093

---

## ✅ Phase 9: GitHub Actions Setup (Optional - 5 minutes)

```bash
# Add GitHub secrets in repository settings
```

Required secrets:
- [ ] `AWS_ACCESS_KEY_ID`
- [ ] `AWS_SECRET_ACCESS_KEY`
- [ ] `SLACK_WEBHOOK_URL` (optional)

---

## ✅ Phase 10: Post-Deployment Verification (5 minutes)

**Run all verification commands:**

```bash
# Application health
ALB_DNS=$(terraform output -raw alb_dns_name)
curl -s http://$ALB_DNS/health | jq .

# Database connectivity
curl -s http://$ALB_DNS/db-status | jq .

# Prometheus metrics
MONITORING_IP=$(terraform output -raw monitoring_instance_public_ip)
curl -s http://$MONITORING_IP:9090/-/healthy

# Grafana ready
curl -s http://$MONITORING_IP:3000/api/health | jq .

# Verify monitoring is collecting metrics
curl -s http://$MONITORING_IP:9090/api/v1/targets | jq .

# Save for reference
terraform output > infrastructure-summary.txt
```

**Verification Checklist:**
- [ ] Application accessible via ALB
- [ ] Database initialized and connected
- [ ] All monitoring services running
- [ ] Prometheus collecting metrics (all targets UP)
- [ ] Grafana dashboards showing data
- [ ] Alert email notifications configured
- [ ] All infrastructure created successfully

---

## 🎉 Deployment Complete!

**Your 3-tier infrastructure is now deployed and monitored:**

### Access Points:
- **Application**: http://<ALB_DNS_NAME>
- **Grafana Dashboard**: http://<MONITORING_IP>:3000
  - Username: `admin`
  - Password: `<Your TF_VAR_grafana_password>`
- **Prometheus**: http://<MONITORING_IP>:9090
- **AlertManager**: http://<MONITORING_IP>:9093

### Infrastructure Summary:
- **Main VPC**: 10.0.0.0/16 (Application)
- **Monitoring VPC**: 10.200.0.0/16 (Separate monitoring)
- **Database**: RDS PostgreSQL Multi-AZ
- **Load Balancer**: AWS Application Load Balancer
- **Bastion Host**: SSH access point
- **Auto-Scaling**: 2-4 application servers
- **Monitoring**: Prometheus, Grafana, AlertManager, Node Exporter

### Next Steps:
1. Login to Grafana and configure custom dashboards
2. Set up Prometheus alert rules
3. Configure AlertManager email notifications
4. Deploy your application code via CI/CD pipeline
5. Monitor and optimize based on collected metrics
6. Scale infrastructure as needed based on load

### Useful Commands:

```bash
# View infrastructure outputs
terraform output

# SSH to monitoring instance
$(terraform output -raw monitoring_ssh_command)

# SSH to bastion host
ssh -i ~/.ssh/my-ec2-key.pem ec2-user@$(terraform output -raw bastion_public_ip)

# SSH to app server via bastion
ssh -i ~/.ssh/my-ec2-key.pem -J ec2-user@<BASTION_IP> ec2-user@<APP_SERVER_IP>

# Connect to RDS database
psql -h $(terraform output -raw rds_address) -U postgres -d appdb

# View monitoring logs
ssh -i ~/.ssh/my-ec2-key.pem ubuntu@<MONITORING_IP>
docker logs monitoring-deployment-prometheus-1
docker logs monitoring-deployment-grafana-1
docker logs monitoring-deployment-alertmanager-1
```

### Documentation:
- **Full Setup**: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **Full Documentation**: [README.md](README.md)
- **Architecture Details**: [ARCHITECTURE.md](ARCHITECTURE.md)
- **CI/CD Pipeline**: [CI_CD_SETUP_GUIDE.md](CI_CD_SETUP_GUIDE.md)
- **GitHub Setup**: [GITHUB_SETUP_GUIDE.md](GITHUB_SETUP_GUIDE.md)

### Troubleshooting:
- Check [README.md](README.md#troubleshooting) troubleshooting section
- Review [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed steps
- SSH to instances to check logs and services
- Monitor CloudWatch logs in AWS Console

**Total Estimated Time**: 1.5-2.5 hours ✅
- [ ] Application handles 1000 requests
- [ ] Response times remain under 2s
- [ ] No 5xx errors
- [ ] Metrics updated in real-time on Grafana
- [ ] Alerts triggered if thresholds exceeded

---

**⏱️ Total Estimated Time**: 1.5-2.5 hours  
**✅ Status**: All phases ready for execution  
**🎯 First Step**: Phase 1 - Environment Setup
