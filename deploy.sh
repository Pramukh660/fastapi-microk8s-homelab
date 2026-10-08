#!/usr/bin/env bash
# Usage: ./deploy.sh <env> <image_tag> [backend|frontend|all]
# Example: ./deploy.sh dev ae85402
set -euo pipefail

env=${1:?env (dev|stg|prod)}
export IMAGE_TAG=${2:?image tag (short SHA)}
what=${3:-all}

cd "$(dirname "$0")"

for app in backend frontend; do
  [[ $what == all || $what == $app ]] || continue
  microk8s kubectl kustomize "homelab-$app/k8s/overlays/$env" \
    | envsubst '${IMAGE_TAG}' \
    | microk8s kubectl apply -f -
done
