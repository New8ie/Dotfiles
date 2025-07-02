#!/usr/bin/env bash
set -euo pipefail

log()  { echo -e "\033[1;32m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

### ========= Deteksi OS ========= ###
detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
  elif [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
      debian|ubuntu|raspbian) OS_TYPE="linux" ;;
      *) err "Distro Linux $ID belum didukung." ;;
    esac
  else
    err "OS tidak dikenali."
  fi
  log "Dikenali OS: $OS_TYPE"
}

### ========= Backup Konfigurasi Lama ========= ###
backup_existing_dotfiles() {
  TIMESTAMP=$(date +%Y%m%d-%H%M%S)
  BACKUP_DIR="$HOME/dotfiles-backup-$TIMESTAMP"
  mkdir -p "$BACKUP_DIR"

  log "Membackup konfigurasi lama ke: $BACKUP_DIR"

  FILES_TO_BACKUP=(
    "$HOME/.zshrc"
    "$HOME/.zprofile"
    "$HOME/.p10k.zsh"
    "$HOME/.nanorc"
    "$HOME/.nano"
    "$HOME/.config/nano"
    "$HOME/.config/neofetch"
    "$HOME/.config/fastfetch"
    "$HOME/.config/zsh"
    "$HOME/.oh-my-zsh"
  )

  for file in "${FILES_TO_BACKUP[@]}"; do
    [ -e "$file" ] && cp -a "$file" "$BACKUP_DIR/" || log "Skip: $file tidak ditemukan."
  done

  tar -czf "$BACKUP_DIR.tar.gz" -C "$HOME" "$(basename "$BACKUP_DIR")"
  rm -rf "$BACKUP_DIR"
  log "Backup disimpan dalam arsip: $BACKUP_DIR.tar.gz"
}

### ========= Install Oh-My-Zsh ========= ###
setup_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Menginstall Oh-My-Zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || warn "Gagal install oh-my-zsh"
  else
    log "Oh-My-Zsh sudah ada."
  fi
}

### ========= Install Plugin Zsh ========= ###
clone_plugin() {
  local repo="$1"
  local dest="$2"
  if [ -d "$dest" ]; then
    log "Plugin $(basename "$dest") sudah ada."
  else
    git clone "$repo" "$dest"
  fi
}

install_zsh_plugins() {
  ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
  mkdir -p "$ZSH_CUSTOM/plugins"
  mkdir -p "$ZSH_CUSTOM/themes"

  clone_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  clone_plugin "https://github.com/zsh-users/zsh-autosuggestions.git" "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  clone_plugin "https://github.com/MichaelAquilina/zsh-you-should-use.git" "$ZSH_CUSTOM/plugins/zsh-you-should-use"
  clone_plugin "https://github.com/fdellwing/zsh-bat.git" "$ZSH_CUSTOM/plugins/zsh-bat"
  clone_plugin "https://github.com/z-shell/zsh-eza.git" "$ZSH_CUSTOM/plugins/zsh-eza"

  # Powerlevel10k
  clone_plugin "https://github.com/romkatv/powerlevel10k.git" "$ZSH_CUSTOM/themes/powerlevel10k"
}

### ========= Unduh Konfigurasi dan Font ========= ###
download_configs() {
  log "Copy konfigurasi .zsh, nano, neofetch, dan alias "

  mkdir -p "$HOME/.config/neofetch"
  mkdir -p "$HOME/.config/nano"
  mkdir -p "$HOME/.config/zsh"

  TEMP_DIR=$(mktemp -d)

  # Sesuaikan .zshrc berdasarkan OS
  if [[ "$OS_TYPE" == "macos" ]]; then
    curl -fsSL -o "$TEMP_DIR/.zshrc" https://raw.githubusercontent.com/New8ie/Dotfiles/main/Zsh/macos-zshrc.zsh || warn "Gagal unduh macos-zshrc"
  else
    curl -fsSL -o "$TEMP_DIR/.zshrc" https://raw.githubusercontent.com/New8ie/Dotfiles/main/Zsh/linux-zshrc.zsh || warn "Gagal unduh linux-zshrc"
  fi

  curl -fsSL -o "$TEMP_DIR/.p10k.zsh" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/zsh/.p10k.zsh || warn "Gagal unduh .p10k.zsh"
  curl -fsSL -o "$TEMP_DIR/.zprofile" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/zsh/.zprofile || warn "Gagal unduh .zprofile"

  mv -f "$TEMP_DIR/.zshrc" "$HOME/.zshrc"
  mv -f "$TEMP_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
  mv -f "$TEMP_DIR/.zprofile" "$HOME/.zprofile"

  curl -fsSL -o "$HOME/.nanorc" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/nano/.nanorc || warn "Gagal unduh .nanorc"
  curl -fsSL -o "$HOME/.config/nano/nanorc.nanorc" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/nano/nanorc.nanorc || warn "Gagal unduh nanorc.nanorc"
  curl -fsSL -o "$HOME/.config/zsh/alias.zsh" https://raw.githubusercontent.com/New8ie/Dotfiles/refs/heads/main/Zsh/Alias/alias.zsh || warn "Gagal unduh alias.zsh"

  curl -fsSL -o "$HOME/.config/neofetch/config.conf" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/neofetch/config.conf || warn "Gagal unduh config.conf"
  curl -fsSL -o "$HOME/.config/neofetch/motd-script.sh" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/script/motd-multi-os.sh || warn "Gagal unduh motd-script.sh"
  curl -fsSL -o "$HOME/.config/neofetch/macos-logo.png" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/neofetch/macos-logo.png || warn "Gagal unduh macos-logo.png"
  curl -fsSL -o "$HOME/.config/neofetch/debian-logo.png" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/neofetch/debian-logo.png || warn "Gagal unduh debian-logo.png"
  curl -fsSL -o "$HOME/.config/neofetch/ubuntu-logo.png" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/neofetch/ubuntu-logo.png || warn "Gagal unduh ubuntu-logo.png"
  curl -fsSL -o "$HOME/.config/neofetch/raspberrypi-logo.png" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/neofetch/raspberrypi-logo.png || warn "Gagal unduh raspberrypi-logo.png"

  chmod +x "$HOME/.config/neofetch/motd-script.sh"
  rm -rf "$TEMP_DIR"

  # Tambahkan symlink bat jika perlu (khusus Debian/Ubuntu)
  if [[ "$OS_TYPE" == "linux" ]] && [ -x /usr/bin/batcat ] && [ ! -e /usr/local/bin/bat ]; then
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
    log "Symlink dibuat: /usr/local/bin/bat -> /usr/bin/batcat"
  fi
}

### ========= Ganti Shell ke Zsh ========= ###
set_default_shell() {
  if [ "$SHELL" != "$(which zsh)" ]; then
    if sudo -n true 2>/dev/null; then
      if sudo chsh -s "$(which zsh)" "$USER"; then
        log "Shell default berhasil diganti ke Zsh (dengan sudo). Logout/login diperlukan."
      else
        warn "Gagal mengganti shell default via sudo. Silakan ubah manual: sudo chsh -s $(which zsh) $USER"
      fi
    else
      if chsh -s "$(which zsh)"; then
        log "Shell default diganti ke Zsh. Logout/login diperlukan."
      else
        warn "Tidak dapat mengganti shell default untuk pengguna $USER. Jalankan secara manual: chsh -s $(which zsh)"
      fi
    fi
  fi
}

### ========= Main ========= ###
detect_os
backup_existing_dotfiles
setup_oh_my_zsh
install_zsh_plugins
download_configs
set_default_shell
