# FastAPI MicroK8s Homelab

A hands-on homelab project for deploying a **FastAPI application to MicroK8s using Ansible and GitHub**.

The deployment is fully automated from the Ansible control machine. Ansible connects to the Ubuntu Server over SSH, pulls the latest code directly from GitHub, builds the container image with Buildah, imports it into MicroK8s containerd, and deploys it to Kubernetes.

## Architecture

```text
                    GitHub
                       │
                       │ git clone / pull
                       ▼
              ┌───────────────────┐
              │   Ubuntu Server   │
              │     MicroK8s      │
              └───────────────────┘
                       ▲
                       │ SSH
                       │
              ┌───────────────────┐
              │      Ansible      │
              │   Control Node    │
              │      (WSL)        │
              └───────────────────┘

Ubuntu Server:
    GitHub Repository
          │
          ▼
       Buildah
          │
          ▼
 fastapi-homelab:<git-sha>
          │
          ▼
 MicroK8s containerd
          │
          ▼
 Kubernetes Deployment
          │
          ▼
   NodePort :30080
          │
          ▼
 FastAPI Application
```

## Project Structure

```text
fastapi-microk8s-homelab/
├── app/
│   └── main.py
├── ansible/
│   ├── deploy.yml
│   └── inventory.ini
├── k8s/
│   └── deployment.yaml
├── Dockerfile
├── requirements.txt
└── .gitignore
```

## Technologies

* Python
* FastAPI
* Uvicorn
* Ansible
* GitHub
* Buildah
* MicroK8s
* Kubernetes
* containerd
* Ubuntu Server
* WSL

## Application

The FastAPI application runs on port `8000` inside the Kubernetes pod.

Example endpoints:

```text
GET /
GET /health
```

Swagger documentation:

```text
/docs
```

## Kubernetes Configuration

The Kubernetes manifest defines both the Deployment and Service.

```yaml
kind: Deployment
```

The application runs as a single replica:

```text
replicas: 1
```

The Service uses a NodePort:

```text
Port:     8000
Target:   8000
NodePort: 30080
```

The application can therefore be accessed through:

```text
http://<server-ip>:30080
```

Health endpoint:

```text
http://<server-ip>:30080/health
```

Swagger UI:

```text
http://<server-ip>:30080/docs
```

## Git-Based Image Tagging

Each deployment uses the short Git commit SHA as the container image tag.

Example:

```text
fastapi-homelab:9ea7f31
```

This provides a direct relationship between:

```text
Git commit
    ↓
Container image
    ↓
Kubernetes deployment
```

It also makes it easy to identify which source revision is currently deployed.

## Deployment Workflow

The Ansible playbook performs the following steps:

```text
1. Connect to Ubuntu Server using SSH key
2. Install Git and Buildah
3. Verify MicroK8s is ready
4. Clone/update the GitHub repository
5. Get the current Git commit SHA
6. Build the FastAPI image with Buildah
7. Export the image as a Docker-compatible archive
8. Import the image into MicroK8s containerd
9. Render the Kubernetes manifest
10. Apply the Kubernetes resources
11. Wait for the deployment rollout
12. Check the FastAPI health endpoint
13. Remove temporary files
```

## Requirements

### Ansible Control Node

Install:

* Ansible
* SSH
* Git

The control node can be WSL or another Linux system.

### Ubuntu Server

The server requires:

* Ubuntu Server
* MicroK8s
* SSH access
* Git
* Buildah

Docker is **not required** on the server.

MicroK8s uses its own containerd runtime.

## SSH Configuration

The Ansible inventory uses SSH key authentication.

Example:

```ini
[microk8s_servers]
dell ansible_host=192.168.1.9 ansible_user=pramukhjs

[microk8s_servers:vars]
ansible_ssh_private_key_file=~/.ssh/homelab_ed25519
ansible_python_interpreter=/usr/bin/python3
```

Make sure the corresponding public key is configured in:

```text
~/.ssh/authorized_keys
```

on the Ubuntu Server.

## GitHub Repository

The server pulls the application directly from GitHub.

Example repository:

```text
https://github.com/Pramukh660/fastapi-microk8s-homelab
```

The deployment does **not** copy the application or container image from the Ansible control node.

There is no SCP step in the deployment workflow.

## Deploy

From the Ansible control node:

```bash
cd ~/homelab-ansible
```

Run:

```bash
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/deploy.yml \
  --ask-become-pass
```

Ansible will:

```text
GitHub → Server → Buildah → MicroK8s → FastAPI
```

## Verify Deployment

Check Kubernetes resources:

```bash
sudo microk8s kubectl get pods
```

```bash
sudo microk8s kubectl get deployment
```

```bash
sudo microk8s kubectl get service
```

Check the image:

```bash
sudo microk8s ctr images list | grep fastapi-homelab
```

Check the deployment:

```bash
sudo microk8s kubectl rollout status deployment/fastapi-homelab
```

Test the application:

```bash
curl http://192.168.1.9:30080/health
```

## Updating the Application

Modify the FastAPI application:

```text
app/main.py
```

Commit and push the changes:

```bash
git add .
git commit -m "feat: update FastAPI endpoint"
git push
```

Then run the Ansible deployment again:

```bash
ansible-playbook \
  -i ansible/inventory.ini \
  ansible/deploy.yml \
  --ask-become-pass
```

Ansible pulls the new GitHub commit and builds a new image tagged with the new commit SHA.

## Container Image Strategy

The project contains a `Dockerfile`, but the server does not require Docker.

Buildah is used to build the image:

```bash
buildah bud
```

The resulting image is exported to an archive and imported into MicroK8s:

```bash
microk8s ctr images import
```

The Kubernetes Deployment uses:

```yaml
imagePullPolicy: Never
```

because the image is loaded directly into the MicroK8s containerd instance rather than pulled from a registry.

## Health Checks

The Kubernetes Deployment includes a readiness probe:

```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 8000
```

This allows Kubernetes to determine when the FastAPI application is ready to receive traffic.

## Why This Setup?

This project is designed as a practical homelab implementation of a small CI/CD-style deployment workflow.

It demonstrates:

```text
Git
 ↓
Configuration Management
 ↓
Container Build
 ↓
Container Runtime
 ↓
Kubernetes Deployment
 ↓
Application Health Check
```

It also provides experience with:

* Infrastructure automation using Ansible
* SSH-based administration
* Git-driven deployments
* Container image lifecycle
* Kubernetes networking
* MicroK8s
* containerd
* FastAPI deployment
* Reproducible application releases

## Future Improvements

Possible next steps include:

* GitHub Actions for automated deployment
* Private container registry
* Kubernetes Ingress
* TLS/HTTPS
* ConfigMaps and Secrets
* Persistent storage
* Horizontal scaling
* Monitoring and logging
* Automatic rollback
* Ansible role-based structure

## License

This project is intended primarily for learning, experimentation, and homelab use.
