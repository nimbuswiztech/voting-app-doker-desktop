#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
./scripts/prepare.sh
docker compose up -d --build
docker compose ps
echo "Jenkins: http://localhost:8080"
echo "SonarQube: http://localhost:9000"
echo "Jenkins initial password:"
docker exec voting-jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || true
