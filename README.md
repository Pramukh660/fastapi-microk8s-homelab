# Homelab: FastAPI + Frontend on MicroK8s

A homelab DevOps project: a FastAPI backend and a static nginx frontend, built by GitHub Actions, published to GitHub Container Registry (GHCR) and deployed to MicroK8s in separate `dev`, `stg` and `prod` namespaces, routed by hostname through the ingress.

## Repository layout

```text
Homelab/
├── .github/workflows/
│   ├── build-backend.yml      # builds and pushes the backend image to GHCR
│   └── build-frontend.yml     # builds and pushes the frontend image to GHCR
├── homelab-backend/           # FastAPI app, Dockerfile, k8s manifests
│   └── k8s/{base,overlays/{dev,stg,prod}}
├── homelab-frontend/          # static page + nginx Dockerfile, k8s manifests
│   └── k8s/{base,overlays/{dev,stg,prod}}
└── deploy.sh                  # deploys an image tag to an environment
```

## Architecture

```text
git push -> GitHub Actions -> GHCR (images tagged with short SHA)
                                   |
                          MicroK8s pulls image
                                   v
        deploy.sh <env> <sha>  ->  kustomize overlay  ->  namespace dev | stg | prod
                                                              |
                                                       nginx ingress
                                                        /          \
                                          <env>.example.com    api.<env>.example.com
                                             (frontend)             (backend)
```

| Env  | Frontend         | API                  |
|------|------------------|----------------------|
| dev  | dev.example.com  | api.dev.example.com  |
| stg  | stg.example.com  | api.stg.example.com  |
| prod | example.com      | api.example.com      |

The frontend image reads `API_URL` at container start, so one image serves every environment. The backend ingress allows CORS from the matching frontend host.

## Images

| App      | Image                                              |
|----------|----------------------------------------------------|
| Backend  | `ghcr.io/pramukh660/fastapi-microk8s-homelab:<sha>` |
| Frontend | `ghcr.io/pramukh660/homelab-frontend:<sha>`         |

Each workflow runs on pushes to `main` that touch its own folder, and tags the image with the 7-character commit SHA.

## Prerequisites

- MicroK8s running on the server, with the `ingress` addon enabled.
- Both GHCR packages set to **Public** (otherwise add a Kubernetes `imagePullSecret`).
- `envsubst`, provided by the `gettext-base` package on Ubuntu.
- Hosts entries on your client machine (no real domain is used locally).

## Deploy

### Usage

```bash
./deploy.sh <env> <tag> [backend|frontend|all]
./deploy.sh dev ae85402            # both apps to dev
./deploy.sh prod ae85402 backend   # backend only to prod
```

Running `kubectl apply -k` directly no longer works, because the image tag in the overlays is a `${IMAGE_TAG}` placeholder, not a valid tag. Always go through `deploy.sh`.

### Full steps

1. Commit and push from `~/Homelab`. `git rev-parse --short=7 HEAD` gives the SHA that CI tags both images with. Use that SHA, not `ae85402`, unless it matches.
2. Wait for both Actions workflows to pass, then make both GHCR packages public.
3. Enable ingress: `microk8s enable ingress`.
4. Add the hosts entries (see below).
5. Deploy: `./deploy.sh dev <sha>`, then `stg` and `prod` when dev works.
6. Verify: `microk8s kubectl get pods,ingress -n dev`, then `curl http://api.dev.example.com/health`, then open http://dev.example.com.

### Hosts entries

Add to `C:\Windows\System32\drivers\etc\hosts` (edit as Administrator), using the IP where the MicroK8s ingress is reachable (`127.0.0.1` locally, or the server IP such as `192.168.1.9`):

```text
192.168.1.9 dev.example.com api.dev.example.com
192.168.1.9 stg.example.com api.stg.example.com
192.168.1.9 example.com api.example.com
```

### Deploying from the server

```bash
git clone https://github.com/Pramukh660/fastapi-microk8s-homelab.git ~/Homelab
cd ~/Homelab
sudo apt install -y gettext-base
sudo usermod -aG microk8s $USER      # log out and back in once
./deploy.sh dev $(git rev-parse --short=7 HEAD)
```

Check from the server without DNS:

```bash
curl -H "Host: api.dev.example.com" http://localhost/health
curl -H "Host: dev.example.com" http://localhost/
```

## Notes

- `deploy.sh` needs `envsubst`, which comes with the `gettext-base` package on Ubuntu. Install it if it's missing.
- Each environment can run a different tag. For example, `./deploy.sh stg <older-sha>` leaves dev on the newer one.
- Later, the same script can run from CI or Ansible, so only the tag needs passing in.
- Everything uses plain HTTP for now. Add TLS (for example cert-manager) later and switch the URLs to `https://`.

## Troubleshooting

- **`ImagePullBackOff`**: the tag doesn't exist yet, or the GHCR package is private. Run `microk8s kubectl describe pod -n dev`.
- **`envsubst: command not found`**: install `gettext-base`.
- **nginx 404**: the hosts entry points at the wrong IP, the `Host` header doesn't match, or the ingress addon isn't running.
- **Page shows "unreachable"**: the backend pod isn't ready, or CORS is blocking the call. Check the browser console.
- **`permission denied` from `microk8s`**: run with `sudo`, or add your user to the `microk8s` group.
