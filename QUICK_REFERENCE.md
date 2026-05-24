# Quick Reference Guide

Quick commands and tips for managing the 3-tier application infrastructure.

## Terraform Quick Commands

### Initialize & Validate
```bash
cd terraform/environments/dev
terraform init                    # Initialize working directory
terraform fmt -recursive ../../   # Format code
terraform validate                # Validate configuration
```

### Planning & Application
```bash
terraform plan -var-file=terraform.tfvars                           # View planned changes
terraform apply -var-file=terraform.tfvars                          # Apply changes
terraform apply -auto-approve -var-file=terraform.tfvars            # Apply without prompt
terraform destroy -var-file=terraform.tfvars                        # Destroy infrastructure
terraform destroy -auto-approve -var-file=terraform.tfvars          # Destroy without prompt
```

### State Management
```bash
terraform state list                                # List all resources
terraform state show aws_instance.bastion           # Show specific resource
terraform state mv old_name new_name                # Rename resource
terraform state rm aws_security_group.example       # Remove resource
terraform state pull > backup.tfstate                # Backup state
terraform validate                                  # Validate current state
```

### Outputs
```bash
terraform output                           # Show all outputs
terraform output -json                     # JSON format
terraform output -raw alb_dns_name        # Get specific output value
```

### Targeting
```bash
terraform apply -target=module.vpc                            # Apply specific module
terraform apply -target=aws_db_instance.main                  # Apply specific resource
terraform destroy -target=aws_instance.bastion                # Destroy specific resource
```

## AWS CLI Commands

### EC2 Management
```bash
# List instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]' --output table

# Get instance details
aws ec2 describe-instances --instance-ids i-1234567890abcdef0

# Start/Stop/Reboot
aws ec2 start-instances --instance-ids i-1234567890abcdef0
aws ec2 stop-instances --instance-ids i-1234567890abcdef0
aws ec2 reboot-instances --instance-ids i-1234567890abcdef0

# Check security group
aws ec2 describe-security-groups --group-ids sg-12345678
```

### RDS Management
```bash
# List databases
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]' --output table

# Get database details
aws rds describe-db-instances --db-instance-identifier dev-database

# Create snapshot
aws rds create-db-snapshot --db-instance-identifier dev-database --db-snapshot-identifier dev-backup-$(date +%Y%m%d)

# List snapshots
aws rds describe-db-snapshots --query 'DBSnapshots[*].[DBSnapshotIdentifier,CreateTime]' --output table
```

### Load Balancer Management
```bash
# List ALBs
aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerName,DNSName,State.Code]' --output table

# Check target group health
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:...

# Describe target groups
aws elbv2 describe-target-groups --names dev-backend-tg
```

### Auto Scaling
```bash
# List Auto Scaling Groups
aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].[AutoScalingGroupName,MinSize,DesiredCapacity,MaxSize]' --output table

# Set desired capacity
aws autoscaling set-desired-capacity --auto-scaling-group-name dev-app-asg --desired-capacity 3

# Update ASG
aws autoscaling update-auto-scaling-group --auto-scaling-group-name dev-app-asg --max-size 5
```

## SSH & Access

### Connect to Bastion
```bash
BASTION_IP=$(terraform output -raw bastion_public_ip)
ssh -i ~/.ssh/my-key.pem ec2-user@$BASTION_IP
```

### Connect to Application Server (via Bastion)
```bash
APP_PRIVATE_IP=10.0.10.x  # Get from console or describe-instances
ssh -i ~/.ssh/my-key.pem -J ec2-user@$BASTION_IP ec2-user@$APP_PRIVATE_IP
```

### Copy Files via Bastion
```bash
scp -i ~/.ssh/my-key.pem -J ec2-user@$BASTION_IP local.file ec2-user@$APP_PRIVATE_IP:/tmp/
```

## Database Access

### Connect to RDS (from Bastion)
```bash
RDS_ENDPOINT=$(terraform output -raw rds_address)
psql -h $RDS_ENDPOINT -U postgres -d appdb
```

### Common PostgreSQL Commands
```sql
-- Show databases
\l

-- Connect to database
\c appdb

-- List tables
\dt

-- Describe table
\d users;

-- Count records
SELECT COUNT(*) FROM users;

-- Sample queries
SELECT * FROM users;
SELECT * FROM logs ORDER BY timestamp DESC LIMIT 10;
SELECT * FROM app_metrics WHERE metric_name='cpu_usage';
```

## API Testing

### Health Check
```bash
ALB_DNS=$(terraform output -raw alb_dns_name)
curl http://$ALB_DNS/health
```

### Create User
```bash
curl -X POST http://$ALB_DNS/users \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com"
  }'
```

### List Users
```bash
curl http://$ALB_DNS/users | jq
```

### Get Metrics
```bash
curl http://$ALB_DNS/metrics | head -20
```

## Monitoring Commands

### Start Monitoring Stack
```bash
cd monitoring/grafana
docker-compose up -d
```

### View Logs
```bash
docker-compose logs -f prometheus
docker-compose logs -f grafana
docker-compose logs -f alertmanager
```

### Stop Monitoring Stack
```bash
docker-compose down
```

### Access Monitoring URLs
```
Grafana: http://localhost:3000 (admin/admin123!@)
Prometheus: http://localhost:9090
AlertManager: http://localhost:9093
```

## Common Troubleshooting

### Reset Terraform State
```bash
rm -rf .terraform .terraform.lock.hcl
terraform init
terraform plan -var-file=terraform.tfvars
```

### Check Application Logs (from Bastion)
```bash
ssh -i ~/.ssh/my-key.pem ec2-user@$BASTION_IP
sudo journalctl -u docker -n 100
docker ps
docker logs <container-id>
```

### Verify Database
```bash
# From bastion
psql -h $RDS_ENDPOINT -U postgres -d appdb
postgres=> SELECT version();
postgres=> SELECT * FROM users LIMIT 5;
postgres=> \q
```

### Check ALB Health
```bash
aws elbv2 describe-target-health --target-group-arn <arn> --output table
```

### Force ASG Refresh
```bash
aws autoscaling start-instance-refresh --auto-scaling-group-name dev-app-asg
```

## Performance Commands

### CloudWatch Metrics
```bash
# CPU Utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

# RDS Connections
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=dev-database \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

## Backup & Recovery

### Create RDS Snapshot
```bash
aws rds create-db-snapshot \
  --db-instance-identifier dev-database \
  --db-snapshot-identifier dev-backup-$(date +%Y%m%d-%H%M%S)
```

### Backup Terraform State
```bash
tar czf terraform-state-backup-$(date +%Y%m%d).tar.gz terraform/
```

### Save Outputs to File
```bash
terraform output -json > infrastructure-outputs.json
```

## Scaling Commands

### Manual Scaling
```bash
# Set desired capacity to 3
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name dev-app-asg \
  --desired-capacity 3

# Set new max capacity
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name dev-app-asg \
  --max-size 6
```

### Scheduled Scaling (for cost savings in dev)
```bash
# Create scheduled action to scale down at night
aws autoscaling put-scheduled-action \
  --auto-scaling-group-name dev-app-asg \
  --scheduled-action-name scale-down-night \
  --start-time 2024-01-01T22:00:00Z \
  --recurrence "0 22 * * MON-FRI"
```

## Environment Variables

Set these for easier command execution:

```bash
export AWS_PROFILE=default
export AWS_REGION=us-east-1
export TF_VAR_environment=dev
export BASTION_IP=$(terraform output -raw bastion_public_ip)
export RDS_ENDPOINT=$(terraform output -raw rds_address)
export ALB_DNS=$(terraform output -raw alb_dns_name)
```

## Useful Aliases

Add to ~/.bashrc or ~/.zshrc:

```bash
# Terraform
alias tf=terraform
alias tfp='terraform plan -var-file=terraform.tfvars'
alias tfa='terraform apply -var-file=terraform.tfvars'
alias tfo='terraform output'

# AWS
alias ec2='aws ec2 describe-instances --query "Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,PublicIpAddress]" --output table'
alias rds='aws rds describe-db-instances --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]" --output table'

# SSH
alias bastion='ssh -i ~/.ssh/my-key.pem ec2-user@$(terraform output -raw bastion_public_ip)'

# Monitoring
alias grafana='open http://localhost:3000'
alias prometheus='open http://localhost:9090'
alias app='open http://$(terraform output -raw alb_dns_name)'
```

## Key Resources

- **Terraform State**: `terraform/environments/dev/terraform.tfstate`
- **Variables**: `terraform/environments/dev/terraform.tfvars`
- **Module Code**: `terraform/modules/*/`
- **Application**: `application/`
- **Monitoring**: `monitoring/grafana/`
- **CI/CD**: `.github/workflows/`

---

**Quick Reference v1.0** | Last Updated: 2024
