#!/bin/bash
# Monitoring setup script for Docker-based Grafana stack

set -e

echo "Setting up Grafana monitoring stack..."

# Create directories if they don't exist
mkdir -p grafana/provisioning/datasources
mkdir -p grafana/provisioning/dashboards
mkdir -p grafana/dashboards

# Create .env file for Docker Compose
cat > .env << 'EOF'
GRAFANA_PASSWORD=admin123!@
AWS_REGION=us-east-1
# Add your AWS credentials here
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
# Add your Slack webhook URL for alerts
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
EOF

echo ".env file created. Please update with your AWS credentials and Slack webhook URL"

# Create Grafana datasource provisioning
cat > grafana/provisioning/datasources/datasources.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true

  - name: CloudWatch
    type: cloudwatch
    access: proxy
    jsonData:
      authType: default
      defaultRegion: us-east-1
    editable: true
EOF

# Create Grafana dashboard provisioning
cat > grafana/provisioning/dashboards/dashboards.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'Default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
EOF

echo "Provisioning files created"
echo ""
echo "To start the monitoring stack:"
echo "1. Update .env with your AWS credentials and Slack webhook URL"
echo "2. Run: docker-compose up -d"
echo "3. Access Grafana at: http://localhost:3000"
echo "4. Access Prometheus at: http://localhost:9090"
echo ""
echo "Default Grafana credentials: admin / admin123!@"
