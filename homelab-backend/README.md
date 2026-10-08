# FastAPI MicroK8s Homelab (Backend)

A homelab DevOps project that builds a FastAPI container image with GitHub Actions, publishes versioned images to GitHub Container Registry (GHCR), and deploys them to MicroK8s namespaces (`dev`, `stg`, `prod`) with Kustomize.

Repository: https://github.com/Pramukh660/fastapi-microk8s-homelab

## Architecture

```text
git push -> GitHub Actions -> GHCR image (tag = short SHA)
                                   |
        microk8s kubectl apply -k k8s/overlays/<env>
                                   |
              Namespace dev / stg / prod -> Deployment + Service
                                   |
                  Ingress: api.<env>.example.com
```

The matching frontend lives in `../homelab-frontend` and uses the same namespaces and hostnames.

## CI: Build and publish

Workflow: `.github/workflows/build-and-push.yml`

On each push to `main`, GitHub Actions publishes `ghcr.io/pramukh660/fastapi-microk8s-homelab:<7-character-sha>`. After the first run, set the GHCR package to **Public** (or configure an `imagePullSecret`).

## Deploy

See [k8s/README.md](k8s/README.md) for the full steps. In short:

1. Enable the ingress addon: `microk8s enable ingress`
2. Add hosts-file entries for `api.dev.example.com`, `api.stg.example.com`, `api.example.com`.
3. Set `newTag` in `k8s/overlays/<env>/kustomization.yaml` to the CI short SHA (or a locally imported tag).
4. `microk8s kubectl apply -k k8s/overlays/dev`
5. Verify: `curl http://api.dev.example.com/health`

## Application endpoints

- `/` — status message
- `/health` — health check
- `/docs` — Swagger UI

## Troubleshooting

- **Workflow cannot publish to GHCR**: check `packages: write` and the Actions logs.
- **`ImagePullBackOff`**: check image name/tag and GHCR visibility, or import the image locally.
- **Rollout problems**: `microk8s kubectl describe pods -n <env>` and `microk8s kubectl get events -n <env> --sort-by=.lastTimestamp`.
- **Host not resolving**: re-check the hosts file entries and the ingress IP.

## Future improvements

- TLS with cert-manager.
- Monitoring, logging, and automated rollback.
