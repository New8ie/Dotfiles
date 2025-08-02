# 🧰 ZshStyle Installer

Automated Zsh environment setup script for **macOS**, **Debian/Ubuntu**, and **Raspberry Pi OS** systems.

## 🚀 Features

✅ Detects OS and CPU architecture  
✅ Installs essential CLI tools:
- `zsh`, `git`, `curl`, `nanorc`, `fzf`, `grc`, `gnupg`,`lolcat`,`neofetch`, `pv`
- `bat` and `eza` with architecture-aware `.deb` or `tar.gz` install (Debian/RPi)
  
✅ Installs and configures **Oh My Zsh**  
✅ Clones and updates custom Zsh plugins:
- `zsh-syntax-highlighting`
- `zsh-autosuggestions`
- `zsh-you-should-use`
- `zsh-bat`
- `zsh-eza`

✅ Sets up **Powerlevel10k** theme and downloads curated configs from GitHub  
✅ Creates symlinks to root for shared config  
✅ Compatible with **Raspberry Pi 5**  
✅ Fully idempotent – safe to re-run anytime

## 🧰 Requirements

- macOS, Debian/Ubuntu, or Raspberry Pi OS
- `bash`
- Internet connection
- `sudo` privileges

## 📦 Installation

```bash
git clone https://github.com/New8ie/ZshStyle.git
cd script
chmod +x zsh-script.sh
./zsh-script.sh
```

bash -c "$(curl -fsSL https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/script/zabbix-install.sh)"