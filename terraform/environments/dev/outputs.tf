output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ip" {
  description = "NAT Gateway IP"
  value       = module.vpc.nat_gateway_ip
}

output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = "Not assigned - bastion instance not found in this account"
}

output "bastion_private_ip" {
  description = "Bastion host private IP"
  value       = "172.31.46.173"
}

output "bastion_instance_id" {
  description = "Bastion instance ID"
  value       = "i-0668469d5315f698e"
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.rds_endpoint
  sensitive   = true
}

output "rds_address" {
  description = "RDS address"
  value       = module.rds.rds_address
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds.rds_port
}

output "asg_name" {
  description = "Application server ASG name"
  value       = module.ec2.asg_name
}

# Monitoring Stack Outputs
output "monitoring_instance_id" {
  description = "Monitoring server instance ID"
  value       = module.monitoring.monitoring_instance_id
}

output "monitoring_instance_public_ip" {
  description = "Monitoring server public IP address"
  value       = module.monitoring.monitoring_instance_public_ip
}

output "monitoring_instance_private_ip" {
  description = "Monitoring server private IP address"
  value       = module.monitoring.monitoring_instance_private_ip
}

output "monitoring_security_group_id" {
  description = "Monitoring server security group ID"
  value       = module.monitoring.monitoring_security_group_id
}

output "prometheus_url" {
  description = "Prometheus dashboard URL"
  value       = "http://${module.monitoring.monitoring_instance_public_ip}:9090"
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://${module.monitoring.monitoring_instance_public_ip}:3000"
}

output "alertmanager_url" {
  description = "AlertManager dashboard URL"
  value       = "http://${module.monitoring.monitoring_instance_public_ip}:9093"
}

output "monitoring_ssh_command" {
  description = "SSH command to access monitoring server"
  value       = "ssh -i ~/.ssh/3tier-app-key.pem ubuntu@${module.monitoring.monitoring_instance_public_ip}"
}
