# ARU Auth — Central Identity for PT Aru Raharja

Central identity service untuk seluruh aplikasi internal PT Aru Raharja tanpa mengubah `kita.aruraharja.co.id`.

## Tujuan

- `kita.aruraharja.co.id` tetap menjadi launcher/portal existing.
- `auth.aruraharja.co.id` menjadi ARU Account / Identity Provider.
- Login dan register lokal aplikasi existing tetap tersedia.
- Masing-masing aplikasi menambah tombol **Masuk dengan ARU Account**.
- Satu session ARU Account dapat dipakai lintas aplikasi melalui OIDC.

## Stack

- Keycloak 26.8.1
- PostgreSQL 16
- Docker Compose
- HestiaCP/Nginx reverse proxy
- OpenID Connect Authorization Code + PKCE S256

## Struktur

```text
ARU_Auth/
├── config/
│   └── user-profile.json
├── themes/aru/login/
├── nginx/
├── scripts/
│   └── build-realm.py
├── docs/
├── integration/
├── docker-compose.yml
└── .env.example
```

`config/aru-realm.json` adalah file generated dan tidak disimpan di Git. File tersebut dibuat otomatis oleh `scripts/build-realm.py` saat deployment.

## Aplikasi OIDC awal

- SIAP ARU
- ARU Ticketing
- Meet ARU
- QRSign
- ARU Link
- VHC

Daftar aplikasi dan origin dikelola di `scripts/build-realm.py`.

## Deployment VPS

GitHub digunakan sebagai source of truth, tetapi deployment ke VPS dilakukan **manual**.

Target:

```text
/opt/apps/aru-auth
```

Deploy pertama:

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

Update berikutnya:

```bash
cd /opt/apps/aru-auth
./scripts/backup.sh
git pull origin main
chmod +x scripts/*.sh scripts/*.py
./scripts/deploy.sh
```

`.env`, database, dan backup tidak disimpan di GitHub.

Keycloak hanya bind ke `127.0.0.1:8180`, sehingga port 8180 tidak perlu dibuka di UFW/iptables. Public traffic harus melewati Nginx/Hestia pada port 443.

## Hestia / Nginx

1. Tambahkan web domain `auth.aruraharja.co.id` pada user Hestia `aru`.
2. Aktifkan SSL/Let's Encrypt setelah DNS menunjuk VPS.
3. Jadikan domain tersebut reverse proxy ke `http://127.0.0.1:8180` menggunakan contoh konfigurasi pada folder `nginx/`.
4. Jalankan `nginx -t` sebelum reload.

## First login admin

Username admin bootstrap berasal dari `.env` (`KC_BOOTSTRAP_ADMIN_USERNAME`). Password dihasilkan oleh `scripts/generate-env.sh` dan tidak boleh dimasukkan ke Git.

Admin console:
`https://auth.aruraharja.co.id/admin/`

Realm aplikasi: `aru`

## Registration workflow

Self-register aktif, tetapi akun baru **tidak langsung dapat mengakses aplikasi**.

```text
Register
  -> pending-users
  -> role aru-pending
  -> diverifikasi administrator
  -> pindah ke employees
  -> role aru-user
  -> dapat digunakan oleh aplikasi SSO
```

Detail field ada di `docs/REGISTRATION_FIELDS.md`.

## OIDC discovery

`https://auth.aruraharja.co.id/realms/aru/.well-known/openid-configuration`

Kontrak integrasi lengkap ada di `integration/OIDC_CONTRACT.md`.

## Backup

```bash
./scripts/backup.sh
```

Backup PostgreSQL ditaruh di `backups/` dan folder tersebut di-ignore Git.

## Security baseline

- Password hanya disimpan di Keycloak, bukan disalin ke setiap aplikasi.
- Brute-force protection aktif.
- Direct Access Grant/password grant dinonaktifkan.
- PKCE S256 dipaksa pada client awal.
- Database tidak diekspos ke host/public network.
- Keycloak hanya listen pada loopback VPS.
- Akun self-register masuk status pending sampai diverifikasi admin.
- `.env` tidak boleh di-commit.

## SMTP / email verification

`verifyEmail` sengaja belum dipaksa pada bootstrap karena kredensial SMTP corporate belum ada di repository. Setelah SMTP ARU dikonfigurasi di Keycloak, aktifkan Verify Email pada Realm Settings > Login.

## Rollout

Urutan aman:
1. Deploy `auth.aruraharja.co.id` secara manual di VPS.
2. Uji register, pending approval, login, logout, reset password.
3. Integrasikan satu aplikasi pilot (disarankan Link/Meet).
4. Setelah stabil, lanjut Ticketing, QRSign, VHC, kemudian SIAP.
5. Login lokal existing tetap dipertahankan selama transisi.

Panduan deployment manual lebih lengkap ada di `docs/DEPLOY_VPS.md`.
