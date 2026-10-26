#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v docker >/dev/null || { echo "Docker belum terpasang"; exit 1; }
docker compose version >/dev/null || { echo "Docker Compose plugin belum tersedia"; exit 1; }
[[ -f .env ]] || ./scripts/generate-env.sh
mkdir -p backups
docker compose pull
docker compose up -d
sleep 5
docker compose ps
printf '\nHealth endpoint internal (setelah Keycloak siap): http://127.0.0.1:8180/realms/aru/.well-known/openid-configuration\n'
