# 🚀 Dotfiles & Zsh Environment Setup

Automasi instalasi tool CLI modern, Zsh, dan dotfiles pribadi untuk Linux dan macOS.

## 📂 Struktur Script

```bash
📁 Dotfiles/
├── Install/
│   ├── 01-install-deps.sh     # Install dependensi CLI & clone dotfiles
│   └── 02-setup-zsh.sh        # Setup Zsh, plugin, konfigurasi, dan theme
```

---

## ✨ Fitur

- Deteksi otomatis OS (Ubuntu, Debian, Fedora, Arch, macOS)
- Instalasi paket penting: `zsh`, `fzf`, `git`, `bat`, `eza`, `fastfetch`, dll
- Clone & setup dotfiles (`.zshrc`, `.p10k.zsh`, `alias.zsh`, `neofetch`, dll)
- Otomatis install Oh-My-Zsh + plugin dan theme `powerlevel10k`
- Backup konfigurasi Zsh lama
- Dukungan penuh macOS (termasuk iTerm2 integration)

---

## ⚙️ Cara Instalasi

### 1. Clone repositori

```bash
git clone https://github.com/New8ie/Dotfiles.git ~/.dotfiles
cd ~/.dotfiles/Install
```

### 2. Jalankan script utama

```bash
./01-install-deps.sh
```

Script ini akan:
- Mendeteksi OS dan menginstall dependensi
- Install `eza`, `viu`, `fastfetch` dari GitHub release
- Clone repo dotfiles ke `~/.dotfiles`
- Menawarkan pilihan untuk melanjutkan ke setup Zsh

---

### 3. Setup Zsh dan konfigurasi

Jika sebelumnya memilih `2`, jalankan manual:

```bash
./02-setup-zsh.sh
```

Script ini akan:
- Backup konfigurasi `.zshrc`, `.p10k.zsh`, dan lain-lain
- Install Oh-My-Zsh dan plugin tambahan
- Salin konfigurasi dotfiles
- Mengatur `zsh` sebagai shell default

---

## 📦 Tools yang Terinstall

| Tool           | Fungsi                           |
| -------------- | -------------------------------- |
| `eza`          | Pengganti `ls` modern            |
| `viu`          | Viewer gambar di terminal        |
| `zsh`          | Shell interaktif                 |
| `fzf`          | Fuzzy finder                     |
| `bat`          | Pengganti `cat` dengan highlight |
| `fastfetch`    | Alternatif cepat `neofetch`      |
| `zoxide`       | Autojump direktori efisien       |
| dan lainnya... | ...                              |

---

## 🖼️ Contoh Tampilan


---

## 🔁 Setelah Selesai

Jalankan ulang terminal atau aktifkan `zsh` dengan:

```bash
exec zsh
```

---

## 🛠️ Kebutuhan Sistem

- Linux (Debian/Ubuntu/Fedora/Arch) atau macOS
- Akses `sudo`
- Koneksi internet stabil

---

## 🧪 Troubleshooting

| Masalah                   | Solusi                                   |
| ------------------------- | ---------------------------------------- |
| `chsh: permission denied` | Jalankan `sudo chsh -s $(which zsh)`     |
| `brew not found` (macOS)  | Akan otomatis ditawarkan untuk install   |
| `command not found: curl` | Install `curl` terlebih dahulu           |
| `zsh tidak berubah`       | Logout dan login kembali atau `exec zsh` |

---

## 💡 Tips Tambahan

Anda juga bisa menjalankan satu baris langsung:

```bash
bash <(curl -s https://raw.githubusercontent.com/New8ie/Dotfiles/main/Install/01-install-deps.sh)
```


---

## 📝 Lisensi

MIT License. Silakan digunakan, dimodifikasi, dan dibagikan.

---

## 🙏 Terima Kasih

Terinspirasi dari komunitas open-source Zsh, CLI modern, dan dotfiles rapi.