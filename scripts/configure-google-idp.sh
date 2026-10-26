#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

[[ -f .env ]] || { echo ".env tidak ditemukan"; exit 1; }
set -a
# shellcheck disable=SC1091
source .env
set +a

GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-${1:-}}"
GOOGLE_CLIENT_SECRET="${GOOGLE_CLIENT_SECRET:-${2:-}}"

if [[ -z "$GOOGLE_CLIENT_ID" ]]; then
  read -r -p "Google OAuth Client ID: " GOOGLE_CLIENT_ID
fi

if [[ -z "$GOOGLE_CLIENT_SECRET" ]]; then
  read -r -s -p "Google OAuth Client Secret: " GOOGLE_CLIENT_SECRET
  echo
fi

[[ -n "$GOOGLE_CLIENT_ID" ]] || { echo "Google Client ID wajib diisi."; exit 1; }
[[ -n "$GOOGLE_CLIENT_SECRET" ]] || { echo "Google Client Secret wajib diisi."; exit 1; }

KC_CONTAINER="aru-auth-keycloak"
KCADM="/opt/keycloak/bin/kcadm.sh"
SERVER="http://127.0.0.1:8080"

if ! docker ps --format '{{.Names}}' | grep -qx "$KC_CONTAINER"; then
  echo "Container $KC_CONTAINER belum berjalan."
  exit 1
fi

echo "Login ke Keycloak Admin API..."
docker exec "$KC_CONTAINER" "$KCADM" config credentials \
  --server "$SERVER" \
  --realm master \
  --user "$KC_BOOTSTRAP_ADMIN_USERNAME" \
  --password "$KC_BOOTSTRAP_ADMIN_PASSWORD" >/dev/null

COMMON_ARGS=(
  -r aru
  -s alias=google
  -s displayName='Google'
  -s providerId=google
  -s enabled=true
  -s trustEmail=true
  -s storeToken=false
  -s linkOnly=false
  -s firstBrokerLoginFlowAlias='first broker login'
  -s "config.clientId=$GOOGLE_CLIENT_ID"
  -s "config.clientSecret=$GOOGLE_CLIENT_SECRET"
  -s 'config.defaultScope=openid profile email'
  -s 'config.syncMode=IMPORT'
)

if docker exec "$KC_CONTAINER" "$KCADM" get identity-provider/instances/google -r aru >/dev/null 2>&1; then
  echo "Google IdP sudah ada, memperbarui konfigurasi..."
  docker exec "$KC_CONTAINER" "$KCADM" update identity-provider/instances/google "${COMMON_ARGS[@]}" >/dev/null
else
  echo "Membuat Google IdP..."
  docker exec "$KC_CONTAINER" "$KCADM" create identity-provider/instances "${COMMON_ARGS[@]}" >/dev/null
fi

unset GOOGLE_CLIENT_SECRET

echo
echo "Google login aktif untuk realm ARU."
echo "Authorized redirect URI Google:"
echo "https://auth.aruraharja.co.id/realms/aru/broker/google/endpoint"
echo
echo "Catatan keamanan: akun existing dengan email yang sama tidak di-auto-link tanpa verifikasi."
echo "First Broker Login bawaan Keycloak akan meminta verifikasi/re-authentication saat diperlukan."
