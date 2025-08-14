#!/bin/bash

# K3s cluster installation script with multi-node support

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This script must be run as root${NC}" >&2
    exit 1
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --server)
            ROLE="server"
            shift
            ;;
        --agent)
            ROLE="agent"
            SERVER_IP="$2"
            shift 2
            ;;
        --uninstall)
            UNINSTALL=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ "$UNINSTALL" = true ]; then
    echo -e "${YELLOW}Uninstalling k3s...${NC}"
    /usr/local/bin/k3s-uninstall.sh || echo "k3s not installed or already removed"
    exit 0
fi

# Install k3s
echo -e "${GREEN}Installing k3s as ${ROLE:-standalone}...${NC}"

if [ "$ROLE" = "agent" ]; then
    curl -sfL https://get.k3s.io | K3S_URL=https://${SERVER_IP}:6443 K3S_TOKEN=your_token_here sh -
else
    curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
    
    # Configure Traefik as LoadBalancer
    echo -e "${YELLOW}Configuring Traefik...${NC}"
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    helm repo add traefik https://traefik.github.io/charts
    helm upgrade --install traefik traefik/traefik -n kube-system \
      --version 23.1.0 \
      --set service.type=LoadBalancer \
      --set ports.web.http.redirections.entryPoint.to=websecure \
      --set ports.web.http.redirections.entryPoint.scheme=https \
      --set ports.websecure.tls.enabled=true \
      --set "providers.kubernetesCRD.enabled=true" \
      --set "providers.kubernetesIngress.enabled=true"
    
    # Update kubeconfig with server IP
    sed -i "s/127.0.0.1/62.169.16.31/g" /etc/rancher/k3s/k3s.yaml
fi

# Verify installation
echo -e "${YELLOW}Verifying k3s installation...${NC}"
kubectl get nodes

# Install addons if server
if [ "$ROLE" != "agent" ]; then
    # Install Helm
    echo -e "${GREEN}Installing Helm...${NC}"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    # Install cert-manager
    echo -e "${GREEN}Installing cert-manager...${NC}"
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
    
    # Wait for k3s to be ready
    echo -e "${YELLOW}Waiting for k3s to become ready...${NC}"
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    until kubectl get nodes >/dev/null 2>&1; do
        sleep 5
    done

    # Install Rancher Dashboard
    echo -e "${GREEN}Installing Rancher Dashboard...${NC}"
    helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
    kubectl create namespace cattle-system 2>/dev/null || true
    
    # Install or upgrade Rancher
    if helm list -n cattle-system | grep -q rancher; then
        echo -e "${YELLOW}Rancher already installed, upgrading...${NC}"
        helm upgrade rancher rancher-latest/rancher \
          --namespace cattle-system \
          --set hostname=rancher-con.tawfiqulbari.work \
          --set bootstrapPassword=admin \
          --set replicas=1
    else
        echo -e "${GREEN}Installing Rancher...${NC}"
        helm install rancher rancher-latest/rancher \
          --namespace cattle-system \
          --set hostname=rancher-con.tawfiqulbari.work \
          --set bootstrapPassword=admin \
          --set replicas=1 \
          --set ingress.tls.source=letsEncrypt \
          --set letsEncrypt.email=admin@tawfiqulbari.work
    fi

    # Verify Rancher installation
    echo -e "${YELLOW}Waiting for Rancher to become ready...${NC}"
    kubectl rollout status deployment rancher -n cattle-system --timeout=300s
    
    echo -e "${GREEN}Installing Metrics Server...${NC}"
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
fi

# Get kubeconfig location
echo -e "${YELLOW}Kubeconfig is available at: /etc/rancher/k3s/k3s.yaml (already configured with server IP 62.169.16.31)${NC}"

# Instructions for accessing the cluster
if [ "$ROLE" != "agent" ]; then
    echo -e "${GREEN}To access the cluster from another host:${NC}"
    echo "1. Copy /etc/rancher/k3s/k3s.yaml to ~/.kube/config on your local machine"
    echo "2. Set KUBECONFIG environment variable: export KUBECONFIG=~/.kube/config"
    
    echo -e "\n${GREEN}To access Rancher Dashboard:${NC}"
    echo "Wait for installation to complete (check with: kubectl get pods -n cattle-system)"
    echo "Access at: https://rancher-con.tawfiqulbari.work"
    echo "Initial credentials: admin / admin"
fi