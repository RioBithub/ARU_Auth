#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

[[ -f .env ]] || { echo ".env tidak ditemukan"; exit 1; }
[[ -f config/user-profile.json ]] || { echo "config/user-profile.json tidak ditemukan"; exit 1; }

set -a
# shellcheck disable=SC1091
source .env
set +a

KC_CONTAINER="aru-auth-keycloak"
KCADM="/opt/keycloak/bin/kcadm.sh"
SERVER="http://127.0.0.1:8080"
TMP_PROFILE="/tmp/aru-user-profile.json"

docker exec "$KC_CONTAINER" "$KCADM" config credentials \
  --server "$SERVER" \
  --realm master \
  --user "$KC_BOOTSTRAP_ADMIN_USERNAME" \
  --password "$KC_BOOTSTRAP_ADMIN_PASSWORD" >/dev/null

docker cp config/user-profile.json "$KC_CONTAINER:$TMP_PROFILE" >/dev/null

docker exec "$KC_CONTAINER" "$KCADM" update users/profile \
  -r aru \
  -f "$TMP_PROFILE" >/dev/null

docker exec "$KC_CONTAINER" rm -f "$TMP_PROFILE"

echo "User Profile realm ARU berhasil diperbarui."
docker exec "$KC_CONTAINER" "$KCADM" get users/profile -r aru --fields attributes.name,groups.name
