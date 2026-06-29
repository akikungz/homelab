# MetalLB Load Balancer Setup

This directory contains the Kubernetes manifests and Kustomize setup to deploy and configure [MetalLB](https://metallb.universe.tf/) in a personal homelab cluster.

MetalLB is a load-balancer implementation for bare metal Kubernetes clusters, using standard routing protocols. This deployment is configured to run in **Layer 2 (L2)** mode.

## Directory Structure

```text
metallb/
├── README.md              # Deployment guide and overview
├── .env.example           # Example configuration template
├── ipaddresspool.yaml     # Custom resource defining the IP pool
├── l2advertisement.yaml   # Custom resource defining L2 advertisement
└── kustomization.yaml     # Kustomize manifest tying everything together
```

## How It Works

1. **Helm Chart Integration**: The `kustomization.yaml` incorporates the official MetalLB Helm chart directly from `https://metallb.github.io/metallb`.
2. **Environment Configuration**: An environment-specific IP address range is specified in a local `.env` file.
3. **Kustomize Replacements**: The `.env` file is read via a `configMapGenerator` and used to replace the placeholder IP address range in `ipaddresspool.yaml` dynamically.

---

## Deployment Instructions

### Step 1: Configure Environment Variables

Before deploying, create the `.env` file from the example and set your desired IP range:

```bash
cp network/metallb/.env.example network/metallb/.env
```

Open `network/metallb/.env` and update the `IP_RANGE` to match the unused IP range of your local network/subnet (e.g. `192.168.1.200-192.168.1.250`).

### Step 2: Deploy to the Cluster

Since the Custom Resources (`IPAddressPool` and `L2Advertisement`) depend on Custom Resource Definitions (CRDs) installed by the base manifests, applying everything in a single run can fail on clean clusters. 

To deploy everything correctly, use the `--server-side` and `--enable-helm` apply flags:

```bash
kubectl apply -k network/metallb --server-side --enable-helm
```

Alternatively, you can run the standard apply command twice (allowing time for CRDs to register in-between):

```bash
# Step 2a: Run first apply to install CRDs and controllers
kubectl apply -k network/metallb --enable-helm

# (Wait 10-15 seconds for CRDs to be registered by Kubernetes)

# Step 2b: Run second apply to configure the IP pool and advertisement
kubectl apply -k network/metallb --enable-helm
```

---

## Verification

To verify that MetalLB is running correctly:

1. Check that the controller and speaker pods are running in the `metallb-system` namespace:
   ```bash
   kubectl get pods -n metallb-system
   ```

2. Verify that the IP Address Pool and Layer 2 Advertisements are configured:
   ```bash
   kubectl get ipaddresspools -n metallb-system
   kubectl get l2advertisements -n metallb-system
   ```

3. You can test MetalLB by deploying a Service of type `LoadBalancer`. MetalLB should automatically assign an IP from your configured `IP_RANGE` to the service.
