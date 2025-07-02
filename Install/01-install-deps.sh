#!/usr/bin/env bash
set -euo pipefail

### ========= utils.sh style logging ========= ###
log()  { echo -e "\033[1;32m[INFO]\033[0m $*" | tee -a install-log.txt; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*" | tee -a install-log.txt; }
err()  { echo -e "\033[1;31m[ERROR]\033[0m $*" | tee -a install-log.txt >&2; exit 1; }

### ========= Deteksi OS dan Arsitektur ========= ###
detect_os() {
  ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64|amd64) ARCH_TYPE="amd64" ;;
    aarch64|arm64) ARCH_TYPE="arm64" ;;
    *) ARCH_TYPE="unknown" ;;
  esac

  if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
  elif [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
      debian|ubuntu|raspbian) OS_TYPE="debian" ;;
      arch)                   OS_TYPE="arch" ;;
      fedora)                 OS_TYPE="fedora" ;;
      *) err "Distro Linux $ID belum didukung." ;;
    esac
  else
    err "OS tidak dikenali."
  fi

  log "Dikenali OS: $OS_TYPE ($ARCH_TYPE)"
}

### ========= Konfirmasi Interaktif ========= ###
prompt_package_type() {
  echo -e "\nApakah Anda ingin menginstall aplikasi desktop (GUI)?"
  select opt in "Ya (desktop)" "Tidak (server)"; do
    case $REPLY in
      1) PACKAGE_MODE="desktop"; break ;;
      2) PACKAGE_MODE="server"; break ;;
      *) echo "Pilihan tidak valid." ;;
    esac
  done
  log "Mode dipilih: $PACKAGE_MODE"
}

### ========= Daftar Paket ========= ###
SERVER_PACKAGES=(zsh git curl fzf grc gnupg lolcat neofetch pv bat nmap fd zoxide fastfetch unzip nano fontconfig)
DESKTOP_PACKAGES=(yazi kitty iterm2 telnet mounty raycast vlc awscli btop coreutils w3m openvpn-connect speedtest keepassxc ollama)

### ========= Install Paket Berdasarkan OS ========= ###
install_packages() {
  local packages=("${SERVER_PACKAGES[@]}")
  [ "$PACKAGE_MODE" = "desktop" ] && packages+=("${DESKTOP_PACKAGES[@]}")

  case "$OS_TYPE" in
    macos)
      if ! command -v brew &>/dev/null; then
        log "Menginstall Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      for pkg in "${packages[@]}"; do
        if brew list "$pkg" &>/dev/null; then
          log "[SKIP] $pkg sudah terinstall."
        else
          if brew install "$pkg"; then
            log "[OK] $pkg berhasil diinstall."
          else
            warn "[FAIL] Gagal menginstall $pkg."
          fi
        fi
      done
      ;;

    debian)
      sudo apt update
      for pkg in "${packages[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
          log "[SKIP] $pkg sudah terinstall."
        else
          if sudo apt install -y "$pkg"; then
            log "[OK] $pkg berhasil diinstall."
          else
            warn "[FAIL] Gagal menginstall $pkg."
          fi
        fi
      done
      if ! command -v eza &>/dev/null; then
        log "Mengunduh dan menginstall eza binary..."
        LATEST_EZA=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest | grep browser_download_url | grep "linux-${ARCH_TYPE}.tar.gz" | cut -d '"' -f 4 | head -n1)
        mkdir -p /tmp/eza-install && cd /tmp/eza-install
        curl -LO "$LATEST_EZA"
        tar -xf *.tar.gz
        sudo mv eza /usr/local/bin/
        cd ~ && rm -rf /tmp/eza-install
        log "[OK] eza berhasil diinstall dari GitHub."
      fi
      ;;

    arch)
      sudo pacman -Sy --noconfirm
      for pkg in "${packages[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
          log "[SKIP] $pkg sudah terinstall."
        else
          if sudo pacman -S --noconfirm "$pkg"; then
            log "[OK] $pkg berhasil diinstall."
          else
            warn "[FAIL] Gagal menginstall $pkg."
          fi
        fi
      done
      if ! command -v yay &>/dev/null; then
        log "Menginstall yay AUR helper..."
        git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm && cd ..
      fi
      for pkg in bat viu fastfetch; do yay -S --noconfirm "$pkg" && log "[OK] $pkg berhasil diinstall (yay)." || warn "[FAIL] Gagal menginstall $pkg (yay)."; done
      [ "$PACKAGE_MODE" = "desktop" ] && for pkg in "${DESKTOP_PACKAGES[@]}"; do yay -S --noconfirm "$pkg" && log "[OK] $pkg berhasil diinstall (yay)." || warn "[FAIL] Gagal menginstall $pkg (yay)."; done
      ;;

    fedora)
      sudo dnf install -y "${packages[@]}"
      ;;
  esac
}

### ========= Clone Dotfiles ========= ###
clone_dotfiles() {
  if [ ! -d "$HOME/.dotfiles" ]; then
    git clone https://github.com/New8ie/Dotfiles.git "$HOME/.dotfiles"
    log "Repo Dotfiles berhasil diklon."
  else
    log "Repo .dotfiles sudah ada."
  fi
}

### ========= Jalankan Script Kedua ========= ###
run_next_script() {
  local next_script="$HOME/.dotfiles/Install/02-setup-zsh.sh"
  if [ -f "$next_script" ]; then
    chmod +x "$next_script"
    log "Menjalankan konfigurasi Zsh dari $next_script"
    "$next_script" 2>&1 | tee -a install-log.txt
  else
    warn "Script konfigurasi kedua tidak ditemukan: $next_script"
  fi
}

### ========= Main ========= ###
detect_os
prompt_package_type
install_packages
clone_dotfiles
run_next_script
