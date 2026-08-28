#!/bin/bash
# Simple Chat Platform - Automated Setup Script
# Usage: ./setup.sh [action]
# Actions: docker, k8s, argocd, all, clean

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ARGOCD_VERSION="stable"
K8S_TIMEOUT="300s"

# Helper functions
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing=0
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        missing=1
    else
        print_success "Docker found: $(docker --version)"
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        missing=1
    else
        print_success "kubectl found: $(kubectl version --short 2>/dev/null || kubectl version --client 2>/dev/null)"
    fi
    
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed"
        missing=1
    else
        print_success "Git found: $(git --version)"
    fi
    
    if [ $missing -eq 1 ]; then
        print_error "Please install missing prerequisites"
        exit 1
    fi
}

# Setup Docker Compose
setup_docker() {
    print_header "Setting up Docker Compose"
    
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found in current directory"
        exit 1
    fi
    
    print_warning "Building Docker images... this may take a few minutes"
    docker-compose build
    print_success "Docker images built successfully"
    
    print_warning "Starting services..."
    docker-compose up -d
    print_success "Services started"
    
    echo -e "\n${BLUE}Access points:${NC}"
    echo "  Frontend: http://localhost:5173"
    echo "  Backend:  http://localhost:5000"
    echo "\n${BLUE}View logs:${NC}"
    echo "  docker-compose logs -f frontend-dev"
    echo "  docker-compose logs -f backend-dev"
}

# Setup Kubernetes
setup_k8s() {
    print_header "Setting up Kubernetes"
    
    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Kubernetes cluster not accessible"
        exit 1
    fi
    print_success "Connected to Kubernetes cluster"
    
    # Create namespaces
    print_warning "Creating namespaces..."
    for ns in simple-chat-dev simple-chat-stage simple-chat-prod; do
        if kubectl get namespace "$ns" &> /dev/null; then
            print_warning "Namespace $ns already exists"
        else
            kubectl create namespace "$ns"
            print_success "Created namespace: $ns"
        fi
    done
    
    # Deploy manifests
    print_warning "Deploying Kubernetes manifests..."
    for env in dev stage prod; do
        if [ -d "k8s/$env" ]; then
            kubectl apply -f "k8s/$env/"
            print_success "Deployed $env environment"
        fi
    done
    
    # Wait for deployments
    print_warning "Waiting for deployments to be ready... (${K8S_TIMEOUT})"
    for ns in simple-chat-dev simple-chat-stage simple-chat-prod; do
        kubectl wait --for=condition=available --timeout=${K8S_TIMEOUT} \
            deployment --all -n "$ns" || print_warning "Some deployments in $ns didn't become ready"
    done
    
    print_success "Kubernetes deployment complete"
    
    echo -e "\n${BLUE}Next steps:${NC}"
    echo "  View namespaces: kubectl get ns"
    echo "  Check pods: kubectl get pods -A"
    echo "  Port-forward frontend: kubectl port-forward svc/frontend-dev 3000:3000 -n simple-chat-dev"
    echo "  Port-forward backend:  kubectl port-forward svc/backend-dev 5000:5000 -n simple-chat-dev"
}

# Setup Argo CD
setup_argocd() {
    print_header "Setting up Argo CD"
    
    # Create namespace
    if kubectl get namespace argocd &> /dev/null; then
        print_warning "Argo CD namespace already exists"
    else
        kubectl create namespace argocd
        print_success "Created argocd namespace"
    fi
    
    # Install Argo CD
    print_warning "Installing Argo CD... this may take a minute"
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml
    
    # Wait for Argo CD
    print_warning "Waiting for Argo CD to be ready..."
    kubectl wait --for=condition=available --timeout=300s \
        deployment --all -n argocd
    
    print_success "Argo CD installed"
    
    # Apply applications
    if [ -d "argocd" ]; then
        print_warning "Creating Argo CD applications..."
        kubectl apply -f argocd/
        print_success "Argo CD applications created"
    fi
    
    echo -e "\n${BLUE}Access Argo CD:${NC}"
    echo "  Port-forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "  URL: https://localhost:8080"
    echo -e "\n${BLUE}Get admin password:${NC}"
    echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\\\"{.data.password}\\\" | base64 -d"
    echo -e "\n${BLUE}Check application status:${NC}"
    echo "  argocd app list"
}

# Clean up
cleanup() {
    print_header "Cleaning Up"
    
    # Stop Docker Compose
    if [ -f "docker-compose.yml" ]; then
        print_warning "Stopping Docker Compose services..."
        docker-compose down
        print_success "Docker Compose stopped"
    fi
    
    # Delete Kubernetes resources
    print_warning "Deleting Kubernetes resources..."
    for env in dev stage prod; do
        if [ -d "k8s/$env" ]; then
            kubectl delete -f "k8s/$env/" --ignore-not-found
            print_success "Deleted $env environment"
        fi
    done
    
    # Delete namespaces
    for ns in simple-chat-dev simple-chat-stage simple-chat-prod argocd; do
        if kubectl get namespace "$ns" &> /dev/null; then
            kubectl delete namespace "$ns"
            print_success "Deleted namespace: $ns"
        fi
    done
    
    print_success "Cleanup complete"
}

# Show usage
show_usage() {
    cat << EOF
${BLUE}Simple Chat Platform - Setup Script${NC}

Usage: ./setup.sh [action]

Actions:
  docker      - Setup and start Docker Compose
  k8s         - Setup Kubernetes manifests
  argocd      - Install and configure Argo CD
  all         - Run all setup steps (docker, k8s, argocd)
  clean       - Remove all resources (WARNING: destructive)
  help        - Show this help message

Examples:
  ./setup.sh docker          # Start local development
  ./setup.sh k8s            # Deploy to Kubernetes
  ./setup.sh all            # Complete setup
  ./setup.sh clean          # Remove everything

Prerequisites:
  - Docker & Docker Compose
  - kubectl
  - Git
  - Active Kubernetes cluster

EOF
}

# Main script
main() {
    local action="${1:-help}"
    
    case "$action" in
        docker)
            check_prerequisites
            setup_docker
            ;;
        k8s)
            check_prerequisites
            setup_k8s
            ;;
        argocd)
            check_prerequisites
            setup_argocd
            ;;
        all)
            check_prerequisites
            setup_docker
            setup_k8s
            setup_argocd
            print_header "Setup Complete!"
            echo -e "${GREEN}All components installed and configured.${NC}\n"
            echo -e "${BLUE}Quick reference:${NC}"
            echo "  Docker logs: docker-compose logs -f"
            echo "  K8s pods: kubectl get pods -A"
            echo "  Argo CD: kubectl port-forward svc/argocd-server -n argocd 8080:443"
            echo ""
            echo "See DEVOPS-GUIDE.md and README-DEVOPS.md for detailed documentation"
            ;;
        clean)
            read -p "Are you sure you want to remove all resources? (yes/no) " -r
            if [[ $REPLY =~ ^[Yy]es$ ]]; then
                cleanup
            else
                print_warning "Cleanup cancelled"
            fi
            ;;
        help|*)
            show_usage
            ;;
    esac
}

main "$@"
