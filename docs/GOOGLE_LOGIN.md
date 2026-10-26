# Google Login — ARU Account

ARU Account menggunakan Keycloak sebagai pusat identitas. Google hanya menjadi Identity Provider (IdP), bukan database akun kedua.

## Kenapa bukan Firebase Auth

Firebase Auth tidak diperlukan untuk flow ini karena Keycloak sudah menangani OIDC, SSO, account linking, session, role, dan identity brokering. Menambahkan Firebase sebagai lapisan autentikasi kedua akan membuat sumber identitas ganda dan proses linking lebih rumit.

## Google Cloud OAuth

Buat OAuth 2.0 Client ID bertipe **Web application** di Google Cloud Console.

Authorized redirect URI:

```
https://auth.aruraharja.co.id/realms/aru/broker/google/endpoint
```

Setelah mendapat Client ID dan Client Secret, jalankan di VPS:

```bash
cd /opt/apps/aru-auth
export GOOGLE_CLIENT_ID='...apps.googleusercontent.com'
export GOOGLE_CLIENT_SECRET='...'
./scripts/configure-google-idp.sh
unset GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET
```

Jangan commit Client Secret ke GitHub.

## Flow user baru dari Google

1. User memilih **Masuk dengan Google**.
2. Google mengembalikan email/nama terverifikasi ke Keycloak.
3. Jika belum ada identity link, Keycloak menjalankan First Broker Login.
4. Karena atribut pegawai wajib belum lengkap, user diarahkan ke Review Profile.
5. User melengkapi NIK/ID Pegawai, unit/divisi, jabatan, status kepegawaian, lokasi kerja, nomor HP, dan data lain yang diperlukan.
6. User baru masuk ke group default `pending-users` sampai admin memverifikasi.

## Jika email Google sama dengan akun ARU existing

Jangan membuat akun kedua dan jangan auto-link hanya berdasarkan string email.

Default First Broker Login Keycloak akan mendeteksi akun existing. Jika email sama tetapi identity Google belum pernah ditautkan, user diminta membuktikan bahwa ia memang pemilik akun existing (misalnya re-authentication dengan password ARU, atau verifikasi email jika SMTP sudah dikonfigurasi). Setelah link berhasil, login Google berikutnya langsung masuk ke akun ARU yang sama.

Ini sengaja lebih aman daripada AutoLink global. AutoLink berdasarkan email saja dapat menjadi risiko apabila sumber email tidak sepenuhnya dikontrol.

## Lokasi kerja

`work_location` adalah dropdown dengan default `Wisma Raharja`. Pilihan `Lainnya` menampilkan field `work_location_other` secara dinamis melalui theme JavaScript.

## Akses aplikasi

Authentication tidak sama dengan authorization. User `pending-users` belum seharusnya mendapat akses aplikasi internal. Aplikasi client harus memeriksa role/group yang sesuai, misalnya `aru-user`, sebelum memberi akses penuh.
