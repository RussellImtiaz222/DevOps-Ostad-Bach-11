output "bastion_id" {
  description = "Bastion instance ID"
  value       = aws_instance.bastion.id
}

output "bastion_private_ip" {
  description = "Bastion private IP address"
  value       = aws_instance.bastion.private_ip
}

output "bastion_public_ip" {
  description = "Bastion public IP address"
  value       = aws_eip.bastion.public_ip
}

output "bastion_dns_name" {
  description = "Bastion DNS name"
  value       = aws_instance.bastion.public_dns
}
