#!/usr/bin/env bash
set -euo pipefail

log()  { echo -e "\033[1;32m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then OS_TYPE="macos"; else OS_TYPE="linux"; fi
  log "Detected OS: $OS_TYPE"
}

backup_dotfiles() {
  TIMESTAMP=$(date +%Y%m%d-%H%M%S)
  DEST="$HOME/dotfiles-backup-$TIMESTAMP"
  mkdir -p "$DEST"
  files=(~/.zshrc ~/.zprofile ~/.p10k.zsh ~/.config/zsh ~/.config/nano ~/.config/neofetch ~/.oh-my-zsh)
  for f in "${files[@]}"; do [ -e "$f" ] && cp -r "$f" "$DEST"; done
  tar -czf "$DEST.tar.gz" -C "$HOME" "$(basename "$DEST")"
  rm -rf "$DEST"
  log "Backup berhasil: $DEST.tar.gz"
}

setup_ohmyzsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    log "Oh-My-Zsh installed."
  fi
}

clone_plugin() {
  local repo dest; repo="$1"; dest="$2"
  [ -d "$dest" ] || ( git clone "$repo" "$dest" && log "Plugin $(basename $dest) cloned." )
}

install_plugins() {
  ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
  mkdir -p "$ZSH_CUSTOM"/{plugins,themes}
  clone_plugin https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  clone_plugin https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  clone_plugin https://github.com/MichaelAquilina/zsh-you-should-use.git "$ZSH_CUSTOM/plugins/zsh-you-should-use"
  clone_plugin https://github.com/fdellwing/zsh-bat.git "$ZSH_CUSTOM/plugins/zsh-bat"
  clone_plugin https://github.com/z-shell/zsh-eza.git "$ZSH_CUSTOM/plugins/zsh-eza"
  clone_plugin https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
}

download_configs() {
  log "Menyalin konfigurasi dari ~/.dotfiles"
  mkdir -p "$HOME/.config"/{zsh,nano,neofetch,fastfetch}

  # zshrc
  if [[ "$OS_TYPE" == "macos" ]]; then
    cp -f ~/.dotfiles/Zsh/macos-zshrc.zsh ~/.zshrc
  else
    cp -f ~/.dotfiles/Zsh/linux-zshrc.zsh ~/.zshrc
  fi
  cp -f ~/.dotfiles/Zsh/.p10k.zsh ~/.p10k.zsh
  cp -f ~/.dotfiles/Zsh/.zprofile ~/.zprofile
  cp -f ~/.dotfiles/Zsh/Alias/alias.zsh ~/.config/zsh/alias.zsh

  # nano
  cp -f ~/.dotfiles/Nano ~/.config/nano
  echo 'include ~/.config/nano/Config/nanorc' > ~/.nanorc

  # neofetch
  cp -f ~/.dotfiles/Neofetch/config.conf ~/.config/neofetch/config.conf
  cp -f ~/.dotfiles/Neofetch/motd-script.sh ~/.config/neofetch/motd-script.sh
  chmod +x ~/.config/neofetch/motd-script.sh
  cp -f ~/.dotfiles/Neofetch/*-logo.png ~/.config/neofetch/ 2>/dev/null || true

  # fastfetch
  cp -f ~/.dotfiles/fastfetch/config.conf ~/.config/neofetch/config.conf
  cp -f ~/.dotfiles/fastfetch/motd-fastfetch.sh ~/.config/fastfetch/motd-fastfetch.sh
  chmod +x ~/.config/fastfetch/motd-fastfetch.sh
  cp -f ~/.dotfiles/fastfetch/logo/*-logo.png ~/.config/fastfetch/logo/ 2>/dev/null || true

   # Iterm2 khusus macOS
  if [[ "$OS_TYPE" == "macos" ]]; then
    mkdir -p "$HOME/.config/iterm2/bin"
    cp -rf ~/.dotfiles/Iterm2/bin/* "$HOME/.config/iterm2/bin" 2>/dev/null || true
    cp -f ~/.dotfiles/Iterm2/iterm2_shell_integration.zsh "$HOME/.config/iterm2/iterm2_shell_integration.zsh" 2>/dev/null || true
  fi
}
  # Windows: alias eza etc not needed here


set_shell() {
  NEW=$(which zsh)
  [ "$SHELL" != "$NEW" ] && {
    if sudo -n true 2>/dev/null; then
      sudo chsh -s "$NEW" "$USER" && log "Default shell diubah ke zsh."
    else
      chsh -s "$NEW" || warn "Jalankan: chsh -s $NEW"
    fi
  }
}

main() {
  detect_os
  backup_dotfiles
  setup_ohmyzsh
  install_plugins
  download_configs
  set_shell
  log "Setup complete! Jalankan ulang terminal atau `exec zsh`."
}
main
