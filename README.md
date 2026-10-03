# Dotfiles by New8ie

![Screenshot](/Source/screenshoot.png "Screenshot")


✨ **Konfigurasi shell interaktif dan lingkungan terminal untuk Linux (Debian/Ubuntu,Fedora,CentOS) dan macOS** — termasuk `zsh`, `oh-my-zsh`, `powerlevel10k`, plugin, alias, `nano`, dan `fastfetch`. Dirancang untuk produktivitas dan estetika maksimal.

---

## 📂 Struktur Repositori

```
Dotfiles/
├── Install/
│   ├── 01-install-deps.sh          # Instalasi dependensi sistem
│   ├── 02-setup-zsh.sh             # Pengaturan Zsh dan Oh My Zsh
│   ├── 03-install-fail2ban.sh      # Pengaturan Fail2Ban dengan notifikasi Telegram dan Cloudflare
│   ├── 04-zsh-root.sh              # Pengaturan Zsh dan Oh My Zsh untuk root
│   └── 05-harden-ssh.sh            # Hardening SSH melalui drop-in sshd
├── .vscode/                        # Konfigurasi VSCode
├── Fail2Ban/                       # Konfigurasi Fail2Ban
├── Fastfetch/                      # Konfigurasi Fastfetch
├── Grc/                            # Konfigurasi GRC Custom Style
├── Iterm2/                         # Konfigurasi iTerm2
├── Kitty/                          # Konfigurasi Kitty
├── Nano/                           # Konfigurasi Nano
├── OhMyPosh/                       # Konfigurasi Oh My Posh
├── OhMyZsh/                        # Konfigurasi Oh My Zsh
├── Powershell/                     # Konfigurasi PowerShell
├── Zsh/                            # Konfigurasi Zsh
└── README.md                       # Dokumentasi repositori
```

---

## 🚀 Instalasi

1. **Clone repository:**

```bash
git clone https://github.com/New8ie/Dotfiles.git ~/.dotfiles
cd .dotfiles
```

2. **Jalankan installer:**

```bash
bash ./Install/01-install-deps.sh
```

Installer akan mendeteksi OS, menginstal dependensi, dan clone repository ke
`~/.dotfiles` jika direktori tersebut belum ada. Setelah itu, pilih:

- **1** untuk menjalankan `02-setup-zsh.sh`.
- **2** untuk melewati setup Zsh.

Pilihan **1** menjalankan setup Zsh secara interaktif. Ikuti prompt tambahan
yang muncul di script tersebut; installer utama baru menampilkan pesan selesai
setelah setup Zsh keluar. Pada menu **Langkah Berikutnya** di setup Zsh, pilih
opsi yang diinginkan, termasuk Fail2Ban atau hardening SSH.

Script juga bisa dijalankan terpisah jika diperlukan:

```bash
bash ./Install/02-setup-zsh.sh
bash ./Install/03-install-fail2ban.sh
```

---

## ⚙️ Konfigurasi

### Fail2Ban

- **Notifikasi Telegram:**  
Skrip `send_telegram_notif.sh` akan mengirimkan notifikasi ke Telegram saat terjadi aksi pada jail Fail2Ban.  
Konfigurasi variabel:

```bash
TELEGRAM_BOT_TOKEN="your_bot_token"
TELEGRAM_CHAT_ID="your_chat_id"
```

- **Integrasi Cloudflare:**  
Fail2Ban dapat mengonfigurasi Cloudflare untuk memblokir IP yang terdeteksi.  
Konfigurasi variabel di file `cloudflare-logging.conf`:

```ini
cftoken = your_cloudflare_token
cfuser = your_cloudflare_user_id
```

### Zsh dan Terminal

- **Oh My Zsh:** Skrip `02-setup-zsh.sh` akan menginstal dan mengonfigurasi Oh My Zsh dengan tema `powerlevel10k` dan plugin yang berguna.  
- **Terminal:** Skrip `02-setup-zsh.sh` akan mengonfigurasi terminal sesuai preferensi, termasuk pengaturan warna dan font.

### Hardening SSH (Linux)

Jalankan dari clone repository pada server Linux yang menggunakan systemd dan
`/etc/ssh/sshd_config.d/`:

```bash
sudo bash ./Install/05-harden-ssh.sh
```

Script ini mengelola drop-in
`/etc/ssh/sshd_config.d/00-local-hardening.conf`; file utama
`/etc/ssh/sshd_config` tidak ditimpa. Kebijakan autentikasi password dan alamat
listen yang sudah ada sengaja tidak diubah. Script menerapkan batas percobaan
autentikasi dan sesi, menonaktifkan login root serta beberapa jenis forwarding,
memvalidasi konfigurasi SSH efektif, lalu me-restart service SSH. Jika validasi
atau restart gagal setelah perubahan, script mencoba memulihkan drop-in
sebelumnya.

Drop-in yang sudah ada tetapi bukan milik script tidak akan ditimpa. Jika
`sshd_config` masih berisi penanda konfigurasi dari versi lama script yang
menimpa file utama, script akan berhenti; tinjau dan pulihkan konfigurasi
tersebut secara manual sebelum menjalankan versi ini.

> **Peringatan:** perubahan SSH dapat memengaruhi akses remote. Pertahankan sesi
> SSH yang sedang aktif dan uji koneksi baru sebelum menutupnya. Pastikan akses
> public key dan akses pemulihan lokal/out-of-band tersedia.

---

## 🧪 Pengujian

Setelah instalasi, Anda dapat menguji konfigurasi dengan:

- **Zsh:** Jalankan `zsh` di terminal.  
- **Terminal:** Periksa tampilan dan fungsionalitas terminal Anda.  
- **Fail2Ban:** Uji notifikasi Telegram dengan memicu aksi pada jail Fail2Ban.

Tampilan alias help

![Screenshot](/Source/alias-show.png "Screenshot")



---

## 🤝 Kontribusi

Kontribusi sangat diterima! Silakan fork repositori ini, buat cabang fitur baru, dan ajukan pull request. Pastikan untuk:

- Menjaga konsistensi gaya kode.  
- Menambahkan dokumentasi untuk perubahan yang signifikan.  
- Menguji perubahan di lingkungan lokal sebelum mengajukan pull request.

---

## 📄 Lisensi

Repositori ini dilisensikan di bawah **MIT License**.

---

Jika Anda memerlukan bantuan lebih lanjut atau memiliki pertanyaan, jangan ragu untuk membuka isu di repositori ini.
