# Agent Architecture

This document describes the design and internal pipeline architecture of the OpenTelemetry Node Agent (`otel-collector-agent`) deployed in the monitoring stack.

---

## 1. Node Agent Overview

The Node Agent runs as a **DaemonSet** on every Kubernetes node. Running on the host network, its primary role is local telemetry extraction, enrichment, and forwarding.

```
       +---------------------------------------------+
       |             Kubernetes Node                 |
       |                                             |
       |  [Host CPU/Memory]   [Kubelet HTTP API]     |
       |         |                    |              |
       |         v                    v              |
       |    +-------------+     +------------+       |   +-----------------------+
       |    | hostmetrics |     |kubeletstats|       |   | Pod Log Files         |
       |    +------+------+     +-----+------+       |   | /var/log/pods/*       |
       |           |                  |              |   +-----------+-----------+
       |           \                  /              |               |
       |            v                v               |               v
       |          +--------------------+             |       +---------------+
       |          |  Metrics Pipeline  |             |       | filelog       |
       |          +---------+----------+             |       +-------+-------+
       |                    |                        |               |
       |                    |                        |               v
       |                    |                        |       +---------------+
       |                    |                        |       | Logs Pipeline |
       |                    v                        |       +-------+-------+
       |         +---------------------+             |               |
       |         |    k8sattributes    |             |               |
       |         |      processor      |<----------------------------+
       |         +----------+----------+             |
       |                    |                        |
       |                    v                        |
       |         +---------------------+             |
       |         |    OTLP Exporter    |             |
       |         +----------+----------+             |
       +--------------------|------------------------+
                            | (gRPC: Port 4317)
                            v
               +--------------------------+
               |  otel-collector-gateway  |
               +--------------------------+
```

---

## 2. Telemetry Ingestion (Receivers)

The agent configures three receivers to collect different types of signals:

1. **`hostmetrics`**:
   - Collects operating system metrics from the host node.
   - Active scrapers: `cpu`, `memory`, `disk`, `filesystem`, `network`, and `load`.
   - Frequency: Every `30s`.
2. **`kubeletstats`**:
   - Scrapes metrics directly from the Kubelet API on the host node (`https://${K8S_NODE_NAME}:10250`).
   - Retrieves resource usage statistics for the Node, Pods, and individual Containers.
   - Communicates using the agent's `ServiceAccount` credentials with SSL validation bypassed (`insecure_skip_verify: true`).
3. **`filelog`**:
   - Audits container output by tailing log files mounted from the host at `/var/log/pods/*/*/*.log`.
   - Uses the built-in `container` helper operator to automatically parse container log formats (e.g. CRI, Docker).

---

## 3. Data Processing

All telemetry passes through these sequential processors:

1. **`memory_limiter`**: Ensures the collector agent drops telemetry data or rejects connection streams if it exceeds the memory threshold (configured at `256 MiB`).
2. **`k8sattributes`**:
   - Interacts with the Kubernetes API server using the agent's RBAC ServiceAccount.
   - Extracts metadata identifiers (such as `k8s.namespace.name`, `k8s.pod.name`, `k8s.container.name`, and `k8s.node.name`) and correlates them with the raw metrics/logs.
3. **`resource`**: Injects the node's hostname (`k8s.node.name`) as an attribute using environment variables set on the pod.
4. **`batch`**: Group telemetry inputs into batches of up to `1024` items or every `5s` to reduce network request overhead.

---

## 4. Exporting

Processed data is exported via OTLP gRPC protocol:
* **Target**: `otel-collector-gateway.monitoring.svc.cluster.local:4317`
* **Transport**: HTTP/2 over cleartext TCP (`tls.insecure: true`).
* **Destination**: The central gateway deployment, which serves as the router to the final backends (Loki, Tempo, Mimir).

---

## 5. Security & Isolation

* **ServiceAccount**: Runs under the `otel-collector-agent` service account.
* **RBAC Roles**: Assigned a `ClusterRole` that is restricted to `get`, `list`, and `watch` actions on:
  - `nodes`
  - `nodes/proxy`
  - `nodes/stats`
  - `pods`
  - `namespaces`
* **Host Networking**: Enabled (`hostNetwork: true`) to scrape Kubelet endpoints locally and run without DNS dependency inside the node namespace.
