#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -f .env ]] || { echo ".env tidak ditemukan"; exit 1; }
set -a; source .env; set +a
mkdir -p backups
STAMP="$(date +%Y%m%d_%H%M%S)"
docker compose exec -T postgres pg_dump -U "$KC_DB_USERNAME" "$KC_DB_DATABASE" | gzip > "backups/aru_auth_${STAMP}.sql.gz"
echo "Backup: backups/aru_auth_${STAMP}.sql.gz"
