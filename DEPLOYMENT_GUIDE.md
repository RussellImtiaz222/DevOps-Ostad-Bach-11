# Deployment Guide

This guide provides step-by-step instructions for deploying the 3-tier application infrastructure on AWS.

## Prerequisites Checklist

- [ ] AWS Account created and verified
- [ ] IAM user with EC2, VPC, RDS, ALB, IAM permissions
- [ ] AWS CLI installed and configured
- [ ] Terraform installed (v1.0+)
- [ ] EC2 Key Pair created in target AWS region
- [ ] GitHub account (for CI/CD)
- [ ] Docker and Docker Compose installed (for monitoring)
- [ ] Git installed

## Step 1: Prepare AWS Environment

### 1.1 Create IAM User (if needed)

```bash
# Create IAM user for deployment
aws iam create-user --user-name terraform-deployer

# Attach policies
aws iam attach-user-policy --user-name terraform-deployer \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Create access key
aws iam create-access-key --user-name terraform-deployer
```

Store the Access Key ID and Secret Access Key securely.

### 1.2 Create EC2 Key Pair

```bash
# Create key pair
aws ec2 create-key-pair --key-name my-terraform-key --region us-east-1 \
  --query 'KeyMaterial' --output text > ~/.ssh/my-terraform-key.pem

# Set permissions
chmod 400 ~/.ssh/my-terraform-key.pem

# Verify
aws ec2 describe-key-pairs --region us-east-1
```

### 1.3 Configure AWS CLI

```bash
aws configure
# Enter:
# - Access Key ID
# - Secret Access Key  
# - Default region: us-east-1
# - Default output format: json
```

Verify configuration:
```bash
aws sts get-caller-identity
```

## Step 2: Prepare Terraform Configuration

### 2.1 Clone or Download Project

```bash
cd /path/to/projects
git clone <repository-url>
cd Assignment\ on\ module\ 6\ \(Terraform\)
```

### 2.2 Create terraform.tfvars

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
aws_region              = "us-east-1"
environment             = "dev"
key_pair_name           = "my-terraform-key"  # Your EC2 key pair name
master_password         = "YourSecurePassword123!@"  # Generate a strong password

# Network configuration
vpc_cidr                = "10.0.0.0/16"
public_subnet_cidrs     = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs    = ["10.0.10.0/24", "10.0.11.0/24"]
availability_zones      = ["us-east-1a", "us-east-1b"]

# Allow SSH from your IP (security best practice)
allowed_ssh_cidr        = ["YOUR.IP.ADDRESS/32"]  # Or "0.0.0.0/0" for testing

# Database configuration
db_name                 = "appdb"
master_username         = "postgres"
rds_instance_class      = "db.t3.micro"
rds_allocated_storage   = 20
rds_multi_az            = true
engine                  = "postgres"
engine_version          = "15"

# Application configuration
app_instance_type       = "t3.small"
app_min_size            = 2
app_max_size            = 4
app_desired_capacity    = 2

# Bastion configuration
bastion_instance_type   = "t3.micro"

# Tags
common_tags = {
  Project     = "3-Tier-Application"
  Owner       = "DevOps-Team"
  Environment = "dev"
}
```

## Step 3: Deploy Infrastructure

### 3.1 Initialize Terraform

```bash
terraform init
```

This downloads the AWS provider and initializes the working directory.

**Output should show:**
```
Terraform has been successfully configured!
```

### 3.2 Format and Validate

```bash
# Format code for consistency
terraform fmt -recursive ../../

# Validate configuration
terraform validate
```

### 3.3 Review the Plan

```bash
terraform plan -var-file=terraform.tfvars -out=tfplan
```

This shows all resources that will be created. Review carefully:
- [ ] Correct number of instances
- [ ] Correct subnets and CIDR blocks
- [ ] Correct database settings
- [ ] Security groups configured properly

### 3.4 Apply Configuration

```bash
# Apply the plan
terraform apply tfplan
```

**Expected duration:** 15-20 minutes

**Important outputs will be displayed:**
- VPC ID
- Subnet IDs
- Bastion public IP
- ALB DNS name
- RDS endpoint

### 3.5 Save Outputs

```bash
# Save outputs to file for reference
terraform output -json > outputs.json

# Display specific outputs
terraform output alb_dns_name
terraform output bastion_public_ip
terraform output rds_address
```

## Step 4: Initialize Database

### 4.1 Connect to Bastion Host

```bash
ssh -i ~/.ssh/my-terraform-key.pem ec2-user@$(terraform output -raw bastion_public_ip)
```

### 4.2 Create Database Schema

From bastion host:

```bash
# Install PostgreSQL client
sudo yum install -y postgresql

# Connect to RDS
psql -h $(terraform output -raw rds_address) -U postgres -d appdb

# At PostgreSQL prompt, enter the password you set in terraform.tfvars
```

Then execute the database schema:

```sql
-- Create database
CREATE DATABASE IF NOT EXISTS appdb;
USE appdb;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create logs table
CREATE TABLE IF NOT EXISTS logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    level VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert sample data
INSERT INTO users (first_name, last_name, email) VALUES
('John', 'Doe', 'john@example.com'),
('Jane', 'Smith', 'jane@example.com');

-- Verify
SELECT * FROM users;
```

Type `exit` to disconnect from PostgreSQL.

## Step 5: Deploy Application

### 5.1 Verify Application Servers are Running

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=dev-app-asg-instance" \
  --query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,State.Name]' \
  --output table
```

### 5.2 Deploy Backend API

The backend application should be deployed via your CI/CD pipeline (GitHub Actions). If deploying manually:

```bash
# Connect to an application server through bastion
ssh -i ~/.ssh/my-terraform-key.pem \
  -J ec2-user@$(terraform output -raw bastion_public_ip) \
  ec2-user@<app-server-private-ip>

# Clone and deploy
git clone <backend-repo>
cd backend
pip3 install -r requirements.txt
python app.py
```

### 5.3 Deploy Frontend

Deploy frontend to a static hosting service or through ALB:

```bash
# The frontend is served through the ALB
# Copy files to the application servers and serve via HTTP
```

## Step 6: Test Application

### 6.1 Get ALB DNS Name

```bash
terraform output alb_dns_name
```

### 6.2 Access Application

Open browser and navigate to:
```
http://<alb-dns-name>
```

### 6.3 Test API Endpoints

```bash
# Health check
curl http://<alb-dns-name>/health

# Get system info
curl http://<alb-dns-name>/system-info

# Create user
curl -X POST http://<alb-dns-name>/users \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Test","last_name":"User","email":"test@example.com"}'

# List users
curl http://<alb-dns-name>/users

# Check database status
curl http://<alb-dns-name>/db-status
```

## Step 7: Setup GitHub Actions (Optional)

### 7.1 Fork Repository

Fork the repository to your GitHub account.

### 7.2 Add Secrets

Go to Settings → Secrets and variables → Actions

Add the following secrets:

| Secret Name | Value |
|---|---|
| AWS_ACCESS_KEY_ID | Your AWS access key |
| AWS_SECRET_ACCESS_KEY | Your AWS secret key |
| TF_VAR_MASTER_PASSWORD | Database password |
| SLACK_WEBHOOK_URL | (Optional) For notifications |

### 7.3 Configure Workflows

Edit `.github/workflows/terraform.yml`:
- Update `TF_VERSION` if needed
- Update `AWS_REGION`

Edit `.github/workflows/deploy.yml`:
- Update deployment configuration
- Add your Slack channel

### 7.4 Trigger Workflows

Push to main branch:
```bash
git add .
git commit -m "Initial infrastructure deployment"
git push origin main
```

Monitor GitHub Actions tab for workflow execution.

## Step 8: Setup Monitoring

### 8.1 Prepare Monitoring Stack

```bash
cd monitoring/grafana

# Run setup script
chmod +x setup.sh
./setup.sh

# Create .env file
cat > .env << 'EOF'
GRAFANA_PASSWORD=admin123!@
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=<your-access-key>
AWS_SECRET_ACCESS_KEY=<your-secret-key>
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
EOF
```

### 8.2 Start Monitoring Stack

```bash
docker-compose up -d
```

### 8.3 Access Grafana

Open browser:
```
http://localhost:3000
```

Login with:
- Username: `admin`
- Password: `admin123!@`

### 8.4 Import Dashboards

1. Create new dashboard
2. Add panels with queries:
   - EC2 CPU utilization
   - RDS connections
   - ALB request count
   - Application metrics

## Step 9: Verification Checklist

- [ ] VPC created with correct CIDR blocks
- [ ] Subnets are in correct AZs
- [ ] Internet Gateway and NAT Gateway are active
- [ ] Security groups have correct rules
- [ ] Bastion host is accessible via SSH
- [ ] Application servers are running in private subnets
- [ ] RDS database is in Multi-AZ
- [ ] ALB is passing health checks
- [ ] Frontend loads in browser
- [ ] Backend API responds to requests
- [ ] Database connectivity works
- [ ] Monitoring stack is collecting metrics
- [ ] GitHub Actions workflows are executing successfully

## Troubleshooting

### Terraform Init Failed

```bash
# Clear terraform cache
rm -rf .terraform
rm -f .terraform.lock.hcl

# Reinitialize
terraform init
```

### Apply Failed

```bash
# Check current state
terraform state list

# Refresh state
terraform refresh

# Review error message and fix configuration
terraform apply -var-file=terraform.tfvars
```

### Cannot Connect to Bastion

```bash
# Verify security group allows SSH
aws ec2 describe-security-groups --group-ids <sg-id>

# Verify key pair permissions
ls -la ~/.ssh/my-terraform-key.pem  # Should be 400

# Test connectivity
ping $(terraform output -raw bastion_public_ip)
```

### Database Connection Fails

```bash
# Verify RDS is running
aws rds describe-db-instances --db-instance-identifier dev-database

# Check security group
aws ec2 describe-security-groups --group-ids <rds-sg-id>

# Test from bastion
psql -h <rds-endpoint> -U postgres -d appdb
```

### Application Health Checks Failing

```bash
# SSH to app server through bastion
# Check application logs
docker logs <container-id>

# Check environment variables
env | grep DB_

# Verify database connectivity
python3 -c "import psycopg2; psycopg2.connect(host='<endpoint>', user='postgres', password='<password>', database='appdb')"
```

## Cost Estimation

Expected monthly costs for this setup (rough estimate):

| Resource | Type | Cost |
|----------|------|------|
| EC2 Instances | t3.small x 2 | ~$15 |
| Bastion | t3.micro | ~$5 |
| RDS | db.t3.micro + Multi-AZ | ~$40 |
| ALB | Application Load Balancer | ~$16 |
| Data Transfer | AWS data transfer | ~$5-10 |
| **Total** | | **~$80-100/month** |

*Costs vary by region. Use AWS Pricing Calculator for accurate estimates.*

## Next Steps

1. **Production Deployment**: Create prod environment with larger instances
2. **Auto Scaling**: Configure auto-scaling based on metrics
3. **Backup**: Enable automated backups and snapshots
4. **CDN**: Add CloudFront for frontend distribution
5. **Custom Domain**: Register domain and setup HTTPS
6. **Cost Optimization**: Review unused resources and right-size instances
7. **Security Hardening**: Implement WAF, VPC Flow Logs, GuardDuty

## Support

For issues:
1. Check troubleshooting section above
2. Review AWS CloudFormation/CloudTrail for detailed error logs
3. Check GitHub Actions logs for deployment errors
4. Review Terraform state for resource status

```bash
# Get detailed AWS error logs
aws cloudtrail lookup-events --max-results 10

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn <arn>

# View CloudWatch logs
aws logs tail /aws/lambda/function-name --follow
```

---

**Last Updated**: 2024
**Guide Version**: 1.0
