#!/usr/bin/env bash

# =============================================================================
# Dotfiles - Install Dependencies
#
# Usage:
#   bash 01-install-dependencies.sh
#   sudo bash 01-install-dependencies.sh
#
# Jika dijalankan dengan sudo:
#   - System package      -> root
#   - Homebrew            -> REAL_USER
#   - Git clone dotfiles  -> REAL_USER
#   - 02-setup-zsh.sh     -> REAL_USER
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
# Error Handler
# =============================================================================

trap 'rc=$?; err "Script berhenti pada line $LINENO dengan exit code $rc."' ERR

# =============================================================================
# Global Variables
# =============================================================================

OS_TYPE=""
ARCH_TYPE=""
SUDO=""
REAL_USER=""
REAL_HOME=""
DOTFILES_DIR=""
BREW_BIN=""

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
# Run Command as Root
# =============================================================================

run_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
    return
  fi

  if [[ -z "$SUDO" ]]; then
    err "Sudo belum tersedia."
    return 1
  fi

  "$SUDO" "$@"
}

# =============================================================================
# Run Command as Real User
#
# Tujuan:
#   Menjamin command user-level tidak berjalan sebagai root.
#
# Linux:
#   root -> runuser
#
# macOS:
#   root -> sudo -u REAL_USER -H
#
# User biasa:
#   langsung menjalankan command.
# =============================================================================

run_as_user() {
  if [[ -z "$REAL_USER" ]]; then
    err "REAL_USER belum ditentukan."
    return 1
  fi

  if [[ -z "$REAL_HOME" ]]; then
    err "REAL_HOME belum ditentukan."
    return 1
  fi

  if [[ "$REAL_USER" == "root" ]]; then
    err "Operasi user-level tidak boleh dijalankan sebagai root."
    return 1
  fi

  # ---------------------------------------------------------------------------
  # Script sudah berjalan sebagai user biasa
  # ---------------------------------------------------------------------------

  if [[ "$(id -u)" -ne 0 ]]; then
    "$@"
    return
  fi

  # ---------------------------------------------------------------------------
  # Linux
  # ---------------------------------------------------------------------------

  if [[ "$OS_TYPE" != "macos" ]] &&
     command -v runuser >/dev/null 2>&1; then

    runuser -u "$REAL_USER" -- env \
      HOME="$REAL_HOME" \
      USER="$REAL_USER" \
      LOGNAME="$REAL_USER" \
      "$@"

    return
  fi

  # ---------------------------------------------------------------------------
  # macOS / fallback
  # ---------------------------------------------------------------------------

  if command -v sudo >/dev/null 2>&1; then
    sudo -u "$REAL_USER" -H -- env \
      HOME="$REAL_HOME" \
      USER="$REAL_USER" \
      LOGNAME="$REAL_USER" \
      "$@"

    return
  fi

  err "Tidak dapat menjalankan command sebagai '$REAL_USER'."
  err "sudo tidak ditemukan."
  return 1
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
# Detect Real User
# =============================================================================

detect_real_user() {
  # ---------------------------------------------------------------------------
  # Jika script dijalankan melalui sudo:
  #
  #   sudo bash script.sh
  #
  # SUDO_USER berisi user asli.
  # ---------------------------------------------------------------------------

  if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    REAL_USER="$SUDO_USER"

  # ---------------------------------------------------------------------------
  # Jika script dijalankan tanpa sudo.
  # ---------------------------------------------------------------------------

  elif [[ "$(id -u)" -ne 0 ]]; then
    REAL_USER="$(id -un)"

  # ---------------------------------------------------------------------------
  # Root langsung tanpa SUDO_USER.
  #
  # Jangan menebak user karena dapat menyebabkan file dibuat pada account
  # yang salah.
  # ---------------------------------------------------------------------------

  else
    err "Tidak dapat menentukan user asli."
    err "Jika menggunakan root, jalankan melalui sudo dari user biasa."
    err "Contoh: sudo bash 01-install-dependencies.sh"
    return 1
  fi

  # ---------------------------------------------------------------------------
  # Cari home directory user.
  #
  # Linux:
  #   getent passwd
  #
  # macOS:
  #   dscl
  # ---------------------------------------------------------------------------

  REAL_HOME=""

  if command -v getent >/dev/null 2>&1; then
    REAL_HOME="$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6)"
  fi

  if [[ -z "$REAL_HOME" ]] &&
     command -v dscl >/dev/null 2>&1; then

    REAL_HOME="$(
      dscl . -read "/Users/$REAL_USER" NFSHomeDirectory 2>/dev/null |
        awk '{print $2}'
    )"
  fi

  # ---------------------------------------------------------------------------
  # Fallback hanya jika script bukan root.
  # ---------------------------------------------------------------------------

  if [[ -z "$REAL_HOME" ]] &&
     [[ "$(id -u)" -ne 0 ]]; then

    REAL_HOME="$HOME"
  fi

  if [[ -z "$REAL_HOME" ]]; then
    err "Home directory user '$REAL_USER' tidak dapat ditemukan."
    return 1
  fi

  # ---------------------------------------------------------------------------
  # Validasi home directory
  # ---------------------------------------------------------------------------

  if [[ ! -d "$REAL_HOME" ]]; then
    err "Home directory tidak ditemukan: $REAL_HOME"
    return 1
  fi

  DOTFILES_DIR="$REAL_HOME/.dotfiles"

  log "Real user : $REAL_USER"
  log "Real home : $REAL_HOME"
  log "Dotfiles  : $DOTFILES_DIR"
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
          OS_TYPE="linux"
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
      ARCH_TYPE="x86_64"
      ;;

    aarch64|arm64)
      ARCH_TYPE="aarch64"
      ;;

    armv7l|armv7)
      ARCH_TYPE="armv7l"
      ;;

    *)
      ARCH_TYPE="$(uname -m)"
      ;;
  esac

  log "Architecture: $ARCH_TYPE"
}

# =============================================================================
# Detect Privilege
# =============================================================================

detect_privilege() {
  if [[ "$(id -u)" -eq 0 ]]; then
    SUDO=""
    log "Script berjalan sebagai root."
    return 0
  fi

  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
    log "Menggunakan sudo untuk operasi privileged."
    return 0
  fi

  err "sudo tidak ditemukan dan script bukan root."
  return 1
}

# =============================================================================
# Detect Homebrew
# =============================================================================

detect_brew() {
  BREW_BIN=""

  # ---------------------------------------------------------------------------
  # PATH user
  # ---------------------------------------------------------------------------

  if [[ -x "$REAL_HOME/.linuxbrew/bin/brew" ]]; then
    BREW_BIN="$REAL_HOME/.linuxbrew/bin/brew"
    return 0
  fi

  # ---------------------------------------------------------------------------
  # Apple Silicon
  # ---------------------------------------------------------------------------

  if [[ -x /opt/homebrew/bin/brew ]]; then
    BREW_BIN="/opt/homebrew/bin/brew"
    return 0
  fi

  # ---------------------------------------------------------------------------
  # Intel macOS
  # ---------------------------------------------------------------------------

  if [[ -x /usr/local/bin/brew ]]; then
    BREW_BIN="/usr/local/bin/brew"
    return 0
  fi

  # ---------------------------------------------------------------------------
  # PATH aktif
  # ---------------------------------------------------------------------------

  if command -v brew >/dev/null 2>&1; then
    BREW_BIN="$(command -v brew)"
    return 0
  fi

  return 1
}

# =============================================================================
# Install eza - Linux
# =============================================================================

install_eza() {
  log "Menginstall eza dari GitHub releases resmi..."

  local ARCH_DEB
  local VERSION
  local TARBALL
  local URL
  local TEMP_DIR
  local API_DIR
  local API_FILE

  case "$ARCH_TYPE" in
    x86_64)
      ARCH_DEB="x86_64-unknown-linux-gnu"
      ;;

    aarch64)
      ARCH_DEB="aarch64-unknown-linux-gnu"
      ;;

    armv7l)
      ARCH_DEB="armv7-unknown-linux-gnueabihf"
      ;;

    *)
      err "Arsitektur '$ARCH_TYPE' tidak dikenali untuk eza."
      return 1
      ;;
  esac

  require_command curl
  require_command tar
  require_command grep
  require_command cut

  API_DIR="$(mktemp -d /tmp/eza-latest.XXXXXX)"
  API_FILE="$API_DIR/latest.json"

  log "Mendeteksi versi eza terbaru..."

  if ! curl -fsSL \
      --retry 3 \
      --retry-delay 2 \
      -o "$API_FILE" \
      "https://api.github.com/repos/eza-community/eza/releases/latest"; then

    rm -rf "$API_DIR"
    err "Gagal mengambil informasi release terbaru eza."
    return 1
  fi

  VERSION="$(grep -m1 '"tag_name":' "$API_FILE" | cut -d '"' -f4)"

  rm -rf "$API_DIR"

  if [[ -z "$VERSION" ]]; then
    err "Tidak dapat menentukan versi terbaru eza."
    return 1
  fi

  log "Versi eza terbaru: $VERSION"

  TARBALL="eza_${ARCH_DEB}.tar.gz"
  URL="https://github.com/eza-community/eza/releases/download/${VERSION}/${TARBALL}"
  TEMP_DIR="$(mktemp -d /tmp/eza.XXXXXX)"

  log "Mengunduh eza..."
  log "URL: $URL"

  if ! curl -fL \
      --retry 3 \
      --retry-delay 2 \
      "$URL" \
      -o "$TEMP_DIR/$TARBALL"; then

    rm -rf "$TEMP_DIR"
    err "Gagal mengunduh eza."
    return 1
  fi

  log "Mengekstrak eza..."

  if ! tar -xzf "$TEMP_DIR/$TARBALL" -C "$TEMP_DIR"; then
    rm -rf "$TEMP_DIR"
    err "Gagal mengekstrak eza."
    return 1
  fi

  if [[ ! -f "$TEMP_DIR/eza" ]]; then
    rm -rf "$TEMP_DIR"
    err "Binary eza tidak ditemukan setelah ekstraksi."
    return 1
  fi

  run_as_root install -d /usr/local/bin
  run_as_root install -m755 "$TEMP_DIR/eza" /usr/local/bin/eza

  rm -rf "$TEMP_DIR"

  log "[OK] eza berhasil diinstall ke /usr/local/bin/eza."
}

# =============================================================================
# Install Homebrew - macOS
# =============================================================================

install_homebrew_macos() {
  if detect_brew; then
    log "[SKIP] Homebrew sudah terinstall: $BREW_BIN"
    return 0
  fi

  require_command curl
  require_command mktemp

  local TEMP_INSTALLER

  TEMP_INSTALLER="$REAL_HOME/.homebrew-install-$$.sh"

  log "Homebrew belum ditemukan."
  log "Mengunduh installer Homebrew sebagai '$REAL_USER'..."

  # ---------------------------------------------------------------------------
  # Download installer sebagai REAL_USER.
  #
  # Jangan:
  #
  #   curl ... > /tmp/file
  #
  # sebagai root untuk kemudian menjalankannya sebagai user.
  #
  # Seluruh operasi Homebrew dilakukan sebagai user asli.
  # ---------------------------------------------------------------------------

  if ! run_as_user curl -fsSL \
      --retry 3 \
      --retry-delay 2 \
      "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" \
      -o "$TEMP_INSTALLER"; then

    rm -f "$TEMP_INSTALLER" 2>/dev/null || true

    err "Gagal mengunduh installer Homebrew."
    return 1
  fi

  run_as_user chmod 700 "$TEMP_INSTALLER"

  log "Menjalankan installer Homebrew sebagai '$REAL_USER'..."

  if ! run_as_user /bin/bash "$TEMP_INSTALLER"; then
    run_as_user rm -f "$TEMP_INSTALLER" 2>/dev/null || true

    err "Instalasi Homebrew gagal."
    return 1
  fi

  run_as_user rm -f "$TEMP_INSTALLER" 2>/dev/null || true

  # ---------------------------------------------------------------------------
  # Homebrew installer mungkin baru saja membuat brew.
  # ---------------------------------------------------------------------------

  if ! detect_brew; then
    err "Homebrew installer selesai tetapi brew tidak ditemukan."
    err "Path yang diperiksa:"
    err "  /opt/homebrew/bin/brew"
    err "  /usr/local/bin/brew"
    err "  $REAL_HOME/.linuxbrew/bin/brew"
    return 1
  fi

  log "[OK] Homebrew ditemukan: $BREW_BIN"
}

# =============================================================================
# Install macOS Packages
# =============================================================================

install_packages_macos() {
  install_homebrew_macos

  if [[ -z "$BREW_BIN" ]]; then
    if ! detect_brew; then
      warn "Homebrew tidak tersedia. Package macOS dilewati."
      return 0
    fi
  fi

  log "Homebrew: $BREW_BIN"
  log "User Homebrew: $REAL_USER"

  # ---------------------------------------------------------------------------
  # Pastikan Homebrew dapat dijalankan sebagai REAL_USER.
  # ---------------------------------------------------------------------------

  if ! run_as_user "$BREW_BIN" --version >/dev/null 2>&1; then
    err "Homebrew tidak dapat dijalankan sebagai '$REAL_USER'."
    return 1
  fi

  log "Mengupdate metadata Homebrew..."

  if ! run_as_user "$BREW_BIN" update; then
    warn "Homebrew update gagal. Melanjutkan."
  fi

  # ---------------------------------------------------------------------------
  # Formula
  #
  # Install satu per satu agar satu package yang gagal tidak membatalkan
  # seluruh instalasi.
  # ---------------------------------------------------------------------------

  local packages=(
    zsh
    git
    curl
    fzf
    grc
    gnupg
    nano
    lolcat
    pv
    bat
    coreutils
    w3m
    zoxide
    eza
    fd
    ffmpeg
    sevenzip
    rsync
    jq
    poppler
    ripgrep
    resvg
    imagemagick
  )

  local package

  for package in "${packages[@]}"; do
    if run_as_user "$BREW_BIN" list --formula "$package" >/dev/null 2>&1; then
      log "[SKIP] $package sudah terinstall."
      continue
    fi

    log "Menginstall $package..."

    if run_as_user "$BREW_BIN" install "$package"; then
      log "[OK] $package berhasil diinstall."
    else
      warn "$package gagal diinstall. Melanjutkan."
    fi
  done

  # ---------------------------------------------------------------------------
  # Nerd Font
  #
  # font-symbols-only-nerd-font adalah cask.
  # ---------------------------------------------------------------------------

  local FONT_CASK="font-symbols-only-nerd-font"

  if run_as_user "$BREW_BIN" list --cask "$FONT_CASK" >/dev/null 2>&1; then
    log "[SKIP] $FONT_CASK sudah terinstall."
  else
    log "Menginstall $FONT_CASK..."

    if run_as_user "$BREW_BIN" install --cask "$FONT_CASK"; then
      log "[OK] $FONT_CASK berhasil diinstall."
    else
      warn "$FONT_CASK gagal diinstall. Melanjutkan."
    fi
  fi

  log "[OK] Package macOS selesai diproses."
}

# =============================================================================
# Install Glow
# =============================================================================

install_glow() {
  case "$OS_TYPE" in

    # =========================================================================
    # Debian / Ubuntu / Raspbian
    # =========================================================================

    linux)
      require_command apt-get
      require_command curl
      require_command gpg

      local KEYRING="/etc/apt/keyrings/charm.gpg"
      local SOURCES="/etc/apt/sources.list.d/charm.list"
      local TEMP_KEY

      TEMP_KEY="$(mktemp /tmp/charm-gpg.XXXXXX)"

      log "Menyiapkan repository Charm untuk glow..."

      if ! curl -fsSL \
          "https://repo.charm.sh/apt/gpg.key" \
          -o "$TEMP_KEY"; then

        rm -f "$TEMP_KEY"
        warn "Gagal mengunduh GPG key Charm. Glow dilewati."
        return 0
      fi

      run_as_root install -d -m0755 /etc/apt/keyrings

      if ! run_as_root gpg \
          --dearmor \
          --yes \
          -o "$KEYRING" \
          "$TEMP_KEY"; then

        rm -f "$TEMP_KEY"
        warn "Gagal menginstall GPG key Charm. Glow dilewati."
        return 0
      fi

      rm -f "$TEMP_KEY"

      run_as_root chmod 0644 "$KEYRING"

      if ! run_as_root sh -c \
          "printf '%s\n' \
          'deb [signed-by=$KEYRING] https://repo.charm.sh/apt/ * *' \
          > '$SOURCES'"; then

        warn "Gagal membuat repository Charm. Glow dilewati."
        return 0
      fi

      if ! run_as_root apt-get update; then
        warn "Update repository Charm gagal. Glow dilewati."
        return 0
      fi

      if ! run_as_root apt-get install -y glow; then
        warn "Glow gagal diinstall. Melanjutkan."
        return 0
      fi

      log "[OK] Glow berhasil diinstall."
      ;;

    # =========================================================================
    # macOS
    # =========================================================================

    macos)
      if [[ -z "$BREW_BIN" ]]; then
        if ! detect_brew; then
          warn "Homebrew tidak ditemukan. Glow dilewati."
          return 0
        fi
      fi

      if run_as_user "$BREW_BIN" list --formula glow >/dev/null 2>&1; then
        log "[SKIP] Glow sudah terinstall."
      else
        log "Menginstall glow..."

        if run_as_user "$BREW_BIN" install glow; then
          log "[OK] Glow berhasil diinstall."
        else
          warn "Glow gagal diinstall. Melanjutkan."
        fi
      fi
      ;;

    # =========================================================================
    # Arch
    # =========================================================================

    arch)
      require_command pacman

      if run_as_root pacman -S --needed --noconfirm glow; then
        log "[OK] Glow berhasil diinstall."
      else
        warn "Glow gagal diinstall. Melanjutkan."
      fi
      ;;

    # =========================================================================
    # Fedora
    # =========================================================================

    fedora)
      require_command dnf

      if run_as_root dnf install -y glow; then
        log "[OK] Glow berhasil diinstall."
      else
        warn "Glow gagal diinstall. Melanjutkan."
      fi
      ;;

    # =========================================================================
    # RedHat
    # =========================================================================

    redhat)
      require_command yum

      if run_as_root yum install -y glow; then
        log "[OK] Glow berhasil diinstall."
      else
        warn "Glow gagal diinstall. Melanjutkan."
      fi
      ;;

    *)
      warn "OS '$OS_TYPE' tidak memiliki konfigurasi Glow."
      ;;
  esac
}

# =============================================================================
# Install Packages
# =============================================================================

install_packages() {
  log "Mulai proses instalasi paket..."

  case "$OS_TYPE" in

    # =========================================================================
    # Debian / Ubuntu / Raspbian
    # =========================================================================

    linux)
      require_command apt-get

      log "Update repository APT..."

      if ! run_as_root apt-get update; then
        err "Gagal melakukan apt update."
        return 1
      fi

      log "Menginstall package Linux..."

      if run_as_root apt-get install -y \
        zsh \
        git \
        curl \
        fzf \
        grc \
        gnupg \
        lolcat \
        pv \
        bat \
        rsync \
        nano \
        coreutils \
        sudo \
        w3m \
        fd-find \
        zoxide \
        net-tools \
        xclip \
        iproute2; then

        log "[OK] Package Linux berhasil diproses."
      else
        err "Gagal menginstall package Linux."
        return 1
      fi

      # -----------------------------------------------------------------------
      # fd
      # -----------------------------------------------------------------------

      if [[ -x /usr/bin/fdfind ]]; then
        if [[ -L /usr/local/bin/fd || -e /usr/local/bin/fd ]]; then
          log "[SKIP] Symlink fd sudah tersedia."
        else
          run_as_root install -d /usr/local/bin
          run_as_root ln -s /usr/bin/fdfind /usr/local/bin/fd
          log "[OK] Symlink fd -> fdfind berhasil dibuat."
        fi
      else
        warn "/usr/bin/fdfind tidak ditemukan."
      fi

      # -----------------------------------------------------------------------
      # eza
      # -----------------------------------------------------------------------

      if ! command -v eza >/dev/null 2>&1; then
        detect_arch
        install_eza
      else
        log "[SKIP] eza sudah terinstall."
      fi
      ;;

    # =========================================================================
    # RedHat / CentOS / Rocky / AlmaLinux
    # =========================================================================

    redhat)
      require_command yum

      log "Menginstall EPEL..."

      if ! run_as_root yum install -y epel-release; then
        warn "EPEL gagal diinstall. Melanjutkan."
      fi

      if run_as_root yum install -y \
        zsh \
        git \
        curl \
        fzf \
        nano \
        grc \
        gnupg2 \
        lolcat \
        pv \
        bat \
        sudo \
        coreutils \
        w3m \
        zoxide \
        fd-find \
        net-tools \
        iproute2 \
        rsync; then

        log "[OK] Package RedHat berhasil diproses."
      else
        err "Gagal menginstall package RedHat."
        return 1
      fi
      ;;

    # =========================================================================
    # Fedora
    # =========================================================================

    fedora)
      require_command dnf

      log "Menginstall package Fedora..."

      if run_as_root dnf install -y \
        zsh \
        git \
        curl \
        fzf \
        nano \
        grc \
        gnupg2 \
        lolcat \
        pv \
        bat \
        sudo \
        coreutils \
        w3m \
        zoxide \
        fd-find \
        net-tools \
        iproute \
        rsync; then

        log "[OK] Package Fedora berhasil diproses."
      else
        err "Gagal menginstall package Fedora."
        return 1
      fi
      ;;

    # =========================================================================
    # Arch
    # =========================================================================

    arch)
      require_command pacman

      log "Menginstall package Arch Linux..."

      if run_as_root pacman -Syu --needed --noconfirm \
        zsh \
        git \
        curl \
        fzf \
        grc \
        gnupg \
        lolcat \
        pv \
        bat \
        rsync \
        nano \
        coreutils \
        sudo \
        w3m \
        fd \
        zoxide \
        net-tools \
        xclip \
        iproute2; then

        log "[OK] Package Arch berhasil diproses."
      else
        err "Gagal menginstall package Arch."
        return 1
      fi
      ;;

    # =========================================================================
    # macOS
    # =========================================================================

    macos)
      install_packages_macos
      ;;

    *)
      err "OS '$OS_TYPE' tidak didukung."
      return 1
      ;;
  esac

  # ===========================================================================
  # Glow
  # ===========================================================================

  install_glow
}

# =============================================================================
# Clone Dotfiles
# =============================================================================

clone_dotfiles() {
  # ---------------------------------------------------------------------------
  # Jangan pernah clone ke /root/.dotfiles hanya karena script menggunakan sudo.
  # ---------------------------------------------------------------------------

  if [[ -d "$DOTFILES_DIR" ]]; then
    log "[SKIP] $DOTFILES_DIR sudah ada."
    return 0
  fi

  require_command git

  log "Clone repository dotfiles sebagai '$REAL_USER'..."
  log "Destination: $DOTFILES_DIR"

  run_as_user git clone \
    "https://github.com/New8ie/Dotfiles.git" \
    "$DOTFILES_DIR"

  # ---------------------------------------------------------------------------
  # Validasi directory berhasil dibuat.
  # ---------------------------------------------------------------------------

  if [[ ! -d "$DOTFILES_DIR" ]]; then
    err "Directory dotfiles tidak ditemukan setelah clone."
    return 1
  fi

  # ---------------------------------------------------------------------------
  # Jika root menjalankan script, pastikan repository baru tidak salah owner.
  #
  # Ini hanya dilakukan setelah clone baru.
  # Repository yang sudah ada TIDAK disentuh.
  # ---------------------------------------------------------------------------

  if [[ "$(id -u)" -eq 0 ]]; then
    run_as_root chown -R "$REAL_USER" "$DOTFILES_DIR"
  fi

  log "[OK] Dotfiles berhasil di-clone ke $DOTFILES_DIR."
}

# =============================================================================
# Run 02 as Real User
# =============================================================================

run_zsh_setup() {
  local ZSH_SETUP="$DOTFILES_DIR/Install/02-setup-zsh.sh"

  # ---------------------------------------------------------------------------
  # Validasi file
  # ---------------------------------------------------------------------------

  if [[ ! -f "$ZSH_SETUP" ]]; then
    err "File tidak ditemukan:"
    err "$ZSH_SETUP"
    return 1
  fi

  if [[ "$REAL_USER" == "root" ]]; then
    err "02-setup-zsh.sh tidak boleh dijalankan sebagai root."
    return 1
  fi

  log "Menjalankan 02-setup-zsh.sh sebagai '$REAL_USER'..."

  # ---------------------------------------------------------------------------
  # chmod sebagai user asli
  # ---------------------------------------------------------------------------

  run_as_user chmod +x "$ZSH_SETUP"

  # ---------------------------------------------------------------------------
  # Jalankan 02 sebagai user asli.
  #
  # macOS:
  #   sudo -u REAL_USER -H
  #
  # Linux root:
  #   runuser
  # ---------------------------------------------------------------------------

  run_as_user bash "$ZSH_SETUP"

  log "[OK] Setup ZSH selesai."
}

# =============================================================================
# Main
# =============================================================================

main() {
  detect_os
  detect_arch
  detect_privilege
  detect_real_user

  echo
  log "============================================================================="
  log " Environment"
  log "============================================================================="
  log "OS         : $OS_TYPE"
  log "Architecture: $ARCH_TYPE"
  log "Real user  : $REAL_USER"
  log "Real home  : $REAL_HOME"
  log "Dotfiles   : $DOTFILES_DIR"

  if [[ "$(id -u)" -eq 0 ]]; then
    log "Execution  : root + user-level delegation"
  else
    log "Execution  : user + sudo delegation"
  fi

  echo

  # ---------------------------------------------------------------------------
  # Install dependencies
  # ---------------------------------------------------------------------------

  install_packages

  # ---------------------------------------------------------------------------
  # Clone dotfiles sebagai REAL_USER
  # ---------------------------------------------------------------------------

  clone_dotfiles

  # ---------------------------------------------------------------------------
  # Menu
  # ---------------------------------------------------------------------------

  echo
  echo "============================================================================="
  echo " Dotfiles Installation"
  echo "============================================================================="
  echo
  echo "1. Jalankan 02-setup-zsh.sh"
  echo "2. Lewati setup ZSH"
  echo

  while true; do
    read -rp "Pilih [1/2]: " choice

    case "$choice" in
      1)
        run_zsh_setup
        break
        ;;

      2)
        log "[SKIP] Setup ZSH dilewati."
        break
        ;;

      *)
        warn "Pilihan tidak valid. Masukkan 1 atau 2."
        ;;
    esac
  done

  echo

  log "============================================================================="
  log " Instalasi dependency selesai."
  log "============================================================================="
}

# =============================================================================
# Run
# =============================================================================

main "$@"

