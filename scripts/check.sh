#!/usr/bin/env bash
set -euo pipefail
curl -fsS http://127.0.0.1:8180/realms/aru/.well-known/openid-configuration >/dev/null
echo "OK: realm aru aktif dan OIDC discovery tersedia"
