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
    jq \
    python3 \
    python3-pip

# Install pip packages
pip3 install --upgrade pip
pip3 install \
    flask \
    psycopg2-binary \
    boto3 \
    prometheus-client \
    requests

# Start Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Configure AWS CLI
aws configure set region ${region}

# Create application directory
mkdir -p /opt/app
cd /opt/app

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Store database credentials in environment file
cat > /etc/environment << EOF
DB_HOST=${db_endpoint}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
AWS_REGION=${region}
EOF

echo "Application server setup completed successfully!"
