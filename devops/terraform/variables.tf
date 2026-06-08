variable "aws_region" {
  description = "AWS region for the monitoring server."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used for provisioned resources."
  type        = string
  default     = "module8-devops"
}

variable "environment" {
  description = "Environment tag for cloud resources."
  type        = string
  default     = "assignment"
}

variable "instance_type" {
  description = "EC2 instance size."
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key" {
  description = "Public SSH key used to access the server."
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach SSH, Grafana, Prometheus, and the demo app."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
