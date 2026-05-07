# Troubleshooting Guide

## 🔧 Common Issues & Solutions

### Local Development Issues

#### Issue 1: Docker Containers Won't Start

**Symptoms:**
- `docker-compose up` fails
- Container exits immediately
- Port already in use errors

**Solutions:**

1. **Check Docker is running:**
   ```bash
   docker --version
   docker ps
   ```

2. **Free up ports:**
   ```bash
   # Find process using port 80
   lsof -i :80
   
   # Find process using port 3000
   lsof -i :3000
   
   # Find process using port 5432
   lsof -i :5432
   ```

3. **Remove stopped containers:**
   ```bash
   docker-compose down -v
   docker system prune -a
   ```

4. **Check logs:**
   ```bash
   docker-compose logs
   docker-compose logs backend
   docker-compose logs postgres
   ```

---

#### Issue 2: Cannot Connect to Database

**Symptoms:**
- "Cannot connect to postgres" errors
- Connection timeout
- Authentication failed

**Solutions:**

1. **Wait for database startup:**
   ```bash
   docker-compose ps
   # Wait until postgres shows "healthy"
   ```

2. **Check database credentials:**
   - Username: `postgres`
   - Password: `postgres123`
   - Database: `appdb`
   - Host: `postgres` (Docker DNS)

3. **Test database directly:**
   ```bash
   docker-compose exec postgres psql -U postgres -d appdb
   \dt  # List tables
   ```

4. **Reset database:**
   ```bash
   docker-compose down -v
   docker-compose up -d postgres
   sleep 10
   docker-compose up -d
   ```

---

#### Issue 3: Application Returns 503 Error

**Symptoms:**
- `503 Service Unavailable`
- Connection refused
- Load balancer shows unhealthy targets

**Solutions:**

1. **Check backend health:**
   ```bash
   curl -v http://localhost:3000/health
   curl -v http://localhost/health
   ```

2. **Check logs:**
   ```bash
   docker-compose logs backend
   docker-compose logs nginx
   ```

3. **Restart services:**
   ```bash
   docker-compose restart
   ```

4. **Check network:**
   ```bash
   docker network ls
   docker network inspect 3tierapp_3tier-network
   ```

---

### AWS Deployment Issues

#### Issue 1: CloudFormation Stack Creation Failed

**Symptoms:**
- Stack status: `CREATE_FAILED`
- Error in CloudFormation events

**Solutions:**

1. **Check stack events for error details:**
   ```bash
   aws cloudformation describe-stack-events \
     --stack-name my-3-tier-app \
     --region us-east-1 \
     --query 'StackEvents[0:10]'
   ```

2. **Common causes & fixes:**

   **a) IAM permissions insufficient:**
   ```bash
   # User needs:
   - ec2:*
   - rds:*
   - elasticloadbalancingv2:*
   - iam:*
   - vpc:*
   ```

   **b) Region limits exceeded:**
   ```bash
   # Switch region:
   aws cloudformation create-stack ... --region us-west-2
   ```

   **c) Duplicate stack name:**
   ```bash
   # List existing stacks:
   aws cloudformation list-stacks --region us-east-1
   ```

   **d) Template syntax error:**
   ```bash
   # Validate template:
   aws cloudformation validate-template \
     --template-body file://infrastructure/3-tier-stack.yaml
   ```

3. **Delete failed stack and retry:**
   ```bash
   aws cloudformation delete-stack --stack-name my-3-tier-app
   # Wait for deletion
   aws cloudformation wait stack-delete-complete --stack-name my-3-tier-app
   ```

---

#### Issue 2: EC2 Instances Not Starting

**Symptoms:**
- Instances show as "running" but not healthy
- Target Group shows "unhealthy"
- Cannot SSH to instance

**Solutions:**

1. **Check instance status:**
   ```bash
   aws ec2 describe-instances \
     --filters "Name=tag:Name,Values=production-web-server-*" \
     --query 'Reservations[*].Instances[*].[InstanceId,State.Name,StateTransitionReason]'
   ```

2. **Check system status:**
   ```bash
   aws ec2 describe-instance-status \
     --instance-ids i-1234567890abcdef0 \
     --include-all-instances
   ```

3. **Check user data logs:**
   ```bash
   # SSH to instance
   ssh -i your-key.pem ec2-user@<public-ip>
   
   # View initialization logs
   tail -f /var/log/cloud-init-output.log
   tail -f /var/log/messages
   ```

4. **Check Node.js application:**
   ```bash
   # On the instance
   ps aux | grep node
   cd /opt/app && npm list
   tail -f /var/log/nodejs.log
   ```

---

#### Issue 3: Cannot Access Application from Browser

**Symptoms:**
- Timeout when accessing ALB DNS
- Connection refused
- Page not found

**Solutions:**

1. **Get ALB DNS:**
   ```bash
   aws cloudformation describe-stacks \
     --stack-name my-3-tier-app \
     --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
     --output text
   ```

2. **Test ALB directly:**
   ```bash
   curl -v http://<alb-dns>/health
   ```

3. **Check ALB status:**
   ```bash
   # Get ALB ARN
   ALB_ARN=$(aws cloudformation describe-stacks \
     --stack-name my-3-tier-app \
     --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerArn`].OutputValue' \
     --output text)
   
   # Check ALB details
   aws elbv2 describe-load-balancers \
     --load-balancer-arns $ALB_ARN
   ```

4. **Check target health:**
   ```bash
   # Get target group ARN
   TG_ARN=$(aws elbv2 describe-target-groups \
     --load-balancer-arn $ALB_ARN \
     --query 'TargetGroups[0].TargetGroupArn' \
     --output text)
   
   # Check targets
   aws elbv2 describe-target-health \
     --target-group-arn $TG_ARN
   ```

5. **Check security groups:**
   ```bash
   # ALB security group should allow port 80
   aws ec2 describe-security-groups \
     --filters "Name=tag:Name,Values=production-alb-sg"
   
   # Web server security group should allow port 80 and 3000
   aws ec2 describe-security-groups \
     --filters "Name=tag:Name,Values=production-web-sg"
   ```

---

#### Issue 4: Database Connection Issues

**Symptoms:**
- API returns database connection errors
- `ECONNREFUSED` errors
- Timeout errors

**Solutions:**

1. **Check RDS status:**
   ```bash
   aws rds describe-db-instances \
     --db-instance-identifier production-postgres-db \
     --query 'DBInstances[0].[DBInstanceStatus,Endpoint.Address]'
   ```

2. **Test database connection from EC2:**
   ```bash
   # SSH to EC2 instance
   ssh -i your-key.pem ec2-user@<instance-ip>
   
   # Install PostgreSQL client
   sudo yum install -y postgresql
   
   # Test connection
   psql -h <db-endpoint> -U postgres -d appdb
   ```

3. **Check security group:**
   ```bash
   # Database security group should allow 5432 from web servers
   aws ec2 describe-security-groups \
     --filters "Name=tag:Name,Values=production-db-sg"
   ```

4. **Check database credentials:**
   ```bash
   # Check EC2 instance environment variables
   cat /opt/app/.env
   ```

5. **Verify database was initialized:**
   ```bash
   # SSH to RDS instance not possible, but:
   # Check CloudWatch logs
   aws logs tail /aws/rds/instance/production-postgres-db
   ```

---

### Performance Issues

#### Issue 1: High Latency / Slow Responses

**Symptoms:**
- API responses take >5 seconds
- ALB response time > 1000ms
- Database queries slow

**Solutions:**

1. **Check application logs:**
   ```bash
   docker-compose logs -f backend
   # Look for slow queries or errors
   ```

2. **Monitor AWS resources:**
   ```bash
   # EC2 CPU usage
   aws cloudwatch get-metric-statistics \
     --namespace AWS/EC2 \
     --metric-name CPUUtilization \
     --dimensions Name=InstanceId,Value=i-xxxx \
     --start-time 2024-01-01T00:00:00Z \
     --end-time 2024-01-01T01:00:00Z \
     --period 300 \
     --statistics Average
   
   # RDS database latency
   aws cloudwatch get-metric-statistics \
     --namespace AWS/RDS \
     --metric-name ReadLatency \
     --dimensions Name=DBInstanceIdentifier,Value=production-postgres-db \
     --start-time 2024-01-01T00:00:00Z \
     --end-time 2024-01-01T01:00:00Z \
     --period 300 \
     --statistics Average
   ```

3. **Add database indexes:**
   ```sql
   CREATE INDEX idx_users_email ON users(email);
   CREATE INDEX idx_users_created_at ON users(created_at DESC);
   ```

4. **Scale up resources:**
   - Change instance type from t3.micro to t3.small
   - Change RDS instance type from db.t3.micro to db.t3.small

---

#### Issue 2: High Memory Usage

**Symptoms:**
- Out of memory errors
- Application crashes
- Swap usage high

**Solutions:**

1. **Check application memory:**
   ```bash
   docker stats 3tier-backend
   ```

2. **Check Node.js heap:**
   ```bash
   # Add memory limit in Dockerfile
   ENV NODE_OPTIONS="--max-old-space-size=256"
   ```

3. **Restart application:**
   ```bash
   docker-compose restart backend
   ```

---

### Network & Connectivity Issues

#### Issue 1: VPC / Subnet Configuration Issues

**Solutions:**

1. **Verify VPC was created:**
   ```bash
   aws ec2 describe-vpcs \
     --filters "Name=tag:Name,Values=production-vpc"
   ```

2. **Check subnets:**
   ```bash
   aws ec2 describe-subnets \
     --filters "Name=tag:Name,Values=production-*"
   ```

3. **Verify routing:**
   ```bash
   aws ec2 describe-route-tables \
     --filters "Name=association.main,Values=false"
   ```

---

## 🔍 Debugging Commands

### Quick Diagnostics

```bash
#!/bin/bash

# Set variables
STACK_NAME="my-3-tier-app"
REGION="us-east-1"

echo "=== CloudFormation Stack ==="
aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --region $REGION \
  --query 'Stacks[0].StackStatus'

echo "=== EC2 Instances ==="
aws ec2 describe-instances \
  --filters "Name=tag:aws:cloudformation:stack-name,Values=$STACK_NAME" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,PrivateIpAddress]' \
  --region $REGION

echo "=== RDS Database ==="
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]' \
  --region $REGION

echo "=== Load Balancer ==="
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].[LoadBalancerName,State.Code,DNSName]' \
  --region $REGION

echo "=== Target Health ==="
TG_ARN=$(aws elbv2 describe-target-groups \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text --region $REGION)

aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --region $REGION

echo "=== Security Groups ==="
aws ec2 describe-security-groups \
  --filters "Name=tag:aws:cloudformation:stack-name,Values=$STACK_NAME" \
  --query 'SecurityGroups[*].[GroupName,GroupId]' \
  --region $REGION
```

---

## 🆘 Getting Help

### Collect Diagnostic Information

Before requesting help, collect:

1. **CloudFormation Stack Events:**
   ```bash
   aws cloudformation describe-stack-events \
     --stack-name my-3-tier-app \
     --region us-east-1 > stack-events.json
   ```

2. **Application Logs:**
   ```bash
   docker-compose logs > app-logs.txt
   # Or AWS CloudWatch Logs
   ```

3. **Resource Status:**
   ```bash
   aws ec2 describe-instance-status --instance-ids <id> > instance-status.json
   ```

4. **Error Messages:**
   - Browser console (F12)
   - CloudWatch Logs
   - Application logs

### AWS Support Resources

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [AWS Support Center](https://console.aws.amazon.com/support/)

---

## 📝 Issue Reporting Template

When reporting issues, include:

```
## Issue Title: [Concise description]

## Environment
- Local/AWS: [ ]
- OS: [ ]
- Docker version: [ ]
- AWS Region: [ ]

## Steps to Reproduce
1. [ ]
2. [ ]
3. [ ]

## Expected Behavior
[ ]

## Actual Behavior
[ ]

## Error Messages
[ ]

## Logs
[ ]

## Screenshots
[ ]

## Additional Context
[ ]
```

---

**For more help, see README.md, QUICKSTART.md, and ARCHITECTURE.md**
