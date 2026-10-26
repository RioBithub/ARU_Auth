# Deployment VPS + GitHub Actions

Target production: `/opt/apps/aru-auth`

## 1. Prasyarat VPS

- Ubuntu VPS
- Docker Engine + Docker Compose plugin
- Python 3
- user deployment memiliki akses menjalankan Docker
- Nginx/HestiaCP menangani HTTPS di port 443
- port Keycloak tidak dibuka publik; container bind ke `127.0.0.1:8180`

## 2. Secrets GitHub

Repository > Settings > Secrets and variables > Actions, tambahkan:

- `VPS_HOST` = IP/hostname VPS
- `VPS_USER` = user SSH deployment
- `VPS_SSH_PRIVATE_KEY` = private key SSH untuk deployment

Workflow **tidak** menyimpan `.env` di GitHub. Saat deploy pertama, VPS membuat `.env` sendiri melalui `scripts/generate-env.sh`.

## 3. Deploy

Workflow production dijalankan manual dari **Actions > Deploy ARU Auth > Run workflow** setelah tiga secret VPS tersedia.

Workflow melakukan:

1. checkout repo;
2. validasi secret deployment;
3. SSH ke VPS;
4. rsync source ke `/opt/apps/aru-auth`;
5. mempertahankan `.env` dan `backups/` di server;
6. generate `config/aru-realm.json` dari source;
7. `docker compose pull`;
8. `docker compose up -d`;
9. menampilkan status container.

## 4. Cloudflare

Sesudah aplikasi berjalan di VPS, buat record DNS:

- `A` record
- name `auth`
- target IP VPS

Untuk penerbitan SSL pertama lewat Hestia/Let's Encrypt, paling mudah gunakan DNS Only. Setelah origin certificate valid, Cloudflare proxy dapat diaktifkan dengan SSL/TLS `Full (strict)`.

## 5. Verifikasi di VPS

```bash
cd /opt/apps/aru-auth
./scripts/check.sh
curl -I https://auth.aruraharja.co.id/realms/aru/.well-known/openid-configuration
```

## 6. Rollback

Karena database berada pada named volume `aru_auth_postgres`, mengganti container image/source tidak menghapus database. Sebelum upgrade besar:

```bash
cd /opt/apps/aru-auth
./scripts/backup.sh
```

Kemudian checkout/tag commit sebelumnya dan jalankan kembali `./scripts/deploy.sh`.
