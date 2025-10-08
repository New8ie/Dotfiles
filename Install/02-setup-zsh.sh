#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Logging Helpers
# =============================================================================
log()  { echo -e "\033[1;32m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[ERROR]\033[0m $*"; exit 1; }

# =============================================================================
# Detect OS
# =============================================================================
detect_os() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if   [ -f /etc/debian_version ]; then OS_TYPE="debian"
    elif [ -f /etc/redhat-release ]; then OS_TYPE="redhat"
    elif [ -f /etc/arch-release   ]; then OS_TYPE="arch"
    else OS_TYPE="linux"
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
  else
    OS_TYPE="unknown"
  fi
  log "Terdeteksi OS: $OS_TYPE"
}

# =============================================================================
# Backup Dotfiles
# =============================================================================
backup_dotfiles() {
  TIMESTAMP=$(date +%Y%m%d-%H%M%S)
  DEST="$HOME/dotfiles-backup-$TIMESTAMP"
  mkdir -p "$DEST"

  # Daftar file/folder yang ingin dibackup
  files=(~/.zshrc ~/.zprofile ~/.p10k.zsh ~/.config ~/.oh-my-zsh ~/.nanorc)

  # Daftar folder yang akan di-exclude (tidak ikut dibackup)
  exclude_list=(
    "$HOME/.config/Code"
    "$HOME/.config/discord"
    "$HOME/.config/BraveSoftware"
    "$HOME/.config/google-chrome"
    "$HOME/.config/Slack"
    "$HOME/.config/venv"
  )

  # Salin file/folder ke direktori tujuan
  for f in "${files[@]}"; do
    [ -e "$f" ] && rsync -a --exclude-from=<(printf "%s\n" "${exclude_list[@]}") "$f" "$DEST"
  done

  # Kompres hasil backup
  tar -czf "$DEST.tar.gz" -C "$HOME" "$(basename "$DEST")"
  rm -rf "$DEST"

  echo "✅ Backup berhasil: $DEST.tar.gz"
}

# =============================================================================
# Setup Oh My Zsh
# =============================================================================
setup_ohmyzsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=no sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    log "Oh-My-Zsh berhasil diinstall."
  else
    log "Oh-My-Zsh sudah ada, skip install."
  fi
}

# =============================================================================
# Clone Helper
# =============================================================================
clone_plugin() {
  local repo dest
  repo="$1"
  dest="$2"
  [ -d "$dest" ] || ( git clone "$repo" "$dest" && log "Plugin $(basename "$dest") cloned." )
}

# =============================================================================
# Install Plugins
# =============================================================================
install_plugins() {
  ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
  mkdir -p "$ZSH_CUSTOM"/{plugins,themes}

  clone_plugin https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  clone_plugin https://github.com/zsh-users/zsh-autosuggestions.git      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  clone_plugin https://github.com/zsh-users/zsh-completions.git          "$ZSH_CUSTOM/plugins/zsh-completions"
  clone_plugin https://github.com/MichaelAquilina/zsh-you-should-use.git "$ZSH_CUSTOM/plugins/zsh-you-should-use"
  clone_plugin https://github.com/fdellwing/zsh-bat.git                  "$ZSH_CUSTOM/plugins/zsh-bat"
  clone_plugin https://github.com/z-shell/zsh-eza.git                    "$ZSH_CUSTOM/plugins/zsh-eza"
  clone_plugin https://github.com/romkatv/powerlevel10k.git              "$ZSH_CUSTOM/themes/powerlevel10k"
}

# =============================================================================
# Install Fastfetch
# =============================================================================
install_fastfetch() {
  case "$OS_TYPE" in
    debian|ubuntu)
      log "Install Fastfetch via dpkg/apt..."
      wget -O /tmp/fastfetch.deb https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb \
        || err "Gagal download fastfetch"
      sudo apt install -y /tmp/fastfetch.deb || err "Gagal install fastfetch"
      rm -f /tmp/fastfetch.deb
      ;;
    arch)
      sudo pacman -S --noconfirm fastfetch
      ;;
    redhat|fedora)
      sudo dnf install -y fastfetch || err "Gagal install fastfetch"
      ;;
    centos)
      if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y fastfetch || err "Gagal install fastfetch"
      else
        sudo yum install -y fastfetch || err "Gagal install fastfetch"
      fi
      ;;
    macos)
      brew install fastfetch
      ;;
    *)
      err "OS tidak didukung: $OS_TYPE"
      ;;
  esac
}

# =============================================================================
# Copy Configs
# =============================================================================
copy_configs() {
  log "📂 Menyalin konfigurasi (mode copy)"
  
  # ---------------------------------------------------------------------------
  # Persiapan folder
  # ---------------------------------------------------------------------------
  mkdir -p "$HOME/.config"/{nano,fastfetch,iterm2,script,zsh/functions}
  mkdir -p "$HOME/.config/fastfetch/logo"

  # ---------------------------------------------------------------------------
  # Daftar file yang akan di-replace
  # ---------------------------------------------------------------------------
  files_to_replace=(
    "$HOME/.zshrc"
    "$HOME/.zprofile"
    "$HOME/.p10k.zsh"
    "$HOME/.nanorc"
  )

  # Hapus file atau symlink lama sebelum copy
  for f in "${files_to_replace[@]}"; do
    if [ -L "$f" ]; then
      log "🧹 Menghapus symlink lama: $f"
      rm -f "$f"
    elif [ -e "$f" ]; then
      log "🧹 Menghapus file lama: $f"
      rm -f "$f"
    fi
  done

  # ---------------------------------------------------------------------------
  # Salin konfigurasi utama Zsh
  # ---------------------------------------------------------------------------
  if [[ "$OS_TYPE" == "macos" ]]; then
    cp -f ~/.dotfiles/Zsh/macos-zshrc.zsh ~/.zshrc
  else
    cp -f ~/.dotfiles/Zsh/linux-zshrc.zsh ~/.zshrc
  fi

  cp -f ~/.dotfiles/OhMyZsh/p10k.zsh ~/.p10k.zsh
  cp -f ~/.dotfiles/Zsh/zprofile.zsh ~/.zprofile
  cp -f ~/.dotfiles/Zsh/Alias/alias.zsh ~/.config/zsh/alias.zsh

  # ---------------------------------------------------------------------------
  # Nano
  # ---------------------------------------------------------------------------
  log "🧹 Membersihkan konfigurasi nano lama"
  rm -rf ~/.config/nano 2>/dev/null || true
  mkdir -p ~/.config/nano
  cp -rf ~/.dotfiles/Nano/* ~/.config/nano
  cp -f ~/.config/nano/Config/nanorc ~/.nanorc

  # ---------------------------------------------------------------------------
  # Functions & Script
  # ---------------------------------------------------------------------------
  log "🧹 Membersihkan konfigurasi zsh functions & script lama"
  rm -rf ~/.config/zsh/functions ~/.config/script 2>/dev/null || true
  mkdir -p ~/.config/zsh/functions ~/.config/script
  cp -rf ~/.dotfiles/Zsh/Alias/Functions/* ~/.config/zsh/functions
  cp -rf ~/.dotfiles/Script/* ~/.config/script
  chmod +x ~/.config/script/* 2>/dev/null || true

  # ---------------------------------------------------------------------------
  # Fastfetch
  # ---------------------------------------------------------------------------
  log "🧹 Membersihkan konfigurasi fastfetch lama"
  rm -rf ~/.config/fastfetch 2>/dev/null || true
  mkdir -p ~/.config/fastfetch/logo
  cp -f ~/.dotfiles/Fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc
  cp -f ~/.dotfiles/Fastfetch/motd-fastfetch.sh ~/.config/fastfetch/motd-fastfetch.sh
  chmod +x ~/.config/fastfetch/motd-fastfetch.sh
  cp -f ~/.dotfiles/Fastfetch/logo/*-logo.png ~/.config/fastfetch/logo/ 2>/dev/null || true

  # ---------------------------------------------------------------------------
  # iTerm2 (khusus macOS, tapi tetap aman di Linux)
  # ---------------------------------------------------------------------------
  log "🧹 Membersihkan konfigurasi iTerm2 lama"
  rm -rf ~/.config/iterm2 2>/dev/null || true
  mkdir -p "$HOME/.config/iterm2/bin"
  cp -rf ~/.dotfiles/Iterm2/bin/* "$HOME/.config/iterm2/bin" 2>/dev/null || true
  cp -f ~/.dotfiles/Iterm2/iterm2_shell_integration.zsh "$HOME/.config/iterm2/iterm2_shell_integration.zsh" 2>/dev/null || true
  chmod +x ~/.config/iterm2/bin/* 2>/dev/null || true

  # ---------------------------------------------------------------------------
  # Selesai
  # ---------------------------------------------------------------------------
  log "✅ Semua konfigurasi berhasil dicopy dan file lama/symlink telah direplace"
}

# =============================================================================
# Symlink Configs
# =============================================================================
symlink_configs() {
  log "🔗 Membuat symlink konfigurasi (mode symlink dengan replace aman)"

  mkdir -p "$HOME/.config"/{zsh,nano,fastfetch,iterm2,script}
  mkdir -p "$HOME/.config/fastfetch/logo" "$HOME/.config/zsh/functions"

  safe_link() {
    local src="$1"
    local dest="$2"
    # Jika sudah ada file atau symlink lama, hapus dulu
    [ -e "$dest" ] || [ -L "$dest" ] && rm -rf "$dest"
    ln -s "$src" "$dest"
  }

  # ==== ZSH ====
  if [[ "$OS_TYPE" == "macos" ]]; then
    safe_link ~/.dotfiles/Zsh/macos-zshrc.zsh ~/.zshrc
  else
    safe_link ~/.dotfiles/Zsh/linux-zshrc.zsh ~/.zshrc
  fi

  safe_link ~/.dotfiles/OhMyZsh/p10k.zsh ~/.p10k.zsh
  safe_link ~/.dotfiles/Zsh/zprofile.zsh ~/.zprofile
  safe_link ~/.dotfiles/Zsh/Alias/alias.zsh ~/.config/zsh/alias.zsh

  # ==== Zsh Functions ====
  cp -rf ~/.dotfiles/Zsh/Alias/Functions/* ~/.config/zsh/functions

  # ==== Nano ====
  cp -rf ~/.dotfiles/Nano/* ~/.config/nano
  cp -f ~/.config/nano/Config/nanorc ~/.nanorc

  # ==== Script ====
  [ -L ~/.config/script ] && rm -rf ~/.config/script
  [ -d ~/.config/script ] && rm -rf ~/.config/script
  safe_link ~/.dotfiles/Script ~/.config/script
  chmod +x ~/.config/script/* 2>/dev/null || true

  # ==== Fastfetch ====
  safe_link ~/.dotfiles/Fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc
  safe_link ~/.dotfiles/Fastfetch/motd-fastfetch.sh ~/.config/fastfetch/motd-fastfetch.sh
  chmod +x ~/.config/fastfetch/motd-fastfetch.sh
  cp -f ~/.dotfiles/Fastfetch/logo/*-logo.png ~/.config/fastfetch/logo/ 2>/dev/null || true

  # ==== iTerm2 ====
  mkdir -p "$HOME/.config/iterm2/bin"
  cp -rf ~/.dotfiles/Iterm2/bin/* "$HOME/.config/iterm2/bin" 2>/dev/null || true
  safe_link ~/.dotfiles/Iterm2/iterm2_shell_integration.zsh ~/.config/iterm2/iterm2_shell_integration.zsh
  chmod +x ~/.config/iterm2/bin/* 2>/dev/null || true

  log "✅ Symlink konfigurasi berhasil dibuat dan file lama sudah direplace"
}


# =============================================================================
# Config Menu
# =============================================================================
config_menu() {
  echo
  echo "=========================================="
  echo "  Pilih mode setup konfigurasi dotfiles"
  echo "=========================================="
  echo "  [1] Copy file (aman, standalone)"
  echo "  [2] Symlink (lebih fleksibel, sync dengan repo)"
  echo "------------------------------------------"
  read -rp "Masukkan pilihan [1/2]: " pilihan
  case "$pilihan" in
    1) copy_configs ;;
    2) symlink_configs ;;
    *) warn "Pilihan tidak valid, default: Copy"; copy_configs ;;
  esac
}

# =============================================================================
# Set Default Shell
# =============================================================================
set_shell() {
  NEW=$(which zsh)
  if [ "$SHELL" != "$NEW" ]; then
    if sudo -n true 2>/dev/null; then
      sudo chsh -s "$NEW" "$USER" && log "Default shell diubah ke zsh."
    else
      chsh -s "$NEW" || warn "Jalankan manual: chsh -s $NEW"
    fi
  fi
}

# =============================================================================
# Verify Fastfetch
# =============================================================================
verify_fastfetch() {
  if command -v fastfetch >/dev/null 2>&1; then
    log "Fastfetch berhasil terinstall."
    fastfetch --version || warn "Fastfetch terinstall tapi gagal dijalankan"
  else
    err "Fastfetch tidak ditemukan setelah instalasi"
  fi
}

# =============================================================================
# Main
# =============================================================================
main() {
  detect_os
  backup_dotfiles
  setup_ohmyzsh
  install_plugins
  install_fastfetch
  config_menu
  set_shell
  verify_fastfetch
  log "Setup selesai! Restart terminal atau jalankan \`exec zsh\`."
}

main

# =============================================================================
# Next Step (Interactive Menu)
# =============================================================================
while true; do
  echo
  echo "=========================================="
  echo "Langkah selanjutnya:"
  echo "=========================================="
  echo "  [1] Install & konfigurasi Fail2ban"
  echo "  [2] Keluar"
  echo "------------------------------------------"
  read -rp "Masukkan pilihan [1/2]: " pilihan
  case "$pilihan" in
    1)
      chmod +x ~/.dotfiles/Install/03-install-fail2ban.sh
      bash ~/.dotfiles/Install/03-install-fail2ban.sh
      break
      ;;
    2)
      echo "✅ Setup selesai. Keluar."
      break
      ;;
    *)
      echo "⚠️  Pilihan tidak valid. Silakan pilih lagi."
      ;;
  esac
done
