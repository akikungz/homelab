# OpenTelemetry Agent (Node Collector)

This directory contains documentation and architecture details regarding the OpenTelemetry Node Agent (`otel-collector-agent`) deployed in the monitoring stack.

The agent runs as a daemonset on all Kubernetes nodes to gather logs, host metrics, and container stats.

## Documentation Index

1. **[ARCHITECTURE.md](file:///c:/Users/akikungz/github/lab/monitoring/agent/ARCHITECTURE.md)**: 
   - Explains the collection pipelines (metrics and logs).
   - Details the receivers (`hostmetrics`, `kubeletstats`, `filelog`), processors (`k8sattributes`), and internal forwarding design.
2. **[MEMORY.md](file:///c:/Users/akikungz/github/lab/monitoring/agent/MEMORY.md)**:
   - Breaks down container resource requests, limits, and the OTel `memory_limiter` processor parameters.
   - Highlights tuning recommendations to align limits for optimized performance and prevention of OOM (Out Of Memory) crashes.

## Parent Manifests

The configuration and Kubernetes workloads referenced by this documentation are located in the parent folder:
* Manifest deployment: **[04-otel-collector-daemonset.yaml](file:///c:/Users/akikungz/github/lab/monitoring/04-otel-collector-daemonset.yaml)**
* Common central OTel gateway: **[03-otel-collector-gateway.yaml](file:///c:/Users/akikungz/github/lab/monitoring/03-otel-collector-gateway.yaml)**
* Master deployment descriptor: **[kustomization.yaml](file:///c:/Users/akikungz/github/lab/monitoring/kustomization.yaml)**
