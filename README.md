
```markdown
# 🧪 Dotfiles by New8ie

🛠️ Konfigurasi shell interaktif dan terminal environment untuk Linux (Debian/Ubuntu) dan macOS — termasuk `zsh`, `oh-my-zsh`, `powerlevel10k`, plugin, alias, `neofetch`, `nano`, dan `fastfetch`. Dirancang untuk produktivitas dan estetika maksimal.

---

## 🧬 Struktur Repositori

```bash
Dotfiles/
├── Install/
│   ├── 01-install-deps.sh        # Instalasi dependencies (zsh, curl, git, bat, eza, dll)
│   └── 02-setup-zsh.sh           # Setup oh-my-zsh, plugin, powerlevel10k, dan konfigurasi
├── Zsh/
│   ├── macos-zshrc.zsh           # Konfigurasi .zshrc untuk macOS
│   ├── linux-zshrc.zsh           # Konfigurasi .zshrc untuk Linux
│   ├── .p10k.zsh                 # Tema Powerlevel10k
│   ├── .zprofile                 # Konfigurasi shell startup
│   └── Alias/
│       └── alias.zsh             # Alias perintah untuk Linux/macOS
├── Nano/
│   └── nanorc.nanorc             # Konfigurasi highlight Nano
├── Neofetch/
│   ├── config.conf               # Konfigurasi neofetch
│   ├── motd-script.sh           # Skrip MOTD bergambar
│   └── *-logo.png                # Logo distro (macOS, Debian, Ubuntu, Raspberry Pi)
├── fastfetch/
│   ├── config.conf               # Konfigurasi fastfetch horizontal
│   ├── motd-fastfetch.sh        # Skrip MOTD untuk fastfetch
│   └── logo/
│       └── *-logo.png            # Logo distro untuk fastfetch
├── Iterm2/
│   ├── bin/                      # Binary tools (imgcat, dll)
│   └── iterm2_shell_integration.zsh
```

---

## 🚀 Instalasi Cepat

### 1. Clone repositori
```bash
git clone https://github.com/New8ie/Dotfiles.git ~/.dotfiles
```

### 2. Jalankan skrip instalasi Zsh dan konfigurasi:
```bash
chmod +x ~/.dotfiles/Install/01-install-deps.sh
chmod +x ~/.dotfiles/Install/02-setup-zsh.sh
bash ~/.dotfiles/Install/01-install-deps.sh
```

> Pastikan Anda memiliki `git`, `curl`, dan akses `sudo`. Skrip akan:
> - Menginstal oh-my-zsh + plugin
> - Mengganti `.zshrc`, `.p10k.zsh`, `.zprofile`, alias, dan konfigurasi lainnya
> - Menyalin konfigurasi `nano`, `neofetch`, dan `fastfetch`
> - Otomatis mengganti shell default ke Zsh
> - Membuat backup konfigurasi lama ke `.tar.gz`

---

## 💡 Dukungan Sistem

| OS        | Status     | Keterangan                    |
|-----------|------------|-------------------------------|
| Debian 11+| ✅ Stabil   | Paket diinstal via APT        |
| Ubuntu 22+| ✅ Stabil   | eza fallback dari GitHub      |
| macOS 13+ | ✅ Stabil   | Menggunakan Homebrew & iTerm2 |

---

## 📦 Tools yang Digunakan

- `zsh` + [oh-my-zsh](https://ohmyz.sh)
- [powerlevel10k](https://github.com/romkatv/powerlevel10k)
- Plugin: syntax-highlighting, autosuggestions, you-should-use, bat, eza, fzf
- `bat`, `eza`, `zoxide`, `neofetch`, `fastfetch`
- `nano` dengan syntax highlighting
- Logo bergambar untuk `neofetch` dan `fastfetch`

---

## 🧯 Troubleshooting

- **.zshrc tidak berubah?** → Pastikan tidak ada `.zshrc` custom yang dikunci permission-nya.
- **bat tidak ditemukan?** → Jalankan manual: `sudo ln -s /usr/bin/batcat /usr/local/bin/bat`
- **Zsh bukan default shell?** → Jalankan: `chsh -s $(which zsh)`

---

## 🧰 Kontributor

Dibuat dan dirawat oleh [New8ie](https://github.com/New8ie).  
Feel free untuk fork dan kirim pull request.

---

## 📝 Lisensi

MIT License. Gunakan, modifikasi, atau distribusikan dengan bebas.
```