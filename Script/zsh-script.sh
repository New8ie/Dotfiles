#!/usr/bin/env bash
set -euo pipefail

### ========= Logging Utility ========= ###
log() { echo -e "\033[1;32m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

### ========= Deteksi OS & Arsitektur ========= ###
detect_os_arch() {
  OS_TYPE=""
  ARCH_TYPE="$(uname -m)"

  case "$(uname)" in
    Darwin)
      OS_TYPE="macos"
      ;;
    Linux)
      if grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
        OS_TYPE="raspbian"
      elif [ -f /etc/debian_version ]; then
        OS_TYPE="debian"
      else
        err "Distro Linux ini belum didukung (Hanya support Debian/Ubuntu)."
      fi
      ;;
    *)
      err "OS $(uname) belum didukung."
      ;;
  esac

  log "Mendeteksi OS: $OS_TYPE"
  log "Mendeteksi Arsitektur: $ARCH_TYPE"
}

### ========= Install Paket ========= ###
install_packages() {
  if [ "$OS_TYPE" = "macos" ]; then
    if ! command -v brew &>/dev/null; then
      log "Menginstall Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install zsh git curl nano bat fzf grc gnupg eza lolcat neofetch pv viu 

  elif [[ "$OS_TYPE" == "debian" || "$OS_TYPE" == "raspbian" ]]; then
    sudo apt update
    sudo apt install -y zsh git gzip curl unzip nano fzf grc gnupg lolcat pv
    install_bat_deb
    install_eza_deb
    install_neofetch_or_fastfetch
    install_imgcat
    install_viu

    log "Meng-clone konfigurasi nanorc dari scopatz..."
    curl https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh || warn "Gagal clone nanorc"
  fi
}

### ========= Install bat dari GitHub Releases ========= ###
install_bat_deb() {
  log "Menginstall bat dari GitHub releases..."

  ARCH_DEB=""
  case "$ARCH_TYPE" in
    x86_64) ARCH_DEB="amd64" ;;
    aarch64 | arm64 | armv7l) ARCH_DEB="arm64" ;;
    *) err "Arsitektur tidak dikenali untuk bat." ;;
  esac

  VERSION=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | grep tag_name | cut -d '"' -f4 | sed 's/^v//')
  FILENAME="bat_${VERSION}_${ARCH_DEB}.deb"
  URL="https://github.com/sharkdp/bat/releases/download/v${VERSION}/${FILENAME}"
  TEMP_DEB="/tmp/$FILENAME"

  curl -fL -o "$TEMP_DEB" "$URL" || err "Gagal mengunduh bat .deb"
  sudo dpkg -i "$TEMP_DEB" || sudo apt install -f -y
  rm -f "$TEMP_DEB"

  if [ -f "/usr/bin/batcat" ] && [ ! -f "/usr/local/bin/bat" ]; then
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
  fi
}

### ========= Install eza dari GitHub Releases resmi ========= ###
install_eza_deb() {
  log "Menginstall eza dari GitHub releases resmi..."

  case "$ARCH_TYPE" in
    x86_64) ARCH_DEB="x86_64-unknown-linux-gnu" ;;
    aarch64 | arm64) ARCH_DEB="aarch64-unknown-linux-gnu" ;;
    armv7l) ARCH_DEB="armv7-unknown-linux-gnueabihf" ;;
    *) err "Arsitektur tidak dikenali untuk eza." ;;
  esac

  VERSION=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest | grep '"tag_name":' | cut -d '"' -f4)
  TARBALL="eza_${ARCH_DEB}.tar.gz"
  URL="https://github.com/eza-community/eza/releases/download/${VERSION}/${TARBALL}"
  TEMP_DIR="/tmp/eza-${VERSION}"

  mkdir -p "$TEMP_DIR"
  log "Mengunduh $URL ..."
  curl -fL "$URL" | tar -xz -C "$TEMP_DIR" || err "[ERROR] Gagal mengunduh dan ekstrak eza"
  sudo install -m755 "$TEMP_DIR/eza" /usr/local/bin/eza
  rm -rf "$TEMP_DIR"

  log "eza versi $VERSION berhasil diinstall."
}

### ========= Install Neofetch atau Fastfetch ========= ###
install_neofetch_or_fastfetch() {
  if ! sudo apt install -y neofetch; then
    warn "Gagal install neofetch, mencoba fastfetch..."
    sudo apt install -y fastfetch || warn "Gagal install fastfetch juga."
  fi
}


### ========= Install imgcat (hanya untuk macOS) ========= ###
install_imgcat() {
  if [[ "$OS_TYPE" == "macos" ]]; then
    log "Menginstall imgcat untuk macOS (iTerm2)..."

    if ! command -v imgcat &>/dev/null; then
      mkdir -p "$HOME/.local/bin"
      curl -fsSL -o "$HOME/.local/bin/imgcat" https://iterm2.com/utilities/imgcat \
        || { warn "Gagal mengunduh imgcat"; return; }

      chmod +x "$HOME/.local/bin/imgcat"
      export PATH="$HOME/.local/bin:$PATH"

      log "✅ imgcat berhasil diinstal di ~/.local/bin"
    else
      log "imgcat sudah tersedia."
    fi
  else
    log "Lewati instalasi imgcat karena OS saat ini bukan macOS."
  fi
}

### ========= Install viu (image viewer CLI) ========= ###
install_viu() {
  log "Menginstall viu..."

  case "$ARCH_TYPE" in
    x86_64) ARCH_DL="x86_64-unknown-linux-musl" ;;
    aarch64 | arm64) ARCH_DL="aarch64-unknown-linux-musl" ;;
    armv7l) ARCH_DL="armv7-unknown-linux-musleabihf" ;;
    *) err "Arsitektur tidak dikenali untuk viu." ;;
  esac

  VERSION="v1.5.1"
  FILE="viu-${ARCH_DL}"
  URL="https://github.com/atanunq/viu/releases/download/${VERSION}/${FILE}"

  TEMP_DIR=$(mktemp -d)
  if curl -fsSL "$URL" -o "$TEMP_DIR/viu"; then
    chmod +x "$TEMP_DIR/viu"
    sudo install -m755 "$TEMP_DIR/viu" /usr/local/bin/viu || {
      rm -rf "$TEMP_DIR"
      err "Gagal install viu"
    }
    log "✅ viu v1.5.1 berhasil diinstall."
  else
    rm -rf "$TEMP_DIR"
    if command -v imgcat >/dev/null 2>&1; then
      warn "Gagal mengunduh viu, tapi imgcat tersedia. Melanjutkan..."
    else
      err "Gagal mengunduh viu dan imgcat tidak tersedia. Tidak bisa menampilkan gambar logo."
    fi
  fi
}


### ========= Install Oh My Zsh ========= ###
install_oh_my_zsh() {
  export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
  export ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

  if [ -d "$ZSH" ]; then
    log "Folder Oh My Zsh sudah ada di $ZSH, lewati instalasi."
  else
    log "Menginstall Oh My Zsh..."
    export RUNZSH=no
    export CHSH=no
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
}

### ========= Clone Plugin Zsh ========= ###
clone_plugin() {
  local repo_url="$1"
  local plugin_dir="$2"

  if [ -d "$plugin_dir/.git" ]; then
    log "Plugin $(basename "$plugin_dir") sudah ada, update..."
    git -C "$plugin_dir" pull --quiet || warn "Gagal update plugin $(basename "$plugin_dir")"
  elif [ -d "$plugin_dir" ]; then
    warn "Direktori $plugin_dir sudah ada tapi bukan repo git. Lewati."
  else
    log "Clone plugin $(basename "$plugin_dir")..."
    git clone --depth=1 "$repo_url" "$plugin_dir" || warn "Gagal clone plugin $(basename "$plugin_dir")"
  fi
}

clone_plugins() {
  log "Meng-clone plugin-plugin Zsh..."
  clone_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  clone_plugin "https://github.com/zsh-users/zsh-autosuggestions.git" "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  clone_plugin "https://github.com/MichaelAquilina/zsh-you-should-use.git" "$ZSH_CUSTOM/plugins/zsh-you-should-use"
  clone_plugin "https://github.com/fdellwing/zsh-bat.git" "$ZSH_CUSTOM/plugins/zsh-bat"
  clone_plugin "https://github.com/z-shell/zsh-eza.git" "$ZSH_CUSTOM/plugins/zsh-eza"
}

### ========= Setup Powerlevel10k ========= ###
setup_powerlevel10k() {
  log "Menginstall Powerlevel10k..."
  clone_plugin "https://github.com/romkatv/powerlevel10k.git" "$ZSH_CUSTOM/themes/powerlevel10k"
}

### ========= Unduh Konfigurasi dari GitHub ========= ###
download_config_files() {
  log "Mengunduh konfigurasi zsh dan lainnya dari GitHub..."
  mkdir -p "$HOME/.config/neofetch"
  mkdir -p "$HOME/.nano"

  OS_TYPE="$(uname)"

  if [[ "$OS_TYPE" == "Darwin" ]]; then
    log "Terdeteksi macOS"
    curl -fsSL -o "$HOME/.zshrc" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/zsh/.macos-zshrc || warn "Gagal unduh .macos-zshrc"
  elif [[ "$OS_TYPE" == "Linux" ]]; then
    log "Terdeteksi Linux"
    curl -fsSL -o "$HOME/.zshrc" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/zsh/.zshrc || warn "Gagal unduh .zshrc"
  else
    warn "OS tidak dikenali: $OS_TYPE. Lewati unduhan .zshrc"
  fi

  # Umum untuk semua OS:
  curl -fsSL -o "$HOME/.p10k.zsh" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/zsh/.p10k.zsh || warn "Gagal unduh .p10k.zsh"
  curl -fsSL -o "$HOME/.zprofile" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/zsh/.zprofile || warn "Gagal unduh .zprofile"
  curl -fsSL -o "$HOME/.nanorc" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/nano/.nanorc || warn "Gagal unduh .nanorc"
  curl -fsSL -o "$HOME/.nano/nanorc.nanorc" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/nano/nanorc.nanorc || warn "Gagal unduh nanorc.nanorc"
  curl -fsSL -o "$HOME/.config/neofetch/config.conf" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/neofetch/config.conf || warn "Gagal unduh config.conf"
  curl -fsSL -o "$HOME/.config/neofetch/motd-script.sh" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/script/motd-multi-os.sh || warn "Gagal unduh motd-script.sh"
  curl -fsSL -o "$HOME/.config/neofetch/macos-logo.png" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/neofetch/macos-logo.png || warn "Gagal unduh macos-logo.png"
  curl -fsSL -o "$HOME/.config/neofetch/debian-logo.png" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/neofetch/debian-logo.png || warn "Gagal unduh debian-logo.png"
  curl -fsSL -o "$HOME/.config/neofetch/ubuntu-logo.png" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/neofetch/ubuntu-logo.png || warn "Gagal unduh ubuntu-logo.png"
  curl -fsSL -o "$HOME/.config/neofetch/raspberrypi-logo.png" https://raw.githubusercontent.com/New8ie/ZshStyle/refs/heads/main/neofetch/raspberrypi-logo.png || warn "Gagal unduh raspberrypi-logo.png"

  chmod +x "$HOME/.config/neofetch/motd-script.sh"
}


### ========= Symlink untuk Root User ========= ###
create_symlinks_for_root() {
  log "Membuat symlink konfigurasi untuk root..."

  sudo ln -sf "$HOME/.oh-my-zsh" /root/.oh-my-zsh
  sudo ln -sf "$HOME/.zshrc" /root/.zshrc
  sudo ln -sf "$HOME/.p10k.zsh" /root/.p10k.zsh
  sudo ln -sf "$HOME/.config" /root/.config
  sudo ln -sf "$HOME/.local" /root/.local
  sudo ln -sf "$HOME/.nanorc" /root/.nanorc
  sudo ln -sf "$HOME/.nano" /root/.nano
  sudo ln -sf /usr/games/lolcat /usr/local/bin/lolcat
}

### ========= Eksekusi Utama ========= ###
main() {
  detect_os_arch
  install_packages
  install_oh_my_zsh
  clone_plugins
  setup_powerlevel10k
  download_config_files
  create_symlinks_for_root

  log "✅ Instalasi Zsh with environment selesai!🎉 "
  log "\033[1;93mJalankan:\033[0m \033[1;32msudo chsh -s\033[0m \$(\033[1;31mwhich\033[0m zsh) \033[1;96m\$USER\033[0m -> \033[1;93mUntuk menganti default shell ke current user.\033[0m"
  log "\033[1;93mJalankan:\033[0m \033[1;32mzsh\033[0m -> \033[1;93mUntuk mulai menggunakan zsh shell.\033[0m"
}

main "$@"
