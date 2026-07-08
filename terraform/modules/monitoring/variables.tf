# Input variables for the monitoring module

variable "project_name" {
  description = "Project name"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{1,30}$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric with hyphens, max 30 characters."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for monitoring VPC"
  type        = string
  default     = "10.200.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "monitoring_subnet_cidr" {
  description = "CIDR block for monitoring subnet"
  type        = string
  default     = "10.200.1.0/24"
  validation {
    condition     = can(cidrhost(var.monitoring_subnet_cidr, 0))
    error_message = "Subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "instance_type" {
  description = "EC2 instance type for monitoring server"
  type        = string
  default     = "t3.medium"
  validation {
    condition     = can(regex("^t[3-4]\\.", var.instance_type)) || can(regex("^m[5-7]\\.", var.instance_type))
    error_message = "Instance type must be t3, t4, m5, m6, or m7 family."
  }
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
  validation {
    condition     = var.root_volume_size >= 20 && var.root_volume_size <= 1000
    error_message = "Root volume size must be between 20 and 1000 GB."
  }
}

variable "key_pair_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  validation {
    condition     = length(var.key_pair_name) > 0
    error_message = "Key pair name must not be empty."
  }
}

variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  validation {
    condition = alltrue([
      for cidr in var.allowed_ssh_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid IPv4 CIDR notation."
  }
}

variable "allowed_access_cidr_blocks" {
  description = "CIDR blocks allowed for monitoring access (Prometheus, Grafana, etc.)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  validation {
    condition = alltrue([
      for cidr in var.allowed_access_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid IPv4 CIDR notation."
  }
}

# SMTP Configuration
variable "smtp_host" {
  description = "SMTP server hostname"
  type        = string
  default     = "smtp.gmail.com"
  validation {
    condition     = length(var.smtp_host) > 0
    error_message = "SMTP host must not be empty."
  }
}

variable "smtp_port" {
  description = "SMTP server port"
  type        = number
  default     = 587
  validation {
    condition     = var.smtp_port > 0 && var.smtp_port <= 65535
    error_message = "SMTP port must be between 1 and 65535."
  }
}

variable "smtp_username" {
  description = "SMTP username/email address (set via environment variable)"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.smtp_username) > 0
    error_message = "SMTP username must not be empty."
  }
}

variable "alert_from_email" {
  description = "Email address for alert sender"
  type        = string
  default     = "alerts@example.com"
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_from_email))
    error_message = "Alert from email must be a valid email address."
  }
}

variable "alert_email_to" {
  description = "Email address for alerts"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email_to))
    error_message = "Alert email must be a valid email address."
  }
}

variable "alert_critical_email_to" {
  description = "Email address for critical alerts (oncall, etc.)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_critical_email_to))
    error_message = "Critical alert email must be a valid email address."
  }
}

variable "grafana_password" {
  description = "Grafana admin password (set via environment variable)"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.grafana_password) >= 8
    error_message = "Grafana password must be at least 8 characters."
  }
}

variable "alarm_actions" {
  description = "SNS topic ARNs for CloudWatch alarms"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
