
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

  if [[ -z "$VERSION" ]]; then
    rm -rf "$API_DIR"
    err "Tidak dapat menentukan versi terbaru eza dari GitHub."
    return 1
  fi

  rm -rf "$API_DIR"

  log "Versi eza terbaru: $VERSION"

  # ---------------------------------------------------------------------------
  # Download eza
  # ---------------------------------------------------------------------------

  TARBALL="eza_${ARCH_DEB}.tar.gz"

  URL="https://github.com/eza-community/eza/releases/download/${VERSION}/${TARBALL}"

  TEMP_DIR="/tmp/eza-${VERSION}"

  rm -rf "$TEMP_DIR"
  mkdir -p "$TEMP_DIR"

  log "Mengunduh eza $VERSION..."
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

  # ---------------------------------------------------------------------------
  # Extract
  # ---------------------------------------------------------------------------

  log "Mengekstrak eza..."

  if ! tar -xzf "$TEMP_DIR/$TARBALL" -C "$TEMP_DIR"; then
    rm -rf "$TEMP_DIR"
    err "Gagal mengekstrak eza."
    return 1
  fi

  # ---------------------------------------------------------------------------
  # Validate binary
  # ---------------------------------------------------------------------------

  if [[ ! -f "$TEMP_DIR/eza" ]]; then
    rm -rf "$TEMP_DIR"
    err "Binary eza tidak ditemukan setelah ekstraksi."
    return 1
  fi

  # ---------------------------------------------------------------------------
  # Install binary
  # ---------------------------------------------------------------------------

  run_as_root install -d /usr/local/bin

  run_as_root install \
    -m755 \
    "$TEMP_DIR/eza" \
    /usr/local/bin/eza

  # ---------------------------------------------------------------------------
  # Cleanup
  # ---------------------------------------------------------------------------

  rm -rf "$TEMP_DIR"

  log "[OK] eza berhasil diinstall ke /usr/local/bin/eza."
}

# =============================================================================
# Install Glow
# =============================================================================

install_glow() {
  case "$OS_TYPE" in

    # -------------------------------------------------------------------------
    # Debian / Ubuntu / Raspbian
    # -------------------------------------------------------------------------

    linux)
      require_command apt-get
      require_command curl
      require_command gpg

      local KEYRING="/etc/apt/keyrings/charm.gpg"
      local SOURCES="/etc/apt/sources.list.d/charm.list"

      log "Menyiapkan repository Charm untuk glow..."

      run_as_root install -d -m0755 /etc/apt/keyrings

      if ! curl -fsSL \
          https://repo.charm.sh/apt/gpg.key |
          run_as_root gpg --dearmor --yes -o "$KEYRING"; then

        warn "Gagal menginstall GPG key repository Charm."
        return 0
      fi

      run_as_root chmod 0644 "$KEYRING"

      if ! run_as_root sh -c \
          "echo 'deb [signed-by=$KEYRING] https://repo.charm.sh/apt/ * *' > '$SOURCES'"; then

        warn "Gagal membuat repository Charm."
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

    # -------------------------------------------------------------------------
    # macOS
    # -------------------------------------------------------------------------

    macos)
      if ! command -v brew >/dev/null 2>&1; then
        warn "Homebrew tidak ditemukan. Glow dilewati."
        return 0
      fi

      if brew list --formula glow >/dev/null 2>&1; then
        log "[SKIP] Glow sudah terinstall."
      else
        if brew install glow; then
          log "[OK] Glow berhasil diinstall."
        else
          warn "Glow gagal diinstall. Melanjutkan."
        fi
      fi
      ;;

    # -------------------------------------------------------------------------
    # Arch
    # -------------------------------------------------------------------------

    arch)
      require_command pacman

      if run_as_root pacman -S --needed --noconfirm glow; then
        log "[OK] Glow berhasil diinstall."
      else
        warn "Glow gagal diinstall. Melanjutkan."
      fi
      ;;

    # -------------------------------------------------------------------------
    # Fedora
    # -------------------------------------------------------------------------

    fedora)
      require_command dnf

      if run_as_root dnf install -y glow; then
        log "[OK] Glow berhasil diinstall."
      else
        warn "Glow gagal diinstall. Melanjutkan."
      fi
      ;;

    # -------------------------------------------------------------------------
    # RHEL / CentOS / Rocky / AlmaLinux
    # -------------------------------------------------------------------------

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
      # Debian menyediakan executable dengan nama fdfind.
      # Path symlink dipertahankan.
      # -----------------------------------------------------------------------

      if [[ -x /usr/bin/fdfind ]]; then

        if [[ -L /usr/local/bin/fd || -e /usr/local/bin/fd ]]; then
          log "[SKIP] Symlink fd sudah tersedia."
        else
          run_as_root ln -s /usr/bin/fdfind /usr/local/bin/fd
          log "[OK] Symlink fd -> fdfind berhasil dibuat."
        fi

      else
        warn "[WARN] /usr/bin/fdfind tidak ditemukan."
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
        warn "[WARN] EPEL gagal diinstall. Melanjutkan."
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

      # -----------------------------------------------------------------------
      # Homebrew
      # -----------------------------------------------------------------------

      if ! command -v brew >/dev/null 2>&1; then

        while true; do
          echo
          read -rp "Homebrew belum terinstall. Install Homebrew? (y/n): " jawab

          case "$jawab" in
            y|Y)
              log "Menginstall Homebrew..."

              /bin/bash -c \
                "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

              # Cari brew setelah instalasi.
              if command -v brew >/dev/null 2>&1; then
                eval "$(brew shellenv)"

              elif [[ -x /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"

              elif [[ -x /usr/local/bin/brew ]]; then
                eval "$(/usr/local/bin/brew shellenv)"

              else
                err "Homebrew berhasil dijalankan tetapi binary brew tidak ditemukan."
                return 1
              fi

              break
              ;;

            n|N)
              warn "Melewati instalasi paket Homebrew."
              return 0
              ;;

            *)
              warn "Input tidak valid. Pilih y atau n."
              ;;
          esac
        done
      fi

      require_command brew

      log "Menginstall package macOS..."

      if brew install \
        zsh \
        git \
        curl \
        fzf \
        grc \
        gnupg \
        nano \
        lolcat \
        pv \
        bat \
        coreutils \
        w3m \
        zoxide \
        eza \
        fd \
        ffmpeg \
        sevenzip \
        rsync \
        jq \
        poppler \
        ripgrep \
        resvg \
        imagemagick \
        font-symbols-only-nerd-font \
        xclip; then

        log "[OK] Package macOS berhasil diproses."

      else
        err "Gagal menginstall package macOS."
        return 1
      fi

      ;;

    *)
      err "OS '$OS_TYPE' tidak didukung untuk instalasi package."
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
  local DOTFILES_DIR="$HOME/.dotfiles"

  if [[ -d "$DOTFILES_DIR" ]]; then
    log "[SKIP] $DOTFILES_DIR sudah ada."
    return 0
  fi

  require_command git

  log "Clone repository dotfiles..."

  if git clone \
      https://github.com/New8ie/Dotfiles.git \
      "$DOTFILES_DIR"; then

    log "[OK] Dotfiles berhasil di-clone ke $DOTFILES_DIR."

  else
    err "Gagal clone repository dotfiles."
    return 1
  fi
}

# =============================================================================
# Main
# =============================================================================

main() {
  detect_os
  detect_privilege
  install_packages
  clone_dotfiles

  local ZSH_SETUP="$HOME/.dotfiles/Install/02-setup-zsh.sh"

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
        if [[ ! -f "$ZSH_SETUP" ]]; then
          err "File tidak ditemukan: $ZSH_SETUP"
          return 1
        fi

        chmod +x "$ZSH_SETUP"

        log "Menjalankan 02-setup-zsh.sh..."

        bash "$ZSH_SETUP"

        log "[OK] Setup ZSH selesai."
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
                      