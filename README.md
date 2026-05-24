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
┌─────────────────────────────────────────────────────┐
│                   Internet (0.0.0.0/0)              │
└────────────────────────┬────────────────────────────┘
                         │ HTTP/HTTPS
                         ▼
        ┌────────────────────────────────┐
        │   Application Load Balancer    │
        │  (Public Subnets: Multi-AZ)    │
        └────────────────┬───────────────┘
                         │
        ┌────────────────┴───────────────┐
        ▼                                 ▼
    ┌─────────┐                     ┌─────────┐
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

Bastion Host for SSH Access (Public Subnet)
NAT Gateway for Private Subnet Outbound Access
```

## Directory Structure

```
.
├── terraform/
│   ├── modules/
│   │   ├── vpc/                 # VPC and networking
│   │   ├── security_groups/     # Security groups
│   │   ├── bastion/             # Bastion host
│   │   ├── ec2/                 # Application servers with ASG
│   │   └── rds/                 # RDS PostgreSQL database
│   └── environments/
│       └── dev/                 # Development environment
│           ├── main.tf
│           ├── variables.tf
│           ├── outputs.tf
│           └── terraform.tfvars.example
├── application/
│   ├── frontend/                # Static HTML/CSS/JS frontend
│   ├── backend/                 # Python Flask API
│   └── database/                # Database initialization scripts
├── .github/workflows/           # GitHub Actions CI/CD
│   ├── terraform.yml
│   └── deploy.yml
├── monitoring/grafana/          # Grafana and Prometheus setup
│   ├── docker-compose.yml
│   ├── prometheus.yml
│   ├── alertmanager.yml
│   └── dashboards/
└── README.md
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

### 2. Create terraform.tfvars

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:
- AWS region
- EC2 key pair name
- Database password
- Allowed SSH CIDR blocks

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan -var-file=terraform.tfvars
```

### 5. Apply the Configuration

```bash
terraform apply -var-file=terraform.tfvars
```

### 6. Get Outputs

```bash
terraform output
```

This will display:
- ALB DNS name
- Bastion host IP
- RDS endpoint
- ASG name

## Configuration

### Environment Variables

Create `.env` file in the project root:

```bash
export AWS_PROFILE=default
export AWS_REGION=us-east-1
export TF_VAR_master_password=YourSecurePassword123!@
```

### terraform.tfvars Example

```hcl
aws_region           = "us-east-1"
environment          = "dev"
key_pair_name        = "my-keypair"
master_password      = "SecurePassword123!@"

vpc_cidr              = "10.0.0.0/16"
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]
availability_zones    = ["us-east-1a", "us-east-1b"]

rds_instance_class    = "db.t3.micro"
rds_allocated_storage = 20
rds_multi_az          = true

app_instance_type    = "t3.small"
app_min_size         = 2
app_max_size         = 4
app_desired_capacity = 2

bastion_instance_type = "t3.micro"

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

### Setup Monitoring Stack

```bash
cd monitoring/grafana
chmod +x setup.sh
./setup.sh
```

Edit `.env` with AWS credentials and Slack webhook URL:

```bash
docker-compose up -d
```

### Access Monitoring

- **Grafana**: http://localhost:3000 (admin / admin123!@)
- **Prometheus**: http://localhost:9090
- **AlertManager**: http://localhost:9093

### Included Dashboards

- Infrastructure metrics (CPU, memory, network)
- Database performance (connections, storage, queries)
- ALB health and response times
- Application metrics
- Alert status

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

✅ **Modularity**: Separate modules for VPC, EC2, RDS, Security Groups
✅ **Environment Separation**: Dev environment with easy extension to prod
✅ **Variables & Outputs**: Clear input variables and outputs for each module
✅ **State Management**: Local state (configure S3 backend for production)
✅ **Security**:
   - Security groups with least privilege
   - Encrypted RDS storage
   - IAM roles for EC2 instances
   - No hardcoded credentials
   - Bastion host for private server access

✅ **High Availability**:
   - Multi-AZ deployment
   - Auto-scaling for application servers
   - RDS Multi-AZ
   - Application Load Balancer

✅ **Monitoring & Logging**:
   - CloudWatch metrics
   - Prometheus/Grafana dashboards
   - Application health checks
   - Auto-scaling alarms

✅ **Documentation**: Comprehensive comments and documentation
✅ **CI/CD Integration**: GitHub Actions workflows for infrastructure and app

## Accessing the Application

### Get ALB DNS Name

```bash
terraform output alb_dns_name
```

### Access Frontend

```
http://<alb-dns-name>/
```

### SSH to Bastion Host

```bash
ssh -i /path/to/keypair.pem ec2-user@<bastion-public-ip>
```

### SSH to Application Server (via Bastion)

```bash
ssh -i /path/to/keypair.pem -J ec2-user@<bastion-ip> ec2-user@<app-server-private-ip>
```

### Connect to RDS Database

```bash
psql -h <rds-endpoint> -U postgres -d appdb
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
psql -h <endpoint> -U postgres -d appdb
```

### Monitoring Issues

**Prometheus Not Scraping**:
- Check prometheus.yml targets
- Verify network connectivity
- Review Prometheus logs

**Grafana Dashboard Empty**:
- Verify Prometheus datasource connection
- Check CloudWatch exporter credentials
- Review Prometheus targets status

## Cleanup

### Destroy Infrastructure

```bash
cd terraform/environments/dev
terraform destroy -var-file=terraform.tfvars
```

### Stop Monitoring Stack

```bash
cd monitoring/grafana
docker-compose down
docker volume prune  # Remove volumes if needed
```

## Advanced Features

### State Backend Configuration (S3)

Create `terraform/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### Add Production Environment

1. Copy `terraform/environments/dev` to `terraform/environments/prod`
2. Update variables for production (larger instances, Multi-AZ, deletion protection)
3. Update terraform.tfvars with production values
4. Apply separately

### Custom Domain and HTTPS

1. Register domain in Route53 or external provider
2. Create ACM certificate
3. Add Route53 record for ALB
4. Update ALB listener with HTTPS

## Contributing

1. Create feature branch
2. Make changes
3. Test with `terraform plan`
4. Create pull request
5. GitHub Actions will validate
6. Merge and auto-deploy to dev

## License

MIT License - See LICENSE file

## Support

For issues and questions:
- Check the troubleshooting section
- Review Terraform and AWS documentation
- Check GitHub Actions logs for deployment errors
- Review application logs in CloudWatch

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
