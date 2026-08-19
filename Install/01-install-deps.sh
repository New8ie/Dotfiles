#!/usr/bin/env bash
set -euo pipefail

trap 'echo -e "\033[1;31m[ERROR]\033[0m Terjadi error pada baris $LINENO. Keluar dengan kode $?"' ERR

log()  { echo -e "\033[1;32m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[ERROR]\033[0m $*"; exit 1; }

detect_os() {
  log "Deteksi OS..."
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

install_packages() {
  log "Mulai proses instalasi paket..."
  set +e
  case "$OS_TYPE" in
    linux)
      sudo apt update
      packages=(zsh git curl fzf grc gnupg lolcat pv bat rsync nano coreutils sudo w3m fd-find zoxide net-tools xclip iproute2)
      sudo ln -s $(which fdfind) /usr/local/bin/fd
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

      # Install eza
      if ! command -v eza &>/dev/null; then
        ARCH_TYPE=$(uname -m)
        install_eza_deb
      else
        log "[SKIP] eza sudah terinstall."
      fi
    ;;
    redhat)
      sudo yum install -y epel-release
      sudo yum install -y zsh git curl fzf nano grc gnupg2 lolcat pv bat sudo coreutils w3m zoxide fd-find net-tools iproute2 rsync
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
              warn "Melewati instalasi paket Homebrew."
              return
              ;;
            *)
              warn "Input tidak valid. Pilih y atau n."
              ;;
          esac
        done
      fi
      brew update
      brew install zsh git curl fzf grc gnupg nano lolcat pv bat coreutils w3m zoxide eza nano fd-find ffmpeg sevenzip rsync jq caskhub poppler fd ripgrep resvg imagemagick font-symbols-only-nerd-font xclip
      ;;
    arch)
      sudo pacman -Sy --noconfirm zsh git curl fzf grc gnupg nano lolcat pv bat coreutils w3m zoxide fd-find net-tools iproute2 rsync xclip
      ;;
    fedora)
      sudo dnf install -y zsh git curl fzf grc gnupg lolcat pv nano bat coreutils w3m fd-find zoxide net-tools iproute2 rsync sudo xclip rsync
      ;;
  esac
  set -e
}

clone_dotfiles() {
  log "Clone repo dotfiles..."
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

  log "Sampai ke akhir script, masuk ke tahap setup Zsh."

  while true; do
    echo
    echo "=========================================="
    echo "Langkah selanjutnya: setup Zsh"
    echo "=========================================="
    echo "Pilih opsi berikut:"
    echo "  [1] Lanjut jalankan ~/.dotfiles/Install/02-setup-zsh.sh"
    echo "  [2] Keluar"
    echo "------------------------------------------"
    read -rp "Masukkan pilihan [1/2]: " pilihan
    case "$pilihan" in
      1)
        chmod +x ~/.dotfiles/Install/02-setup-zsh.sh
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
