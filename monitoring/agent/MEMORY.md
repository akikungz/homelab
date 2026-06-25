# AI Agent Workspace Memory

This file serves as the persistent memory log for AI agents working in this repository workspace, specifically detailing the analysis of the `monitoring` stack. It ensures that future agent sessions can instantly recover the state, context, and findings established in previous runs.

---

## 1. Session Context (June 25, 2026)

* **Goal**: Analyze the [monitoring](file:///c:/Users/akikungz/github/lab/monitoring) folder, explain its design, and establish persistent reference documentation for the agent architecture.
* **Status**: Completed. Documentation folder `agent/` created.

---

## 2. Core Knowledge: The Monitoring Stack (LGTM + OTel)

The stack is a Kubernetes-native deployment (configured using Kustomize) in the `monitoring` namespace.

### Component Summary & Ports
* **Grafana Loki** (`http://loki:3100`): Stores container and pod logs using a 20Gi PVC.
* **Grafana Tempo** (`http://tempo:3200`): Stores trace spans using a 20Gi PVC (24h retention).
* **Grafana Mimir** (`http://mimir:9009`): Monolithic metrics store with a 50Gi PVC.
* **Grafana** (`http://grafana:3000`): Provisions Mimir (default), Loki, and Tempo datasources using custom config maps.
* **OTel Gateway**: Receives metrics, logs, and traces.
  * Internal gRPC receiver: Port `4317` (unauthenticated).
  * External HTTP receiver: Port `4318` (authenticated using `OTEL_HTTP_BEARER_TOKEN`).
* **OTel Node Agent**: Runs as a `DaemonSet` on every cluster node. Gathers local `hostmetrics`, `kubeletstats`, and container stdout logs via `filelog`.

---

## 3. Key Configurations & Memory Limits

### Resource Allocation Settings
| Component | CPU Request/Limit | Memory Request/Limit | `memory_limiter` Config |
| :--- | :--- | :--- | :--- |
| **Node Agent** | `100m` / `500m` | `256Mi` / `1Gi` | limit: `256Mi`, spike: `64Mi` |
| **Gateway** | `100m` / `500m` | `256Mi` / `1Gi` | limit: `512Mi`, spike: `128Mi` |

### Limiter Tuning Recommendations
* **Agent**: Currently uses only 25% of the `1Gi` memory limit (`limit_mib: 256`). Recommended to tune `limit_mib` to `800` MiB and `spike_limit_mib` to `200` MiB to fully utilize the resource budget.
* **Gateway**: Currently uses 50% of the limit (`limit_mib: 512`). Recommended to tune `limit_mib` to `800` MiB and `spike_limit_mib` to `200` MiB.

---

## 4. Documentation Index

The following reference files have been created in the [agent](file:///c:/Users/akikungz/github/lab/monitoring/agent) subdirectory:
* **[README.md](file:///c:/Users/akikungz/github/lab/monitoring/agent/README.md)**: Index and quick references.
* **[ARCHITECTURE.md](file:///c:/Users/akikungz/github/lab/monitoring/agent/ARCHITECTURE.md)**: Detailed node agent pipelines and ingestion details.
* **[MEMORY.md](file:///c:/Users/akikungz/github/lab/monitoring/agent/MEMORY.md)**: This file (serving as the persistent AI Agent memory log & memory configs).

---

## 5. Deployment Instructions for Future Reference

To deploy the entire monitoring stack, use:
```powershell
# 1. Create env configurations from templates
cp monitoring/.env.config.example monitoring/.env.config
cp monitoring/.env.secrets.example monitoring/.env.secrets

# 2. Deploy via Kustomize
kubectl apply -k monitoring
```
To access Grafana dashboard locally:
```powershell
kubectl -n monitoring port-forward svc/grafana 3000:3000
```
