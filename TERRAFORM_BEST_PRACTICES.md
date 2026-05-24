# Terraform Best Practices Implementation Guide

## Overview

This project demonstrates Terraform best practices through:
- Modular architecture with reusable components
- Clear separation of concerns
- Environment-specific configurations
- Comprehensive documentation
- Security-first approach
- CI/CD automation

## Project Structure

```
terraform/
├── environments/              # Environment-specific configurations
│   ├── dev/
│   │   ├── main.tf           # Root module orchestrating components
│   │   ├── variables.tf       # Variable definitions
│   │   ├── outputs.tf         # Output values
│   │   ├── terraform.tfvars   # Variable values (NOT in git)
│   │   ├── terraform.tfvars.example  # Example template
│   │   └── .terraform/        # Local state and plugins
│   │
│   └── staging/               # Staging environment (future)
│
└── modules/                   # Reusable infrastructure components
    ├── vpc/                   # VPC, subnets, gateways
    ├── security_groups/       # Security group configurations
    ├── ec2/                   # Application servers & ASG
    ├── rds/                   # Database infrastructure
    └── bastion/               # Bastion host (optional)
```

## Best Practice 1: Modular Architecture

### Why Modules?

✅ **Reusability** - Use same module for dev, staging, prod
✅ **Maintainability** - Single source of truth
✅ **Testability** - Module can be tested independently
✅ **Scalability** - Easy to add new environments

### Module Structure

Each module follows this pattern:

```
modules/vpc/
├── main.tf          # Primary resources
├── variables.tf     # Input variables
├── outputs.tf       # Output values
└── README.md        # Module documentation
```

### Example: VPC Module

```hcl
# modules/vpc/variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

# modules/vpc/outputs.tf
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}
```

## Best Practice 2: Variable Management

### Define Variables Clearly

```hcl
variable "instance_type" {
  description = "EC2 instance type for application servers"
  type        = string
  default     = "t3.medium"

  validation {
    condition     = can(regex("^t[3-4]\\.", var.instance_type))
    error_message = "Instance type must be t3 or t4 family."
  }
}
```

### Organize Variables

```hcl
# Group related variables with comments

# VPC Configuration
variable "vpc_cidr" { ... }
variable "public_subnet_cidrs" { ... }
variable "private_subnet_cidrs" { ... }

# Database Configuration
variable "db_engine_version" { ... }
variable "db_instance_class" { ... }
variable "db_allocated_storage" { ... }
```

### Use terraform.tfvars Properly

```hcl
# terraform/environments/dev/terraform.tfvars
environment         = "dev"
vpc_cidr            = "10.0.0.0/16"
instance_type       = "t3.medium"
db_instance_class   = "db.t3.micro"
db_allocated_storage = 20
```

**Important:** Never commit sensitive values!
```
# .gitignore
terraform.tfvars
terraform.tfvars.json
```

## Best Practice 3: Clear Outputs

### Document Outputs

```hcl
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
  sensitive   = false  # False for non-sensitive
}

output "rds_endpoint" {
  description = "RDS endpoint for application connection"
  value       = aws_db_instance.main.endpoint
  sensitive   = true   # True for passwords, keys
}
```

### Export Outputs

```bash
# View outputs after apply
terraform output

# Export specific output
terraform output alb_dns_name

# Export as JSON for CI/CD
terraform output -json > outputs.json
```

## Best Practice 4: State Management

### Local State (Development)

```bash
# terraform/environments/dev/
terraform init
terraform apply

# Creates terraform.tfstate
# Use only for development!
```

### Remote State (Production Ready)

```hcl
# terraform/environments/prod/main.tf
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### State Security

```bash
# Enable encryption
aws s3api put-bucket-encryption \
  --bucket company-terraform-state \
  --server-side-encryption-configuration '...'

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket company-terraform-state \
  --versioning-configuration Status=Enabled
```

## Best Practice 5: Resource Naming

### Consistent Naming Convention

```hcl
# Format: {environment}-{resource_type}-{purpose}

resource "aws_vpc" "main" {
  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_security_group" "alb" {
  name = "${var.environment}-alb-sg"
}

resource "aws_autoscaling_group" "app" {
  name = "${var.environment}-app-asg"
}
```

### Use Local Values

```hcl
# terraform/environments/dev/main.tf
locals {
  common_tags = {
    Environment = var.environment
    Project     = "3-Tier Application"
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }

  naming_prefix = "${var.environment}-app"
}

# Use in resources
resource "aws_instance" "web" {
  tags = merge(
    local.common_tags,
    {
      Name = "${local.naming_prefix}-web"
    }
  )
}
```

## Best Practice 6: Documentation

### Module README

```markdown
# VPC Module

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  environment     = "prod"
  vpc_cidr        = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| environment | string | - | Environment name |
| vpc_cidr | string | 10.0.0.0/16 | VPC CIDR block |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| public_subnet_ids | List of public subnet IDs |
```

### Code Comments

```hcl
# Create VPC with DNS enabled for container orchestration
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true  # Required for ECS
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}
```

## Best Practice 7: Error Handling & Validation

### Input Validation

```hcl
variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_count" {
  type = number

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}
```

### Depends On

```hcl
# Ensure explicit dependencies
resource "aws_autoscaling_group" "app" {
  depends_on = [
    aws_db_instance.main,
    aws_security_group.app,
  ]

  # ...
}
```

## Best Practice 8: Security

### Sensitive Data

```hcl
variable "db_password" {
  type      = string
  sensitive = true
  description = "RDS master password"
}

output "rds_endpoint" {
  value     = aws_db_instance.main.endpoint
  sensitive = true  # Masks in output
}
```

### Security Groups

```hcl
# Explicit inbound rules (deny by default)
resource "aws_security_group" "app" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.alb_security_group_cidr]
    description = "Allow HTTP from ALB only"
  }

  # Explicit deny outbound if needed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
}
```

### IAM Least Privilege

```hcl
data "aws_iam_policy_document" "app_server" {
  statement {
    sid    = "S3Access"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.app_data.arn,
      "${aws_s3_bucket.app_data.arn}/*",
    ]
  }
}
```

## Best Practice 9: Testing

### Validate Syntax

```bash
cd terraform/environments/dev
terraform fmt -check     # Check formatting
terraform validate       # Validate syntax
```

### Plan Review

```bash
terraform plan -out=tfplan
terraform show tfplan    # Review before apply
```

### Automated Testing

```bash
# Use Terraform Cloud / Enterprise
# Use TFLint for linting
# Use Checkov for security
# Use TFTest for integration tests
```

## Best Practice 10: CI/CD Integration

### GitHub Actions

```yaml
- name: Terraform Format
  run: terraform fmt -check

- name: Terraform Validate
  run: terraform validate

- name: Terraform Plan
  run: terraform plan -out=tfplan

- name: Checkov Scan
  run: checkov -d terraform/
```

## Checklist for Production

- [ ] Module documentation complete
- [ ] Variables validated with constraints
- [ ] Outputs documented and tested
- [ ] Remote state configured with encryption
- [ ] IAM policies follow least privilege
- [ ] Security groups explicitly defined
- [ ] Tags consistent across resources
- [ ] Backup/recovery tested
- [ ] Cost estimated and reviewed
- [ ] CI/CD pipeline automated
- [ ] Code reviewed by team
- [ ] Security scanning passed
- [ ] Disaster recovery plan documented

## Common Mistakes to Avoid

❌ **Hardcoding Values**
```hcl
# Bad
resource "aws_instance" "web" {
  instance_type = "t3.medium"  # Hardcoded
}

# Good
resource "aws_instance" "web" {
  instance_type = var.instance_type
}
```

❌ **Committing Secrets**
```hcl
# Bad - Never do this!
variable "db_password" {
  default = "MyPassword123!"
}

# Good
variable "db_password" {
  type = string
  # No default
}
```

❌ **Monolithic Code**
```hcl
# Bad - Everything in one file
resource "aws_vpc" "main" { ... }
resource "aws_subnet" "main" { ... }
resource "aws_instance" "web" { ... }
resource "aws_db_instance" "main" { ... }

# Good - Use modules
module "vpc" { ... }
module "ec2" { ... }
module "rds" { ... }
```

## Resources

- [Terraform Official Best Practices](https://www.terraform.io/language/basics/best-practices)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Registry Modules](https://registry.terraform.io/)
- [TerraForm Testing](https://developer.hashicorp.com/terraform/language/testing)
