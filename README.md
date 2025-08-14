# K3s Installation Script

This script automates the installation and configuration of a k3s Kubernetes cluster with additional components.

## Features

- Installs k3s (lightweight Kubernetes)
- Configures Traefik as a LoadBalancer
- Installs cert-manager for TLS certificates
- Deploys Rancher management UI
- Supports both single-node and multi-node clusters

## Requirements

- Ubuntu/Debian Linux
- Root/sudo access
- Internet connectivity
- Minimum 2GB RAM, 2 vCPUs

## Usage

1. Make the script executable:
   ```bash
   chmod +x install_k3s.sh
   ```

2. Run the script:
   ```bash
   sudo ./install_k3s.sh
   ```

3. Access Rancher dashboard at:
   ```
   https://rancher-con.tawfiqulbari.work
   ```

## Components

- **k3s**: Lightweight Kubernetes distribution
- **Traefik**: Ingress controller configured as LoadBalancer
- **cert-manager**: Automated TLS certificate management
- **Rancher**: Kubernetes management UI

## Customization

Edit the following variables in the script:
- `RANCHER_HOSTNAME`: Set your domain for Rancher
- `K3S_TOKEN`: Change the cluster join token
- `NODE_IPS`: Add your node IPs for multi-node setup

## Notes

- Script assumes Ubuntu/Debian environment
- Requires ports 80/443 to be available
- DNS must point to your server IP