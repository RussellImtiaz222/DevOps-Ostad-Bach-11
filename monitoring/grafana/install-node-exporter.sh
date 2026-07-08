#!/bin/bash
# Node Exporter Installation and Configuration Script
# This script installs and configures Node Exporter on EC2 instances for system monitoring

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Node Exporter Installation ===${NC}"

# Variables
NODE_EXPORTER_VERSION="1.7.0"
NODE_EXPORTER_USER="node_exporter"
NODE_EXPORTER_PORT="9100"

# Install prerequisites
echo -e "${YELLOW}Installing prerequisites...${NC}"
sudo apt-get update
sudo apt-get install -y curl wget

# Create service user
echo -e "${YELLOW}Creating node_exporter service user...${NC}"
if ! id -u $NODE_EXPORTER_USER > /dev/null 2>&1; then
    sudo useradd --no-create-home --shell /bin/false $NODE_EXPORTER_USER
    echo -e "${GREEN}Service user created${NC}"
else
    echo -e "${YELLOW}Service user already exists${NC}"
fi

# Download and install Node Exporter
echo -e "${YELLOW}Downloading Node Exporter v${NODE_EXPORTER_VERSION}...${NC}"
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

echo -e "${YELLOW}Extracting and installing...${NC}"
tar xvfz node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
sudo chown $NODE_EXPORTER_USER:$NODE_EXPORTER_USER /usr/local/bin/node_exporter
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*

# Create systemd service file
echo -e "${YELLOW}Creating systemd service...${NC}"
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=$NODE_EXPORTER_USER
Group=$NODE_EXPORTER_USER
Type=simple
ExecStart=/usr/local/bin/node_exporter \\
  --collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)(\$|/) \\
  --collector.filesystem.fs-types-exclude=^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)(\$|/) \\
  --collector.netdev.device-exclude=^(veth.*|docker.*|br.*|virbr.*|lo)(\$|/) \\
  --collector.netdev.device-include=^(eth|ens|wlan|wg|docker).*(\$|/) \\
  --web.telemetry-path=/metrics \\
  --web.listen-address=:${NODE_EXPORTER_PORT}

Restart=always
RestartSec=5
SyslogIdentifier=node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
echo -e "${YELLOW}Enabling Node Exporter service...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Verify installation
echo -e "${YELLOW}Verifying installation...${NC}"
sleep 2

if curl -s http://localhost:${NODE_EXPORTER_PORT}/metrics > /dev/null; then
    echo -e "${GREEN}✓ Node Exporter is running and responding${NC}"
    echo -e "${GREEN}✓ Metrics available at http://localhost:${NODE_EXPORTER_PORT}/metrics${NC}"
else
    echo -e "${RED}✗ Node Exporter failed to start${NC}"
    sudo systemctl status node_exporter
    exit 1
fi

echo -e "${YELLOW}=== Installation Complete ===${NC}"
echo -e "${GREEN}Node Exporter v${NODE_EXPORTER_VERSION} installed successfully${NC}"
echo -e "${GREEN}Service: node_exporter${NC}"
echo -e "${GREEN}Port: ${NODE_EXPORTER_PORT}${NC}"
echo -e "${GREEN}Metrics endpoint: http://localhost:${NODE_EXPORTER_PORT}/metrics${NC}"
