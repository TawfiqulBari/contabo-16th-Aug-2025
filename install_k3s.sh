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
        --add-worker)
            ROLE="add-worker"
            WORKER_IP="$2"
            WORKER_USER="$3"
            WORKER_PASSWORD="$4"
            shift 4
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
    if [ -z "$K3S_TOKEN" ]; then
        echo -e "${RED}Error: K3S_TOKEN environment variable must be set for agent installation${NC}"
        echo -e "${YELLOW}Get the token from the master node: cat /var/lib/rancher/k3s/server/node-token${NC}"
        exit 1
    fi
    curl -sfL https://get.k3s.io | K3S_URL=https://${SERVER_IP}:6443 K3S_TOKEN=${K3S_TOKEN} sh -
elif [ "$ROLE" = "add-worker" ]; then
    # Add worker node remotely via SSH
    if [ -z "$WORKER_IP" ] || [ -z "$WORKER_USER" ] || [ -z "$WORKER_PASSWORD" ]; then
        echo -e "${RED}Error: Worker IP, user, and password must be provided for --add-worker${NC}"
        exit 1
    fi
    
    # Get token from master node
    if [ ! -f "/var/lib/rancher/k3s/server/node-token" ]; then
        echo -e "${RED}Error: This script must be run on the master node to add workers${NC}"
        exit 1
    fi
    
    K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
    MASTER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "${GREEN}Adding worker node $WORKER_IP to cluster...${NC}"
    
    # Install sshpass if not available
    if ! command -v sshpass &> /dev/null; then
        echo -e "${YELLOW}Installing sshpass...${NC}"
        apt-get update && apt-get install -y sshpass
    fi
    
    # Install K3s agent on worker node
    sshpass -p "$WORKER_PASSWORD" ssh -o StrictHostKeyChecking=no ${WORKER_USER}@${WORKER_IP} \
        "curl -sfL https://get.k3s.io | K3S_URL=https://${MASTER_IP}:6443 K3S_TOKEN=${K3S_TOKEN} sh -"
    
    echo -e "${GREEN}Worker node installation completed. Verifying...${NC}"
    sleep 10
    kubectl get nodes
    
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
    
    # Install MetalLB LoadBalancer
    echo -e "${GREEN}Installing MetalLB LoadBalancer...${NC}"
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
    
    # Wait for MetalLB to be ready
    echo -e "${YELLOW}Waiting for MetalLB to become ready...${NC}"
    kubectl wait --namespace metallb-system \
                --for=condition=ready pod \
                --selector=app=metallb \
                --timeout=300s
    
    # Configure MetalLB IP address pool
    echo -e "${GREEN}Configuring MetalLB IP address pool...${NC}"
    cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.240-192.168.1.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
EOF
    
    echo -e "${GREEN}MetalLB installation completed!${NC}"
    
    # Verify MetalLB installation
    echo -e "${YELLOW}Verifying MetalLB installation...${NC}"
    kubectl get pods -n metallb-system
    kubectl get ipaddresspools.metallb.io -n metallb-system
    kubectl get l2advertisements.metallb.io -n metallb-system
    
    echo -e "${YELLOW}Note: If your network uses a different IP range, please modify the IPAddressPool configuration.${NC}"
    
    # Test MetalLB with a simple LoadBalancer service
    echo -e "${GREEN}Testing MetalLB with a test service...${NC}"
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: metallb-test
  namespace: default
spec:
  selector:
    app: metallb-test
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metallb-test
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: metallb-test
  template:
    metadata:
      labels:
        app: metallb-test
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF
    
    echo -e "${YELLOW}Waiting for test service to get an external IP...${NC}"
    sleep 10
    kubectl get svc metallb-test -w --timeout=60s || echo "Test service may take time to get an IP"
    
    echo -e "${GREEN}MetalLB is now operational!${NC}"
fi

# Get kubeconfig location
echo -e "${YELLOW}Kubeconfig is available at: /etc/rancher/k3s/k3s.yaml (already configured with server IP 62.169.16.31)${NC}"

# Instructions for accessing the cluster
if [ "$ROLE" != "agent" ] && [ "$ROLE" != "add-worker" ]; then
    echo -e "${GREEN}To access the cluster from another host:${NC}"
    echo "1. Copy /etc/rancher/k3s/k3s.yaml to ~/.kube/config on your local machine"
    echo "2. Set KUBECONFIG environment variable: export KUBECONFIG=~/.kube/config"
    
    echo -e "\n${GREEN}To access Rancher Dashboard:${NC}"
    echo "Wait for installation to complete (check with: kubectl get pods -n cattle-system)"
    echo "Access at: https://rancher-con.tawfiqulbari.work"
    echo "Initial credentials: admin / admin"
    
    # Display join token for manual worker node setup
    if [ -f "/var/lib/rancher/k3s/server/node-token" ]; then
        echo -e "\n${GREEN}Cluster join token:${NC}"
        echo "K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)"
        echo -e "\n${GREEN}To add worker nodes manually:${NC}"
        echo "1. Install sshpass: apt-get install sshpass"
        echo "2. Run: ./install_k3s.sh --add-worker <WORKER_IP> <USER> <PASSWORD>"
        echo "3. Or set K3S_TOKEN env var and run agent install on worker node"
    fi
fi