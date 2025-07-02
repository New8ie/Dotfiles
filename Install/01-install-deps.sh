#!/usr/bin/env bash
set -euo pipefail

log()  { echo -e "\033[1;32m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[ERROR]\033[0m $*"; exit 1; }

detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
  elif [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
      debian|ubuntu|raspbian) OS_TYPE="linux" ;;
      arch)                   OS_TYPE="arch" ;;
      fedora)                 OS_TYPE="fedora" ;;
      *) err "Distro Linux $ID belum didukung." ;;
    esac
  else
    err "OS tidak dikenali."
  fi
  log "Detected OS: $OS_TYPE"
}

install_packages() {
  case "$OS_TYPE" in
    linux)
      sudo apt update
      packages=(zsh git curl fzf grc gnupg lolcat pv neofetch bat fastfetch awscli btop coreutils w3m zoxide)

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

      # Alias batcat -> bat
      if ! command -v bat &>/dev/null && command -v batcat &>/dev/null; then
        sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
        log "[OK] Alias batcat → bat dibuat."
      fi

      # Install eza dari GitHub jika belum ada
      if ! command -v eza &>/dev/null; then
        log "Install eza dari GitHub release..."
        ARCH_TYPE=$(dpkg --print-architecture)
        LATEST=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest \
          | grep browser_download_url \
          | grep "linux-${ARCH_TYPE}.tar.gz" \
          | cut -d '"' -f 4 | head -n1)
        if [ -n "$LATEST" ]; then
          tmp=$(mktemp -d)
          cd "$tmp"
          curl -LO "$LATEST"
          tar -xf *.tar.gz
          sudo mv eza /usr/local/bin/
          cd ~ && rm -rf "$tmp"
          log "[OK] eza berhasil diinstall: $(eza --version)"
        else
          warn "[FAIL] URL download eza tidak ditemukan."
        fi
      else
        log "[SKIP] eza sudah terinstall."
      fi
      ;;
    macos)
      brew update
      brew install zsh git curl fzf grc gnupg lolcat pv neofetch bat fastfetch awscli btop coreutils w3m zoxide
      ;;
    arch)
      sudo pacman -Sy --noconfirm zsh git curl fzf grc gnupg lolcat pv neofetch bat fastfetch awscli btop coreutils w3m zoxide
      ;;
    fedora)
      sudo dnf install -y zsh git curl fzf grc gnupg lolcat pv neofetch bat fastfetch awscli btop coreutils w3m zoxide
      ;;
  esac
}

clone_dotfiles() {
  if [ ! -d "$HOME/.dotfiles" ]; then
    git clone https://github.com/New8ie/Dotfiles.git "$HOME/.dotfiles"
    log "Repo Dotfiles berhasil diklon."
  else
    log "Repo .dotfiles sudah ada."
  fi
}

main() {
  detect_os
  install_packages
  clone_dotfiles
  log "Langkah selanjutnya: jalankan bash ~/.dotfiles/Install/02-setup-zsh.sh"
}
main
