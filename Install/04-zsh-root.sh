#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Auto elevate jika bukan root
# =============================================================================
if [[ $EUID -ne 0 ]]; then
   echo "⚠️  Script butuh akses root, mencoba sudo..."
   exec sudo bash "$0" "$@"
fi

# =============================================================================
# Logging Helpers
# =============================================================================
log()  { echo -e "\033[1;32m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[ERROR]\033[0m $*"; exit 1; }

# =============================================================================
# Deteksi OS / Distro (untuk kompatibilitas jika butuh zsh)
# =============================================================================
OS_TYPE=$(uname -s)
DISTRO="unknown"

case "$OS_TYPE" in
    Linux)
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
        fi
        ;;
    Darwin)
        DISTRO="macOS"
        ;;
esac

log "OS / Distro terdeteksi: $OS_TYPE / $DISTRO"

# Pastikan Zsh terinstall
if ! command -v zsh >/dev/null 2>&1; then
    warn "Zsh tidak ditemukan. Script akan menginstall Zsh..."

    case "$DISTRO" in
        ubuntu|debian)
            apt update -y
            apt install -y zsh
            ;;
        fedora)
            dnf install -y zsh
            ;;
        arch|manjaro)
            pacman -Syu --noconfirm zsh
            ;;
        macOS)
            brew install zsh
            ;;
        *)
            err "Distro tidak dikenali dan Zsh tidak dapat diinstall otomatis"
            ;;
    esac
fi

# =============================================================================
# Lokasi dotfiles
# =============================================================================
if [ -n "${SUDO_USER-}" ] && [ "$SUDO_USER" != "root" ]; then
    USER_HOME="/home/$SUDO_USER"
else
    USER_HOME="$HOME"
fi

DOTFILES_DIR="$USER_HOME/.dotfiles"
ROOT_HOME="/root"

log "Dotfiles user: $DOTFILES_DIR"
log "Home user: $USER_HOME"

# =============================================================================
# Backup Dotfiles
# =============================================================================
BACKUP_DIR="$USER_HOME/dotfiles-backup"
BACKUP_FILE="$BACKUP_DIR/dotfiles-$(date +%Y%m%d-%H%M).tar.gz"

log "Membuat folder backup..."
mkdir -p "$BACKUP_DIR"

log "Backup konfigurasi ke $BACKUP_FILE..."
tar -czf "$BACKUP_FILE" \
    "$USER_HOME/.oh-my-zsh" \
    "$USER_HOME/.config" \
    "$USER_HOME/.zshrc" \
    "$USER_HOME/.nanorc" \
    "$USER_HOME/.p10k.zsh" \
    "$USER_HOME/.zprofile" \
    2>/dev/null || true

# =============================================================================
# Copy & Symlink
# =============================================================================
log "Replace /root/.oh-my-zsh dengan milik user..."
rm -rf "$ROOT_HOME/.oh-my-zsh"
cp -r "$USER_HOME/.oh-my-zsh" "$ROOT_HOME/.oh-my-zsh"

log "Replace /root/.config dengan symlink..."
rm -rf "$ROOT_HOME/.config"
ln -s "$USER_HOME/.config" "$ROOT_HOME/.config"

FILES=(
    ".zshrc"
    ".nanorc"
    ".p10k.zsh"
    ".zprofile"
)

log "Symlink file konfigurasi ke /root..."
for file in "${FILES[@]}"; do
    if [ -f "$USER_HOME/$file" ]; then
        rm -f "$ROOT_HOME/$file"
        ln -s "$USER_HOME/$file" "$ROOT_HOME/$file"
        log " → $file disymlink"
    else
        warn "Lewat: $file tidak ditemukan"
    fi
done

# =============================================================================
# Ubah Shell Root ke Zsh
# =============================================================================
log "Mengubah shell root ke Zsh..."

ZSH_BIN="$(command -v zsh || true)"

if [[ -z "$ZSH_BIN" ]]; then
    err "Zsh binary tidak ditemukan padahal instalasi dilakukan."
fi

# Pastikan zsh ada di /etc/shells
if ! grep -q "$ZSH_BIN" /etc/shells 2>/dev/null; then
    log "Menambahkan $ZSH_BIN ke /etc/shells..."
    echo "$ZSH_BIN" >> /etc/shells
fi

chsh -s "$ZSH_BIN" root
log "Shell root berhasil diubah ke: $ZSH_BIN"

# =============================================================================
# Selesai
# =============================================================================
echo
log "✅ Konfigurasi Zsh untuk root selesai!"
echo "   Logout & login ulang agar shell baru aktif."
echo "   Root kini memakai konfigurasi Zsh dari $USER_HOME."
