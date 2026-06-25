# Monitoring Stack (LGTM + OpenTelemetry)

This folder deploys a Kubernetes monitoring stack in the monitoring namespace:
- Grafana
- Loki
- Tempo
- Mimir
- OpenTelemetry Collector Gateway
- OpenTelemetry Collector DaemonSet (node agent)

## Prerequisites

- Kubernetes cluster access
- kubectl installed and configured
- A StorageClass named nfs-csi (used by PVCs)

## File Layout

- 00-namespace.yaml: Namespace
- 01-*.yaml: Component configs (ConfigMaps)
- 02-*.yaml: Loki, Tempo, Mimir workloads
- 03-*.yaml: Grafana and OTel Gateway workloads
- 04-otel-collector-daemonset.yaml: OTel node agent DaemonSet + RBAC
- 05-ingress.yaml: Ingress resources for Grafana and OTel HTTP
- kustomization.yaml: Main deployment entrypoint
- .env.config.example: Non-secret config template (ingress hosts)
- .env.secret.example: Secret template (credentials and tokens)

## Secret and Environment Setup

This setup is safe for GitHub when real secrets are kept in .env.secret only.

1. Copy the template:
   cp monitoring/.env.config.example monitoring/.env.config
   cp monitoring/.env.secret.example monitoring/.env.secret

2. Edit monitoring/.env.config (non-secret values):
   - STORAGE_CLASS (example: nfs-csi)
   - INGRESS_CLASS (example: nginx or traefik)
   - GRAFANA_INGRESS_HOST
   - OTEL_COLLECTOR_INGRESS_HOST

3. Edit monitoring/.env.secret with real values:
   - GRAFANA_ADMIN_USER
   - GRAFANA_ADMIN_PASSWORD
   - OTEL_HTTP_BEARER_TOKEN

4. Ensure monitoring/.env.secret is ignored by Git (recommended in repository .gitignore).

kustomization.yaml uses:
- secretGenerator to create Secret monitoring-env from .env.secret
- configMapGenerator to create ConfigMap monitoring-env from .env.config

## Deploy

Apply everything:

kubectl apply -k monitoring

## Verify

Check pods:

kubectl -n monitoring get pods

Check services:

kubectl -n monitoring get svc

Open Grafana locally:

kubectl -n monitoring port-forward svc/grafana 3000:3000

Then open http://localhost:3000 and log in with GRAFANA_ADMIN_USER and GRAFANA_ADMIN_PASSWORD from .env.

Ingress access (if ingress controller and DNS are configured):

- Grafana: http://$GRAFANA_INGRESS_HOST
- OTel HTTP: http://$OTEL_COLLECTOR_INGRESS_HOST/v1/{traces|metrics|logs}

Ingress controller selection examples:

- k3s (Traefik): INGRESS_CLASS=traefik
- Rancher Kubernetes with NGINX ingress: INGRESS_CLASS=nginx

## External Collector Authentication (OTLP HTTP)

The OTel Gateway OTLP HTTP endpoint requires bearer token authentication.

- Endpoint: http://<gateway-host>:4318/v1/{traces|metrics|logs}
- Header: Authorization: Bearer <OTEL_HTTP_BEARER_TOKEN>

## Update

Re-apply after manifest or secret changes:

kubectl apply -k monitoring

## Remove

kubectl delete -k monitoring
