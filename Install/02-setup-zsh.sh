
#!/usr/bin/env bash

# =============================================================================
# Dotfiles - Setup ZSH
#
# Script ini HARUS dijalankan sebagai user biasa.
#
# Jangan menjalankan:
#   sudo bash 02-setup-zsh.sh
#
# Script 01 akan menjalankan script ini sebagai REAL_USER.
# =============================================================================

set -euo pipefail

# =============================================================================
# Color
# =============================================================================

RESET='\033[0m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'

# =============================================================================
# Root Guard
# =============================================================================

if [[ "$(id -u)" -eq 0 ]]; then
  printf '%b[ERROR]%b 02-setup-zsh.sh harus dijalankan sebagai user biasa.\n' \
    "$RED" \
    "$RESET"

  printf '%b[ERROR]%b Jangan menjalankan script ini dengan sudo.\n' \
    "$RED" \
    "$RESET"

  exit 1
fi

# =============================================================================
# Error Handler
# =============================================================================

trap 'rc=$?; err "Script berhenti pada line $LINENO dengan exit code $rc."' ERR

# =============================================================================
# Global Variables
# =============================================================================

OS_TYPE=""
INSTALL_DIR="$HOME/.dotfiles/Install"

# =============================================================================
# Logging
# =============================================================================

log() {
  local message="$*"

  case "$message" in
    "[OK]"*)
      printf '%b[OK]%b %s\n' \
        "$GREEN" \
        "$RESET" \
        "${message#"[OK] "}"
      ;;

    "[SKIP]"*)
      printf '%b[SKIP]%b %s\n' \
        "$YELLOW" \
        "$RESET" \
        "${message#"[SKIP] "}"
      ;;

    *)
      printf '%b[INFO]%b %s\n' \
        "$CYAN" \
        "$RESET" \
        "$message"
      ;;
  esac
}

warn() {
  local message="$*"

  case "$message" in
    "[WARN]"*)
      printf '%b[WARN]%b %s\n' \
        "$YELLOW" \
        "$RESET" \
        "${message#"[WARN] "}" >&2
      ;;

    *)
      printf '%b[WARN]%b %s\n' \
        "$YELLOW" \
        "$RESET" \
        "$message" >&2
      ;;
  esac
}

err() {
  local message="$*"

  case "$message" in
    "[ERROR]"*)
      printf '%b[ERROR]%b %s\n' \
        "$RED" \
        "$RESET" \
        "${message#"[ERROR] "}" >&2
      ;;

    *)
      printf '%b[ERROR]%b %s\n' \
        "$RED" \
        "$RESET" \
        "$message" >&2
      ;;
  esac
}

# =============================================================================
# Require Command
# =============================================================================

require_command() {
  local cmd="$1"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    err "Command '$cmd' tidak ditemukan."
    return 1
  fi
}

# =============================================================================
# Detect OS
# =============================================================================

detect_os() {
  log "Deteksi OS..."

  local OS_NAME

  OS_NAME="$(uname -s | tr '[:upper:]' '[:lower:]')"

  case "$OS_NAME" in
    darwin)
      OS_TYPE="macos"
      ;;

    linux)
      if [[ ! -r /etc/os-release ]]; then
        err "File /etc/os-release tidak ditemukan."
        return 1
      fi

      # shellcheck disable=SC1091
      source /etc/os-release

      case "${ID:-}" in
        debian|ubuntu|raspbian)
          OS_TYPE="debian"
          ;;

        arch)
          OS_TYPE="arch"
          ;;

        fedora)
          OS_TYPE="fedora"
          ;;

        rhel|centos|rocky|almalinux)
          OS_TYPE="redhat"
          ;;

        *)
          err "Distribusi Linux '${ID:-unknown}' tidak didukung."
          return 1
          ;;
      esac
      ;;

    *)
      err "OS '$OS_NAME' tidak didukung."
      return 1
      ;;
  esac

  log "Detected OS: $OS_TYPE"
}

# =============================================================================
# Detect Architecture
# =============================================================================

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64)
      echo "x86_64"
      ;;

    arm64|aarch64)
      echo "aarch64"
      ;;

    armv7l|armv7)
      echo "armv7l"
      ;;

    *)
      uname -m
      ;;
  esac
}

# =============================================================================
# Detect Homebrew
# =============================================================================

BREW_BIN=""

detect_brew() {
  BREW_BIN=""

  # Apple Silicon
  if [[ -x /opt/homebrew/bin/brew ]]; then
    BREW_BIN="/opt/homebrew/bin/brew"
    return 0
  fi

  # Intel macOS
  if [[ -x /usr/local/bin/brew ]]; then
    BREW_BIN="/usr/local/bin/brew"
    return 0
  fi

  # PATH
  if command -v brew >/dev/null 2>&1; then
    BREW_BIN="$(command -v brew)"
    return 0
  fi

  return 1
}

# =============================================================================
# Backup Dotfiles
# =============================================================================

backup_dotfiles() {
  local TIMESTAMP
  local DEST
  local files
  local config_dirs
  local item
  local copied_count=0

  TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
  DEST="$HOME/dotfiles-backup-$TIMESTAMP"

  files=(
    "$HOME/.zshrc"
    "$HOME/.zprofile"
    "$HOME/.p10k.zsh"
    "$HOME/.nanorc"
  )

  config_dirs=(
    "$HOME/.config/zsh"
    "$HOME/.config/nvim"
    "$HOME/.config/iterm2"
    "$HOME/.config/nano"
    "$HOME/.config/tmux"
    "$HOME/.config/glow"
    "$HOME/.config/fastfetch"
    "$HOME/.config/homebrew"
  )

  log "Membuat backup konfigurasi ZSH..."

  mkdir -p "$DEST/.config"

  # ---------------------------------------------------------------------------
  # Backup file konfigurasi utama
  # ---------------------------------------------------------------------------

  for item in "${files[@]}"; do
    if [[ -e "$item" || -L "$item" ]]; then
      if cp -a "$item" "$DEST/"; then
        copied_count=$((copied_count + 1))
      else
        warn "Gagal membackup: $item"
      fi
    else
      log "[SKIP] File tidak ditemukan: $item"
    fi
  done

  # ---------------------------------------------------------------------------
  # Backup konfigurasi .config terpilih
  # ---------------------------------------------------------------------------

  for item in "${config_dirs[@]}"; do
    if [[ -e "$item" || -L "$item" ]]; then
      if cp -a "$item" "$DEST/.config/"; then
        copied_count=$((copied_count + 1))
      else
        warn "Gagal membackup: $item"
      fi
    else
      log "[SKIP] Direktori tidak ditemukan: $item"
    fi
  done

  # ---------------------------------------------------------------------------
  # Tidak ada data
  # ---------------------------------------------------------------------------

  if [[ "$copied_count" -eq 0 ]]; then
    rm -rf "$DEST"
    log "[SKIP] Tidak ada konfigurasi yang perlu dibackup."
    return 0
  fi

  # ---------------------------------------------------------------------------
  # Archive
  # ---------------------------------------------------------------------------

  if tar -czf "$DEST.tar.gz" -C "$HOME" "$(basename "$DEST")"; then
    rm -rf "$DEST"
    log "[OK] Backup konfigurasi dibuat: $DEST.tar.gz"
  else
    warn "Backup konfigurasi gagal."
    warn "Data staging dipertahankan: $DEST"
    return 1
  fi
}

# =============================================================================
# Setup Oh My Zsh
# =============================================================================

setup_ohmyzsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log "[SKIP] Oh My Zsh sudah terinstall."
    return 0
  fi

  require_command curl
  require_command sh

  log "Menginstall Oh My Zsh..."

  if RUNZSH=no \
    CHSH=no \
    KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then

    log "[OK] Oh My Zsh berhasil diinstall."
  else
    err "Gagal menginstall Oh My Zsh."
    return 1
  fi
}

# =============================================================================
# Clone Plugin
# =============================================================================

clone_plugin() {
  local repo="$1"
  local destination="$2"

  if [[ -d "$destination" ]]; then
    log "[SKIP] Plugin sudah ada: $destination"
    return 0
  fi

  require_command git

  mkdir -p "$(dirname "$destination")"

  log "Clone plugin: $repo"

  if git clone "$repo" "$destination"; then
    log "[OK] Plugin berhasil diinstall: $destination"
  else
    err "Gagal clone plugin: $repo"
    return 1
  fi
}

# =============================================================================
# Install Plugins
# =============================================================================

install_plugins() {
  log "Menginstall plugin Oh My Zsh..."

  clone_plugin \
    "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

  clone_plugin \
    "https://github.com/zsh-users/zsh-autosuggestions.git" \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"

  clone_plugin \
    "https://github.com/zsh-users/zsh-completions.git" \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-completions"

  clone_plugin \
    "https://github.com/Aloxaf/fzf-tab.git" \
    "$HOME/.oh-my-zsh/custom/plugins/fzf-tab"

  clone_plugin \
    "https://github.com/MichaelAquilina/zsh-you-should-use.git" \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-you-should-use"

  clone_plugin \
    "https://github.com/fdellwing/zsh-bat.git" \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-bat"

  clone_plugin \
    "https://github.com/z-shell/F-Sy-H.git" \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-eza"

  clone_plugin \
    "https://github.com/romkatv/powerlevel10k.git" \
    "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"

  log "[OK] Proses plugin selesai."
}

# =============================================================================
# Install Fastfetch
# =============================================================================

install_fastfetch() {
  local ARCH
  local URL
  local TEMP_FILE

  # ---------------------------------------------------------------------------
  # Jangan reinstall jika sudah tersedia
  # ---------------------------------------------------------------------------

  if command -v fastfetch >/dev/null 2>&1; then
    log "[SKIP] Fastfetch sudah terinstall: $(fastfetch --version 2>/dev/null | head -n1)"
    return 0
  fi

  case "$OS_TYPE" in

    # =========================================================================
    # Debian / Ubuntu / Raspbian
    # =========================================================================

    debian)
      require_command curl
      require_command dpkg
      require_command sudo
      require_command apt-get

      ARCH="$(detect_arch)"

      case "$ARCH" in
        x86_64)
          URL="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb"
          ;;

        aarch64)
          URL="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-aarch64.deb"
          ;;

        armv7l)
          URL="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-armhf.deb"
          ;;

        *)
          err "Fastfetch package otomatis belum tersedia untuk arsitektur: $ARCH"
          return 1
          ;;
      esac

      TEMP_FILE="/tmp/fastfetch-$$.deb"

      log "Menginstall Fastfetch via dpkg..."
      log "Architecture: $ARCH"

      if ! curl -fsSL "$URL" -o "$TEMP_FILE"; then
        rm -f "$TEMP_FILE"
        err "Gagal mengunduh Fastfetch."
        return 1
      fi

      if ! sudo dpkg -i "$TEMP_FILE"; then
        log "Memperbaiki dependency Fastfetch..."

        if ! sudo apt-get install -f -y; then
          rm -f "$TEMP_FILE"
          err "Gagal memperbaiki dependency Fastfetch."
          return 1
        fi
      fi

      rm -f "$TEMP_FILE"

      if command -v fastfetch >/dev/null 2>&1; then
        log "[OK] Fastfetch berhasil diinstall."
      else
        err "Fastfetch gagal diinstall."
        return 1
      fi
      ;;

    # =========================================================================
    # macOS
    # =========================================================================

    macos)
      if ! detect_brew; then
        warn "Homebrew tidak ditemukan. Fastfetch dilewati."
        return 0
      fi

      log "Menginstall Fastfetch via Homebrew..."

      if "$BREW_BIN" list --formula fastfetch >/dev/null 2>&1; then
        log "[SKIP] Fastfetch sudah terinstall."
        return 0
      fi

      if "$BREW_BIN" install fastfetch; then
        log "[OK] Fastfetch berhasil diinstall."
      else
        err "Gagal menginstall Fastfetch via Homebrew."
        return 1
      fi
      ;;

    # =========================================================================
    # Arch
    # =========================================================================

    arch)
      require_command sudo
      require_command pacman

      log "Menginstall Fastfetch via pacman..."

      if sudo pacman -S --needed --noconfirm fastfetch; then
        log "[OK] Fastfetch berhasil diinstall."
      else
        err "Gagal menginstall Fastfetch via pacman."
        return 1
      fi
      ;;

    # =========================================================================
    # Fedora
    # =========================================================================

    fedora)
      require_command sudo
      require_command dnf

      log "Menginstall Fastfetch via dnf..."

      if sudo dnf install -y fastfetch; then
        log "[OK] Fastfetch berhasil diinstall."
      else
        err "Gagal menginstall Fastfetch via dnf."
        return 1
      fi
      ;;

    # =========================================================================
    # RHEL / CentOS / Rocky / AlmaLinux
    # =========================================================================

    redhat)
      require_command sudo
      require_command yum

      log "Menginstall Fastfetch via yum..."

      if sudo yum install -y fastfetch; then
        log "[OK] Fastfetch berhasil diinstall."
      else
        err "Gagal menginstall Fastfetch via yum."
        return 1
      fi
      ;;

    *)
      warn "OS '$OS_TYPE' tidak didukung untuk instalasi Fastfetch otomatis."
      return 1
      ;;
  esac
}

# =============================================================================
# Copy Configurations
# =============================================================================

copy_file() {
  local source="$1"
  local destination="$2"

  if [[ -L "$destination" ]]; then
    rm -f "$destination"
  fi

  cp "$source" "$destination"
}

copy_directory_contents() {
  local source="$1"
  local destination="$2"
  local item
  local target

  [[ -d "$source" ]] || return 0

  if [[ -L "$destination" ]]; then
    rm -f "$destination"
  fi

  mkdir -p "$destination"

  for item in "$source"/* "$source"/.[!.]* "$source"/..?*; do
    [[ -e "$item" || -L "$item" ]] || continue

    target="$destination/$(basename "$item")"
    if [[ -e "$target" || -L "$target" ]]; then
      rm -rf "$target"
    fi

    cp -a "$item" "$destination/"
  done
}

copy_configs() {
  local file

  log "Menyalin konfigurasi..."

  mkdir -p \
    "$HOME/.config/nano" \
    "$HOME/.config/fastfetch" \
    "$HOME/.config/iterm2/bin" \
    "$HOME/.config/script" \
    "$HOME/.config/zsh/functions"

  mkdir -p "$HOME/.config/fastfetch/logo"

  # ---------------------------------------------------------------------------
  # Hapus konfigurasi lama yang akan diganti
  # ---------------------------------------------------------------------------

  local files_to_replace=(
    "$HOME/.zshrc"
    "$HOME/.zprofile"
    "$HOME/.p10k.zsh"
    "$HOME/.nanorc"
    "$HOME/.config/zsh/alias.zsh"
    "$HOME/.config/zsh/function-manager.zsh"
  )

  for file in "${files_to_replace[@]}"; do
    if [[ -e "$file" || -L "$file" ]]; then
      rm -rf "$file"
    fi
  done

  # ---------------------------------------------------------------------------
  # ZSH
  # ---------------------------------------------------------------------------

  if [[ "$OS_TYPE" == "macos" ]]; then
    copy_file "$HOME/.dotfiles/Zsh/macos-zshrc.zsh" "$HOME/.zshrc"
  else
    copy_file "$HOME/.dotfiles/Zsh/linux-zshrc.zsh" "$HOME/.zshrc"
  fi

  copy_file "$HOME/.dotfiles/OhMyZsh/p10k.zsh" "$HOME/.p10k.zsh"
  copy_file "$HOME/.dotfiles/Zsh/zprofile.zsh" "$HOME/.zprofile"
  copy_file "$HOME/.dotfiles/Zsh/Alias/alias.zsh" "$HOME/.config/zsh/alias.zsh"
  copy_file "$HOME/.dotfiles/Zsh/function-manager.zsh" "$HOME/.config/zsh/function-manager.zsh"

  # ---------------------------------------------------------------------------
  # Nano
  # ---------------------------------------------------------------------------

  copy_directory_contents "$HOME/.dotfiles/Nano" "$HOME/.config/nano"

  copy_file "$HOME/.dotfiles/Nano/Config/nanorc" "$HOME/.nanorc"

  # ---------------------------------------------------------------------------
  # ZSH Functions
  # ---------------------------------------------------------------------------

  copy_directory_contents \
    "$HOME/.dotfiles/Zsh/Functions" \
    "$HOME/.config/zsh/functions"

  # ---------------------------------------------------------------------------
  # Scripts
  # ---------------------------------------------------------------------------

  copy_directory_contents "$HOME/.dotfiles/Script" "$HOME/.config/script"

  # ---------------------------------------------------------------------------
  # Fastfetch
  # ---------------------------------------------------------------------------

  copy_file \
    "$HOME/.dotfiles/Fastfetch/config.jsonc" \
    "$HOME/.config/fastfetch/config.jsonc"

  copy_file \
    "$HOME/.dotfiles/Fastfetch/motd-fastfetch.sh" \
    "$HOME/.config/fastfetch/motd-fastfetch.sh"

  copy_directory_contents \
    "$HOME/.dotfiles/Fastfetch/logo" \
    "$HOME/.config/fastfetch/logo"

  # ---------------------------------------------------------------------------
  # iTerm2
  #
  # Hanya relevan untuk macOS, tetapi tidak berbahaya jika directory tidak ada.
  # ---------------------------------------------------------------------------

  copy_directory_contents \
    "$HOME/.dotfiles/Iterm2/bin" \
    "$HOME/.config/iterm2/bin"

  if [[ -f "$HOME/.dotfiles/Iterm2/iterm2_shell_integration.zsh" ]]; then
    copy_file \
      "$HOME/.dotfiles/Iterm2/iterm2_shell_integration.zsh" \
      "$HOME/.config/iterm2/iterm2_shell_integration.zsh"
  fi

  log "[OK] Konfigurasi berhasil disalin."
}

# =============================================================================
# Approve Configuration Copy
# =============================================================================

config_menu() {
  local choice

  echo
  echo "============================================================================="
  echo " Salin konfigurasi Dotfiles"
  echo "============================================================================="
  echo "File konfigurasi yang sudah ada dan dikelola installer akan diganti."
  echo

  while true; do
    read -r -p "Lanjutkan menyalin konfigurasi? [y/N]: " choice

    case "$choice" in
      y|Y|yes|YES|Yes)
        copy_configs
        return
        ;;

      ""|n|N|no|NO|No)
        log "[SKIP] Penyalinan konfigurasi dilewati."
        return
        ;;

      *)
        warn "Pilihan tidak valid. Masukkan y atau n."
        ;;
    esac
  done
}

# =============================================================================
# Set Default Shell
# =============================================================================

set_shell() {
  local NEW_SHELL

  require_command zsh
  require_command chsh

  NEW_SHELL="$(command -v zsh)"

  if [[ -z "$NEW_SHELL" ]]; then
    err "Path zsh tidak ditemukan."
    return 1
  fi

  # ---------------------------------------------------------------------------
  # Pastikan zsh terdaftar sebagai valid shell jika /etc/shells tersedia.
  #
  # macOS dan Linux sama-sama menggunakan /etc/shells.
  # ---------------------------------------------------------------------------

  if [[ -f /etc/shells ]]; then
    if ! grep -Fxq "$NEW_SHELL" /etc/shells 2>/dev/null; then
      warn "zsh belum terdaftar di /etc/shells: $NEW_SHELL"
      warn "Perubahan default shell mungkin meminta privilege tambahan."
    fi
  fi

  # ---------------------------------------------------------------------------
  # Deteksi shell saat ini.
  #
  # $SHELL bisa berasal dari environment dan tidak selalu sama dengan passwd.
  # ---------------------------------------------------------------------------

  local CURRENT_SHELL="${SHELL:-}"

  if [[ "$CURRENT_SHELL" == "$NEW_SHELL" ]]; then
    log "[SKIP] Default shell sudah menggunakan zsh: $NEW_SHELL"
    return 0
  fi

  log "Mengubah default shell menjadi zsh: $NEW_SHELL"

  # ---------------------------------------------------------------------------
  # macOS
  #
  # chsh biasanya meminta password user sendiri.
  # Jangan memaksa sudo jika tidak diperlukan.
  # ---------------------------------------------------------------------------

  if [[ "$OS_TYPE" == "macos" ]]; then
    if chsh -s "$NEW_SHELL"; then
      log "[OK] Default shell berhasil diubah ke zsh."
      return 0
    fi

    warn "chsh gagal mengubah default shell."
    warn "Coba jalankan manual:"
    warn "chsh -s $NEW_SHELL"
    return 1
  fi

  # ---------------------------------------------------------------------------
  # Linux
  # ---------------------------------------------------------------------------

  if chsh -s "$NEW_SHELL"; then
    log "[OK] Default shell berhasil diubah ke zsh."
    return 0
  fi

  # ---------------------------------------------------------------------------
  # Fallback Linux jika chsh membutuhkan privilege.
  # ---------------------------------------------------------------------------

  if command -v sudo >/dev/null 2>&1; then
    if sudo chsh -s "$NEW_SHELL" "$USER"; then
      log "[OK] Default shell berhasil diubah ke zsh."
      return 0
    fi
  fi

  warn "Gagal mengubah default shell menjadi zsh."
  return 1
}

# =============================================================================
# Verify Fastfetch
# =============================================================================

verify_fastfetch() {
  require_command fastfetch

  log "Memverifikasi Fastfetch..."

  if fastfetch --version >/dev/null 2>&1; then
    log "[OK] Fastfetch tersedia: $(fastfetch --version 2>/dev/null | head -n1)"
  else
    err "Fastfetch tidak dapat dijalankan."
    return 1
  fi
}

# =============================================================================
# Run Next Script
# =============================================================================

run_next_script() {
  local script="$1"

  if [[ ! -f "$INSTALL_DIR/$script" ]]; then
    err "Script tidak ditemukan: $INSTALL_DIR/$script"
    return 1
  fi

  if [[ ! -x "$INSTALL_DIR/$script" ]]; then
    chmod +x "$INSTALL_DIR/$script"
  fi

  bash "$INSTALL_DIR/$script"
}

# =============================================================================
# Langkah Berikutnya
# =============================================================================

next_steps_menu() {
  local choice

  while true; do
    echo
    echo "============================================================================="
    echo " Langkah Berikutnya"
    echo "============================================================================="
    echo
    echo "  1. Selesai"
    echo "     Keluar dari installer."
    echo
    echo "  2. Install Fail2Ban"
    echo "     Memasang dan mengonfigurasi Fail2Ban sebagai service sistem."
    echo
    echo "  3. Hardening SSH"
    echo "     Mengamankan konfigurasi SSH pada sistem."
    echo
    echo "  4. Setup ZSH Root"
    echo "     Menyalin konfigurasi ZSH untuk akun root."
    echo
    echo "============================================================================="
    echo

    read -r -p "Pilih [1-4] (default: 1): " choice

    choice="${choice:-1}"

    case "$choice" in
      1)
        log "Selesai."
        return 0
        ;;

      2)
        if [[ "$OS_TYPE" == "macos" ]]; then
          warn "Fail2Ban bukan bagian dari setup macOS ini."
          warn "Pilihan dilewati pada macOS."
          continue
        fi

        log "Pilihan: Install Fail2Ban."
        log "Menjalankan 03-install-fail2ban.sh..."

        if run_next_script "03-install-fail2ban.sh"; then
          log "[OK] Install Fail2Ban selesai."
        else
          err "Install Fail2Ban gagal."
        fi
        ;;

      3)
        if [[ "$OS_TYPE" == "macos" ]]; then
          warn "Hardening SSH ini ditujukan untuk sistem Linux."
          warn "Pilihan dilewati pada macOS."
          continue
        fi

        log "Pilihan: Hardening SSH."
        log "Menjalankan 05-harden-ssh.sh..."

        if run_next_script "05-harden-ssh.sh"; then
          log "[OK] Hardening SSH selesai."
        else
          err "Hardening SSH gagal."
        fi
        ;;

      4)
        log "Pilihan: Setup ZSH Root."
        log "Menjalankan 04-setup-zsh-root.sh..."

        if command -v sudo >/dev/null 2>&1; then
          if sudo bash "$INSTALL_DIR/04-setup-zsh-root.sh"; then
            log "[OK] Setup ZSH Root selesai."
          else
            err "Setup ZSH Root gagal."
          fi
        else
          warn "sudo tidak ditemukan."
          warn "Setup ZSH Root dilewati."
        fi
        ;;

      *)
        warn "Pilihan tidak valid: $choice"
        warn "Masukkan angka 1 sampai 4."
        ;;
    esac
  done
}

# =============================================================================
# Main
# =============================================================================

main() {
  detect_os

  echo
  log "============================================================================="
  log " ZSH Environment"
  log "============================================================================="
  log "OS   : $OS_TYPE"
  log "USER : $USER"
  log "HOME : $HOME"
  log "============================================================================="
  echo

  backup_dotfiles
  setup_ohmyzsh
  install_plugins
  install_fastfetch
  config_menu
  set_shell
  verify_fastfetch

  echo

  log "============================================================================="
  log " Setup ZSH selesai."
  log "============================================================================="
  log "Restart terminal atau jalankan: exec zsh"

  next_steps_menu
}

# =============================================================================
# Run
# =============================================================================

main "$@"
