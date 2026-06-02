variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default = {
    Project = "3-Tier-Application"
  }
}

# VPC Variables
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# Security Group Variables
variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["10.0.0.0/8"] # Restrict to corporate network/VPN
}

variable "monitoring_cidr" {
  description = "CIDR block for monitoring access"
  type        = string
  default     = "10.0.0.0/16"
}

# RDS Variables
variable "engine" {
  description = "RDS engine"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "RDS engine version"
  type        = string
  default     = "15"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_storage_type" {
  description = "RDS storage type"
  type        = string
  default     = "gp3"
}

variable "rds_multi_az" {
  description = "Enable RDS Multi-AZ"
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "master_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "master_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  # Set this in terraform.tfvars or via environment variable TF_VAR_master_password
}

variable "backup_retention_period" {
  description = "RDS backup retention period"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "RDS backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "RDS maintenance window"
  type        = string
  default     = "mon:04:00-mon:05:00"
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot"
  type        = bool
  default     = false
}

# Bastion Variables
variable "bastion_instance_type" {
  description = "Bastion instance type"
  type        = string
  default     = "t3.micro"
}

variable "bastion_root_volume_size" {
  description = "Bastion root volume size"
  type        = number
  default     = 20
}

variable "key_pair_name" {
  description = "EC2 Key Pair name"
  type        = string
}

# Application Server Variables
variable "app_instance_type" {
  description = "Application server instance type"
  type        = string
  default     = "t3.small"
}

variable "app_min_size" {
  description = "Minimum number of app servers"
  type        = number
  default     = 2
}

variable "app_max_size" {
  description = "Maximum number of app servers"
  type        = number
  default     = 4
}

variable "app_desired_capacity" {
  description = "Desired number of app servers"
  type        = number
  default     = 2
}

# Monitoring Stack Variables
variable "smtp_host" {
  description = "SMTP host for email alerts"
  type        = string
  default     = ""
}

variable "smtp_port" {
  description = "SMTP port for email alerts"
  type        = number
  default     = 587
}

variable "smtp_username" {
  description = "SMTP username for email alerts"
  type        = string
  sensitive   = true
  default     = ""
}

variable "smtp_password" {
  description = "SMTP password for email alerts"
  type        = string
  sensitive   = true
  default     = ""
}

variable "alert_from_email" {
  description = "Email address to send alerts from"
  type        = string
  default     = ""
}

variable "alert_email_to" {
  description = "Email address(es) to send alerts to (comma-separated)"
  type        = string
  default     = ""
}

variable "alert_critical_email_to" {
  description = "Email address(es) for critical alerts (comma-separated)"
  type        = string
  default     = ""
}

variable "grafana_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "changeme"
}
