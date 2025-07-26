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
      rhel|centos|rocky|almalinux) OS_TYPE="redhat" ;;
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
      packages=(zsh git curl fzf grc gnupg lolcat pv neofetch bat fastfetch coreutils w3m fd yazi zoxide)

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
    redhat)
      sudo yum install -y epel-release
      sudo yum install -y zsh git curl fzf grc gnupg2 lolcat pv neofetch bat fastfetch awscli btop coreutils w3m zoxide net-tools 
      ;;
    macos)
      if ! command -v brew &>/dev/null; then
        while true; do
          read -rp "Homebrew belum terinstall. Install Homebrew? (y/n): " jawab
          case "$jawab" in
            y|Y)
              /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
              eval "$($(command -v brew) shellenv)"
              break
              ;;
            n|N)
              warn "Homebrew sudah diinstall. Melewati instalasi paket Homebrew."
              return
              ;;
            *)
              warn "Input tidak valid. Pilih y atau n."
              ;;
          esac
        done
      fi
      brew update
      brew install zsh git curl fzf grc gnupg lolcat pv neofetch bat fastfetch coreutils w3m zoxide eza nano yazi fd
      ;;
    arch)
      sudo pacman -Sy --noconfirm zsh git curl fzf grc gnupg lolcat pv neofetch bat fastfetch coreutils w3m zoxide fd net-tools
      ;;
    fedora)
      sudo dnf install -y zsh git curl fzf grc gnupg lolcat pv neofetch bat fastfetch coreutils w3m zoxide net-tools
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
  while true; do
    echo
    echo "Langkah selanjutnya: setup Zsh."
    echo "Pilih opsi berikut:"
    echo "[1] Lanjut jalankan ~/.dotfiles/Install/02-setup-zsh.sh"
    echo "[2] Keluar"
    read -rp "Masukkan pilihan [1/2]: " pilihan
    case "$pilihan" in
      1)
        bash ~/.dotfiles/Install/02-setup-zsh.sh
        break
        ;;
      2)
        log "Script selesai. Keluar."
        break
        ;;
      *)
        warn "Pilihan tidak valid. Silakan pilih lagi."
        ;;
    esac
  done
}
main
