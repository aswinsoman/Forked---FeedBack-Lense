#!/usr/bin/env bash
set -euo pipefail
HOST="$1"; PORT="${2:-4000}"
echo "Healthcheck http://${HOST}:${PORT}/ ..."
curl -fsS "http://${HOST}:${PORT}/" >/dev/null && echo "OK" || (echo "FAIL" && exit 1)
