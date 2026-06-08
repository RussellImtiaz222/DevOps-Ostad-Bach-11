#!/usr/bin/env bash
set -euo pipefail

PROMETHEUS_VERSION="2.53.3"
NODE_EXPORTER_VERSION="1.8.2"
LOKI_VERSION="3.2.1"
PROMTAIL_VERSION="3.2.1"
GRAFANA_ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-admin12345}"

export DEBIAN_FRONTEND=noninteractive

install_base_packages() {
  apt-get update
  apt-get install -y apt-transport-https ca-certificates curl gpg unzip
}

stop_monitoring_services() {
  systemctl stop grafana-server prometheus loki promtail node_exporter 2>/dev/null || true
}

install_grafana() {
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://apt.grafana.com/gpg.key | gpg --batch --yes --dearmor -o /etc/apt/keyrings/grafana.gpg
  echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
    > /etc/apt/sources.list.d/grafana.list
  apt-get update
  apt-get install -y grafana

  sed -i "s/^;admin_password = admin/admin_password = ${GRAFANA_ADMIN_PASSWORD}/" /etc/grafana/grafana.ini
  systemctl enable grafana-server
}

install_prometheus() {
  useradd --no-create-home --shell /usr/sbin/nologin prometheus || true
  mkdir -p /etc/prometheus /var/lib/prometheus

  curl -fsSL "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz" \
    -o /tmp/prometheus.tar.gz
  tar -xzf /tmp/prometheus.tar.gz -C /tmp
  install -m 0755 "/tmp/prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus" /usr/local/bin/prometheus.new
  install -m 0755 "/tmp/prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool" /usr/local/bin/promtool.new
  mv -f /usr/local/bin/prometheus.new /usr/local/bin/prometheus
  mv -f /usr/local/bin/promtool.new /usr/local/bin/promtool
  cp -r "/tmp/prometheus-${PROMETHEUS_VERSION}.linux-amd64/consoles" /etc/prometheus/
  cp -r "/tmp/prometheus-${PROMETHEUS_VERSION}.linux-amd64/console_libraries" /etc/prometheus/

  chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
  cp /opt/module8-devops/monitoring/prometheus.yml /etc/prometheus/prometheus.yml
  chown prometheus:prometheus /etc/prometheus/prometheus.yml
  cp /opt/module8-devops/monitoring/systemd/prometheus.service /etc/systemd/system/prometheus.service
  systemctl enable prometheus
}

install_node_exporter() {
  useradd --no-create-home --shell /usr/sbin/nologin node_exporter || true
  curl -fsSL "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" \
    -o /tmp/node_exporter.tar.gz
  tar -xzf /tmp/node_exporter.tar.gz -C /tmp
  install -m 0755 "/tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/node_exporter.new
  mv -f /usr/local/bin/node_exporter.new /usr/local/bin/node_exporter
  cp /opt/module8-devops/monitoring/systemd/node_exporter.service /etc/systemd/system/node_exporter.service
  systemctl enable node_exporter
}

install_loki_and_promtail() {
  useradd --system --no-create-home --shell /usr/sbin/nologin loki || true
  mkdir -p /etc/loki /var/lib/loki /etc/promtail /var/lib/promtail

  curl -fsSL "https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/loki-linux-amd64.zip" -o /tmp/loki.zip
  unzip -o /tmp/loki.zip -d /tmp
  install -m 0755 /tmp/loki-linux-amd64 /usr/local/bin/loki.new
  mv -f /usr/local/bin/loki.new /usr/local/bin/loki

  curl -fsSL "https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip" -o /tmp/promtail.zip
  unzip -o /tmp/promtail.zip -d /tmp
  install -m 0755 /tmp/promtail-linux-amd64 /usr/local/bin/promtail.new
  mv -f /usr/local/bin/promtail.new /usr/local/bin/promtail

  cp /opt/module8-devops/monitoring/loki.yml /etc/loki/loki.yml
  cp /opt/module8-devops/monitoring/promtail.yml /etc/promtail/promtail.yml
  cp /opt/module8-devops/monitoring/systemd/loki.service /etc/systemd/system/loki.service
  cp /opt/module8-devops/monitoring/systemd/promtail.service /etc/systemd/system/promtail.service
  chown -R loki:loki /etc/loki /var/lib/loki
  systemctl enable loki promtail
}

provision_grafana() {
  mkdir -p /etc/grafana/provisioning/datasources /etc/grafana/provisioning/dashboards /var/lib/grafana/dashboards
  cp /opt/module8-devops/monitoring/grafana/provisioning/datasources/datasources.yml /etc/grafana/provisioning/datasources/datasources.yml
  cp /opt/module8-devops/monitoring/grafana/provisioning/dashboards/dashboards.yml /etc/grafana/provisioning/dashboards/dashboards.yml
  cp /opt/module8-devops/monitoring/grafana/dashboards/module8-system-overview.json /var/lib/grafana/dashboards/module8-system-overview.json
  chown -R grafana:grafana /etc/grafana/provisioning /var/lib/grafana/dashboards
}

main() {
  stop_monitoring_services
  install_base_packages
  install_grafana
  install_prometheus
  install_node_exporter
  install_loki_and_promtail
  provision_grafana
  systemctl daemon-reload
  systemctl restart node_exporter prometheus loki promtail grafana-server
  systemctl --no-pager --failed
}

main "$@"
