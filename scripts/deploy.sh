#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

command -v docker >/dev/null || { echo "Docker belum terpasang"; exit 1; }
command -v python3 >/dev/null || { echo "Python 3 belum terpasang"; exit 1; }
command -v curl >/dev/null || { echo "curl belum terpasang"; exit 1; }
docker compose version >/dev/null || { echo "Docker Compose plugin belum tersedia"; exit 1; }

[[ -f .env ]] || ./scripts/generate-env.sh
mkdir -p backups

python3 ./scripts/build-realm.py
python3 -m json.tool ./config/aru-realm.json >/dev/null

docker compose pull
docker compose up -d

OIDC_URL="http://127.0.0.1:8180/realms/aru/.well-known/openid-configuration"
echo "Menunggu ARU Auth siap..."

for attempt in $(seq 1 45); do
  if curl -fsS "$OIDC_URL" >/dev/null 2>&1; then
    echo "ARU Auth siap."
    docker compose ps
    echo "OIDC internal: $OIDC_URL"
    exit 0
  fi

  keycloak_state="$(docker inspect -f '{{.State.Status}}' aru-auth-keycloak 2>/dev/null || true)"
  keycloak_restarting="$(docker inspect -f '{{.State.Restarting}}' aru-auth-keycloak 2>/dev/null || true)"

  if [[ "$keycloak_state" == "exited" || "$keycloak_restarting" == "true" ]]; then
    echo "Keycloak gagal start. Log terakhir:"
    docker logs aru-auth-keycloak --tail 120 || true
    exit 1
  fi

  sleep 2
done

echo "Timeout menunggu Keycloak siap. Status dan log terakhir:"
docker compose ps || true
docker logs aru-auth-keycloak --tail 120 || true
exit 1
