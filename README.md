# 3-Tier Application Infrastructure on AWS with Terraform

A complete Infrastructure as Code (IaC) project for deploying a scalable 3-tier application on AWS using Terraform, with CI/CD pipeline via GitHub Actions and comprehensive monitoring with Grafana.

## Project Overview

This project demonstrates enterprise-grade infrastructure deployment practices:

- **Infrastructure Layer**: VPC with public/private subnets, NAT gateway, bastion host
- **Compute Layer**: Auto-scaling application servers with load balancing
- **Database Layer**: Managed RDS PostgreSQL database with Multi-AZ
- **Security**: Security groups, IAM roles, encrypted storage
- **CI/CD**: GitHub Actions workflows for infrastructure and application deployment
- **Monitoring**: Prometheus, Grafana, and CloudWatch integration
- **Best Practices**: Modular Terraform, reusable components, environment separation

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      Internet (0.0.0.0/0)                                   │
└──────────────────────┬─────────────────────────────────┬────────────────────┘
                       │ HTTP/HTTPS                      │ HTTP (Monitoring)
                       ▼                                 ▼
        ┌────────────────────────────────┐    ┌──────────────────────────┐
        │ Application Load Balancer      │    │  Monitoring Instance     │
        │ (Public Subnets: Multi-AZ)     │    │  (t3.medium, Public)     │
        └────────────────┬───────────────┘    │  • Prometheus (9090)     │
                         │                    │  • Grafana (3000)        │
        ┌────────────────┴───────────────┐    │  • AlertManager (9093)   │
        ▼                                 ▼    │  • Node Exporter (9100)  │
    ┌─────────┐                     ┌─────────┐ └──────────────────────────┘
    │ App Srv │                     │ App Srv │
    │ (ASG)   │                     │ (ASG)   │
    │Private  │                     │Private  │
    │Subnet-A │                     │Subnet-B │
    └────┬────┘                     └────┬────┘
         │                              │
         └──────────────────┬───────────┘
                            │
                            ▼ Port 5432
        ┌───────────────────────────────┐
        │   RDS PostgreSQL Database     │
        │   (Private Subnets: Multi-AZ) │
        │      (Subnet-A, Subnet-B)     │
        └───────────────────────────────┘

Main VPC (10.0.0.0/16): Application infrastructure
Monitoring VPC (10.200.0.0/16): Separate monitoring infrastructure
Bastion Host: SSH access to private servers
NAT Gateway: Private subnet outbound internet access
```

## Directory Structure

```
.
├── terraform/
│   ├── modules/
│   │   ├── vpc/                 # VPC and networking (main application)
│   │   ├── security_groups/     # Security groups (application & monitoring)
│   │   ├── bastion/             # Bastion host for secure SSH access
│   │   ├── ec2/                 # Application servers with Auto-Scaling
│   │   ├── rds/                 # RDS PostgreSQL database
│   │   └── monitoring/          # Monitoring infrastructure (separate VPC)
│   │       ├── main.tf          # EC2, VPC, security groups for monitoring
│   │       ├── variables.tf     # Module variables
│   │       ├── outputs.tf       # Outputs (IPs, URLs, credentials)
│   │       └── user_data.sh     # Docker installation and setup script
│   └── environments/
│       └── dev/                 # Development environment
│           ├── main.tf          # Main orchestration
│           ├── variables.tf     # Environment variables
│           ├── outputs.tf       # Infrastructure outputs
│           ├── terraform.tfvars # Configuration values
│           └── terraform.tfvars.example
├── application/
│   ├── frontend/                # Static HTML/CSS/JS frontend
│   ├── backend/                 # Python Flask API
│   └── database/                # Database initialization scripts
├── 3-Tier Application on AWS EC2/
│   ├── docker-compose.yml       # Application deployment
│   ├── docker-up.sh             # Helper scripts
│   ├── README.md                # Application documentation
│   ├── frontend/                # Frontend application
│   ├── backend/                 # Backend application
│   ├── config/                  # Configuration files
│   ├── database/                # Database scripts
│   └── scripts/                 # Utility scripts
├── monitoring/
│   └── grafana/                 # Grafana setup (local reference)
│       ├── docker-compose.yml
│       ├── prometheus.yml
│       ├── alertmanager.yml
│       ├── prometheus_rules.yml
│       ├── dashboard.json
│       └── setup.sh
├── .github/workflows/           # GitHub Actions CI/CD
│   └── terraform-security.yml   # Security scanning pipeline
├── ARCHITECTURE.md              # Detailed architecture documentation
├── DEPLOYMENT_GUIDE.md          # Step-by-step deployment guide
├── CI_CD_SETUP_GUIDE.md         # GitHub Actions configuration
└── README.md                    # This file
```

## Prerequisites

- AWS Account with appropriate IAM permissions
- Terraform >= 1.0
- AWS CLI configured
- Docker and Docker Compose (for local monitoring)
- GitHub account for CI/CD
- EC2 Key Pair created in AWS

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/3-tier-terraform.git
cd 3-tier-terraform
```

### 2. Set Environment Variables

Set critical environment variables before proceeding:

```bash
# Set Grafana admin password (required for monitoring stack)
export TF_VAR_grafana_password="YourSecureGrafanaPassword123!@"

# Set database master password (required for RDS)
export TF_VAR_master_password="SecurePassword123!@"

# Optional: Set AWS profile
export AWS_PROFILE=default
export AWS_REGION=us-east-1
```

### 3. Create terraform.tfvars

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:
- AWS region
- EC2 key pair name (e.g., "my-keypair")
- Alert email configuration
- SMTP configuration (for AlertManager)
- Allowed SSH CIDR blocks
- Application instance sizing

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Review the Plan

```bash
terraform plan -var-file=terraform.tfvars
```

This will show:
- Main application VPC (10.0.0.0/16) with EC2, RDS, ALB
- Separate monitoring VPC (10.200.0.0/16) with Prometheus, Grafana, AlertManager
- Security groups, IAM roles, and other infrastructure

### 6. Apply the Configuration

```bash
terraform apply -var-file=terraform.tfvars
```

**Deployment Timeline:**
- VPC and networking: 1-2 minutes
- RDS database: 5-10 minutes
- EC2 instances: 2-3 minutes
- Monitoring instance Docker setup: 5-15 minutes (image pulls and container start)

### 7. Retrieve Outputs

```bash
terraform output
```

**Critical Outputs:**
- `alb_dns_name` - Access application frontend
- `bastion_public_ip` - SSH access point
- `rds_endpoint` - Database connection
- `monitoring_instance_public_ip` - Monitoring services IP
- `grafana_url` - Grafana dashboard access
- `prometheus_url` - Prometheus metrics access

## Configuration

### Environment Variables

Create `.env` file in the project root or set in your terminal:

```bash
export AWS_PROFILE=default
export AWS_REGION=us-east-1
export TF_VAR_master_password=YourSecurePassword123!@
export TF_VAR_grafana_password=YourSecureGrafanaPassword123!@
```

**Important**: Always set `TF_VAR_grafana_password` before deploying - this sets the Grafana admin password.

### terraform.tfvars Example

```hcl
# AWS Configuration
aws_region           = "us-east-1"
environment          = "dev"
key_pair_name        = "my-keypair"

# Database Configuration
master_password      = "SecurePassword123!@"

# Main Application VPC
vpc_cidr              = "10.0.0.0/16"
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]
availability_zones    = ["us-east-1a", "us-east-1b"]

# RDS Database
rds_instance_class    = "db.t3.micro"
rds_allocated_storage = 20
rds_multi_az          = true

# Application Servers
app_instance_type    = "t3.small"
app_min_size         = 2
app_max_size         = 4
app_desired_capacity = 2

# Bastion Host
bastion_instance_type = "t3.micro"

# Monitoring Instance (separate VPC: 10.200.0.0/16)
monitoring_instance_type = "t3.medium"
monitoring_root_volume_size = 50

# Alert Email Configuration (for AlertManager)
alert_email_to = "ops-team@example.com"
alert_critical_email_to = "sre-oncall@example.com"
alert_from_email = "alerts@example.com"

# SMTP Configuration for Email Alerts
smtp_host = "smtp.gmail.com"
smtp_port = 587
smtp_username = "your-email@gmail.com"

# Common Tags
common_tags = {
  Project     = "3-Tier-Application"
  Owner       = "DevOps-Team"
  CostCenter  = "Engineering"
}
```

## Application Deployment

### Backend API

The backend is a Python Flask application that:
- Provides RESTful API for user management
- Connects to RDS PostgreSQL database
- Exposes Prometheus metrics
- Includes health checks

**Endpoints:**
- `GET /health` - Health check
- `GET /system-info` - System information
- `GET /db-status` - Database connectivity
- `POST /users` - Create user
- `GET /users` - List all users
- `GET /users/{id}` - Get specific user
- `PUT /users/{id}` - Update user
- `DELETE /users/{id}` - Delete user
- `GET /metrics` - Prometheus metrics

### Frontend

Interactive HTML/CSS/JavaScript interface for:
- Viewing system information
- Managing users (CRUD operations)
- Checking database status
- Application health monitoring

Access via ALB DNS name from the Terraform outputs.

## CI/CD Pipeline

### GitHub Actions Workflows

#### Terraform Workflow (terraform.yml)
- Triggered on push to main/develop branches
- Terraform format check
- Plan and validate
- Auto-apply on main branch merge
- Exports outputs as artifacts

#### Deploy Workflow (deploy.yml)
- Builds Docker image for backend
- Tests frontend
- Deploys to application servers
- Performs health checks
- Sends Slack notifications

### Setting Up GitHub Actions

1. Go to repository settings
2. Add secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `TF_VAR_MASTER_PASSWORD`
   - `SLACK_WEBHOOK_URL` (optional)

## Monitoring with Grafana

### AWS-Deployed Monitoring Infrastructure

The monitoring stack is deployed as part of the Terraform infrastructure on a separate t3.medium EC2 instance with its own VPC (10.200.0.0/16). This provides complete isolation from the application infrastructure.

**Monitoring Stack Components:**
- **Prometheus** v2.48.0 - Metrics collection and storage
- **Grafana** 10.2.0 - Metrics visualization and dashboards
- **Node Exporter** v1.7.0 - System metrics collection
- **AlertManager** v0.26.0 - Alert management and routing

### Accessing Monitoring Services

Once the instance is deployed and Docker services initialize (5-15 minutes), access the monitoring services:

**Services Endpoints:** ✅ VERIFIED WORKING
- **Grafana Dashboard**: http://3.212.99.113:3000 - Status: HTTP 200 ✅
- **Prometheus Targets**: http://3.212.99.113:9090 - Status: HTTP 200 ✅
- **AlertManager**: http://3.212.99.113:9093 - Status: HTTP 200 ✅
- **Node Exporter**: http://3.212.99.113:9100 - Status: HTTP 200 ✅

**Note**: Security group inbound rules for ports 3000, 9090, 9093, and 9100 are automatically configured by Terraform with `0.0.0.0/0` CIDR to allow public access.

### Grafana Login

**Default Credentials:**
- Username: `admin`
- Password: Set via `TF_VAR_grafana_password` environment variable

**Set Password Before Deployment:**
```bash
export TF_VAR_grafana_password="YourSecureGrafanaPassword123!@"
cd terraform/environments/dev
terraform apply
```

### Monitoring Instance Details

After deployment, retrieve monitoring infrastructure details:

```bash
cd terraform/environments/dev
terraform output | grep monitoring
```

**Key Outputs:**
- `monitoring_instance_id` - EC2 instance ID
- `monitoring_instance_public_ip` - Public IP address
- `monitoring_security_group_id` - Security group for monitoring
- `grafana_url` - Full Grafana access URL
- `prometheus_url` - Full Prometheus access URL
- `alertmanager_url` - Full AlertManager access URL
- `monitoring_ssh_command` - SSH command for instance access

### SSH Access to Monitoring Instance

```bash
# Option 1: Using SSH command from Terraform output
ssh -i ~/.ssh/3tier-app-key.pem ubuntu@3.212.99.113

# Option 2: Using Terraform output directly
$(terraform output -raw monitoring_ssh_command)

# Option 3: Using EC2 Instance Connect (no key required)
# Available in AWS EC2 Console for quick troubleshooting
```

### View Docker Logs and Container Status

To troubleshoot Docker services, SSH into the monitoring instance:

```bash
ssh -i ~/.ssh/3tier-app-key.pem ubuntu@3.212.99.113

# Check all running containers and their health status
docker ps

# Expected output:
# grafana          - Status: Up (healthy) ✅
# prometheus       - Status: Up ✅
# alertmanager     - Status: Up ✅
# node-exporter    - Status: Up ✅

# View specific service logs
docker logs monitoring-deployment-prometheus-1
docker logs monitoring-deployment-grafana-1
docker logs monitoring-deployment-node-exporter-1
docker logs monitoring-deployment-alertmanager-1

# Quick health checks from local instance
curl -s http://localhost:3000/api/health       # Grafana
curl -s http://localhost:9090/-/healthy        # Prometheus
curl -s http://localhost:9093/-/healthy        # AlertManager
curl -s http://localhost:9100/metrics | head   # Node Exporter

# View user data initialization logs
tail -f /var/log/cloud-init-output.log
```

### Configure Grafana Dashboards

1. Login to Grafana with admin credentials
2. Add Prometheus as a data source:
   - URL: `http://localhost:9090`
   - Access: Server (default)
3. Import pre-built dashboards from Grafana marketplace:
   - Node Exporter Full
   - Prometheus Stats
   - AlertManager

### Alert Configuration

Alerts are configured via AlertManager for email notifications:

**Edit alertmanager-config.yml in the monitoring instance:**
```bash
ssh -i ~/.ssh/3tier-app-key.pem ubuntu@3.212.99.113
nano /home/ubuntu/monitoring-deployment/alertmanager-config.yml
```

Then restart AlertManager:
```bash
docker restart monitoring-deployment-alertmanager-1
```

### Prometheus Scrape Targets

Prometheus automatically scrapes metrics from:
- **Prometheus itself** - http://localhost:9090/metrics
- **Node Exporter** - http://node-exporter:9100/metrics
- **AlertManager** - http://alertmanager:9093/metrics

View available targets in Prometheus UI: http://3.212.99.113:9090/targets

## Terraform Commands

### Basic Operations

```bash
# Initialize Terraform
terraform init

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes
terraform plan -var-file=terraform.tfvars

# Apply changes
terraform apply -var-file=terraform.tfvars

# Destroy infrastructure
terraform destroy -var-file=terraform.tfvars
```

### Advanced Operations

```bash
# Refresh state
terraform refresh

# Target specific resource
terraform apply -target=module.rds

# Import existing resource
terraform import aws_security_group.existing sg-12345678

# Show outputs
terraform output

# State management
terraform state list
terraform state show aws_instance.bastion
terraform state rm module.old_module
```

## Best Practices Implemented

✅ **Modularity**: Separate modules for VPC, EC2, RDS, Security Groups, and Monitoring
✅ **Infrastructure Isolation**: 
   - Main application VPC (10.0.0.0/16)
   - Separate monitoring VPC (10.200.0.0/16)
   - Independent security groups and networking

✅ **Environment Separation**: Dev environment with easy extension to prod/staging
✅ **Variables & Outputs**: Clear input variables and outputs for each module
✅ **State Management**: Local state (configure S3 backend for production)
✅ **Security**:
   - Security groups with least privilege
   - Encrypted RDS storage (EBS encryption)
   - IAM roles for EC2 instances with CloudWatch access
   - No hardcoded credentials (use environment variables)
   - Bastion host for private server SSH access
   - Separate VPC for monitoring to isolate from application

✅ **High Availability**:
   - Multi-AZ deployment for application and RDS
   - Auto-scaling for application servers
   - RDS Multi-AZ with automatic failover
   - Application Load Balancer for traffic distribution

✅ **Monitoring & Observability**:
   - CloudWatch metrics and logs integration
   - Prometheus for metrics collection
   - Grafana dashboards for visualization
   - AlertManager for alert routing and notifications
   - Node Exporter for system-level metrics
   - Application health checks and status endpoints

✅ **Infrastructure as Code**:
   - Terraform modules for reusability
   - Version-controlled infrastructure
   - Consistent tagging and resource naming
   - Automated security scanning via GitHub Actions

✅ **CI/CD Integration**: 
   - GitHub Actions workflows for security scanning
   - tfsec, Checkov, Trivy for infrastructure scanning
   - Terraform compliance checking
   - Automated deployments on merge to main

✅ **Documentation**: 
   - Comprehensive code comments
   - Architecture documentation
   - Deployment guides
   - Troubleshooting guides

## Accessing the Application

### Get Infrastructure Details

```bash
# View all outputs
terraform output

# View specific outputs
terraform output alb_dns_name
terraform output monitoring_instance_public_ip
terraform output grafana_url
terraform output rds_endpoint
```

### Access Frontend Application

```bash
# Get ALB DNS name
terraform output alb_dns_name

# Open in browser
http://<alb-dns-name>/
```

### Access Monitoring Services

Once the monitoring instance is deployed and Docker services initialize (5-15 minutes):

```bash
# Grafana Dashboard
http://3.212.99.113:3000
Username: admin
Password: <Your TF_VAR_grafana_password>

# Prometheus Metrics
http://3.212.99.113:9090

# AlertManager
http://3.212.99.113:9093
```

Or use Terraform outputs:

```bash
terraform output grafana_url
terraform output prometheus_url
terraform output alertmanager_url
```

### SSH to Bastion Host

```bash
# Get bastion IP
terraform output bastion_public_ip

# SSH using key pair
ssh -i /path/to/keypair.pem ec2-user@<bastion-public-ip>
```

### SSH to Application Server (via Bastion)

```bash
ssh -i /path/to/keypair.pem -J ec2-user@<bastion-ip> ec2-user@<app-server-private-ip>
```

### SSH to Monitoring Instance

```bash
# Option 1: Using stored command in Terraform
$(terraform output -raw monitoring_ssh_command)

# Option 2: Manual SSH
ssh -i ~/.ssh/3tier-app-key.pem ubuntu@<monitoring_instance_public_ip>
```

### Connect to RDS Database

```bash
# Get RDS endpoint
terraform output rds_endpoint

# Connect using psql
psql -h <rds-endpoint> -U postgres -d appdb
```

### Verify Services

```bash
# Check application health
curl -s http://<alb-dns-name>/health | jq .

# Check database connectivity
curl -s http://<alb-dns-name>/db-status | jq .

# Check monitoring instance
curl -s http://3.212.99.113:9090/-/healthy
curl -s http://3.212.99.113:3000/api/health
```

## Cost Optimization

- Use `t3.micro` and `t3.small` instance types for dev
- Enable auto-scaling to match demand
- Use NAT gateway only in one AZ (cross-AZ data transfer charges)
- Implement scheduled scaling for dev environments
- Monitor CloudWatch costs

## Troubleshooting

### Terraform Issues

**State Lock**: If Terraform is stuck in a lock:
```bash
terraform force-unlock <lock-id>
```

**Apply Failed**: Check error messages and review resource dependencies

**Variable Issues**:
```bash
# Verify required variables are set
terraform validate

# Check variable values
terraform plan -var-file=terraform.tfvars -var="debug=true"
```

### Monitoring Services Issues

**Services Not Accessible (Timeout)**:

1. Verify security group allows public access:
   ```bash
   aws ec2 describe-security-groups --group-ids sg-0be1b40626894576d --region us-east-1
   ```

2. Check if ports are listening:
   ```bash
   ssh -i ~/.ssh/3tier-app-key.pem ubuntu@<monitoring-ip>
   
   # Check listening ports
   sudo netstat -tlnp | grep -E '3000|9090|9093'
   
   # Check Docker containers
   docker ps -a
   docker logs <container-id>
   ```

3. Check Docker initialization:
   ```bash
   # View user data logs
   tail -100 /var/log/cloud-init-output.log
   tail -100 /var/log/user-data.log
   
   # Check if Docker is running
   systemctl status docker
   docker ps
   ```

4. Security Group Configuration:
   ```bash
   # Ensure these ports are open to 0.0.0.0/0:
   # Port 22 (SSH)
   # Port 3000 (Grafana)
   # Port 9090 (Prometheus)
   # Port 9093 (AlertManager)
   
   # Add missing rules if needed
   aws ec2 authorize-security-group-ingress \
     --group-id sg-0be1b40626894576d \
     --protocol tcp \
     --port 3000 \
     --cidr 0.0.0.0/0 \
     --region us-east-1
   ```

**Grafana Login Failed**:
- Verify `TF_VAR_grafana_password` was set before deployment
- Check environment variable is exported:
  ```bash
  echo $TF_VAR_grafana_password
  ```
- Reset password by logging into the instance and restarting Grafana:
  ```bash
  docker restart monitoring-deployment-grafana-1
  ```

**Prometheus Not Scraping Targets**:
```bash
# View Prometheus logs
docker logs monitoring-deployment-prometheus-1

# Check targets in Prometheus UI
curl -s http://3.212.99.113:9090/api/v1/targets | jq .

# Verify prometheus.yml configuration
docker exec monitoring-deployment-prometheus-1 cat /etc/prometheus/prometheus.yml
```

### Application Issues

**Health Check Failing**:
```bash
# Check ALB target group health
aws elbv2 describe-target-health --target-group-arn <arn>

# SSH to instance and check logs
sudo journalctl -u docker -n 100
docker logs <container-id>
```

**Database Connection Issues**:
```bash
# Check security group rules
# Verify database is running
# Test connection from bastion host
psql -h <rds-endpoint> -U postgres -d appdb
```

**Application Not Responding**:
```bash
# Check ALB target health
aws elbv2 describe-target-health \
  --target-group-arn <tg-arn> \
  --region us-east-1

# Verify application is running
aws ec2 describe-instances \
  --instance-ids <instance-id> \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].State'
```

### Monitoring Stack Issues

**AlertManager Not Sending Emails**:

1. Verify SMTP configuration:
   ```bash
   ssh -i ~/.ssh/3tier-app-key.pem ubuntu@<monitoring-ip>
   
   # Check alertmanager config
   cat /home/ubuntu/monitoring-deployment/alertmanager-config.yml
   
   # View AlertManager logs
   docker logs monitoring-deployment-alertmanager-1
   ```

2. Update configuration if needed:
   ```bash
   # Edit alertmanager config
   nano /home/ubuntu/monitoring-deployment/alertmanager-config.yml
   
   # Restart AlertManager
   docker restart monitoring-deployment-alertmanager-1
   ```

**Low Disk Space on Monitoring Instance**:
```bash
# Check disk usage
df -h

# Clean up old logs and data
docker system prune -a
docker volume prune

# Increase volume size (if needed)
# Requires stopping instance and resizing EBS volume
```

### Docker Issues

**Out of Memory**:
```bash
# Check docker stats
docker stats

# Increase instance size if needed (t3.large)
# Update terraform variables and reapply
```

**Network Connectivity**:
```bash
# Check if docker network exists
docker network ls

# Check container network settings
docker inspect <container-id> | jq '.[0].NetworkSettings'

# Restart docker daemon if needed
sudo systemctl restart docker
```

## Cleanup

### Destroy All Infrastructure

**Warning**: This will destroy all AWS resources including databases. Backups are recommended before cleanup.

```bash
cd terraform/environments/dev

# Review what will be destroyed
terraform plan -destroy -var-file=terraform.tfvars

# Destroy all resources
terraform destroy -var-file=terraform.tfvars
```

This will destroy:
- Application Load Balancer
- Auto-Scaling Group and EC2 instances
- RDS PostgreSQL database (Multi-AZ)
- Bastion host
- Monitoring instance and VPC
- VPCs, subnets, and networking
- Security groups and IAM roles
- EBS volumes and EIPs

### Destroy Only Monitoring Stack

If you want to keep the application but remove monitoring:

```bash
# Edit terraform/environments/dev/main.tf
# Comment out or remove the monitoring module instantiation

# Plan and apply
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

### Stop Monitoring Services (Without Destroying Infrastructure)

SSH into monitoring instance and stop Docker services:

```bash
ssh -i ~/.ssh/3tier-app-key.pem ubuntu@<monitoring-ip>

# Stop all Docker containers
docker-compose -C /home/ubuntu/monitoring-deployment down

# Optionally remove volumes
docker volume rm monitoring-deployment_prometheus_data
docker volume rm monitoring-deployment_grafana_data
docker volume rm monitoring-deployment_alertmanager_data
```

## Advanced Features

### Monitoring Module Configuration

The monitoring module can be customized via variables:

```hcl
# terraform/environments/dev/terraform.tfvars

# Monitoring instance sizing
monitoring_instance_type = "t3.medium"  # or t3.large for production
monitoring_root_volume_size = 50        # GB

# Network configuration
monitoring_vpc_cidr = "10.200.0.0/16"
monitoring_subnet_cidr = "10.200.2.0/24"  # Public subnet for public access

# Alert email recipients
alert_email_to = "ops-team@company.com"
alert_critical_email_to = "sre-oncall@company.com"

# SMTP server for AlertManager
smtp_host = "smtp.gmail.com"
smtp_port = 587
smtp_username = "your-email@gmail.com"

# Security
allowed_ssh_cidr_blocks = ["0.0.0.0/0"]  # Restrict in production
allowed_access_cidr_blocks = ["0.0.0.0/0"]  # Public access to ports 3000, 9090, 9093
```

### Disable Monitoring Module

To remove monitoring infrastructure:

1. Edit `terraform/environments/dev/main.tf`:
```hcl
# Comment out the monitoring module
# module "monitoring" {
#   ...
# }
```

2. Comment out monitoring outputs in `terraform/environments/dev/outputs.tf`

3. Apply changes:
```bash
terraform apply -var-file=terraform.tfvars
```

### State Backend Configuration (S3)

For production, use S3 for state storage:

Create `terraform/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

**Setup S3 backend:**

```bash
# Create S3 bucket and DynamoDB table
aws s3api create-bucket --bucket your-terraform-state-bucket --region us-east-1
aws s3api put-bucket-versioning --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1

# Migrate state
terraform init -migrate-state
```

### Add Production Environment

1. Create prod environment:
```bash
mkdir -p terraform/environments/prod
cp terraform/environments/dev/* terraform/environments/prod/
```

2. Update `terraform/environments/prod/terraform.tfvars`:
```hcl
environment = "prod"

# Larger instances
app_instance_type = "t3.medium"
rds_instance_class = "db.t3.small"
monitoring_instance_type = "t3.large"

# More redundancy
app_min_size = 3
app_max_size = 10
app_desired_capacity = 3

rds_multi_az = true
rds_allocated_storage = 100

# Enhanced monitoring
rds_enhanced_monitoring_interval = 60
```

3. Deploy:
```bash
cd terraform/environments/prod
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

### Custom Domain and HTTPS

1. Register domain (Route53 or external)

2. Request ACM certificate:
```bash
aws acm request-certificate \
  --domain-name example.com \
  --subject-alternative-names www.example.com \
  --validation-method DNS \
  --region us-east-1
```

3. Add Route53 record:
```bash
aws route53 create-resource-record-set \
  --hosted-zone-id <zone-id> \
  --change-batch file://route53-change.json
```

4. Update ALB listener to use HTTPS certificate

### Integrate with External Monitoring

**Send Prometheus metrics to external system:**

1. Update `user_data.sh` in monitoring module to configure remote write:

```yaml
# In prometheus.yml
remote_write:
  - url: "https://your-external-monitoring.com/api/v1/write"
    basic_auth:
      username: 'your-username'
      password: 'your-password'
```

2. Configure Grafana data source to point to external Prometheus

### Auto-Scaling Based on Metrics

Configure application auto-scaling based on CPU or memory:

```bash
# CPU-based scaling
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name <asg-name> \
  --policy-name scale-up-cpu \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration file://cpu-target.json
```

## Contributing

1. Create feature branch
2. Make changes
3. Test with `terraform plan`
4. Validate with `terraform validate` and `terraform fmt`
5. Create pull request
6. GitHub Actions will run security scans
7. Merge and auto-deploy to dev

## Project Documentation

Key documentation files included in the project:

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed architecture and design decisions
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Step-by-step deployment instructions
- **[CI_CD_SETUP_GUIDE.md](CI_CD_SETUP_GUIDE.md)** - GitHub Actions configuration
- **[GITHUB_SETUP_GUIDE.md](GITHUB_SETUP_GUIDE.md)** - GitHub repository setup
- **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** - Pre-deployment verification
- **[TERRAFORM_BEST_PRACTICES.md](TERRAFORM_BEST_PRACTICES.md)** - Terraform guidelines

## License

MIT License - See LICENSE file

## Support and Resources

### Documentation
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [AlertManager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)

### Troubleshooting Resources
- [AWS Documentation](https://docs.aws.amazon.com/)
- [Terraform CLI Docs](https://www.terraform.io/cli)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Workflows](https://docs.github.com/en/actions)

### Getting Help

For issues and questions:

1. **Check the troubleshooting section** - Most common issues are documented above
2. **Review logs**:
   - Terraform logs: `TF_LOG=DEBUG terraform apply`
   - CloudWatch logs: Check application logs via AWS Console
   - Docker logs: SSH to instance and run `docker logs <container>`
   - CloudInit logs: `/var/log/cloud-init-output.log` on instances

3. **Verify configuration**:
   - Run `terraform validate` to check syntax
   - Run `terraform plan` to review changes before applying
   - Check security group rules with AWS CLI

4. **GitHub Actions Workflow**:
   - Check workflow runs in GitHub Actions tab
   - Review job logs for errors
   - Verify environment variables and secrets are set

5. **AWS Health Dashboard**:
   - Check AWS service status for any outages
   - Verify IAM permissions are correct
   - Review CloudTrail logs for API calls

### Common Commands Reference

```bash
# Terraform
terraform init              # Initialize workspace
terraform validate          # Check configuration syntax
terraform fmt -recursive    # Format code
terraform plan              # Show planned changes
terraform apply             # Apply configuration
terraform destroy           # Destroy infrastructure
terraform output            # Show outputs
terraform state list        # List resources in state

# AWS CLI
aws ec2 describe-instances --region us-east-1
aws ec2 describe-security-groups --region us-east-1
aws rds describe-db-instances --region us-east-1
aws elbv2 describe-load-balancers --region us-east-1

# SSH
ssh -i ~/.ssh/keypair.pem ec2-user@<bastion-ip>
ssh -i ~/.ssh/keypair.pem ubuntu@<monitoring-ip>

# Docker
docker ps                   # List running containers
docker ps -a                # List all containers
docker logs <container>     # View container logs
docker exec -it <container> bash  # Enter container shell
```

### Monitoring Stack Quick Reference

**Monitoring Services:**
- Prometheus: http://3.212.99.113:9090
- Grafana: http://3.212.99.113:3000
- AlertManager: http://3.212.99.113:9093
- Node Exporter: http://3.212.99.113:9100/metrics

**Access monitoring instance:**
```bash
ssh -i ~/.ssh/3tier-app-key.pem ubuntu@3.212.99.113
```

**Monitor Docker services:**
```bash
docker ps                          # View running containers
docker logs -f <container-name>    # Follow logs
docker stats                       # View resource usage
docker-compose ps -a               # View all services
```

## References

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform.io/language/modules/develop)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

---

**Last Updated**: 2024
**Terraform Version**: >= 1.0
**AWS Provider Version**: >= 5.0
