# Dotfiles & Zsh Environment Setup

Kumpulan script untuk memasang dependensi CLI dan mengatur lingkungan Zsh pada
Linux serta macOS. Script tambahan tersedia untuk Fail2Ban, Zsh root, dan
hardening SSH Linux.

## Struktur Script

```text
Install/
├── 01-install-deps.sh     # Instal dependensi dan clone repository
├── 02-setup-zsh.sh        # Atur Zsh, Oh My Zsh, plugin, dan konfigurasi
├── 03-install-fail2ban.sh # Instal dan konfigurasi Fail2Ban pada Linux
├── 04-zsh-root.sh         # Salin konfigurasi Zsh user ke root
└── 05-harden-ssh.sh       # Hardening SSH melalui drop-in sshd
```

## Persyaratan dan Dukungan

- Bash, koneksi internet, dan `git`.
- `sudo` untuk instalasi paket atau perubahan sistem jika tidak dijalankan
  sebagai root.
- `01-install-deps.sh` mendukung Ubuntu, Debian, Raspbian, Fedora, RHEL,
  CentOS, Rocky Linux, AlmaLinux, Arch Linux, dan macOS.
- `03-install-fail2ban.sh` ditujukan untuk Linux dengan systemd dan iptables;
  script menolak berjalan di macOS.
- `05-harden-ssh.sh` membutuhkan Linux, systemd, OpenSSH `sshd`, serta direktori
  `/etc/ssh/sshd_config.d/`.
- Jalankan `02-setup-zsh.sh` sebagai user biasa, bukan dengan `sudo`. Installer
  utama akan menjalankannya sebagai user asli jika installer dipanggil melalui
  `sudo`.

Dukungan distro dapat berbeda antar-script. Khususnya, cek persyaratan script
tambahan sebelum menjalankannya pada distro yang tidak tercantum di atas.

## Instalasi

Clone repository dan jalankan installer utama:

```bash
git clone https://github.com/New8ie/Dotfiles.git ~/.dotfiles
cd ~/.dotfiles
bash ./Install/01-install-deps.sh
```

Installer utama mendeteksi OS, menginstal paket yang tersedia untuk platform,
dan clone repository ke home user jika belum ada. Pada akhirnya:

- Pilih **1** untuk menjalankan `02-setup-zsh.sh`.
- Pilih **2** untuk melewati setup Zsh.

Jika memilih **1**, setup Zsh berjalan secara interaktif. Ikuti prompt metode
konfigurasi dan menu langkah berikutnya; installer utama baru selesai setelah
script setup tersebut keluar.

## Setup Zsh

Untuk menjalankan setup secara terpisah:

```bash
bash ./Install/02-setup-zsh.sh
```

Sebelum setup, script menawarkan metode konfigurasi:

1. **Update / Merge** — memperbarui file yang dikelola tanpa menghapus file
   lain yang sudah ada.
2. **Replace / Sync** — mengganti direktori konfigurasi yang dikelola. File
   lama dalam direktori tersebut yang tidak ada di repository dapat dihapus;
   backup dibuat terlebih dahulu dan script meminta konfirmasi.
3. **Skip** — melewati penyalinan konfigurasi.

Mode **Update / Merge** dan **Replace / Sync** membuat backup terlebih dahulu.
Jika salah satu mode tersebut dipilih, script memasang Oh My Zsh dan plugin
termasuk Powerlevel10k, memasang atau memverifikasi Fastfetch, menerapkan
konfigurasi, dan mencoba mengubah default shell menjadi Zsh. Opsi **Skip**
melewati langkah setup tersebut. Setelah itu menu **Langkah Berikutnya**
menawarkan Fail2Ban, hardening SSH, setup Zsh root, atau keluar. Periksa pesan
terminal untuk mengetahui apakah langkah tambahan berhasil.

## Fail2Ban

Jalankan dari checkout repository pada Linux:

```bash
sudo bash ./Install/03-install-fail2ban.sh
```

Script memasang Fail2Ban dan dependensi yang dibutuhkan, memasang action Telegram,
Cloudflare dan iptables, filter Guacamole/Nextcloud/Immich, serta konfigurasi
jail. Script kemudian memvalidasi konfigurasi dan mengaktifkan serta me-restart
service Fail2Ban.

Sebelum mengaktifkan jail atau action terkait notifikasi/integrasi, siapkan
kredensial sesuai konfigurasi yang digunakan:

- Telegram: `/root/.env/telegram`, berisi nilai yang dibutuhkan script seperti
  `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, `SERVER_NAME`, dan variabel host
  notifikasi.
- Cloudflare: `/root/.env/cloudflare`, berisi `CF_EMAIL`, `API_KEY`, dan
  `ZONE_ID`.

Simpan file tersebut hanya untuk root (misalnya permission `600`) dan jangan
menaruh token atau API key ke repository. Setelah instalasi, periksa status
dengan:

```bash
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

Nama jail yang tersedia bergantung pada konfigurasi di `Fail2Ban/Jail.conf` dan
layanan yang benar-benar digunakan pada server.

## Zsh untuk root

Script mandiri:

```bash
sudo bash ./Install/04-zsh-root.sh
```

Script ini membuat arsip backup konfigurasi user, menyalin konfigurasi Oh My Zsh
ke home root, membuat symlink beberapa file konfigurasi, dan mencoba mengubah
default shell root ke Zsh. Periksa sumber dan target symlink sebelum
menjalankannya; perubahan ini memengaruhi lingkungan akun root.

> **Catatan:** menu opsi setup Zsh saat ini memanggil nama
> `04-setup-zsh-root.sh`, sedangkan file yang tersedia bernama
> `04-zsh-root.sh`. Jika opsi menu tersebut gagal karena file tidak ditemukan,
> jalankan perintah mandiri di atas.

## Hardening SSH

Jalankan pada server Linux yang memenuhi persyaratan:

```bash
sudo bash ./Install/05-harden-ssh.sh
```

Script membuat atau memperbarui drop-in
`/etc/ssh/sshd_config.d/00-local-hardening.conf`; file utama
`/etc/ssh/sshd_config` tidak ditimpa. Drop-in yang sudah ada tetapi bukan milik
script tidak akan ditimpa. Kebijakan autentikasi password dan alamat listen
yang ada sengaja tidak diubah.

Sebelum restart, script memvalidasi sintaks dan nilai efektif SSH. Jika validasi
atau restart gagal setelah perubahan, script mencoba memulihkan drop-in
sebelumnya (atau menghapus drop-in baru) dan mengaktifkan kembali service.
Perubahan hardening mencakup penolakan login root, pembatasan percobaan
autentikasi/sesi, serta penonaktifan beberapa jenis forwarding.

Jika `sshd_config` masih memiliki penanda konfigurasi dari versi lama yang
menimpa file utama, script akan berhenti. Tinjau dan pulihkan konfigurasi
tersebut secara manual sebelum menjalankan versi ini.

> **Peringatan:** pertahankan sesi SSH yang sedang aktif dan uji koneksi baru
> sebelum menutupnya. Pastikan akses pemulihan lokal atau out-of-band tersedia.

## Paket CLI

Daftar paket berbeda menurut OS dan package manager. Contoh paket yang dipasang
oleh installer mencakup `zsh`, `git`, `curl`, `fzf`, `bat`, `zoxide`, `eza`,
`fd`, `Fastfetch`, dan `glow`; tidak semua paket tersedia atau dipasang otomatis
di setiap platform. macOS menggunakan Homebrew.

Setup Fastfetch juga menghubungkan konfigurasi di repository ke
`~/.config/fastfetch/`. Setelah setup selesai, buka terminal baru atau jalankan:

```bash
exec zsh
```

## Troubleshooting

| Gejala | Pemeriksaan |
|---|---|
| Installer berhenti setelah memilih **1** | `02-setup-zsh.sh` berjalan interaktif. Periksa prompt atau pesan error terakhir di terminal. |
| `sudo` atau package manager gagal | Pastikan distro didukung, jaringan tersedia, dan akun memiliki hak administratif. |
| Setup Zsh menolak berjalan | Jalankan sebagai user biasa, bukan `root` atau dengan `sudo`. |
| Fastfetch gagal dipasang | Periksa dukungan package manager dan arsitektur CPU; jalankan kembali pesan error yang ditampilkan. |
| Fail2Ban tidak aktif | Periksa hasil validasi dan log service: `sudo systemctl status fail2ban`. |
| Koneksi SSH gagal setelah hardening | Jangan tutup sesi lama; gunakan akses lokal/out-of-band dan periksa log SSH serta konfigurasi efektif. |

## Lisensi

MIT License.
