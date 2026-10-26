# Cloudflare DNS

Tambahkan record setelah vhost VPS siap:

- Type: `A`
- Name: `auth`
- IPv4: IP public VPS ARU
- Proxy status: **DNS only** saat instalasi/tes SSL pertama.

Setelah HTTPS origin stabil, proxy Cloudflare dapat diaktifkan. Gunakan SSL/TLS mode **Full (strict)** dan pastikan certificate origin/Hestia valid.
