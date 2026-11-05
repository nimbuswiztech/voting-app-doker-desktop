#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
for c in docker kubectl; do command -v "$c" >/dev/null || { echo "Missing: $c"; exit 1; }; done
docker info >/dev/null
CTX="${K8S_CONTEXT:-docker-desktop}"
kubectl config get-contexts "$CTX" >/dev/null 2>&1 || { echo "Context '$CTX' not found"; exit 1; }
kubectl config use-context "$CTX" >/dev/null
echo "Context: $(kubectl config current-context)"
kubectl get nodes -o wide
mkdir -p .secrets
kubectl config view --raw --flatten --minify --context="$CTX" > .secrets/kubeconfig
chmod 600 .secrets/kubeconfig
while IFS= read -r node; do
  [ -n "$node" ] || continue
  docker inspect "$node" >/dev/null 2>&1 || {
    echo "Docker cannot inspect Kubernetes node '$node'."
    echo "Enable Docker Desktop > Kubernetes > Show system containers (advanced), then retry."
    exit 2
  }
done < <(kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
if [ ! -f .env ]; then cp .env.example .env; echo "Created .env; edit SONAR_DB_PASSWORD."; fi
echo "Preflight passed."
