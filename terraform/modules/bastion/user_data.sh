#!/bin/bash
set -e

# Update system packages
yum update -y
yum install -y \
    git \
    docker \
    aws-cli \
    htop \
    curl \
    wget \
    net-tools \
    postgresql \
    jq

# Start Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Configure AWS CLI
aws configure set region ${region}

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

echo "Bastion host setup completed successfully!"
