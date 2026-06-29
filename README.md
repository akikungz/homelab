# Homelab Kubernetes Deployment Stack

This repository contains Kubernetes manifests, configurations, and templates used to manage and deploy services in a personal homelab cluster using **Kustomize**.

---

## 📁 Repository Structure

*   **[`network/metallb/`](./network/metallb)**: Deploys and configures the MetalLB load balancer in Layer 2 mode with dynamic IP range configurations.
*   **[`storage/nfs/`](./storage/nfs)**: Configures and deploys the NFS CSI StorageClass (`nfs-csi`) using environment variable replacements.
*   **[`monitoring/`](./monitoring)**: Deploys the LGTM monitoring stack along with OpenTelemetry (Grafana, Loki, Tempo, Mimir, OTel Collector Gateway, and OTel DaemonSet agent).
*   **[`template/`](./template)**: A reusable application template structure using `base` and overlay-specific environments (`development`, `staging`, and `production`) for consistent, multi-environment app deployments.

---

## 🛠️ Getting Started

### Prerequisites

- A running Kubernetes cluster (e.g., k3s, Rancher, kubeadm).
- `kubectl` CLI installed and configured with access to the cluster.
- `kustomize` (often built into `kubectl` via the `-k` or `--kustomize` flag).

---

## ⚙️ Stack Details & Deployment

### 1. Storage (NFS CSI)

Sets up the persistent storage backbone using an NFS backend.

*   **Path**: [`storage/nfs/`](./storage/nfs)
*   **Setup**:
    ```bash
    cp storage/nfs/.env.example storage/nfs/.env
    # Edit storage/nfs/.env with your NFS Server and Share Path
    ```
*   **Deploy**:
    ```bash
    kubectl apply -k storage/nfs
    ```
*   Refer to the [Storage README](./storage/nfs/README.md) for more details.

### 2. Monitoring (LGTM + OpenTelemetry)

Deploys a complete observability stack under the `monitoring` namespace.

*   **Path**: [`monitoring/`](./monitoring)
*   **Components**:
    *   **Grafana**: Visualization dashboard.
    *   **Loki**: Log aggregation.
    *   **Tempo**: Distributed tracing.
    *   **Mimir**: Metric storage.
    *   **OpenTelemetry Collector**: Collects, processes, and exports telemetry data.
*   **Setup**:
    ```bash
    cp monitoring/.env.config.example monitoring/.env.config
    cp monitoring/.env.secret.example monitoring/.env.secret
    # Edit the config and secret files with your hostnames and credentials
    ```
*   **Deploy**:
    ```bash
    kubectl apply -k monitoring
    ```
*   Refer to the [Monitoring README](./monitoring/README.md) for detailed configuration, ingress setup, and validation steps.

### 3. Network (MetalLB)

Deploys the MetalLB load balancer to provide external IP addresses to Services of type `LoadBalancer` inside your local subnet.

*   **Path**: [`network/metallb/`](./network/metallb)
*   **Setup**:
    ```bash
    cp network/metallb/.env.example network/metallb/.env
    # Edit network/metallb/.env with your local IP range pool
    ```
*   **Deploy**:
    ```bash
    kubectl apply -k network/metallb --server-side --enable-helm
    ```
*   Refer to the [MetalLB README](./network/metallb/README.md) for more details on configuration, BGP, and validation.

### 4. Application Template

A boilerplate/blueprint for deploying new applications with separate environment configurations.

*   **Path**: [`template/`](./template)
*   **Environments**: `development`, `staging`, `production`.
*   **Setup & Deploy**:
    ```bash
    # For development environment
    cp template/overlays/development/.env.config.example template/overlays/development/.env.config
    cp template/overlays/development/.env.secret.example template/overlays/development/.env.secret
    kubectl apply -k template/overlays/development
    ```
*   Refer to the [Template README](./template/README.md) for structure and customization instructions.

---

## 🔒 Security & Git Best Practices

Sensitive credentials, hostnames, and local settings are externalized using `.env` files. Ensure you never commit active `.env` or `.env.secret` files to Git. The root [`.gitignore`](./.gitignore) is configured to keep these files private.

*   Only edit and apply locally.
*   Always copy from the `.example` files when setting up a new environment.
