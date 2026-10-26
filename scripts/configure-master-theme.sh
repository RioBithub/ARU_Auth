#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

[[ -f .env ]] || { echo ".env tidak ditemukan"; exit 1; }
set -a
# shellcheck disable=SC1091
source .env
set +a

KC_CONTAINER="aru-auth-keycloak"
KCADM="/opt/keycloak/bin/kcadm.sh"
SERVER="http://127.0.0.1:8080"

if ! docker ps --format '{{.Names}}' | grep -qx "$KC_CONTAINER"; then
  echo "Container $KC_CONTAINER belum berjalan."
  exit 1
fi

login_admin() {
  local user="$1"
  local password="$2"
  docker exec "$KC_CONTAINER" "$KCADM" config credentials \
    --server "$SERVER" \
    --realm master \
    --user "$user" \
    --password "$password" >/dev/null 2>&1
}

ADMIN_USER="${KC_BOOTSTRAP_ADMIN_USERNAME:-aruadmin}"
ADMIN_PASSWORD="${KC_BOOTSTRAP_ADMIN_PASSWORD:-}"

if [[ -z "$ADMIN_PASSWORD" ]] || ! login_admin "$ADMIN_USER" "$ADMIN_PASSWORD"; then
  echo "Credential admin dari .env tidak valid atau sudah berubah."
  read -r -p "Username admin/recovery master: " ADMIN_USER
  read -r -s -p "Password: " ADMIN_PASSWORD
  echo
  if ! login_admin "$ADMIN_USER" "$ADMIN_PASSWORD"; then
    echo "Login realm master gagal. Jalankan ./scripts/recover-admin.sh jika akses admin hilang."
    exit 1
  fi
fi

echo "Menerapkan theme ARU ke login realm master..."
docker exec "$KC_CONTAINER" "$KCADM" update realms/master \
  -s 'loginTheme=aru' \
  -s 'internationalizationEnabled=true' \
  -s 'supportedLocales=["id","en"]' \
  -s 'defaultLocale=id' >/dev/null

echo "Theme master realm sekarang:"
docker exec "$KC_CONTAINER" "$KCADM" get realms/master \
  --fields realm,loginTheme,defaultLocale,internationalizationEnabled
