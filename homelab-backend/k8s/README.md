# Homelab Backend: multi-env deploy

Kubernetes manifests for the FastAPI backend (app code and image build are in this repo).
Namespaces `dev`, `stg`, `prod`; API hosts `api.dev.example.com`, `api.stg.example.com`, `api.example.com`.
CORS is allowed from the matching frontend host via ingress annotations, so no backend code change is needed.

Pairs with `../homelab-frontend` (same namespaces, same hosts-file entries; see its README for ingress and hosts setup).

## Deploy

1. Set `newTag` in `k8s/overlays/<env>/kustomization.yaml` to the CI short SHA of the image (or import a local build and use that tag).
2. Apply:

   ```bash
   microk8s kubectl apply -k k8s/overlays/dev
   microk8s kubectl apply -k k8s/overlays/stg
   microk8s kubectl apply -k k8s/overlays/prod
   ```

3. Check: `curl http://api.dev.example.com/health` (needs the hosts entry).
