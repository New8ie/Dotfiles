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
│   └── 03-install-fail2ban.sh      # Pengaturan Fail2Ban dengan notifikasi Telegram dan Cloudflare
├── .vscode/                        # Konfigurasi VSCode
├── Fail2Ban/                       # Konfigurasi Fail2Ban
├── Fastfetch/                      # Konfigurasi Fastfetch
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

2. **Jalankan skrip instalasi otomatis:**

```bash
./Install/01-install-deps.sh
./Install/02-setup-zsh.sh
./Install/03-install-fail2ban.sh
```

Skrip ini akan:

- Menginstal dependensi sistem yang diperlukan.  
- Mengonfigurasi Zsh dengan Oh My Zsh dan plugin terkait.   
- Mengonfigurasi Fail2Ban dengan notifikasi Telegram dan integrasi Cloudflare.

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

---

## 🧪 Pengujian

Setelah instalasi, Anda dapat menguji konfigurasi dengan:

- **Zsh:** Jalankan `zsh` di terminal.  
- **Terminal:** Periksa tampilan dan fungsionalitas terminal Anda.  
- **Fail2Ban:** Uji notifikasi Telegram dengan memicu aksi pada jail Fail2Ban.

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
