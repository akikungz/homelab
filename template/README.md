# Kubernetes Kustomize Application Template

A reusable template for deploying applications to the Kubernetes cluster using Kustomize. It is structured to share common configurations via the `base/` directory and customize resources, replicas, configurations, and namespaces via environment-specific `overlays/` (`development`, `staging`, and `production`).

## Directory Structure

```text
template/
├── README.md
├── base/
│   ├── deployment.yaml      # Shared base Deployment resource
│   ├── service.yaml         # Shared base Service resource
│   ├── pvc.yaml             # Shared base PersistentVolumeClaim resource
│   └── kustomization.yaml   # Base kustomization linking the resources
└── overlays/
    ├── development/         # Development environment overlay
    │   ├── kustomization.yaml
    │   ├── .env.config
    │   ├── .env.config.example
    │   ├── .env.secret
    │   └── .env.secret.example
    ├── staging/             # Staging environment overlay
    │   ├── kustomization.yaml
    │   ├── .env.config
    │   ├── .env.config.example
    │   ├── .env.secret
    │   └── .env.secret.example
    └── production/          # Production environment overlay
        ├── kustomization.yaml
        ├── .env.config
        ├── .env.config.example
        ├── .env.secret
        └── .env.secret.example
```

## How It Works

1. **Base**: Contains the core configuration. The deployment relies on environment variables supplied via `envFrom` referencing a ConfigMap named `template-app-config` and a Secret named `template-app-secret`.
2. **Overlays**:
   - Each overlay targets its own `namespace` (`development`, `staging`, or `production`).
   - Each overlay uses a `configMapGenerator` to create `template-app-config` from the environment-specific `.env.config` file.
   - Each overlay uses a `secretGenerator` to create `template-app-secret` from the environment-specific `.env.secret` file.
   - Each overlay includes a `patches` section to override resources (CPU/Memory requests & limits) and scale replicas appropriately for the target environment.

## Usage

### 1. Configure Environment Variables
Copy `.env.config.example` to `.env.config`, and `.env.secret.example` to `.env.secret` in the desired overlay directory, and update the values:
```bash
cp overlays/development/.env.config.example overlays/development/.env.config
cp overlays/development/.env.secret.example overlays/development/.env.secret
```

### 2. View Generated Manifests
You can inspect the fully generated YAML manifests before applying them using `kubectl kustomize`:

```bash
# View base manifests
kubectl kustomize base

# View environment-specific overlay manifests
kubectl kustomize overlays/development
kubectl kustomize overlays/staging
kubectl kustomize overlays/production
```

### 3. Deploy to the Cluster
Apply the manifests directly using the `-k` (kustomize) flag:

```bash
# Deploy to Development
kubectl apply -k overlays/development

# Deploy to Staging
kubectl apply -k overlays/staging

# Deploy to Production
kubectl apply -k overlays/production
```

### 4. Delete the Deployment
To remove the deployed resources:

```bash
kubectl delete -k overlays/development
```
