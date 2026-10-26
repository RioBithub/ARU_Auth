#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

TEMP_ADMIN="${1:-aru-recovery-admin}"

command -v docker >/dev/null || { echo "Docker belum terpasang"; exit 1; }
docker compose version >/dev/null || { echo "Docker Compose plugin belum tersedia"; exit 1; }

if ! docker compose ps postgres --status running >/dev/null 2>&1; then
  echo "PostgreSQL ARU Auth belum berjalan."
  exit 1
fi

echo "Membuat temporary recovery admin Keycloak: $TEMP_ADMIN"
echo "Keycloak akan dihentikan sementara sesuai prosedur recovery resmi."

docker compose stop keycloak >/dev/null

cleanup() {
  docker compose up -d keycloak >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo

echo "Masukkan password sementara saat diminta oleh Keycloak."
echo "Password tidak perlu dimasukkan ke command line atau .env."
echo

docker compose run --rm --no-deps keycloak bootstrap-admin user --username "$TEMP_ADMIN"

echo

echo "Recovery admin berhasil dibuat. Menyalakan Keycloak kembali..."
docker compose up -d keycloak >/dev/null
trap - EXIT

echo

echo "Login Admin Console dengan:"
echo "Username: $TEMP_ADMIN"
echo "Password: password sementara yang baru saja dimasukkan"
echo
echo "Setelah akses permanent admin pulih, hapus akun temporary ini dari realm master."
