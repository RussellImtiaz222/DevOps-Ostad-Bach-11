# Monitoring Stack Terraform Module
# This module creates all necessary resources for the monitoring infrastructure

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Get current AWS region
data "aws_region" "current" {}

# Get available zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create VPC (or use existing)
resource "aws_vpc" "monitoring" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-monitoring-vpc"
    Environment = var.environment
  }
}

# Create private subnet for monitoring
resource "aws_subnet" "monitoring_private" {
  vpc_id                  = aws_vpc.monitoring.id
  cidr_block              = var.monitoring_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-monitoring-private-subnet"
    Environment = var.environment
  }
}

# NAT Gateway for private subnet outbound access
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-monitoring-nat-eip"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.monitoring]
}

resource "aws_nat_gateway" "monitoring" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.monitoring_public.id

  tags = {
    Name        = "${var.project_name}-monitoring-nat"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.monitoring]
}

# Private route table
resource "aws_route_table" "monitoring_private" {
  vpc_id = aws_vpc.monitoring.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.monitoring.id
  }

  tags = {
    Name        = "${var.project_name}-monitoring-private-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "monitoring_private" {
  subnet_id      = aws_subnet.monitoring_private.id
  route_table_id = aws_route_table.monitoring_private.id
}

# Create public subnet for monitoring (for bastion access only)
resource "aws_subnet" "monitoring_public" {
  vpc_id                  = aws_vpc.monitoring.id
  cidr_block              = "10.200.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-monitoring-public-subnet"
    Environment = var.environment
  }
}

# Associate public route table with public subnet
resource "aws_route_table_association" "monitoring_public" {
  subnet_id      = aws_subnet.monitoring_public.id
  route_table_id = aws_route_table.monitoring_public.id
}

# Internet Gateway
resource "aws_internet_gateway" "monitoring" {
  vpc_id = aws_vpc.monitoring.id

  tags = {
    Name        = "${var.project_name}-monitoring-igw"
    Environment = var.environment
  }
}

# Route table for public subnet
resource "aws_route_table" "monitoring_public" {
  vpc_id = aws_vpc.monitoring.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.monitoring.id
  }

  tags = {
    Name        = "${var.project_name}-monitoring-rt"
    Environment = var.environment
  }
}

# Associate route table with public subnet
resource "aws_route_table_association" "monitoring_igw" {
  subnet_id      = aws_subnet.monitoring_public.id
  route_table_id = aws_route_table.monitoring_public.id
}

# Security group for monitoring
resource "aws_security_group" "monitoring" {
  name_prefix = "${var.project_name}-monitoring-"
  description = "Security group for monitoring stack"
  vpc_id      = aws_vpc.monitoring.id

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-monitoring-sg"
    Environment = var.environment
  }
}

# Ingress rules for monitoring
resource "aws_security_group_rule" "monitoring_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidr_blocks
  security_group_id = aws_security_group.monitoring.id
  description       = "SSH from authorized IPs"
}

resource "aws_security_group_rule" "monitoring_prometheus" {
  type              = "ingress"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  cidr_blocks       = var.allowed_access_cidr_blocks
  security_group_id = aws_security_group.monitoring.id
  description       = "Prometheus HTTP"
}

resource "aws_security_group_rule" "monitoring_grafana" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = var.allowed_access_cidr_blocks
  security_group_id = aws_security_group.monitoring.id
  description       = "Grafana HTTP"
}

resource "aws_security_group_rule" "monitoring_alertmanager" {
  type              = "ingress"
  from_port         = 9093
  to_port           = 9093
  protocol          = "tcp"
  cidr_blocks       = var.allowed_access_cidr_blocks
  security_group_id = aws_security_group.monitoring.id
  description       = "AlertManager HTTP"
}

resource "aws_security_group_rule" "monitoring_node_exporter" {
  type              = "ingress"
  from_port         = 9100
  to_port           = 9100
  protocol          = "tcp"
  cidr_blocks       = var.allowed_access_cidr_blocks
  security_group_id = aws_security_group.monitoring.id
  description       = "Node Exporter"
}

resource "aws_security_group_rule" "monitoring_cloudwatch_exporter" {
  type              = "ingress"
  from_port         = 9106
  to_port           = 9106
  protocol          = "tcp"
  cidr_blocks       = var.allowed_access_cidr_blocks
  security_group_id = aws_security_group.monitoring.id
  description       = "CloudWatch Exporter"
}

# IAM role for EC2 instance
resource "aws_iam_role" "monitoring" {
  name_prefix = "${var.project_name}-monitoring-"

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

  tags = {
    Name        = "${var.project_name}-monitoring-role"
    Environment = var.environment
  }
}

# IAM policy for CloudWatch access
resource "aws_iam_role_policy" "monitoring_cloudwatch" {
  name_prefix = "${var.project_name}-monitoring-cw-"
  role        = aws_iam_role.monitoring.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "rds:DescribeDBInstances",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetHealth"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = data.aws_region.current.name
          }
        }
      }
    ]
  })
}

# IAM instance profile
resource "aws_iam_instance_profile" "monitoring" {
  name_prefix = "${var.project_name}-monitoring-"
  role        = aws_iam_role.monitoring.name
}

# EC2 instance for monitoring
resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.monitoring_private.id
  iam_instance_profile   = aws_iam_instance_profile.monitoring.name
  vpc_security_group_ids = [aws_security_group.monitoring.id]

  # User data script to install Docker and monitoring stack
  user_data = base64encode(<<-EOF
#!/bin/bash
set -e
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting monitoring stack deployment..."

# Install Docker
apt-get update
apt-get install -y docker.io docker-compose curl wget git
usermod -aG docker ubuntu
systemctl start docker
systemctl enable docker

REPO_DIR="/home/ubuntu/monitoring-deployment"
mkdir -p $REPO_DIR
cd $REPO_DIR

# Create docker-compose.yml with all services
cat > docker-compose.yml << 'DOCKER_EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:v2.48.0
    user: root
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus_rules.yml:/etc/prometheus/rules/prometheus_rules.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
    ports:
      - "9090:9090"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9090/-/healthy"]
      interval: 30s
      timeout: 10s
      retries: 3

  grafana:
    image: grafana/grafana:10.2.0
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${var.grafana_password}
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
    ports:
      - "3000:3000"
    depends_on:
      - prometheus
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  node-exporter:
    image: prom/node-exporter:v1.7.0
    user: root
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9100/metrics"]
      interval: 30s
      timeout: 10s
      retries: 3

  alertmanager:
    image: prom/alertmanager:v0.26.0
    user: root
    volumes:
      - ./alertmanager-config.yml:/etc/alertmanager/alertmanager.yml
      - alertmanager_data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
    ports:
      - "9093:9093"
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
  alertmanager_data:
DOCKER_EOF

# Create prometheus configuration
cat > prometheus.yml << 'PROM_EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

rule_files:
  - /etc/prometheus/rules/prometheus_rules.yml

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets:
          - prometheus:9090

  - job_name: node-exporter
    static_configs:
      - targets:
          - node-exporter:9100

  - job_name: alertmanager
    static_configs:
      - targets:
          - alertmanager:9093
PROM_EOF

# Create alertmanager configuration
cat > alertmanager-config.yml << 'ALERT_EOF'
global:
  resolve_timeout: 5m
  smtp_smarthost: '${var.smtp_host}:${var.smtp_port}'
  smtp_auth_username: '${var.smtp_username}'
  smtp_require_tls: true

route:
  receiver: 'default-receiver'
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    - match:
        severity: critical
      receiver: 'critical-alerts'
      group_wait: 0s
      repeat_interval: 1h

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'cluster', 'service']

receivers:
  - name: 'default-receiver'
    email_configs:
      - to: '${var.alert_email_to}'
        from: '${var.alert_from_email}'
        smarthost: '${var.smtp_host}:${var.smtp_port}'
        auth_username: '${var.smtp_username}'
        require_tls: true
        headers:
          Subject: '[{{ .GroupLabels.severity | toUpper }}] {{ .GroupLabels.alertname }}'

  - name: 'critical-alerts'
    email_configs:
      - to: '${var.alert_critical_email_to}'
        from: '${var.alert_from_email}'
        smarthost: '${var.smtp_host}:${var.smtp_port}'
        auth_username: '${var.smtp_username}'
        require_tls: true
        headers:
          Subject: '🚨 CRITICAL: {{ .GroupLabels.alertname }}'
ALERT_EOF

# Create prometheus rules
cat > prometheus_rules.yml << 'RULES_EOF'
groups:
  - name: system_alerts
    interval: 30s
    rules:
      - alert: HighCPUUsage
        expr: node_cpu_seconds_total > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"

      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) > 0.85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"

      - alert: DiskSpaceRunningOut
        expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) < 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Disk space running out"
RULES_EOF

# Set correct permissions
chown -R ubuntu:ubuntu $REPO_DIR

# Start Docker services
cd $REPO_DIR
sudo -u ubuntu docker-compose up -d

echo "Monitoring stack deployment completed successfully!"
  EOF
  )

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.project_name}-monitoring-root"
    }
  }

  monitoring = true

  tags = {
    Name        = "${var.project_name}-monitoring-server"
    Environment = var.environment
    Service     = "monitoring"
  }

  depends_on = [aws_internet_gateway.monitoring]
}

# Elastic IP for monitoring instance
resource "aws_eip" "monitoring" {
  instance = aws_instance.monitoring.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-monitoring-eip"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.monitoring]
}

# CloudWatch alarms for monitoring server itself (DISABLED - requires cloudwatch:PutMetricAlarm IAM permission)
# Use Prometheus + Grafana for equivalent monitoring
# resource "aws_cloudwatch_metric_alarm" "monitoring_cpu" {
#   alarm_name          = "${var.project_name}-monitoring-high-cpu"
#   alarm_description   = "Alert when monitoring server CPU is high"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "2"
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/EC2"
#   period              = "300"
#   statistic           = "Average"
#   threshold           = "80"
#   treat_missing_data  = "notBreaching"
#
#   dimensions = {
#     InstanceId = aws_instance.monitoring.id
#   }
#
#   alarm_actions = var.alarm_actions
# }

# CloudWatch alarm for monitoring status check (DISABLED - requires cloudwatch:PutMetricAlarm IAM permission)
# Use Prometheus + Grafana for equivalent monitoring
# resource "aws_cloudwatch_metric_alarm" "monitoring_status_check" {
#   alarm_name          = "${var.project_name}-monitoring-status-check-failed"
#   alarm_description   = "Alert when monitoring server status check fails"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "StatusCheckFailed"
#   namespace           = "AWS/EC2"
#   period              = "60"
#   statistic           = "Sum"
#   threshold           = "1"
#   treat_missing_data  = "notBreaching"
#
#   dimensions = {
#     InstanceId = aws_instance.monitoring.id
#   }
#
#   alarm_actions = var.alarm_actions
# }

# Data sources
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_caller_identity" "current" {}
