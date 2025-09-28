#!/usr/bin/env bash
set -euo pipefail
cd /opt/feedback-lense
echo "Deploying to staging (local Docker build)..."
docker compose -f docker-compose.staging.localbuild.yml build --pull
docker compose -f docker-compose.staging.localbuild.yml up -d
docker image prune -f
