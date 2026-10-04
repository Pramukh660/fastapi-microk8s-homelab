# FastAPI MicroK8s Homelab

A homelab DevOps project that builds a FastAPI container image with GitHub Actions, publishes versioned images to GitHub Container Registry (GHCR), and deploys them to MicroK8s using Ansible.

Repository: https://github.com/Pramukh660/fastapi-microk8s-homelab

## Architecture

```text
Developer -> git push -> GitHub Repository
                         |
                         v
              GitHub Actions (CI)
              - Build container image
              - Tag with short Git SHA
              - Push image to GHCR
                         |
                         v
              GitHub Container Registry
                         |
                  Kubernetes pulls image
                         v
Ansible (WSL/Linux) --SSH--> Ubuntu Server / MicroK8s
                                  |
                                  v
                    Kubernetes Deployment -> FastAPI Pod
                                  |
                                  v
                          NodePort :30080
                                  |
                                  v
                           /health check
```

## Components

- **FastAPI/Uvicorn**: application and ASGI server.
- **Dockerfile**: repeatable container build instructions.
- **GitHub Actions**: builds and publishes an image on pushes to `main`.
- **GHCR**: stores versioned container images.
- **Ansible**: deploys a selected image tag to the homelab server.
- **MicroK8s/Kubernetes**: runs the app and exposes NodePort `30080`.

Docker is used on the GitHub-hosted runner for image building. Docker Engine is not required on the MicroK8s server. The new flow no longer needs Buildah on the server, image tar archives, or manual `ctr images import`.

## CI: Build and publish

Workflow: `.github/workflows/build-and-push.yml`

On each push to `main`, GitHub Actions builds the Dockerfile and publishes an image tagged with the short Git commit SHA:

`ghcr.io/pramukh660/fastapi-microk8s-homelab:<7-character-sha>`

The workflow uses `GITHUB_TOKEN` with `packages: write`; no personal access token is required for publishing.

### GHCR visibility

After the first successful workflow run, open the package in GitHub Packages and set visibility to **Public** if you want MicroK8s to pull without credentials. If the package remains private, configure a Kubernetes `imagePullSecret` before deploying.

## CD: Deploy with Ansible

Ansible deploys an image already published by CI. It does not clone the application repository on the server, build images, transfer archives, or import images into containerd.

### Prerequisites

- Ansible installed on WSL/Linux.
- SSH key authentication configured for the Ubuntu Server.
- MicroK8s installed and running.
- GHCR package public, or a Kubernetes pull secret configured.
- `ansible/inventory.ini` present locally and excluded from Git.

Example inventory:

```ini
[microk8s_servers]
dell ansible_host=192.168.1.9 ansible_user=pramukhjs

[microk8s_servers:vars]
ansible_ssh_private_key_file=~/.ssh/homelab_ed25519
ansible_python_interpreter=/usr/bin/python3
```

### Deploy

1. Push the application changes to `main`.
2. In GitHub, open **Actions** and wait for **Build and Publish FastAPI Image** to succeed.
3. Get the short SHA of the commit whose workflow succeeded:

   ```bash
   git rev-parse --short=7 HEAD
   ```

4. From the repository root, run the playbook with that SHA:

   ```bash
   ansible-playbook -i ansible/inventory.ini ansible/deploy.yml --ask-become-pass -e image_tag=abcdef1
   ```

   Replace `abcdef1` with the real seven-character SHA.

The playbook checks MicroK8s, renders the manifest, applies the Deployment and Service, waits for rollout, prints the deployed image, and checks `/health` from the Ansible control node.

## Application endpoints

For a server at `192.168.1.9`:

- App: http://192.168.1.9:30080/
- Health: http://192.168.1.9:30080/health
- Swagger UI: http://192.168.1.9:30080/docs

## Kubernetes

The manifest defines a single-replica Deployment and a NodePort Service. FastAPI listens on port `8000`; the service exposes node port `30080`. The image uses `imagePullPolicy: IfNotPresent`. Use unique SHA tags and treat them as immutable.

If a pod reports `ImagePullBackOff`, verify the exact tag exists in GHCR and that the package is public or the Kubernetes pull secret is correct.

## Troubleshooting

- **Workflow cannot publish to GHCR**: check `packages: write` and the Actions logs.
- **`ImagePullBackOff`**: check image name/tag and GHCR visibility or pull-secret configuration.
- **Rollout timeout**: inspect `sudo microk8s kubectl describe pods` and `sudo microk8s kubectl get events --sort-by=.lastTimestamp` on the server.
- **Health check fails from WSL**: verify NodePort `30080`, server reachability, and `sudo microk8s kubectl get pods,svc`.

## Previous implementation and lessons

The first version built images with Buildah on the server, exported a tar archive, and imported it into MicroK8s containerd. Troubleshooting included SSH file-transfer interruptions, sudo privilege-escalation issues, containerd import errors, and Buildah refusing to overwrite an existing Docker archive.

The GHCR design removes those manual image-transfer steps. CI builds and publishes the image; Ansible handles deployment and verification.

## Future improvements

- Trigger CD automatically after successful image publishing.
- Add Ingress and TLS.
- Add monitoring, logging, and automated rollback.
