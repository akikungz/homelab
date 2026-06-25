# Storage (NFS CSI)

This folder deploys a Kubernetes StorageClass named nfs-csi.

The StorageClass values are sourced from a local .env file via Kustomize replacements:
- SERVER -> parameters.server
- SHARE_PATH -> parameters.share

## Files

- nfs-sc.yaml: StorageClass template with placeholders
- kustomization.yaml: Kustomize config, env generator, and replacements
- .env.example: Example environment values

## Configure

1. Create local env file:

   cp storage/.env.example storage/.env

2. Edit storage/.env with your NFS values:

   SERVER=<nfs-server-ip-or-hostname>
   SHARE_PATH=<nfs-export-path>

## Deploy

Apply with Kustomize (recommended):

kubectl apply -k storage

## Validate Rendered Output

Preview the final manifest before apply:

kubectl kustomize storage

You should see resolved values under:
- parameters.server
- parameters.share

## Important Notes

- Do not apply nfs-sc.yaml directly if it still contains placeholders (${SERVER}, ${SHARE_PATH}).
- Always apply via kustomization to ensure .env values are injected.
- Keep storage/.env out of Git. Only commit .env.example.

## Remove

kubectl delete -k storage
