#!/usr/bin/env bash
set -euo pipefail
docker exec voting-jenkins cat /var/jenkins_home/secrets/initialAdminPassword
