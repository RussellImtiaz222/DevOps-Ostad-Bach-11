# Monitoring Module - Terraform

This Terraform module creates a complete monitoring infrastructure for the 3-Tier Application on AWS EC2.

## Components

- **EC2 Instance**: t3.medium (configurable) for hosting monitoring stack
- **VPC**: Isolated network for monitoring infrastructure
- **Security Group**: Configured with appropriate ingress/egress rules
- **IAM Role**: For CloudWatch access
- **Elastic IP**: Static IP for stable DNS resolution
- **CloudWatch Alarms**: For monitoring server health

## Monitored Services

- **Prometheus**: Time-series metrics database (port 9090)
- **Grafana**: Visualization and dashboarding (port 3000)
- **AlertManager**: Alert routing and management (port 9093)
- **Node Exporter**: System metrics collection (port 9100)

## Usage

### Basic Usage

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  project_name             = "3tier-app"
  environment              = "dev"
  key_pair_name            = "my-key-pair"
  alert_email_to           = "ops@example.com"
  alert_critical_email_to  = "oncall@example.com"
  smtp_username            = var.smtp_username
  grafana_password         = var.grafana_password
}

output "grafana_url" {
  value = module.monitoring.grafana_url
}
```

### Required Variables

- `project_name`: Name of the project
- `key_pair_name`: EC2 key pair for SSH access
- `alert_email_to`: Email address for regular alerts
- `alert_critical_email_to`: Email address for critical alerts
- `smtp_username`: SMTP username (sensitive)
- `grafana_password`: Grafana admin password (sensitive)

### Optional Variables

- `environment`: "dev" | "staging" | "prod" (default: "dev")
- `instance_type`: EC2 instance type (default: "t3.medium")
- `vpc_cidr`: VPC CIDR block (default: "10.200.0.0/16")
- `monitoring_subnet_cidr`: Subnet CIDR (default: "10.200.1.0/24")
- `root_volume_size`: Root volume size in GB (default: 30)
- `allowed_ssh_cidr_blocks`: CIDR blocks for SSH (default: ["0.0.0.0/0"])
- `allowed_access_cidr_blocks`: CIDR blocks for monitoring access (default: ["0.0.0.0/0"])
- `smtp_host`: SMTP server (default: "smtp.gmail.com")
- `smtp_port`: SMTP port (default: 587)

## Outputs

- `monitoring_instance_id`: EC2 instance ID
- `monitoring_instance_public_ip`: Public IP of monitoring server
- `prometheus_url`: URL to access Prometheus
- `grafana_url`: URL to access Grafana
- `alertmanager_url`: URL to access AlertManager
- `monitoring_ssh_command`: SSH command to connect to server

## Security Considerations

1. **Default Access**: All access (0.0.0.0/0) is allowed by default. Restrict in production:
   ```hcl
   allowed_access_cidr_blocks = ["YOUR_IP/32", "OFFICE_IP/32"]
   ```

2. **SMTP Password**: Always pass via environment variable or secure backend:
   ```bash
   export TF_VAR_smtp_password="your-app-password"
   ```

3. **Grafana Password**: Set a strong password and change it after deployment

4. **IAM Permissions**: Minimal permissions for CloudWatch access

## Deployment

### With GitHub Actions

The CI/CD pipeline automatically deploys monitoring stack:

```bash
git push origin main
# GitHub Actions will apply Terraform and deploy monitoring
```

### Manual Deployment

```bash
cd terraform/environments/dev

# Add monitoring module to main.tf
cat >> main.tf << 'EOF'
module "monitoring" {
  source = "../modules/monitoring"
  # ... variables ...
}
EOF

# Initialize and apply
terraform init
terraform plan
terraform apply

# Get outputs
terraform output
```

## Post-Deployment

1. **Access Grafana**:
   - URL: `terraform output grafana_url`
   - Username: admin
   - Password: (from TF_VAR_grafana_password)

2. **Configure Data Source**:
   - Settings → Data Sources → Add Prometheus
   - URL: http://prometheus:9090
   - Save & Test

3. **Test Email Alerts**:
   - Configure SMTP in AlertManager (already done via user_data)
   - Test with: `curl -X POST http://localhost:9093/api/v1/alerts ...`

4. **Configure Node Exporter on App Servers**:
   - Deploy Node Exporter on application servers
   - Add targets to Prometheus configuration
   - Restart Prometheus

## Monitoring the Monitoring Stack

Use CloudWatch Alarms configured in this module:

- `{project}-monitoring-high-cpu`: Alert when CPU > 80%
- `{project}-monitoring-status-check-failed`: Alert on instance failure

## Scaling

For production environments with high metrics volume:

1. **Increase Instance Type**:
   ```hcl
   instance_type = "t3.xlarge"
   ```

2. **Increase Volume Size**:
   ```hcl
   root_volume_size = 100
   ```

3. **Add Additional Prometheus Servers** (federation)

## Troubleshooting

### Services Not Starting
```bash
# SSH to monitoring server
ssh -i ~/.ssh/key ubuntu@$(terraform output -raw monitoring_instance_public_ip)

# Check Docker logs
docker-compose logs -f
```

### Can't Access Grafana
```bash
# Check security group
aws ec2 describe-security-groups --group-ids <sg-id>

# Verify instance is running
aws ec2 describe-instances --instance-ids <instance-id>
```

### SMTP Not Sending Emails
```bash
# Verify AlertManager configuration
docker-compose exec alertmanager cat /etc/alertmanager/alertmanager.yml

# Check logs
docker-compose logs alertmanager
```

## Cleanup

```bash
terraform destroy -target module.monitoring
# Answer 'yes' when prompted
```

## Cost Estimation

**Monthly Cost** (AWS US-EAST-1):
- EC2 t3.medium: ~$30
- Data Transfer: ~$5-10
- CloudWatch: ~$5-10
- **Total**: ~$40-50/month

## Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs)
- [Grafana Documentation](https://grafana.com/docs)
- [AlertManager Documentation](https://prometheus.io/docs/alerting/latest/)
- [Node Exporter Documentation](https://github.com/prometheus/node_exporter)
