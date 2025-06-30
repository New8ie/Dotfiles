#!/usr/bin/env bash
set -euo pipefail

log()  { echo -e "\033[1;32m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

### ========= Backup Konfigurasi Lama ========= ###
backup_existing_dotfiles() {
  TIMESTAMP=$(date +%Y%m%d-%H%M%S)
  BACKUP_DIR="$HOME/dotfiles-backup-$TIMESTAMP"
  mkdir -p "$BACKUP_DIR"

  log "Membackup konfigurasi lama ke: $BACKUP_DIR"

  for file in \
    "$HOME/.zshrc" \
    "$HOME/.zprofile" \
    "$HOME/.p10k.zsh" \
    "$HOME/.nanorc" \
    "$HOME/.nano" \
    "$HOME/.config/nano" \
    "$HOME/.config/neofetch" \
    "$HOME/.config/zsh" \
    "$HOME/.oh-my-zsh"
  do
    [ -e "$file" ] && mv -v "$file" "$BACKUP_DIR/" || log "Skip: $file tidak ditemukan."
  done
}

### ========= Install Oh-My-Zsh ========= ###
setup_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Menginstall Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || warn "Gagal install oh-my-zsh"
  else
    log "Oh-My-Zsh sudah ada."
  fi
}

### ========= Install Plugin Zsh (menggunakan clone_plugin) ========= ###
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

  clone_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  clone_plugin "https://github.com/zsh-users/zsh-autosuggestions.git" "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  clone_plugin "https://github.com/MichaelAquilina/zsh-you-should-use.git" "$ZSH_CUSTOM/plugins/zsh-you-should-use"
  clone_plugin "https://github.com/fdellwing/zsh-bat.git" "$ZSH_CUSTOM/plugins/zsh-bat"
  clone_plugin "https://github.com/z-shell/zsh-eza.git" "$ZSH_CUSTOM/plugins/zsh-eza"
}

### ========= Install Meslo Nerd Font ========= ###
install_fonts() {
  FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"

  for style in Regular Bold Italic "Bold Italic"; do
    FONT_NAME="MesloLGS NF ${style}.ttf"
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/L/Regular/$FONT_NAME"
    curl -fsSL -o "$FONT_DIR/$FONT_NAME" "$FONT_URL" || warn "Gagal mengunduh $FONT_NAME"
  done

  fc-cache -fv || true
  log "Font Meslo Nerd telah dipasang."
}

### ========= Unduh Semua Konfigurasi Dotfiles ========= ###
download_configs() {
  log "Mengunduh konfigurasi .zsh, nano, neofetch, dan alias dari repo ZshStyle"

  mkdir -p "$HOME/.config/neofetch"
  mkdir -p "$HOME/.config/nano"
  mkdir -p "$HOME/.config/zsh"

  curl -fsSL -o "$HOME/.p10k.zsh" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/zsh/.p10k.zsh || warn "Gagal unduh .p10k.zsh"
  curl -fsSL -o "$HOME/.zprofile" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/zsh/.zprofile || warn "Gagal unduh .zprofile"
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
}

### ========= Ganti Shell ke Zsh ========= ###
set_default_shell() {
  if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
    log "Shell default diganti ke Zsh. Logout/login diperlukan."
  fi
}

### ========= Main ========= ###
backup_existing_dotfiles
setup_oh_my_zsh
install_zsh_plugins
install_fonts
download_configs
set_default_shell
