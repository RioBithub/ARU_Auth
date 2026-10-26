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

# Tunggu admin endpoint siap
for attempt in $(seq 1 30); do
  if docker exec "$KC_CONTAINER" sh -lc 'curl -fsS http://127.0.0.1:8080/realms/master >/dev/null 2>&1 || true' >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

echo "Login ke realm master..."
docker exec "$KC_CONTAINER" "$KCADM" config credentials \
  --server http://127.0.0.1:8080 \
  --realm master \
  --user "$KC_BOOTSTRAP_ADMIN_USERNAME" \
  --password "$KC_BOOTSTRAP_ADMIN_PASSWORD"

echo "Menerapkan theme ARU ke login realm master..."
docker exec "$KC_CONTAINER" "$KCADM" update realms/master \
  -s 'loginTheme=aru' \
  -s 'internationalizationEnabled=true' \
  -s 'supportedLocales=["id","en"]' \
  -s 'defaultLocale=id'

echo "Theme master realm sekarang:"
docker exec "$KC_CONTAINER" "$KCADM" get realms/master --fields realm,loginTheme,defaultLocale,internationalizationEnabled
