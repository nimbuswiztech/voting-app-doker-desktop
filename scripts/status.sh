#!/usr/bin/env bash
set -euo pipefail
docker compose ps
kubectl get nodes -o wide
kubectl get all -n votingapp 2>/dev/null || true
