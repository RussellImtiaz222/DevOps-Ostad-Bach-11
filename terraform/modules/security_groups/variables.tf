variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access to bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "monitoring_cidr" {
  description = "CIDR block for monitoring/prometheus access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}
