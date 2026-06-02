terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment to use S3 backend
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# VPC Flow Logs for Network Monitoring
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-vpc-flow-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/flow-logs/${var.environment}"
  retention_in_days = 7

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-flow-logs-group"
    }
  )
}

resource "aws_iam_role" "flow_logs" {
  name_prefix = "${var.environment}-vpc-flow-logs-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "flow_logs" {
  name_prefix = "${var.environment}-vpc-flow-logs-"
  role        = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.flow_logs.arn}:*"
      }
    ]
  })
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  environment            = var.environment
  vpc_cidr               = var.vpc_cidr
  public_subnet_cidrs    = var.public_subnet_cidrs
  private_subnet_cidrs   = var.private_subnet_cidrs
  availability_zones     = var.availability_zones
  common_tags            = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security_groups"

  environment         = var.environment
  vpc_id              = module.vpc.vpc_id
  allowed_ssh_cidr    = var.allowed_ssh_cidr
  monitoring_cidr     = var.monitoring_cidr
  common_tags         = local.common_tags
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  environment           = var.environment
  engine                = var.engine
  engine_version        = var.engine_version
  instance_class        = var.rds_instance_class
  allocated_storage     = var.rds_allocated_storage
  storage_type          = var.rds_storage_type
  multi_az              = var.rds_multi_az
  db_name               = var.db_name
  master_username       = "postgres"  # PostgreSQL default username
  master_password       = var.master_password
  private_subnet_ids    = module.vpc.private_subnet_ids
  rds_security_group_id = module.security_groups.rds_sg_id
  backup_retention_period = var.backup_retention_period
  backup_window         = var.backup_window
  maintenance_window    = var.maintenance_window
  deletion_protection   = var.deletion_protection
  skip_final_snapshot   = var.skip_final_snapshot
  common_tags           = local.common_tags

  depends_on = [module.vpc, module.security_groups]
}

# IAM Role for EC2 Instances
resource "aws_iam_role" "ec2_role" {
  name_prefix = "${var.environment}-ec2-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach policies to EC2 role
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom policy for RDS access with specific ARNs
resource "aws_iam_role_policy" "rds_access" {
  name_prefix = "${var.environment}-rds-"
  role        = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = [module.rds.rds_arn]
      },
      {
        Effect = "Allow"
        Action = [

          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name_prefix = "${var.environment}-ec2-"
  role        = aws_iam_role.ec2_role.name
}

# Elastic IP for existing Bastion instance
# NOTE: Commenting out as the bastion instance ID doesn't exist in this account
# resource "aws_eip" "bastion" {
#   instance = "i-0668469d5315f698e"
#   domain   = "vpc"
#
#   tags = merge(
#     local.common_tags,
#     {
#       Name = "${var.environment}-bastion-eip"
#     }
#   )
# }

# Application Load Balancer
resource "aws_lb" "main" {
  name_prefix = "app"
  internal    = false
  load_balancer_type = "application"
  security_groups    = [module.security_groups.alb_sg_id]
  subnets            = module.vpc.public_subnet_ids

  enable_deletion_protection = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-alb"
    }
  )
}

# Target Group for Backend API
resource "aws_lb_target_group" "backend" {
  name_prefix = "api"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-backend-tg"
    }
  )
}

# ALB Listener - HTTP
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# EC2 Module for Application Servers
module "ec2" {
  source = "../../modules/ec2"

  environment            = var.environment
  instance_type          = var.app_instance_type
  private_subnet_ids     = module.vpc.private_subnet_ids
  app_security_group_id  = module.security_groups.app_server_sg_id

  # Security scanning: findings logged and monitored
}
  iam_instance_profile_arn = aws_iam_instance_profile.ec2_profile.arn
  db_endpoint            = module.rds.rds_address
  db_name                = var.db_name
  db_user                = var.master_username
  db_password            = var.master_password
  aws_region             = var.aws_region
  min_size               = var.app_min_size
  max_size               = var.app_max_size
  desired_capacity       = var.app_desired_capacity
  target_group_arns      = [aws_lb_target_group.backend.arn]
  common_tags            = local.common_tags

  depends_on = [module.vpc, module.security_groups, module.rds, aws_lb_target_group.backend]
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  project_name              = "3-tier-app"
  environment               = var.environment
  vpc_cidr                  = "10.200.0.0/16"
  monitoring_subnet_cidr    = "10.200.1.0/24"
  instance_type             = "t3.medium"
  root_volume_size          = 50
  key_pair_name             = var.key_pair_name
  allowed_ssh_cidr_blocks   = var.allowed_ssh_cidr
  allowed_access_cidr_blocks = [var.vpc_cidr]
  
  # SMTP Configuration
  smtp_host           = var.smtp_host != "" ? var.smtp_host : "smtp.gmail.com"
  smtp_port           = var.smtp_port
  smtp_username       = var.smtp_username != "" ? var.smtp_username : "your-email@gmail.com"
  alert_from_email    = var.alert_from_email != "" ? var.alert_from_email : "alerts@example.com"
  alert_email_to      = var.alert_email_to != "" ? var.alert_email_to : "ops@example.com"
  alert_critical_email_to = var.alert_critical_email_to != "" ? var.alert_critical_email_to : "oncall@example.com"
  
  grafana_password    = var.grafana_password
  alarm_actions       = []
  
  tags                = local.common_tags

  depends_on = [module.vpc, module.security_groups]
}
