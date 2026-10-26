# Form Registrasi ARU Account

Form registrasi disiapkan lebih lengkap tanpa memberi hak akses aplikasi secara otomatis.

Field utama:
1. Email
2. Nama depan
3. Nama belakang
4. NIK / ID Pegawai
5. Unit / Divisi
6. Jabatan
7. Status kepegawaian
8. Lokasi kerja
9. Nomor WhatsApp / HP
10. Kontak darurat (opsional)
11. Password + konfirmasi password (native Keycloak)

## Approval
Akun baru otomatis berstatus `aru-pending`. Administrator memverifikasi data pegawai dan memindahkan user dari group `pending-users` ke `employees`. Baru setelah itu aplikasi SSO menerima user tersebut.

Dengan pola ini, public registration tetap dapat tersedia tanpa membuat setiap orang yang mendaftar langsung memiliki akses ke SIAP, Ticketing, Meet, QRSign, Link, atau VHC.
