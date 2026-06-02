#!/bin/bash
# Monitoring Stack Setup Script
# Sets up Prometheus, Grafana, AlertManager, and Node Exporter with Docker Compose

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure we're in the correct directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       3-Tier Application Monitoring Stack Setup              ║${NC}"
echo -e "${BLUE}║  Prometheus | Grafana | AlertManager | Node Exporter        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"

# Step 1: Check prerequisites
echo -e "\n${YELLOW}[1/5] Checking prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is installed${NC}"

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}✗ Docker Compose is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose is installed${NC}"

# Step 2: Create directories and set permissions
echo -e "\n${YELLOW}[2/5] Creating required directories...${NC}"

mkdir -p prometheus_data grafana_data alertmanager_data

# Create Grafana provisioning directories
mkdir -p grafana/provisioning/dashboards
mkdir -p grafana/provisioning/datasources

# Set permissions
sudo chown -R 472:472 grafana_data || true
sudo chmod -R 775 grafana_data || true

echo -e "${GREEN}✓ Directories created${NC}"

# Step 3: Environment configuration
echo -e "\n${YELLOW}[3/5] Setting up environment configuration...${NC}"

if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${YELLOW}  Created .env from .env.example${NC}"
        echo -e "${YELLOW}  ⚠️  Please update .env with your SMTP and email settings${NC}"
    else
        cat > .env << 'EOF'
# Grafana Configuration
GRAFANA_PASSWORD=admin123
GRAFANA_USER=admin

# SMTP Configuration for Email Alerts
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# Alert Email Configuration
ALERT_FROM_EMAIL=alerts@yourdomain.com
ALERT_EMAIL_TO=ops@yourdomain.com
ALERT_CRITICAL_EMAIL_TO=oncall@yourdomain.com

# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# Prometheus Retention
PROMETHEUS_RETENTION=30d
EOF
        echo -e "${YELLOW}  Created .env with default values${NC}"
        echo -e "${YELLOW}  ⚠️  Please update .env with your SMTP and email settings${NC}"
    fi
else
    echo -e "${GREEN}✓ .env file already exists${NC}"
fi

# Step 4: Validate configuration files
echo -e "\n${YELLOW}[4/5] Validating configuration files...${NC}"

required_files=(
    "prometheus.yml"
    "prometheus_rules.yml"
    "alertmanager-config.yml"
    "cloudwatch-exporter-config.yml"
    "docker-compose.yml"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}✗ Required file missing: $file${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ $file exists${NC}"
done

# Step 5: Start services
echo -e "\n${YELLOW}[5/5] Starting monitoring stack...${NC}"

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

# Start services with docker-compose
docker-compose up -d

# Wait for services to start
echo -e "\n${YELLOW}Waiting for services to start (30 seconds)...${NC}"
sleep 30

# Verify services
echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   Verifying Services                         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"

# Check Prometheus
if curl -s http://localhost:9090/-/healthy > /dev/null; then
    echo -e "${GREEN}✓ Prometheus${NC}       - http://localhost:9090"
else
    echo -e "${RED}✗ Prometheus${NC}       - Failed to connect"
fi

# Check Grafana
if curl -s http://localhost:3000/api/health > /dev/null; then
    echo -e "${GREEN}✓ Grafana${NC}          - http://localhost:3000"
else
    echo -e "${RED}✗ Grafana${NC}          - Failed to connect"
fi

# Check AlertManager
if curl -s http://localhost:9093/-/healthy > /dev/null; then
    echo -e "${GREEN}✓ AlertManager${NC}     - http://localhost:9093"
else
    echo -e "${RED}✗ AlertManager${NC}     - Failed to connect"
fi

# Check Node Exporter
if curl -s http://localhost:9100/metrics > /dev/null; then
    echo -e "${GREEN}✓ Node Exporter${NC}    - http://localhost:9100"
else
    echo -e "${RED}✗ Node Exporter${NC}    - Failed to connect"
fi

# Check CloudWatch Exporter
if curl -s http://localhost:9106 > /dev/null; then
    echo -e "${GREEN}✓ CloudWatch Exporter${NC} - http://localhost:9106"
else
    echo -e "${RED}✗ CloudWatch Exporter${NC} - Failed to connect"
fi

echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   Next Steps                                 ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}1. Configure Grafana:${NC}"
echo "   • Open http://localhost:3000"
echo "   • Login with credentials from .env"
echo "   • Add Prometheus datasource: http://prometheus:9090"
echo "   • Import dashboards from grafana/dashboards/"

echo -e "\n${YELLOW}2. Configure AlertManager:${NC}"
echo "   • Update .env with your SMTP credentials"
echo "   • Modify alertmanager-config.yml for your email addresses"
echo "   • Restart AlertManager: docker-compose restart alertmanager"

echo -e "\n${YELLOW}3. Deploy Node Exporter on Application Servers:${NC}"
echo "   • Copy install-node-exporter.sh to application servers"
echo "   • Run: sudo bash install-node-exporter.sh"
echo "   • Add targets to prometheus.yml"

echo -e "\n${YELLOW}4. View Logs:${NC}"
echo "   • All services: docker-compose logs -f"
echo "   • Specific service: docker-compose logs -f prometheus"

echo -e "\n${YELLOW}5. Stop Stack:${NC}"
echo "   • docker-compose down"

echo -e "\n${GREEN}✓ Setup complete!${NC}\n"

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
