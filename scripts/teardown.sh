#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
echo "This stops only Compose services; it does NOT delete/reset Docker Desktop Kubernetes."
read -r -p "Type STOP to continue: " answer
[ "$answer" = "STOP" ] || exit 0
docker compose down
echo "Stopped. Volumes retained. To delete Compose data: docker compose down -v"
