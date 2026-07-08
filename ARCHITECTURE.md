# Architecture Documentation

## System Architecture Overview

The 3-tier application architecture is designed for scalability, reliability, and security on AWS.

### Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                        │
│          Static HTML/CSS/JavaScript Frontend                │
│  (Served via ALB, cached by CloudFront - optional)          │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTP/HTTPS
                           ▼
    ┌──────────────────────────────────────┐
    │  APPLICATION LOAD BALANCER (ALB)     │
    │  - Public Subnets (Multi-AZ)         │
    │  - SSL/TLS Termination (optional)    │
    │  - Health Checks & Routing           │
    └──────────────┬───────────────────────┘
                   │ Port 8080
        ┌──────────┴──────────┐
        ▼                     ▼
    ┌─────────────────┐  ┌─────────────────┐
    │  APPLICATION    │  │  APPLICATION    │
    │  SERVER 1       │  │  SERVER 2       │
    │ (Private Subnet │  │ (Private Subnet │
    │ us-east-1a)     │  │ us-east-1b)     │
    │                 │  │                 │
    │ - Flask API     │  │ - Flask API     │
    │ - Database Conn │  │ - Database Conn │
    │ - Prometheus    │  │ - Prometheus    │
    └────────┬────────┘  └────────┬────────┘
             │                    │
             └──────────┬─────────┘
                        │ Port 5432
        ┌───────────────────────────────┐
        │      DATABASE LAYER           │
        │   RDS PostgreSQL Instance        │
        │  (Multi-AZ Deployment)        │
        │                               │
        │ - Primary DB (AZ-A)           │
        │ - Standby DB (AZ-B) - Sync    │
        │ - Automated Failover          │
        │ - Encrypted Storage           │
        │ - Automated Backups           │
        └───────────────────────────────┘
```

## Network Architecture

### VPC Design

- **VPC CIDR**: 10.0.0.0/16
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (Multi-AZ)
- **Private Subnets**: 10.0.10.0/24, 10.0.11.0/24 (Multi-AZ)

### Network Flow

```
Internet
   │
   ├─ HTTP (Port 80)
   ├─ HTTPS (Port 443)
   │
   ▼
Internet Gateway (IGW)
   │
   ├─ NAT Gateway (for private subnet outbound)
   │
   ▼
Route Tables
   │
   ├─ Public Route Table (0.0.0.0/0 → IGW)
   │   └─ Public Subnets
   │       ├─ Bastion Host
   │       └─ ALB
   │
   └─ Private Route Table (0.0.0.0/0 → NAT Gateway)
       └─ Private Subnets
           ├─ Application Servers (ASG)
           └─ RDS Database
```

### Security Groups

```
┌─────────────────────────────────────┐
│       Internet (0.0.0.0/0)          │
└─────────────────┬───────────────────┘
                  │ 80, 443
                  ▼
    ┌──────────────────────────┐
    │  ALB Security Group      │
    │  - Inbound: 80, 443      │
    │  - Outbound: All         │
    └──────────────┬───────────┘
                   │ 8080
                   ▼
    ┌──────────────────────────┐
    │  App Server SG           │
    │  - Inbound: 8080 (ALB)   │
    │  - Inbound: 22 (Bastion) │
    │  - Inbound: 9090 (Metrics│
    │  - Outbound: All         │
    └──────────────┬───────────┘
                   │ 3306
                   ▼
    ┌──────────────────────────┐
    │  RDS Security Group      │
    │  - Inbound: 3306 (App)   │
    │  - Outbound: All         │
    └──────────────────────────┘

Bastion Security Group
    - Inbound: 22 (User IP)
    - Outbound: All (→ App servers, RDS, NAT)
```

## Compute Architecture

### Bastion Host

- **Purpose**: Jump host for SSH access to private instances
- **Instance Type**: t3.micro
- **Availability**: Single instance (non-critical)
- **Elastic IP**: Static public IP for consistent access
- **Auto-install**: Docker, AWS CLI, database clients

**Security**: 
- SSH only from allowed CIDR (default: 0.0.0.0/0 for demo)
- In production: restrict to specific IPs

### Application Servers

- **Deployment**: Auto Scaling Group (ASG)
- **Instance Type**: t3.small (default, configurable)
- **Count**: 
  - Min: 2 (multi-AZ)
  - Max: 4 (auto-scale on high CPU)
  - Desired: 2
- **Availability**: Spread across 2 AZs

**Auto Scaling Policies**:
- Scale Up: CPU > 70% for 2 minutes
- Scale Down: CPU < 30% for 2 minutes
- Cooldown: 300 seconds

**Application Stack**:
- OS: Amazon Linux 2
- Runtime: Python 3.11
- Framework: Flask
- Database Driver: psycopg2
- Monitoring: Prometheus Client
- Health Check: /health endpoint (200 OK)

## Database Architecture

### RDS PostgreSQL Configuration

```
┌─────────────────────────────────────────┐
│           RDS PostgreSQL Instance        │
│  - Engine: PostgreSQL 15                │
│  - Instance Class: db.t3.micro          │
│  - Storage: 20 GB (GP3)                 │
│  - Backup Retention: 7 days             │
│  - Backup Window: 03:00-04:00 UTC       │
│  - Maintenance Window: Mon 04:00-05:00  │
│  - Encryption: Enabled (at rest)        │
│  - Multi-AZ: Enabled (synchronous)      │
│  - Performance Insights: Available       │
│  - Enhanced Monitoring: Available        │
│  - CloudWatch Logs: error, general,     │
│                     slowquery           │
└─────────────────────────────────────────┘
```

### Database Schema

```
appdb/
├── users
│   ├── id (INT, PK, AI)
│   ├── first_name (VARCHAR 100)
│   ├── last_name (VARCHAR 100)
│   ├── email (VARCHAR 255, UNIQUE)
│   ├── created_at (TIMESTAMP)
│   ├── updated_at (TIMESTAMP)
│   └── Indexes: email, created_at
│
├── logs
│   ├── id (INT, PK, AI)
│   ├── level (VARCHAR 20)
│   ├── message (TEXT)
│   ├── timestamp (TIMESTAMP)
│   └── Indexes: level, timestamp
│
├── app_metrics
│   ├── id (INT, PK, AI)
│   ├── metric_name (VARCHAR 255)
│   ├── metric_value (DECIMAL)
│   ├── timestamp (TIMESTAMP)
│   └── Indexes: metric_name, timestamp
│
└── user_activities
    ├── id (INT, PK, AI)
    ├── user_id (INT, FK)
    ├── activity_type (VARCHAR 100)
    ├── timestamp (TIMESTAMP)
    └── Indexes: user_id, timestamp
```

### Failover Architecture

```
Primary Instance (AZ-A)          Standby Instance (AZ-B)
┌──────────────────────────┐    ┌──────────────────────────┐
│   PostgreSQL Database    │    │   PostgreSQL Database    │
│   (Read/Write)           │◄──►│   (Standby)              │
│                          │    │                          │
│   - Data synchronized    │    │   - Replica in sync      │
│   - Active connections   │    │   - Automated promotion  │
│   - All transactions     │    │   - If primary fails     │
└──────────────────────────┘    └──────────────────────────┘
     │
     └─ Automatic Failover (< 2 minutes)
```

## Load Balancing Architecture

### Application Load Balancer

- **Type**: Application Load Balancer (ALB)
- **Availability**: Multi-AZ (public subnets)
- **Listeners**:
  - HTTP (80) → Backend TG (8080)
  - HTTPS (443) → Backend TG (8080) - optional

### Target Groups

```
Target Group: backend-api
├── Protocol: HTTP
├── Port: 8080
├── Health Check:
│   ├── Path: /health
│   ├── Interval: 30s
│   ├── Timeout: 3s
│   ├── Healthy Threshold: 2
│   └── Unhealthy Threshold: 2
├── Stickiness: Disabled
└── Targets: Auto Scaling Group
```

## Data Flow

### User Request Flow

```
1. User Browser
   ↓ HTTP GET /
2. Internet → IGW
   ↓
3. ALB (Public Subnet)
   - Receives request on port 80
   - Routes to healthy target on port 8080
   ↓
4. Application Server (Private Subnet)
   - Process request
   - Query database if needed
   ↓
5. RDS Database (Private Subnet)
   - Execute query
   - Return results
   ↓
6. Application Server
   - Render response
   ↓
7. ALB
   - Return response (200 OK)
   ↓
8. Internet → User Browser
   - Display response
```

## Monitoring Architecture

```
┌────────────────────────────────────────┐
│    Application & Infrastructure        │
├────────────────────────────────────────┤
│  Metrics:                              │
│  - CloudWatch (AWS native)             │
│  - Prometheus (/metrics endpoint)      │
│  - Custom metrics (app-specific)       │
└─────────┬──────────────────────────────┘
          │
          ▼
┌────────────────────────────────────────┐
│       Data Collection Layer            │
├────────────────────────────────────────┤
│  - CloudWatch Exporter                 │
│  - Prometheus Scraper                  │
│  - Node Exporter (optional)            │
└─────────┬──────────────────────────────┘
          │
          ▼
┌────────────────────────────────────────┐
│      Time-Series Database              │
├────────────────────────────────────────┤
│  - Prometheus (30-day retention)       │
│  - Alertmanager (rule evaluation)      │
└─────────┬──────────────────────────────┘
          │
          ▼
┌────────────────────────────────────────┐
│    Visualization & Alerting            │
├────────────────────────────────────────┤
│  - Grafana Dashboards                  │
│  - Grafana Alerts                      │
│  - Slack Notifications                 │
│  - CloudWatch Alarms                   │
└────────────────────────────────────────┘
```

### Monitored Metrics

#### Application Metrics
- HTTP request count
- HTTP request duration
- HTTP error rate
- Custom application metrics

#### Infrastructure Metrics
- EC2 CPU utilization
- EC2 memory usage
- EC2 network traffic (in/out)
- RDS CPU utilization
- RDS database connections
- RDS storage space
- ALB target health
- ALB response time

#### Database Metrics
- Active connections
- Query performance
- Slow query log
- Replication lag (Multi-AZ)
- Backup status

## Security Architecture

### Network Security

```
┌─────────────────────────────────┐
│     Internet (Untrusted)        │
└────────────────┬────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
    Bastion Host         ALB
    (Port 22)        (Ports 80, 443)
        │                 │
        ├─ Only SSH       └─ Only HTTP(S)
        │                     to backend
        │
        └──────────────────────────────┐
                                       │
                    ┌──────────────────┴──────┐
                    ▼                         ▼
            Application Servers          RDS Database
            (Port 8080 from ALB)          (Port 5432 from App)
            (Port 22 from Bastion)
            (Port 9090 Metrics)
```

### IAM Roles & Policies

```
EC2 Instance Role
├── Assume Policy
│   └─ Service: ec2.amazonaws.com
│
├── Attached Policies
│   ├─ AmazonSSMManagedInstanceCore
│   │  └─ Systems Manager access
│   │
│   ├─ CloudWatchAgentServerPolicy
│   │  └─ CloudWatch monitoring
│   │
│   └─ Custom: RDS Connect
│      └─ rds-db:connect on specific DB
│
└── Instance Profile
    └─ Attached to EC2 instances
```

### Data Security

- **At Rest**: 
  - EBS volumes encrypted (gp3)
  - RDS storage encrypted (AES-256)
  
- **In Transit**:
  - VPC for internal communication
  - SSL/TLS option for ALB
  - No data exposed on public internet

- **Access Control**:
  - Security groups (network firewall)
  - RDS IAM authentication
  - Database user credentials in environment variables

## Disaster Recovery

### Backup Strategy

```
Daily Automated Backups
├─ RDS Snapshots (7-day retention)
├─ Point-in-time recovery
├─ Stored in S3 (cross-region option)
└─ Manual snapshots before major changes

Application Code
├─ GitHub repository (version control)
├─ Docker images (registry)
└─ Immutable infrastructure (rebuild from code)

Configuration
├─ Terraform state (version controlled)
├─ terraform.tfvars (values tracked)
└─ Infrastructure as Code (reproducible)
```

### Failover Procedures

```
RDS Failover (Automatic)
├─ Primary failure detected (< 2 min)
├─ Standby promoted to primary
├─ Connection string remains same
├─ Application auto-reconnects
└─ No downtime for read/write

ALB Failover
├─ Target health check fails
├─ Route to healthy targets
├─ Scale up if needed (ASG)
└─ Minimal request loss

Multi-AZ Failover
├─ AZ-A unavailable
├─ Traffic switches to AZ-B
├─ Standby database promoted
└─ Bastion host redeploy if needed
```

## Performance Optimization

### Caching Strategy

```
Application Level
├─ Flask response caching
├─ Database query result caching
└─ In-memory caching (optional: Redis)

Content Delivery
├─ CloudFront (CDN) for static assets
├─ ALB keep-alive connections
└─ Compression (gzip)

Database Level
├─ Query optimization
├─ Connection pooling
├─ Slow query monitoring
└─ Index optimization
```

### Scaling Strategy

```
Vertical Scaling
├─ Larger instance types
├─ More CPU/Memory/Storage
└─ RDS: Resize DB instance

Horizontal Scaling
├─ Auto Scaling Group
├─ Add more application servers
├─ Read replicas (RDS - optional)
└─ Database sharding (future)
```

## Cost Optimization

### Resource Optimization

- Right-sized instances (t3.small, t3.micro)
- Auto-scaling (match demand)
- Reserved instances (for prod)
- Spot instances (for non-critical, optional)
- NAT gateway in single AZ (cost vs HA tradeoff)

### Monitoring & Cleanup

- CloudWatch cost monitor
- Unused resource detection
- Right-sizing recommendations
- Scheduled scaling for dev environments

## High Availability Checklist

- [x] Multi-AZ deployment
- [x] Load balancer
- [x] Auto-scaling groups
- [x] RDS Multi-AZ with failover
- [x] Security groups with least privilege
- [x] Health checks
- [x] Automated backups
- [x] Monitoring and alerting
- [x] Bastion host for secure access
- [x] Encrypted storage

## References

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [AWS VPC Security](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security.html)
- [ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)

---

**Last Updated**: 2024
**Version**: 1.0
