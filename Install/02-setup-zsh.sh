#!/usr/bin/env bash
set - euo pipefail # =============================================================================
  # Logging Helpers
  # =============================================================================
  log() { echo - e "\033[1;32m[INFO]\033[0m $*" } warn() { echo - e "\033[1;33m[WARN]\033[0m $*" } err() { echo - e "\033[1;31m[ERROR]\033[0m $*" exit 1 } # =============================================================================
  # Detect OS
  # =============================================================================
  detect_os() { if [[ "$OSTYPE" == linux-gnu* ]]; then

    if [[ -f /etc/debian_version ]]; then
      OS_TYPE="debian"

    elif [[ -f /etc/redhat-release ]]; then
      OS_TYPE="redhat"

    elif [[ -f /etc/arch-release ]]; then
      OS_TYPE="arch"

    else
      OS_TYPE="linux"
    fi

  elif [[ "$OSTYPE" == darwin* ]]; then
    OS_TYPE="macos"

  else
    OS_TYPE="unknown"
  fi

  log "Terdeteksi OS: $OS_TYPE"
}

# =============================================================================
# Detect Architecture
# =============================================================================

detect_arch() {

  ARCH=$(uname -m)

  case "$ARCH" in

    x86_64)
      ARCH_TYPE="amd64"
      ;;

    aarch64|arm64)
      ARCH_TYPE="arm64"
      ;;

    armv7l)
      ARCH_TYPE="armhf"
      ;;

    *)
      err "Arsitektur tidak didukung: $ARCH"
      ;;
  esac

  log "Terdeteksi Arsitektur: $ARCH_TYPE"
}

# =============================================================================
# Check Dependencies
# =============================================================================

check_dependencies() {

  local missing=()

  command -v git >/dev/null 2>&1 || missing+=("git")
  command -v curl >/dev/null 2>&1 || missing+=("curl")
  command -v tar >/dev/null 2>&1 || missing+=("tar")

  if [[ "$OS_TYPE" != "macos" ]]; then
    command -v wget >/dev/null 2>&1 || missing+=("wget")
  fi

  if [[ "${#missing[@] } " -gt 0 ]]; then
    warn " Dependency berikut belum tersedia :"
    printf '  - %s\n' " $ { missing [@] } "

    case " $OS_TYPE " in

      macos)
        warn " Install dependency dengan Homebrew :"
        echo " brew install $ { missing [*] } "
        ;;

      debian)
        warn " Install dependency dengan :"
        echo " sudo apt
update "
        echo " sudo apt install - y $ { missing [*] } "
        ;;

      redhat)
        warn " Install dependency dengan :"
        echo " sudo dnf install - y $ { missing [*] } "
        ;;

      arch)
        warn " Install dependency dengan :"
        echo " sudo pacman - S --noconfirm ${missing[*]}"
;
;
esac err "Dependency belum lengkap." fi log "Dependency dasar tersedia." } # =============================================================================
# Backup Dotfiles
# =============================================================================
backup_dotfiles() { local timestamp backup_file f local - a files archive_paths timestamp = $(date + %Y %m %d - %H %M %S) backup_file = "$HOME/dotfiles-backup-$timestamp.tar.gz" # Daftar file/folder yang ingin dibackup
files =(
  "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.p10k.zsh" "$HOME/.config/script" "$HOME/.config/zsh" "$HOME/.config/nano" "$HOME/.config/fastfetch" "$HOME/.config/iterm2" "$HOME/.config/glow" "$HOME/.config/tmux" "$HOME/.config/homebrew" "$HOME/.oh-my-zsh" "$HOME/.nanorc"
) # Hanya arsipkan item yang ada
archive_paths =() for f in "${files[@]}";
do if [[ -e "$f" || -L "$f" ]]; then
      archive_paths+=("${f#"$HOME"/}")
    else
      warn "Lewati, tidak ditemukan: $f"
    fi

  done

  if [[ "${#archive_paths[@] } " -eq 0 ]]; then
    err " Tidak ada file atau folder yang dapat dibackup."
  fi

  log " Memulai backup ke :"
  echo " $backup_file "

  tar -czvf " $backup_file " \ - C "$HOME" \ "${archive_paths[@]}" log "Backup berhasil: $backup_file" } # =============================================================================
# Setup Oh My Zsh
# =============================================================================
setup_ohmyzsh() { if [[ ! -d "$HOME/.oh-my-zsh" ]]; then

    log "Menginstall Oh-My-Zsh..."

    RUNZSH=no \
    CHSH=no \
    KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    log "Oh-My-Zsh berhasil diinstall."

  else

    log "Oh-My-Zsh sudah ada, skip install."

  fi
}

# =============================================================================
# Clone Helper
# =============================================================================

clone_plugin() {

  local repo="$1"
  local dest="$2"

  if [[ -d "$dest" ]]; then
    log "Plugin $(basename "$dest") sudah ada, skip."
    return
  fi

  git clone "$repo" "$dest"

  log "Plugin $(basename "$dest") berhasil di-clone."
}

# =============================================================================
# Install Plugins
# =============================================================================

install_plugins() {

  local ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

  mkdir -p "$ZSH_CUSTOM/plugins"
  mkdir -p "$ZSH_CUSTOM/themes"

  clone_plugin \
    "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

  clone_plugin \
    "https://github.com/zsh-users/zsh-autosuggestions.git" \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

  clone_plugin \
    "https://github.com/zsh-users/zsh-completions.git" \
    "$ZSH_CUSTOM/plugins/zsh-completions"

  clone_plugin \
    "https://github.com/Aloxaf/fzf-tab.git" \
    "$ZSH_CUSTOM/plugins/fzf-tab"

  clone_plugin \
    "https://github.com/MichaelAquilina/zsh-you-should-use.git" \
    "$ZSH_CUSTOM/plugins/zsh-you-should-use"

  clone_plugin \
    "https://github.com/fdellwing/zsh-bat.git" \
    "$ZSH_CUSTOM/plugins/zsh-bat"

  clone_plugin \
    "https://github.com/z-shell/zsh-eza.git" \
    "$ZSH_CUSTOM/plugins/zsh-eza"

  clone_plugin \
    "https://github.com/romkatv/powerlevel10k.git" \
    "$ZSH_CUSTOM/themes/powerlevel10k"

  log "Semua plugin Oh-My-Zsh selesai."
}

# =============================================================================
# Install Fastfetch
# =============================================================================

install_fastfetch() {

  case "$OS_TYPE" in

    debian)

      log "Install Fastfetch untuk Debian ($ARCH_TYPE)..."

      case "$ARCH_TYPE" in

        amd64)
          PKG_URL="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb"
          ;;

        arm64)
          PKG_URL="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-aarch64.deb"
          ;;

        armhf)
          PKG_URL="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-armhf.deb"
          ;;

        *)
          err "Arsitektur tidak didukung untuk Fastfetch: $ARCH_TYPE"
          ;;
      esac

      wget \
        -O /tmp/fastfetch.deb \
        "$PKG_URL" \
        || err "Gagal download Fastfetch."

      sudo apt install -y /tmp/fastfetch.deb \
        || err "Gagal install Fastfetch."

      rm -f /tmp/fastfetch.deb
      ;;

    arch)

      log "Install Fastfetch untuk Arch Linux..."

      sudo pacman -S --needed --noconfirm fastfetch
      ;;

    redhat)

      log "Install Fastfetch untuk RedHat/Fedora..."

      sudo dnf install -y fastfetch \
        || err "Gagal install Fastfetch."
      ;;

    macos)

      log "Install Fastfetch untuk macOS..."

      if ! command -v brew >/dev/null 2>&1; then
        err "Homebrew tidak ditemukan. Install Homebrew terlebih dahulu."
      fi

      if brew list fastfetch >/dev/null 2>&1; then
        log "Fastfetch sudah terinstall via Homebrew, skip."

      else
        brew install fastfetch \
          || err "Gagal install Fastfetch."
      fi
      ;;

    *)

      err "OS tidak didukung untuk Fastfetch: $OS_TYPE"
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

  mkdir -p "$HOME/.config/zsh/functions"
  mkdir -p "$HOME/.config/nano"
  mkdir -p "$HOME/.config/fastfetch/logo"
  mkdir -p "$HOME/.config/iterm2"
  mkdir -p "$HOME/.config/script"

  # ---------------------------------------------------------------------------
  # Daftar file yang akan di-replace
  # ---------------------------------------------------------------------------

  local -a files_to_replace=(
    "$HOME/.zshrc"
    "$HOME/.zprofile"
    "$HOME/.p10k.zsh"
    "$HOME/.nanorc"
    "$HOME/.config/zsh/alias.zsh"
  )

  # Hapus file atau symlink lama sebelum copy
  for f in "${files_to_replace[@] } "; do

    if [[ -L " $f " ]]; then
      log " 🧹 Menghapus symlink lama: $f "
      rm -f " $f "

    elif [[ -e " $f " ]]; then
      log " 🧹 Menghapus file lama: $f "
      rm -f " $f "
    fi

  done

  # ---------------------------------------------------------------------------
  # Salin konfigurasi utama Zsh
  # ---------------------------------------------------------------------------

  if [[ " $OS_TYPE " == " macos " ] ];
then cp - f \ "$HOME/.dotfiles/Zsh/macos-zshrc.zsh" \ "$HOME/.zshrc"
else cp - f \ "$HOME/.dotfiles/Zsh/linux-zshrc.zsh" \ "$HOME/.zshrc" fi cp - f \ "$HOME/.dotfiles/OhMyZsh/p10k.zsh" \ "$HOME/.p10k.zsh" cp - f \ "$HOME/.dotfiles/Zsh/zprofile.zsh" \ "$HOME/.zprofile" cp - f \ "$HOME/.dotfiles/Zsh/Alias/alias.zsh" \ "$HOME/.config/zsh/alias.zsh" cp - f \ "$HOME/.dotfiles/Zsh/function-manager.zsh" \ "$HOME/.config/zsh/function-manager.zsh" # ---------------------------------------------------------------------------
# Nano
# ---------------------------------------------------------------------------
log "🧹 Membersihkan konfigurasi nano lama" rm - rf "$HOME/.config/nano" mkdir - p "$HOME/.config/nano" cp - rf \ "$HOME/.dotfiles/Nano/." \ "$HOME/.config/nano/" cp - f \ "$HOME/.config/nano/Config/nanorc" \ "$HOME/.nanorc" # ---------------------------------------------------------------------------
# Functions & Script
# ---------------------------------------------------------------------------
log "🧹 Membersihkan konfigurasi zsh functions & script lama" rm - rf \ "$HOME/.config/zsh/functions" \ "$HOME/.config/script" mkdir - p \ "$HOME/.config/zsh/functions" \ "$HOME/.config/script" cp - rf \ "$HOME/.dotfiles/Zsh/Functions/." \ "$HOME/.config/zsh/functions/" cp - rf \ "$HOME/.dotfiles/Script/." \ "$HOME/.config/script/" find "$HOME/.config/script" \ - type f \ - exec chmod + x { } \;
2 > / dev / null || true # ---------------------------------------------------------------------------
# Fastfetch
# ---------------------------------------------------------------------------
log "🧹 Membersihkan konfigurasi Fastfetch lama" rm - rf "$HOME/.config/fastfetch" mkdir - p "$HOME/.config/fastfetch/logo" cp - f \ "$HOME/.dotfiles/Fastfetch/config.jsonc" \ "$HOME/.config/fastfetch/config.jsonc" cp - f \ "$HOME/.dotfiles/Fastfetch/motd-fastfetch.sh" \ "$HOME/.config/fastfetch/motd-fastfetch.sh" chmod + x \ "$HOME/.config/fastfetch/motd-fastfetch.sh" if compgen - G "$HOME/.dotfiles/Fastfetch/logo/*-logo.png" > / dev / null 2 > & 1;
then cp - f \ "$HOME/.dotfiles/Fastfetch/logo/" * - logo.png \ "$HOME/.config/fastfetch/logo/" fi # ---------------------------------------------------------------------------
# iTerm2
# ---------------------------------------------------------------------------
log "🧹 Membersihkan konfigurasi iTerm2 lama" rm - rf "$HOME/.config/iterm2" mkdir - p "$HOME/.config/iterm2/bin" if [[ -d "$HOME/.dotfiles/Iterm2/bin" ]]; then

    cp -rf \
      "$HOME/.dotfiles/Iterm2/bin/." \
      "$HOME/.config/iterm2/bin/"

  fi

  if [[ -f "$HOME/.dotfiles/Iterm2/iterm2_shell_integration.zsh" ]]; then

    cp -f \
      "$HOME/.dotfiles/Iterm2/iterm2_shell_integration.zsh" \
      "$HOME/.config/iterm2/iterm2_shell_integration.zsh"

  fi

  find "$HOME/.config/iterm2/bin" \
    -type f \
    -exec chmod +x {} \; 2>/dev/null || true

  # ---------------------------------------------------------------------------
  # Selesai
  # ---------------------------------------------------------------------------

  log "✅ Semua konfigurasi berhasil dicopy."
  log "File lama/symlink telah direplace."

}

# =============================================================================
# Symlink Configs
# =============================================================================

symlink_configs() {

  log "🔗 Membuat symlink konfigurasi (mode symlink dengan replace aman)"

  mkdir -p "$HOME/.config/zsh"
  mkdir -p "$HOME/.config/nano"
  mkdir -p "$HOME/.config/fastfetch/logo"
  mkdir -p "$HOME/.config/iterm2"

  # ---------------------------------------------------------------------------
  # Safe Symlink Helper
  # ---------------------------------------------------------------------------

  safe_link() {

    local src="$1"
    local dest="$2"

    if [[ -e "$dest" || -L "$dest" ]]; then

      log "🧹 Menghapus target lama: $dest"

      rm -rf "$dest"
    fi

    ln -s "$src" "$dest"

    log "🔗 $dest -> $src"
  }

  # ---------------------------------------------------------------------------
  # ZSH
  # ---------------------------------------------------------------------------

  if [[ "$OS_TYPE" == "macos" ]]; then

    safe_link \
      "$HOME/.dotfiles/Zsh/macos-zshrc.zsh" \
      "$HOME/.zshrc"

  else

    safe_link \
      "$HOME/.dotfiles/Zsh/linux-zshrc.zsh" \
      "$HOME/.zshrc"

  fi

  safe_link \
    "$HOME/.dotfiles/OhMyZsh/p10k.zsh" \
    "$HOME/.p10k.zsh"

  safe_link \
    "$HOME/.dotfiles/Zsh/zprofile.zsh" \
    "$HOME/.zprofile"

  safe_link \
    "$HOME/.dotfiles/Zsh/Alias/alias.zsh" \
    "$HOME/.config/zsh/alias.zsh"

  # ---------------------------------------------------------------------------
  # Zsh Functions
  # ---------------------------------------------------------------------------

  rm -rf "$HOME/.config/zsh/functions"

  mkdir -p "$HOME/.config/zsh/functions"

  cp -rf \
    "$HOME/.dotfiles/Zsh/Functions/." \
    "$HOME/.config/zsh/functions/"

  cp -f \
    "$HOME/.dotfiles/Zsh/function-manager.zsh" \
    "$HOME/.config/zsh/function-manager.zsh"

  # ---------------------------------------------------------------------------
  # Nano
  # ---------------------------------------------------------------------------

  rm -rf "$HOME/.config/nano"

  mkdir -p "$HOME/.config/nano"

  cp -rf \
    "$HOME/.dotfiles/Nano/." \
    "$HOME/.config/nano/"

  cp -f \
    "$HOME/.config/nano/Config/nanorc" \
    "$HOME/.nanorc"

  # ---------------------------------------------------------------------------
  # Script
  # ---------------------------------------------------------------------------

  rm -rf "$HOME/.config/script"

  safe_link \
    "$HOME/.dotfiles/Script" \
    "$HOME/.config/script"

  find "$HOME/.config/script" \
    -type f \
    -exec chmod +x {} \; 2>/dev/null || true

  # ---------------------------------------------------------------------------
  # Fastfetch
  # ---------------------------------------------------------------------------

  safe_link \
    "$HOME/.dotfiles/Fastfetch/config.jsonc" \
    "$HOME/.config/fastfetch/config.jsonc"

  safe_link \
    "$HOME/.dotfiles/Fastfetch/motd-fastfetch.sh" \
    "$HOME/.config/fastfetch/motd-fastfetch.sh"

  chmod +x \
    "$HOME/.config/fastfetch/motd-fastfetch.sh"

  if compgen -G "$HOME/.dotfiles/Fastfetch/logo/*-logo.png" >/dev/null 2>&1; then

    cp -f \
      "$HOME/.dotfiles/Fastfetch/logo/"*-logo.png \
      "$HOME/.config/fastfetch/logo/"

  fi

  # ---------------------------------------------------------------------------
  # iTerm2
  # ---------------------------------------------------------------------------

  mkdir -p "$HOME/.config/iterm2/bin"

  if [[ -d "$HOME/.dotfiles/Iterm2/bin" ]]; then

    cp -rf \
      "$HOME/.dotfiles/Iterm2/bin/." \
      "$HOME/.config/iterm2/bin/"

  fi

  safe_link \
    "$HOME/.dotfiles/Iterm2/iterm2_shell_integration.zsh" \
    "$HOME/.config/iterm2/iterm2_shell_integration.zsh"

  find "$HOME/.config/iterm2/bin" \
    -type f \
    -exec chmod +x {} \; 2>/dev/null || true

  log "✅ Symlink konfigurasi berhasil dibuat."
  log "File lama sudah direplace."

}

# =============================================================================
# Config Menu
# =============================================================================

config_menu() {

  echo
  echo "=========================================="
  echo "  Pilih mode setup konfigurasi dotfiles"
  echo "=========================================="
  echo "  [1] Copy file (aman, standalone) "
  echo " [2] Symlink (lebih fleksibel, sync dengan repo) "
  echo " ------------------------------------------"
read - rp "Masukkan pilihan [1/2]: " pilihan case"$pilihan" in 1) copy_configs;
;
2
) symlink_configs;
;
*
) warn "Pilihan tidak valid, default: Copy" copy_configs;
;
esac } # =============================================================================
# Set Default Shell
# =============================================================================
set_shell() { local NEW NEW = $(command - v zsh) if [[ -z "$NEW" ]]; then
    warn "zsh tidak ditemukan."
    return
  fi

  log "zsh ditemukan: $NEW"

  if [[ "$SHELL" != "$NEW" ]]; then

    log "Default shell saat ini: ${SHELL:-unknown}"
    log "Mengubah default shell menjadi: $NEW"

    if sudo -n true >/dev/null 2>&1; then

      sudo chsh -s "$NEW" "$USER" \
        && log "Default shell diubah ke zsh."

    else

      chsh -s "$NEW" \
        && log "Default shell diubah ke zsh." \
        || warn "Gagal mengubah shell. Jalankan manual: chsh -s $NEW"

    fi

  else

    log "Default shell sudah menggunakan zsh."

  fi
}

# =============================================================================
# Verify Fastfetch
# =============================================================================

verify_fastfetch() {

  if command -v fastfetch >/dev/null 2>&1; then

    log "Fastfetch berhasil terinstall."

    fastfetch --version \
      || warn "Fastfetch terinstall tetapi gagal dijalankan."

  else

    err "Fastfetch tidak ditemukan setelah instalasi."
  fi
}

# =============================================================================
# Verify Dotfiles
# =============================================================================

verify_dotfiles() {

  local -a required_files=(
    "$HOME/.zshrc"
    "$HOME/.zprofile"
    "$HOME/.p10k.zsh"
    "$HOME/.nanorc"
    "$HOME/.config/zsh/alias.zsh"
  )

  local f

  log "Memeriksa konfigurasi utama..."

  for f in "${required_files[@] } "; do

    if [[ -e " $f " || -L " $f " ]]; then
      log " OK: $f "
    else
      warn " Tidak ditemukan: $f "
    fi

  done
}

# =============================================================================
# Main
# =============================================================================

main() {

  detect_os
  detect_arch

  if [[ " $OS_TYPE " == " unknown " ]]; then
    err " OS tidak didukung."
  fi

  check_dependencies

  backup_dotfiles

  setup_ohmyzsh

  install_plugins

  install_fastfetch

  config_menu

  set_shell

  verify_fastfetch

  verify_dotfiles

  echo
  log " == == == == == == == == == == == == == == == == == == == == == "
  log " Setup selesai ! "
  log " == == == == == == == == == == == == == == == == == == == == == "
  log " Restart terminal atau jalankan :"
  echo
  echo " exec zsh "
  echo
}

main

# =============================================================================
# Next Step (Interactive Menu)
# =============================================================================

while true; do

  echo
  echo " == == == == == == == == == == == == == == == == == == == == == "
  echo " Langkah selanjutnya :"
  echo " == == == == == == == == == == == == == == == == == == == == == "
  echo " [1] Install & konfigurasi Fail2ban "
  echo " [2] Keluar "
  echo " ------------------------------------------"
read - rp "Masukkan pilihan [1/2]: " pilihan case"$pilihan" in 1) if [[ ! -f "$HOME/.dotfiles/Install/03-install-fail2ban.sh" ]]; then
        warn "Script Fail2ban tidak ditemukan:"
        echo "  $HOME/.dotfiles/Install/03-install-fail2ban.sh"
        break
      fi

      chmod +x \
        "$HOME/.dotfiles/Install/03-install-fail2ban.sh"

      bash \
        "$HOME/.dotfiles/Install/03-install-fail2ban.sh"

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