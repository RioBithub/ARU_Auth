# Deployment VPS Manual

Target production: `/opt/apps/aru-auth`

GitHub hanya digunakan sebagai source code repository. Deployment ke VPS dilakukan manual dari server.

## 1. Prasyarat VPS

- Ubuntu VPS
- Git
- Docker Engine + Docker Compose plugin
- Python 3
- user deployment memiliki akses menjalankan Docker
- Nginx/HestiaCP menangani HTTPS di port 443
- port Keycloak tidak dibuka publik; container bind ke `127.0.0.1:8180`

## 2. Deploy pertama

```bash
sudo mkdir -p /opt/apps
cd /opt/apps
sudo git clone https://github.com/RioBithub/ARU_Auth.git aru-auth
sudo chown -R $USER:$USER /opt/apps/aru-auth
cd /opt/apps/aru-auth
chmod +x scripts/*.sh scripts/*.py
./scripts/generate-env.sh
./scripts/deploy.sh
```

`generate-env.sh` membuat `.env` lokal di VPS. File tersebut tidak boleh di-commit ke GitHub.

## 3. Update manual dari GitHub

Sebelum menarik perubahan baru, backup database terlebih dahulu:

```bash
cd /opt/apps/aru-auth
./scripts/backup.sh
git status
git pull origin main
chmod +x scripts/*.sh scripts/*.py
./scripts/deploy.sh
```

Jika `git status` menunjukkan perubahan lokal pada source code, jangan lakukan `git pull` sebelum perubahan tersebut diperiksa. `.env`, backup, dan file generated realm memang tidak perlu masuk Git.

## 4. Cloudflare

Sesudah aplikasi berjalan di VPS, buat record DNS:

- Type: `A`
- Name: `auth`
- Target: IP VPS ARU
- Proxy: `DNS Only` untuk setup awal SSL

Setelah origin SSL valid, Cloudflare proxy dapat diaktifkan menggunakan SSL/TLS `Full (strict)`.

Domain akhir:

```text
https://auth.aruraharja.co.id
```

## 5. Hestia / Nginx

Tambahkan domain `auth.aruraharja.co.id` pada user Hestia yang digunakan ARU, lalu pasang konfigurasi reverse proxy ke:

```text
http://127.0.0.1:8180
```

Contoh tersedia di folder `nginx/`.

Selalu validasi sebelum reload:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## 6. Verifikasi aplikasi

```bash
cd /opt/apps/aru-auth
./scripts/check.sh
curl http://127.0.0.1:8180/realms/aru/.well-known/openid-configuration
curl -I https://auth.aruraharja.co.id/realms/aru/.well-known/openid-configuration
```

## 7. Admin

Admin console:

```text
https://auth.aruraharja.co.id/admin/
```

Username bootstrap berasal dari `.env` dan password dibuat saat `generate-env.sh` dijalankan.

## 8. Backup dan rollback

Backup:

```bash
cd /opt/apps/aru-auth
./scripts/backup.sh
```

Untuk rollback source code:

```bash
cd /opt/apps/aru-auth
git log --oneline -10
git checkout <commit-yang-diinginkan>
./scripts/deploy.sh
```

Database berada pada Docker named volume dan tidak hilang hanya karena source/container diperbarui. Tetap lakukan backup sebelum upgrade besar.

## 9. Tidak ada CI/CD ke VPS

Repository ini sengaja tidak memiliki workflow deployment ke server. Push ke `main` hanya memperbarui source di GitHub. Perubahan baru masuk production setelah administrator melakukan `git pull` dan `./scripts/deploy.sh` secara manual di VPS.
