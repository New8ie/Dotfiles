#!/usr/bin/env bash

# =============================================================================
# Dotfiles - Install Dependencies
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
  else
    "$SUDO" "$@"
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

  # ---------------------------------------------------------------------------
  # Ambil versi terbaru dari GitHub API
  #
  # Tidak menggunakan:
  #
  # curl ... | grep ... | cut ...
  #
  # karena script menggunakan pipefail.
  # ---------------------------------------------------------------------------

  API_DIR="/tmp/eza-latest"
  API_FILE="$API_DIR/latest.json"

  rm -rf "$API_DIR"
  mkdir -p "$API_DIR"

  log "Mendeteksi versi eza terbaru..."

  if ! curl -fsSL \
    --retry 3 \
    --retry-delay 2 \
    -o "$API_FILE" \
    "https://api.github.com/repos/eza-community/eza/releases/latest"; then

    rm -rf "$API_DIR"
    err "Gagal mengambil informasi release terbaru eza dari GitHub."
    return 1
  fi

  VERSION="$(grep -m1 '"tag_name":' "$API_FILE" | cut -d '"' -f4)"
