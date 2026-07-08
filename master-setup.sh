#!/bin/bash
# Master Node Kubernetes Setup Script
# Run this on Instance 1: 34.200.249.8
# Copy entire script and paste into SSH terminal

set -e

echo "========================================"
echo "Kubernetes Master Node Setup"
echo "========================================"

# Update system
echo "Updating system..."
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl gnupg2 lsb-release ubuntu-keyring apt-transport-https ca-certificates

# ============================================
# Install Docker
# ============================================
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Enable Docker
sudo systemctl enable docker
sudo systemctl start docker

echo "Docker installed successfully"

# ============================================
# Configure Kubernetes Prerequisites
# ============================================
echo "Configuring Kubernetes prerequisites..."

# Disable swap (required for Kubernetes)
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Load required kernel modules
sudo tee /etc/modules-load.d/kubernetes.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set kernel parameters
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

echo "Kubernetes prerequisites configured"

# ============================================
# Install Kubernetes Components
# ============================================
echo "Installing Kubernetes components..."

# Add Kubernetes GPG key
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

# Add Kubernetes repository
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install kubelet, kubectl, kubeadm
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

# Hold packages to prevent auto-updates
sudo apt-mark hold kubelet kubeadm kubectl

# Enable kubelet
sudo systemctl enable kubelet

echo "========================================"
echo "Setup complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Run: sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --advertise-address=172.31.7.113"
echo "2. Save the kubeadm join command output"
echo "3. Run the kubeconfig setup commands"
echo "4. Install Flannel network plugin"
echo ""
