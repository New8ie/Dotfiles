# 📦 Dotfiles Setup by New8ie

## 🧩 Overview

Skrip ini digunakan untuk mengatur lingkungan Zsh yang lengkap dan konsisten di berbagai OS (macOS, Debian, Ubuntu, Raspberry Pi, Arch, dan Fedora).

## 📁 Struktur Repository

```
Dotfiles/
├── Install/
│   ├── 01-install-deps.sh        # Script untuk menginstal aplikasi via APT, Brew, atau Pacman
│   └── 01-setup-zsh.sh           # Script untuk setup Zsh, plugin, font, dan konfigurasi
├── Zsh/
│   └── Alias/
│       └── alias.zsh             # Alias shell untuk Linux/macOS
├── Nano/
│   └── nanorc.nanorc             # Highlighting config Nano
├── neofetch/
│   └── config.conf
│   └── motd-script.sh
│   └── *.png                     # Logo distro custom
├── zsh/
│   └── .p10k.zsh
│   └── .zprofile
```

## ⚙️ Cara Instalasi

### 1. Clone Repository

```bash
git clone https://github.com/New8ie/Dotfiles.git ~/Dotfiles
cd ~/Dotfiles/Install
```

### 2. Jalankan Instalasi

```bash
bash 01-install-deps.sh    # Optional - install software seperti git, curl, zsh, dll
bash 02-setup-zsh.sh       # Backup konfigurasi lama dan pasang semua dotfiles
```

## 🛠️ Yang Dilakukan oleh `01-setup-zsh.sh`

* Membackup konfigurasi Zsh, Nano, dan Neofetch ke folder: `~/dotfiles-backup-<tanggal>`
* Menginstal Oh-My-Zsh (unattended)
* Mengunduh plugin Zsh:

  * zsh-autosuggestions
  * zsh-syntax-highlighting
  * zsh-you-should-use
  * zsh-bat
  * zsh-eza
* Mengunduh Meslo Nerd Font (untuk Powerlevel10k)
* Mengunduh konfigurasi dari GitHub:

  * `.p10k.zsh`, `.zprofile`, `.nanorc`, `alias.zsh`, dll
  * MotD logo dan konfigurasi `neofetch`
* Mengatur shell default ke `zsh`

## 🔁 Catatan Tambahan

* Anda bisa menambahkan baris berikut ke `.zshrc` untuk memastikan alias termuat:

  ```zsh
  source ~/.config/zsh/alias.zsh
  ```
* Script bersifat *idempotent*, artinya bisa dijalankan ulang tanpa merusak sistem.

## 🧪 Diuji pada

* macOS (Intel & Apple Silicon)
* Debian 12/13
* Ubuntu 20.04–24.04
* Raspberry Pi OS (Bookworm)
* Arch Linux & Fedora Workstation

---

Maintained by: [New8ie](https://github.com/New8ie)
