# Module 8 DevOps Monitoring and Deployment Solution

This folder contains a complete DevOps solution for provisioning a cloud server, deploying an application, and monitoring system health and logs.

## Architecture

- **Terraform** provisions an AWS EC2 Ubuntu server, SSH key pair, and security group.
- **GitHub Actions** validates the application and Terraform configuration, copies files to the server, installs monitoring, and deploys the demo app.
- **Prometheus** collects metrics from Node Exporter.
- **Node Exporter** exposes CPU, memory, disk, and network metrics.
- **Loki** stores logs.
- **Promtail** ships `/var/log/*.log` and systemd journal logs to Loki.
- **Grafana** displays the dashboard and system logs.

## Ports

| Service | Port | Purpose |
| --- | ---: | --- |
| SSH | 22 | Deployment access |
| Demo app | 8000 | Example deployed service |
| Grafana | 3000 | Dashboard UI |
| Prometheus | 9090 | Metrics database |
| Node Exporter | 9100 | Local metrics endpoint |
| Loki | 3100 | Local log database endpoint |
| Promtail | 9080 | Local log shipper endpoint |

Only SSH, Grafana, Prometheus, and the demo app are opened in Terraform. Loki, Promtail, and Node Exporter stay local to the server.

## 1. Provision the cloud server

Install Terraform and configure AWS credentials locally:

```bash
aws configure
cd devops/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

- Set `ssh_public_key` to your public key.
- Set `allowed_cidr_blocks` to your IP, such as `["203.0.113.10/32"]`.

Run:

```bash
terraform init
terraform fmt
terraform validate
terraform apply
```

After apply, Terraform prints:

- `server_public_ip`
- `ssh_command`
- `grafana_url`
- `prometheus_url`

## 2. Configure GitHub Actions secrets

Create these repository secrets:

| Secret | Example | Description |
| --- | --- | --- |
| `SERVER_HOST` | `203.0.113.25` | EC2 public IP from Terraform |
| `SERVER_USER` | `ubuntu` | SSH user for Ubuntu AMIs |
| `SSH_PRIVATE_KEY` | private key text | Private key matching `ssh_public_key` |
| `GRAFANA_ADMIN_PASSWORD` | strong password | Initial Grafana admin password |

## 3. Deploy with CI/CD

The workflow at `.github/workflows/deploy-monitoring.yml` runs on pushes to `main` and can also be started manually with **workflow_dispatch**.

Pipeline stages:

1. Checkout source code.
2. Install and validate the Python package.
3. Run Terraform formatting and validation checks.
4. Connect to the provisioned server over SSH.
5. Copy deployment, monitoring, and application files to `/opt/module8-devops`.
6. Install and restart Grafana, Prometheus, Loki, Promtail, and Node Exporter.
7. Deploy the demo application as `module8-app.service` on port `8000`.

## 4. Grafana dashboard

Open:

```text
http://SERVER_PUBLIC_IP:3000
```

Default username:

```text
admin
```

Password:

```text
GRAFANA_ADMIN_PASSWORD
```

Dashboard path:

```text
Module 8 / Module 8 System Overview
```

Dashboard panels:

- CPU Usage
- Memory Usage
- Disk Usage
- Network Throughput
- System Logs

## 5. Verify services on the server

SSH into the server:

```bash
ssh ubuntu@SERVER_PUBLIC_IP
```

Check services:

```bash
sudo systemctl status grafana-server prometheus loki promtail node_exporter module8-app
```

Check metrics:

```bash
curl http://localhost:9100/metrics
curl http://localhost:9090/-/healthy
```

Check logs:

```bash
journalctl -u promtail -n 50 --no-pager
journalctl -u module8-app -n 50 --no-pager
```

## Files included

```text
devops/
  terraform/
    main.tf
    variables.tf
    outputs.tf
    terraform.tfvars.example
  scripts/
    install_monitoring.sh
  monitoring/
    prometheus.yml
    loki.yml
    promtail.yml
    grafana/
      provisioning/
      dashboards/module8-system-overview.json
    systemd/
      prometheus.service
      node_exporter.service
      loki.service
      promtail.service
      module8-app.service
.github/
  workflows/
    deploy-monitoring.yml
```
