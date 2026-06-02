#!/bin/bash
# User data script for monitoring server
# Installs Docker and deploys monitoring stack

set -e

# Variables
SMTP_HOST="${SMTP_HOST}"
SMTP_PORT="${SMTP_PORT}"
SMTP_USERNAME="${SMTP_USERNAME}"
ALERT_FROM_EMAIL="${ALERT_FROM_EMAIL}"
ALERT_EMAIL_TO="${ALERT_EMAIL_TO}"
ALERT_CRITICAL_EMAIL_TO="${ALERT_CRITICAL_EMAIL_TO}"
AWS_REGION="${AWS_REGION}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD}"

# Log variables for debugging
echo "=== User Data Script Variables ===" >> /var/log/user-data.log
echo "GRAFANA_PASSWORD length: ${#GRAFANA_PASSWORD}" >> /var/log/user-data.log
echo "SMTP_HOST: $SMTP_HOST" >> /var/log/user-data.log

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | bash
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install git
apt-get install -y git

# Wait for Docker to be ready
sleep 10

# Start Docker
systemctl start docker
systemctl enable docker

# Clone repository (if clone URL provided via variable)
# This would need to be passed as a variable
REPO_DIR="/home/ubuntu/monitoring-deployment"
mkdir -p $REPO_DIR
cd $REPO_DIR

# Create docker-compose.yml using template substitution
cat > docker-compose.yml.template << 'DOCKER_EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:v2.48.0
    user: root
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus_rules.yml:/etc/prometheus/rules/prometheus_rules.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
    ports:
      - "9090:9090"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9090/-/healthy"]
      interval: 30s
      timeout: 10s
      retries: 3

  grafana:
    image: grafana/grafana:10.2.0
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=__GRAFANA_PASSWORD__
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
    ports:
      - "3000:3000"
    depends_on:
      - prometheus
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  node-exporter:
    image: prom/node-exporter:v1.7.0
    user: root
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9100/metrics"]
      interval: 30s
      timeout: 10s
      retries: 3

  alertmanager:
    image: prom/alertmanager:v0.26.0
    user: root
    volumes:
      - ./alertmanager-config.yml:/etc/alertmanager/alertmanager.yml
      - alertmanager_data:/alertmanager
    environment:
      - SMTP_HOST=__SMTP_HOST__
      - SMTP_PORT=__SMTP_PORT__
      - SMTP_USERNAME=__SMTP_USERNAME__
      - ALERT_FROM_EMAIL=__ALERT_FROM_EMAIL__
      - ALERT_EMAIL_TO=__ALERT_EMAIL_TO__
      - ALERT_CRITICAL_EMAIL_TO=__ALERT_CRITICAL_EMAIL_TO__
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
    ports:
      - "9093:9093"
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
  alertmanager_data:
DOCKER_EOF

# Substitute variables in the template using sed with # delimiters
sed "s#__GRAFANA_PASSWORD__#${GRAFANA_PASSWORD}#g; \
     s#__SMTP_HOST__#${SMTP_HOST}#g; \
     s#__SMTP_PORT__#${SMTP_PORT}#g; \
     s#__SMTP_USERNAME__#${SMTP_USERNAME}#g; \
     s#__ALERT_FROM_EMAIL__#${ALERT_FROM_EMAIL}#g; \
     s#__ALERT_EMAIL_TO__#${ALERT_EMAIL_TO}#g; \
     s#__ALERT_CRITICAL_EMAIL_TO__#${ALERT_CRITICAL_EMAIL_TO}#g" \
    docker-compose.yml.template > docker-compose.yml

echo "Docker Compose generated at $(date)" >> /var/log/user-data.log
cat > prometheus.yml << 'PROM_EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

rule_files:
  - 'prometheus_rules.yml'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'alertmanager'
    static_configs:
      - targets: ['alertmanager:9093']
PROM_EOF

# Create basic prometheus_rules.yml
cat > prometheus_rules.yml << 'RULES_EOF'
groups:
  - name: system_alerts
    interval: 30s
    rules:
      - alert: HighCPUUtilization
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU on {{ $labels.instance }}"
          description: "CPU usage is {{ $value | humanize }}%"

      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory on {{ $labels.instance }}"
          description: "Memory usage is {{ $value | humanize }}%"

      - alert: LowDiskSpace
        expr: (1 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Disk usage is {{ $value | humanize }}%"
RULES_EOF

# Create alertmanager configuration
cat > alertmanager-config.yml.template << 'ALERT_EOF'
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'default-receiver'

  routes:
    - match:
        severity: critical
      receiver: 'critical-alerts'
      group_wait: 0s
      repeat_interval: 1h

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'cluster', 'service']

receivers:
  - name: 'default-receiver'
    email_configs:
      - to: '__ALERT_EMAIL_TO__'
        from: '__ALERT_FROM_EMAIL__'
        smarthost: '__SMTP_HOST__:__SMTP_PORT__'
        require_tls: true
        auth_username: '__SMTP_USERNAME__'
        headers:
          Subject: '[{{ .GroupLabels.severity | toUpper }}] {{ .GroupLabels.alertname }}'

  - name: 'critical-alerts'
    email_configs:
      - to: '__ALERT_CRITICAL_EMAIL_TO__'
        from: '__ALERT_FROM_EMAIL__'
        smarthost: '__SMTP_HOST__:__SMTP_PORT__'
        require_tls: true
        auth_username: '__SMTP_USERNAME__'
        headers:
          Subject: '🚨 CRITICAL: {{ .GroupLabels.alertname }}'
ALERT_EOF

# Substitute variables in alertmanager template
sed "s#__SMTP_HOST__#${SMTP_HOST}#g; \
     s#__SMTP_PORT__#${SMTP_PORT}#g; \
     s#__SMTP_USERNAME__#${SMTP_USERNAME}#g; \
     s#__ALERT_FROM_EMAIL__#${ALERT_FROM_EMAIL}#g; \
     s#__ALERT_EMAIL_TO__#${ALERT_EMAIL_TO}#g; \
     s#__ALERT_CRITICAL_EMAIL_TO__#${ALERT_CRITICAL_EMAIL_TO}#g" \
    alertmanager-config.yml.template > alertmanager-config.yml

echo "AlertManager config generated at $(date)" >> /var/log/user-data.log
chown -R ubuntu:ubuntu $REPO_DIR
cd $REPO_DIR

# Create monitoring data directories
mkdir -p prometheus_data grafana_data alertmanager_data
chown -R 65534:65534 prometheus_data || true
chown -R 472:472 grafana_data || true
chown -R 65534:65534 alertmanager_data || true

# Start docker-compose
su - ubuntu -c "cd $REPO_DIR && /usr/local/bin/docker-compose up -d"

# Log completion
echo "Monitoring stack deployment completed at $(date)" >> /var/log/user-data.log
echo "Prometheus: http://localhost:9090" >> /var/log/user-data.log
echo "Grafana: http://localhost:3000" >> /var/log/user-data.log
echo "AlertManager: http://localhost:9093" >> /var/log/user-data.log

exit 0
