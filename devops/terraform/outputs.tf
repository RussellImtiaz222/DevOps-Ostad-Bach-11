output "server_public_ip" {
  description = "Public IP address of the provisioned monitoring server."
  value       = aws_instance.monitoring_server.public_ip
}

output "ssh_command" {
  description = "SSH command for the provisioned server."
  value       = "ssh ubuntu@${aws_instance.monitoring_server.public_ip}"
}

output "grafana_url" {
  description = "Grafana URL."
  value       = "http://${aws_instance.monitoring_server.public_ip}:3000"
}

output "prometheus_url" {
  description = "Prometheus URL."
  value       = "http://${aws_instance.monitoring_server.public_ip}:9090"
}
