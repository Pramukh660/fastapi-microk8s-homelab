# Homelab Frontend + multi-env deploy

Static nginx frontend only; it calls the FastAPI backend deployed separately.
Namespaces `dev`, `stg`, `prod` on MicroK8s, routed by hostname through the ingress.

| Env  | Frontend           | API                    |
|------|--------------------|------------------------|
| dev  | dev.example.com    | api.dev.example.com    |
| stg  | stg.example.com    | api.stg.example.com    |
| prod | example.com        | api.example.com        |

The frontend image reads `API_URL` at container start (see `40-config.sh`), so one image serves every env.
The backend (separate project) must allow the frontend origin via CORS or ingress annotations.

## Local MicroK8s setup (laptop, no real domain)

1. Enable addons: `microk8s enable ingress`
2. Add hosts entries (run Notepad as Administrator, file `C:\Windows\System32\drivers\etc\hosts`).
   Use the IP where MicroK8s ingress is reachable (`127.0.0.1` if ports 80/443 are forwarded to localhost, otherwise the MicroK8s VM/server IP, e.g. `192.168.1.9`):

   ```
   192.168.1.9 dev.example.com api.dev.example.com
   192.168.1.9 stg.example.com api.stg.example.com
   192.168.1.9 example.com api.example.com
   ```

3. Get the images into MicroK8s. Either let CI publish them to GHCR (make packages public), or import local builds:

   ```bash
   docker build -t ghcr.io/pramukh660/homelab-frontend:local .
   docker save ghcr.io/pramukh660/homelab-frontend:local | microk8s ctr image import -
   ```

4. Set the image tags in `k8s/overlays/<env>/kustomization.yaml` (`newTag`), then deploy:

   ```bash
   microk8s kubectl apply -k k8s/overlays/dev
   microk8s kubectl apply -k k8s/overlays/stg
   microk8s kubectl apply -k k8s/overlays/prod
   ```

5. Open http://dev.example.com — the page should show `healthy` and the buttons call `http://api.dev.example.com`.

Check: `microk8s kubectl get pods,ingress -A | grep -E "dev|stg|prod"`

Note: the kustomize config uses plain HTTP; add TLS (cert-manager) later and change the `http://` URLs to `https://`.
