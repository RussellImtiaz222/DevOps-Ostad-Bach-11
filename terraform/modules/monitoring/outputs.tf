# Output values from the monitoring module

output "monitoring_instance_id" {
  description = "ID of the monitoring EC2 instance"
  value       = aws_instance.monitoring.id
}

output "monitoring_instance_public_ip" {
  description = "Public IP address of the monitoring instance"
  value       = aws_eip.monitoring.public_ip
}

output "monitoring_instance_private_ip" {
  description = "Private IP address of the monitoring instance"
  value       = aws_instance.monitoring.private_ip
}

output "monitoring_security_group_id" {
  description = "ID of the monitoring security group"
  value       = aws_security_group.monitoring.id
}

output "monitoring_vpc_id" {
  description = "ID of the monitoring VPC"
  value       = aws_vpc.monitoring.id
}

output "monitoring_subnet_id" {
  description = "ID of the monitoring subnet"
  value       = aws_subnet.monitoring_public.id
}

output "prometheus_url" {
  description = "URL to access Prometheus"
  value       = "http://${aws_eip.monitoring.public_ip}:9090"
}

output "grafana_url" {
  description = "URL to access Grafana"
  value       = "http://${aws_eip.monitoring.public_ip}:3000"
}

output "alertmanager_url" {
  description = "URL to access AlertManager"
  value       = "http://${aws_eip.monitoring.public_ip}:9093"
}

output "node_exporter_url" {
  description = "URL to access Node Exporter metrics"
  value       = "http://${aws_eip.monitoring.public_ip}:9100/metrics"
}

output "monitoring_ssh_command" {
  description = "SSH command to connect to monitoring server"
  value       = "ssh -i /path/to/key ubuntu@${aws_eip.monitoring.public_ip}"
  sensitive   = false
}

output "iam_role_arn" {
  description = "ARN of the IAM role for monitoring instance"
  value       = aws_iam_role.monitoring.arn
}

output "access_summary" {
  description = "Summary of monitoring access endpoints"
  value = {
    prometheus_endpoint  = "http://${aws_eip.monitoring.public_ip}:9090"
    grafana_endpoint     = "http://${aws_eip.monitoring.public_ip}:3000 (default: admin/password)"
    alertmanager_endpoint = "http://${aws_eip.monitoring.public_ip}:9093"
    node_exporter_endpoint = "http://${aws_eip.monitoring.public_ip}:9100"
    ssh_access           = "ssh -i <key> ubuntu@${aws_eip.monitoring.public_ip}"
  }
}
