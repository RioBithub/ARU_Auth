#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -f .env ]]; then
  echo ".env sudah ada; tidak diubah."
  exit 0
fi
DB_PASS="$(openssl rand -base64 36 | tr -d '\n' | tr '/+' '_-')"
ADMIN_PASS="$(openssl rand -base64 36 | tr -d '\n' | tr '/+' '_-')"
cat > .env <<EOF
KC_DB_DATABASE=aru_auth
KC_DB_USERNAME=aru_auth
KC_DB_PASSWORD=${DB_PASS}
KC_BOOTSTRAP_ADMIN_USERNAME=aruadmin
KC_BOOTSTRAP_ADMIN_PASSWORD=${ADMIN_PASS}
KC_HOSTNAME=https://auth.aruraharja.co.id
EOF
chmod 600 .env
echo "File .env dibuat. Simpan password admin di password manager dan jangan commit file ini."
