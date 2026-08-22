# AWS EC2 IAM & Security Assignment

This assignment demonstrates a secure AWS EC2 configuration using:
- a custom security group
- an IAM user and policy for administrative control
- an IAM role for EC2 instance access to S3
- Linux hardening with SSH tuning and UFW
- verification that S3 access works without static access keys

## Objectives

1. Launch one EC2 instance in a VPC.
2. Restrict inbound network access with a security group.
3. Create and attach an IAM role that allows S3 access to the EC2 instance.
4. Validate that the EC2 instance can access S3 using the instance role instead of access keys.
5. Harden Linux SSH access and firewall settings.

---

## Architecture

- EC2 instance: Ubuntu 22.04 LTS
- Security group: allows SSH only from a trusted admin IP
- IAM user: used for human/admin actions
- IAM role: attached to the EC2 instance for S3 access
- S3 bucket: used to verify read/write access via the attached role

---

## Prerequisites

- AWS account with permissions to create EC2, IAM, S3 resources
- Existing VPC and subnet in the target region
- SSH key pair created in AWS EC2
- Your public IP address or office VPN IP for SSH
- AWS CLI installed on the EC2 instance

---

## 1) Create the IAM User and Policy

Create a dedicated IAM user for administrative work, such as `module17-admin`.

### Example IAM policy for admin actions

This policy grants only the permissions needed for resource creation and management:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EC2Access",
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:DescribeInstances",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs",
        "ec2:CreateKeyPair",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMRoleAccess",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:PutRolePolicy",
        "iam:AttachRolePolicy",
        "iam:PassRole",
        "iam:GetRole",
        "iam:ListRoles"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3BucketAccess",
      "Effect": "Allow",
      "Action": [
        "s3:ListAllMyBuckets",
        "s3:GetBucketLocation",
        "s3:CreateBucket",
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": "*"
    }
  ]
}
```

### Steps

- In AWS Console: IAM > Users > Add user
- Username: `module17-admin`
- Access type: Programmatic access (for CLI use) or console access if needed
- Attach the policy above
- Save the Access Key ID and Secret Access Key securely

> Important: do not use these keys on the EC2 instance. The instance should rely on an IAM role instead.

---

## 2) Create the IAM Role for EC2 -> S3 Access

Create a role named `EC2S3ReadWriteRole` with a trust relationship that allows EC2 instances to assume it.

### Trust policy

See the file [config/iam-role-trust-policy.json](config/iam-role-trust-policy.json).

### S3 access policy

See the file [config/iam-role-s3-policy.json](config/iam-role-s3-policy.json).

This example policy allows:
- `s3:ListBucket`
- `s3:GetBucketLocation`
- `s3:GetObject`
- `s3:PutObject`
- `s3:DeleteObject`

> Keep permissions restricted to a specific bucket when possible.

### AWS CLI example

```bash
aws iam create-role \
  --role-name EC2S3ReadWriteRole \
  --assume-role-policy-document file://config/iam-role-trust-policy.json

aws iam put-role-policy \
  --role-name EC2S3ReadWriteRole \
  --policy-name EC2S3AccessPolicy \
  --policy-document file://config/iam-role-s3-policy.json
```

Then attach the role to the EC2 instance as an instance profile or via Instance Settings > Attach/Replace IAM Role.

---

## 3) Launch the EC2 Instance

### Recommended settings

- AMI: Ubuntu Server 22.04 LTS
- Instance type: `t3.micro` or similar free-tier eligible size
- Key pair: use the key you created earlier
- VPC/subnet: default or your assigned subnet
- IAM role: `EC2S3ReadWriteRole`

### Example AWS CLI launch command

```bash
aws ec2 run-instances \
  --image-id ami-0c02fb55956c7d316 \
  --count 1 \
  --instance-type t3.micro \
  --key-name module17-key \
  --security-group-ids sg-0123456789abcdef0 \
  --subnet-id subnet-0123456789abcdef0 \
  --iam-instance-profile Name=EC2S3ReadWriteRole
```

> Replace the AMI ID, subnet ID, key name, and security group ID with the values from your AWS environment.

---

## 4) Configure the Security Group

Use a restrictive inbound policy.

### Security group rules

See [config/security-group-rules.json](config/security-group-rules.json).

Recommended rules:
- Inbound SSH (TCP 22) from your office/public IP only
- All outbound traffic allowed
- No open ports to the world except the one required for SSH

### Example AWS CLI rule

```bash
aws ec2 authorize-security-group-ingress \
  --group-id sg-0123456789abcdef0 \
  --protocol tcp \
  --port 22 \
  --cidr 203.0.113.10/32
```

This ensures only your admin workstation can reach the instance over SSH.

---

## 5) Linux Security Hardening

Connect to the instance using SSH:

```bash
chmod 600 your-key.pem
ssh -i your-key.pem ubuntu@PUBLIC_IP
```

### Harden SSH

Edit `/etc/ssh/sshd_config`:

```bash
sudo nano /etc/ssh/sshd_config
```

Recommended settings:

```bash
Port 22
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
AllowUsers ubuntu
```

Then reload SSH:

```bash
sudo systemctl reload sshd
```

### Enable UFW

```bash
sudo apt update
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw enable
sudo ufw status verbose
```

If you want to move SSH to a different port, change it in `sshd_config` and update the firewall rule.

---

## 6) Verify S3 Access from EC2 Without Access Keys

Once the instance role is attached, the EC2 instance can access AWS credentials via the metadata service at `http://169.254.169.254/latest/meta-data/iam/security-credentials/` and the role credentials are automatically provided.

### Install AWS CLI

```bash
sudo apt update
sudo apt install -y awscli
```

### Verify identity and permissions

```bash
aws sts get-caller-identity
aws s3 ls
```

Expected result:
- the ARN should show the EC2 instance role rather than an IAM user access key
- the S3 listing should succeed without any environment variables such as `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY`

### Test read/write access

```bash
aws s3 mb s3://module17-demo-bucket-12345 --region us-east-1
aws s3 cp /etc/os-release s3://module17-demo-bucket-12345/os-release.txt
aws s3 ls s3://module17-demo-bucket-12345
aws s3 cp s3://module17-demo-bucket-12345/os-release.txt /tmp/os-release.txt
cat /tmp/os-release.txt
```

### Verification script

See [scripts/verify-s3-role-access.sh](scripts/verify-s3-role-access.sh).

---

## 7) Security Notes

- Never store access keys on EC2 instances when a role is available
- Restrict IAM policies to least privilege
- Use security groups to lock down ports and source IPs
- Disable direct root SSH and password login
- Keep operating system packages updated
- Review CloudTrail logs and IAM access logs periodically

---

## 8) Final Deliverable Checklist

Your assignment submission should include:
- one EC2 instance launched
- a security group restricting SSH access
- one IAM user with administrative policy
- one IAM role attached to the EC2 instance for S3 access
- proof that S3 access works without access keys
- hardened SSH/UFW configuration notes
- README documentation and supporting configuration files

---

## Useful Reference Commands

```bash
# Check metadata role in EC2
curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/

# Show temporary credentials used by the instance
aws sts get-caller-identity

# List all S3 buckets
aws s3 ls

# Upload a file to S3
aws s3 cp /tmp/test.txt s3://my-bucket/test.txt

# Download a file from S3
aws s3 cp s3://my-bucket/test.txt /tmp/test.txt
```

---

## Assignment Summary

This setup teaches the core AWS security model:
- IAM users are for people and administrative access
- IAM roles are for AWS services such as EC2 to access resources securely
- security groups control network access
- Linux hardening reduces the risk of SSH and server compromise
- temporary credentials from the EC2 metadata service remove the need for static keys
