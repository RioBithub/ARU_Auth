# Kontrak Integrasi ARU Account

Issuer:
`https://auth.aruraharja.co.id/realms/aru`

Discovery:
`https://auth.aruraharja.co.id/realms/aru/.well-known/openid-configuration`

Flow:
- OpenID Connect Authorization Code
- PKCE S256 wajib
- Direct password grant dinonaktifkan

Client ID awal:
- `siap-aru`
- `aru-ticketing`
- `aru-meet`
- `aru-qrsign`
- `aru-link`
- `aru-vhc`

Claim tambahan:
- `employee_id`
- `unit`
- `position`
- `employment_status`
- `work_location`
- `phone_number`

Akses:
- akun self-register otomatis masuk group `pending-users` dan role `aru-pending`;
- setelah diverifikasi admin, pindahkan ke `employees`, yang memberi role `aru-user`;
- aplikasi yang sudah memakai SSO harus menolak akses jika token tidak memiliki `aru-user` atau `aru-admin`.

Catatan migrasi:
Login/register lokal existing tetap dipertahankan. Tombol baru menggunakan label **Masuk dengan ARU Account**. Setelah callback, aplikasi boleh melakukan account linking berdasarkan email yang sudah terverifikasi/diapprove oleh administrator.
