#!/usr/bin/env bash
set -Eeuo pipefail
docker exec voting-jenkins sh -lc 'kubectl config current-context && kubectl get nodes -o wide && docker version'
while IFS= read -r node; do
  [ -n "$node" ] || continue
  docker exec voting-jenkins docker inspect "$node" --format '{{.Name}}'
  docker exec "$node" ctr version
done < <(kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
