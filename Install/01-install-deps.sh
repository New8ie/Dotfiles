#!/usr/bin/env bash
set -euo pipefail

### ========= utils.sh style logging ========= ###
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
      debian|ubuntu|raspbian) OS_TYPE="debian" ;;
      arch)                   OS_TYPE="arch"   ;;
      fedora)                 OS_TYPE="fedora" ;;
      *) err "Distro Linux $ID belum didukung." ;;
    esac
  else
    err "OS tidak dikenali."
  fi
  log "Dikenali OS: $OS_TYPE"
}

### ========= Install Paket ========= ###
install_packages() {
  case "$OS_TYPE" in
    macos)
      if ! command -v brew &>/dev/null; then
        log "Menginstall Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      brew install zsh git curl fzf grc gnupg eza lolcat neofetch pv viu bat
      ;;

    debian)
      sudo apt update
      sudo apt install -y zsh git curl unzip nano fzf grc gnupg lolcat pv
      # Bat & eza manual install (dari skrip existing Anda)
      curl -sS https://deb.gierens.de/gpg.txt | sudo tee /etc/apt/trusted.gpg.d/gierens.asc
      echo "deb [arch=$(dpkg --print-architecture)] https://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
      sudo apt update
      sudo apt install -y bat eza viu fastfetch
      ;;

    arch)
      sudo pacman -Sy --noconfirm zsh git curl unzip nano fzf grc gnupg lolcat pv
      if ! command -v yay &>/dev/null; then
        log "Menginstall yay AUR helper..."
        git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm && cd ..
      fi
      yay -S --noconfirm bat eza viu fastfetch
      ;;

    fedora)
      sudo dnf install -y zsh git curl unzip nano fzf grc gnupg lolcat pv
      sudo dnf install -y bat eza viu fastfetch
      ;;
  esac
}

### ========= Clone Dotfiles ========= ###
clone_dotfiles() {
  if [ ! -d "$HOME/.dotfiles" ]; then
    git clone https://github.com/New8ie/Dotfiles.git "$HOME/.dotfiles"
  else
    log "Repo .dotfiles sudah ada."
  fi
}

### ========= Jalankan Script Kedua ========= ###
run_next_script() {
  chmod +x "$HOME/.dotfiles/scripts/02-setup-zsh.sh"
  "$HOME/.dotfiles/scripts/02-setup-zsh.sh"
}

### ========= Main ========= ###
detect_os
install_packages
clone_dotfiles
run_next_script
