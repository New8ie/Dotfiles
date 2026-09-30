#!/usr/bin/env bash

# =============================================================================
# Dotfiles - Setup ZSH
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

if [[ $EUID -eq 0 ]]; then
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
      if [[ -r /etc/os-release ]]; then
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
      else
        err "File /etc/os-release tidak ditemukan."
        return 1
      fi
      ;;

    *)
      err "OS '$OS_NAME' tidak didukung."
      return 1
      ;;
  esac

  log "Detected OS: $OS_TYPE"
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

  # ===========================================================================
  # File konfigurasi utama di HOME
  # ===========================================================================

  files=(
    "$HOME/.zshrc"
    "$HOME/.zprofile"
    "$HOME/.p10k.zsh"
    "$HOME/.nanorc"
  )

  # ===========================================================================
  # Direktori .config yang memang ingin dibackup
  #
  # Hanya direktori yang tercantum di sini yang akan dibackup.
  # Direktori .config lainnya TIDAK akan ikut.
  # ===========================================================================

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

  # ===========================================================================
  # Buat staging directory
  # ===========================================================================

  mkdir -p "$DEST/.config"

  # ===========================================================================
  # Backup file konfigurasi utama
  # ===========================================================================

  for item in "${files[@]}"; do
    if [[ -e "$item" || -L "$item" ]]; then

      if cp -a "$item" "$DEST/"; then
        copied_count=$((copied_count + 1))
      else
        warn "[WARN] Gagal membackup: $item"
      fi

    else
      log "[SKIP] File tidak ditemukan: $item"
    fi
  done

  # ===========================================================================
  # Backup direktori .config yang dipilih
  # ===========================================================================

  for item in "${config_dirs[@]}"; do
    if [[ -e "$item" || -L "$item" ]]; then

      if cp -a "$item" "$DEST/.config/"; then
        copied_count=$((copied_count + 1))
      else
        warn "[WARN] Gagal membackup: $item"
      fi

    else
      log "[SKIP] Direktori tidak ditemukan: $item"
    fi
  done

  # ===========================================================================
  # Tidak ada data yang berhasil dibackup
  # ===========================================================================

  if [[ "$copied_count" -eq 0 ]]; then
    rm -rf "$DEST"

    log "[SKIP] Tidak ada konfigurasi yang perlu dibackup."

    return 0
  fi

  # ===========================================================================
  # Buat archive
  # ===========================================================================

  if tar \
    -czf "$DEST.tar.gz" \
    -C "$HOME" \
    "$(basename "$DEST")"; then

    # Hapus staging directory setelah archive berhasil dibuat.
    rm -rf "$DEST"

    log "[OK] Backup konfigurasi dibuat: $DEST.tar.gz"

  else
    # Jangan menghapus staging jika proses tar gagal.
    warn "[WARN] Backup konfigurasi gagal."
    warn "[WARN] Data staging dipertahankan: $DEST"

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

  log "Menginstall Oh My Zsh..."

  if RUNZSH=no \
    CHSH=no \
    KEEP_ZSHRC=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then

    log "[OK] Oh My Zsh berhasil diinstall."

  else
    err "[ERROR] Gagal menginstall Oh My Zsh."
    return 1
  fi
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

  log "Clone plugin: $repo"

  if git clone "$repo" "$destination"; then
    log "[OK] Plugin berhasil diinstall: $destination"
  else
    err "[ERROR] Gagal clone plugin: $repo"
    return 1
  fi
}

# =============================================================================
# Install Plugins
# =============================================================================

install_plugins() {
  log "Menginstall plugin Oh My Zsh..."

  clone_plugin \
    https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

  clone_plugin \
    https://github.com/zsh-users/zsh-autosuggestions.git \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"

  clone_plugin \
    https://github.com/zsh-users/zsh-completions.git \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-completions"

  clone_plugin \
    https://github.com/Aloxaf/fzf-tab.git \
    "$HOME/.oh-my-zsh/custom/plugins/fzf-tab"

  clone_plugin \
    https://github.com/MichaelAquilina/zsh-you-should-use.git \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-you-should-use"

  clone_plugin \
    https://github.com/fdellwing/zsh-bat.git \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-bat"

  clone_plugin \
    https://github.com/z-shell/F-Sy-H.git \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-eza"

  clone_plugin \
    https://github.com/romkatv/powerlevel10k.git \
    "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"

  log "[OK] Proses plugin selesai."
}

# =============================================================================
# Install Fastfetch
# =============================================================================

install_fastfetch() {
  # ---------------------------------------------------------------------------
  # Jangan reinstall jika Fastfetch sudah tersedia.
  # Berlaku untuk semua OS.
  # ---------------------------------------------------------------------------

  if command -v fastfetch >/dev/null 2>&1; then
    log "[SKIP] Fastfetch sudah terinstall: $(fastfetch --version 2>/dev/null | head -n1)"
    return 0
  fi

  case "$OS_TYPE" in

    # -------------------------------------------------------------------------
    # Debian / Ubuntu
    # -------------------------------------------------------------------------

    debian)
      require_command curl

      log "Menginstall Fastfetch via dpkg/apt..."

      if curl -fsSL \
          https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb \
          -o /tmp/fastfetch.deb; then

        if sudo dpkg -i /tmp/fastfetch.deb; then
          :
        else
          sudo apt-get install -f -y
        fi

      else
        err "[ERROR] Gagal mengunduh Fastfetch."
        rm -f /tmp/fastfetch.deb
        return 1
      fi

      rm -f /tmp/fastfetch.deb

      if command -v fastfetch >/dev/null 2>&1; then
        log "[OK] Fastfetch berhasil diinstall."
      else
        err "[ERROR] Fastfetch gagal diinstall."
        return 1
      fi
      ;;

    # -------------------------------------------------------------------------
    # macOS
    # -------------------------------------------------------------------------

    macos)
      require_command brew

      log "Menginstall Fastfetch via Homebrew..."

      if brew install fastfetch; then
        if command -v fastfetch >/dev/null 2>&1; then
          log "[OK] Fastfetch berhasil diinstall."
        else
          err "[ERROR] Fastfetch gagal diinstall."
          return 1
        fi
      else
        err "[ERROR] Gagal menginstall Fastfetch via Homebrew."
        return 1
      fi
      ;;

    # -------------------------------------------------------------------------
    # Arch
    # -------------------------------------------------------------------------

    arch)
      require_command pacman

      log "Menginstall Fastfetch via pacman..."

      if sudo pacman -S --needed --noconfirm fastfetch; then
        if command -v fastfetch >/dev/null 2>&1; then
          log "[OK] Fastfetch berhasil diinstall."
        else
          err "[ERROR] Fastfetch gagal diinstall."
          return 1
        fi
      else
        err "[ERROR] Gagal menginstall Fastfetch via pacman."
        return 1
      fi
      ;;

    # -------------------------------------------------------------------------
    # Fedora
    # -------------------------------------------------------------------------

    fedora)
      require_command dnf

      log "Menginstall Fastfetch via dnf..."

      if sudo dnf install -y fastfetch; then
        if command -v fastfetch >/dev/null 2>&1; then
          log "[OK] Fastfetch berhasil diinstall."
        else
          err "[ERROR] Fastfetch gagal diinstall."
          return 1
        fi
      else
        err "[ERROR] Gagal menginstall Fastfetch via dnf."
        return 1
      fi
      ;;

    # -------------------------------------------------------------------------
    # RHEL / CentOS / Rocky / AlmaLinux
    # -------------------------------------------------------------------------

    redhat)
      require_command yum

      log "Menginstall Fastfetch via yum..."

      if sudo yum install -y fastfetch; then
        if command -v fastfetch >/dev/null 2>&1; then
          log "[OK] Fastfetch berhasil diinstall."
        else
          err "[ERROR] Fastfetch gagal diinstall."
          return 1
        fi
      else
        err "[ERROR] Gagal menginstall Fastfetch via yum."
        return 1
      fi
      ;;

    *)
      warn "[WARN] OS '$OS_TYPE' tidak didukung untuk instalasi Fastfetch otomatis."
      return 1
      ;;
  esac
}

# =============================================================================
# Copy Configurations
# =============================================================================

copy_configs() {
  log "Menyalin konfigurasi..."

  mkdir -p "$HOME/.config"/{nano,fastfetch,iterm2,script,zsh/functions}
  mkdir -p "$HOME/.config/fastfetch/logo"

  local files_to_replace=(
    "$HOME/.zshrc"
    "$HOME/.zprofile"
    "$HOME/.p10k.zsh"
    "$HOME/.nanorc"
    "$HOME/.config/zsh/alias.zsh"
  )

  local file

  for file in "${files_to_replace[@]}"; do
    if [[ -e "$file" || -L "$file" ]]; then
      rm -rf "$file"
    fi
  done

  if [[ "$OS_TYPE" == "macos" ]]; then
    cp "$HOME/.dotfiles/Zsh/macos-zshrc.zsh" "$HOME/.zshrc"
  else
    cp "$HOME/.dotfiles/Zsh/linux-zshrc.zsh" "$HOME/.zshrc"
  fi

  cp "$HOME/.dotfiles/OhMyZsh/p10k.zsh" \
    "$HOME/.p10k.zsh"

  cp "$HOME/.dotfiles/Zsh/zprofile.zsh" \
    "$HOME/.zprofile"

  cp "$HOME/.dotfiles/Zsh/Alias/alias.zsh" \
    "$HOME/.config/zsh/alias.zsh"

  cp "$HOME/.dotfiles/Zsh/function-manager.zsh" \
    "$HOME/.config/zsh/function-manager.zsh"

  cp -rf "$HOME/.dotfiles/Nano/"* \
    "$HOME/.config/nano"

  cp "$HOME/.config/nano/Config/nanorc" \
    "$HOME/.nanorc"

  cp -rf "$HOME/.dotfiles/Zsh/Functions/"* \
    "$HOME/.config/zsh/functions"

  cp -rf "$HOME/.dotfiles/Script/"* \
    "$HOME/.config/script"

  cp "$HOME/.dotfiles/Fastfetch/config.jsonc" \
    "$HOME/.config/fastfetch/config.jsonc"

  cp "$HOME/.dotfiles/Fastfetch/motd-fastfetch.sh" \
    "$HOME/.config/fastfetch/motd-fastfetch.sh"

  cp -rf "$HOME/.dotfiles/Fastfetch/logo/"*-logo.png \
    "$HOME/.config/fastfetch/logo/"

  cp -rf "$HOME/.dotfiles/Iterm2/bin/"* \
    "$HOME/.config/iterm2/bin"

  cp "$HOME/.dotfiles/Iterm2/iterm2_shell_integration.zsh" \
    "$HOME/.config/iterm2/iterm2_shell_integration.zsh"

  log "[OK] Konfigurasi berhasil disalin."
}

# =============================================================================
# Safe Symlink
# =============================================================================

safe_link() {
  local src="$1"
  local dest="$2"

  if [[ -e "$dest" || -L "$dest" ]]; then
    rm -rf "$dest"
  fi

  ln -s "$src" "$dest"
}

# =============================================================================
# Symlink Configurations
# =============================================================================

symlink_configs() {
  log "Membuat symlink konfigurasi..."

  mkdir -p "$HOME/.config"/{nano,fastfetch,iterm2,script,zsh/functions}
  mkdir -p "$HOME/.config/fastfetch/logo"

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

  safe_link \
    "$HOME/.dotfiles/Zsh/function-manager.zsh" \
    "$HOME/.config/zsh/function-manager.zsh"

  # ---------------------------------------------------------------------------
  # ZSH Functions
  # ---------------------------------------------------------------------------

  local file
  for file in "$HOME/.dotfiles/Zsh/Functions/"*; do
    [[ -e "$file" ]] || continue

    safe_link \
      "$file" \
      "$HOME/.config/zsh/functions/$(basename "$file")"
  done

  # ---------------------------------------------------------------------------
  # Nano
  # ---------------------------------------------------------------------------

  for file in "$HOME/.dotfiles/Nano/"*; do
    [[ -e "$file" ]] || continue

    safe_link \
      "$file" \
      "$HOME/.config/nano/$(basename "$file")"
  done

  safe_link \
    "$HOME/.dotfiles/Nano/Config/nanorc" \
    "$HOME/.nanorc"

  # ---------------------------------------------------------------------------
  # Script
  # ---------------------------------------------------------------------------

  safe_link \
    "$HOME/.dotfiles/Script" \
    "$HOME/.config/script"

  # ---------------------------------------------------------------------------
  # Fastfetch
  # ---------------------------------------------------------------------------

  safe_link \
    "$HOME/.dotfiles/Fastfetch/config.jsonc" \
    "$HOME/.config/fastfetch/config.jsonc"

  safe_link \
    "$HOME/.dotfiles/Fastfetch/motd-fastfetch.sh" \
    "$HOME/.config/fastfetch/motd-fastfetch.sh"

  for file in "$HOME/.dotfiles/Fastfetch/logo/"*-logo.png; do
    [[ -e "$file" ]] || continue

    safe_link \
      "$file" \
      "$HOME/.config/fastfetch/logo/$(basename "$file")"
  done

  # ---------------------------------------------------------------------------
  # iTerm2
  # ---------------------------------------------------------------------------

  for file in "$HOME/.dotfiles/Iterm2/bin/"*; do
    [[ -e "$file" ]] || continue

    safe_link \
      "$file" \
      "$HOME/.config/iterm2/bin/$(basename "$file")"
  done

  safe_link \
    "$HOME/.dotfiles/Iterm2/iterm2_shell_integration.zsh" \
    "$HOME/.config/iterm2/iterm2_shell_integration.zsh"

  log "[OK] Symlink konfigurasi berhasil dibuat."
}

# =============================================================================
# Configuration Menu
# =============================================================================

config_menu() {
  echo
  echo "============================================================================="
  echo " Konfigurasi Dotfiles"
  echo "============================================================================="
  echo
  echo "1. Copy konfigurasi"
  echo "2. Symlink konfigurasi"
  echo

  while true; do
    read -rp "Pilih [1/2]: " choice

    case "$choice" in
      1)
        copy_configs
        break
        ;;

      2)
        symlink_configs
        break
        ;;

      *)
        warn "Pilihan tidak valid. Masukkan 1 atau 2."
        ;;
    esac
  done
}

# =============================================================================
# Set Default Shell
# =============================================================================

set_shell() {
  require_command zsh

  local NEW

  NEW="$(which zsh)"

  if [[ "$SHELL" == "$NEW" ]]; then
    log "[SKIP] Default shell sudah menggunakan zsh: $NEW"
    return 0
  fi

  log "Mengubah default shell menjadi zsh..."

  if sudo -n true >/dev/null 2>&1; then
    sudo chsh -s "$NEW" "$USER"
  else
    chsh -s "$NEW"
  fi

  log "[OK] Default shell berhasil diubah ke zsh."
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
    err "[ERROR] Fastfetch tidak dapat dijalankan."
    return 1
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

  log "[OK] Setup selesai."
  log "Restart terminal atau jalankan: exec zsh"

  next_steps_menu
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
        log "Pilihan: Install Fail2Ban."
        log "Menjalankan 03-install-fail2ban.sh..."

        if bash "$INSTALL_DIR/03-install-fail2ban.sh"; then
          log "[OK] Install Fail2Ban selesai."
        else
          err "Install Fail2Ban gagal."
        fi
        ;;

      3)
        log "Pilihan: Hardening SSH."
        log "Menjalankan 05-harden-ssh.sh..."

        if bash "$INSTALL_DIR/05-harden-ssh.sh"; then
          log "[OK] Hardening SSH selesai."
        else
          err "Hardening SSH gagal."
        fi
        ;;

      4)
        log "Pilihan: Setup ZSH Root."
        log "Menjalankan 04-setup-zsh-root.sh..."

        if bash "$INSTALL_DIR/04-setup-zsh-root.sh"; then
          log "[OK] Setup ZSH Root selesai."
        else
          err "Setup ZSH Root gagal."
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
# Run
# =============================================================================
main "$@"