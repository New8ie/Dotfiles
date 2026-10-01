#!/usr/bin/env bash

set -euo pipefail

# =============================================================================

# Logging Helpers

# =============================================================================

log() {
local message="$*"


case "$message" in
    "[OK]"*)
        echo -e "\033[1;32m${message}\033[0m"
        ;;
    "[SKIP]"*)
        echo -e "\033[1;33m${message}\033[0m"
        ;;
    *)
        echo -e "\033[1;36m[INFO]\033[0m ${message}"
        ;;
esac


}

warn() {
local message="$*"


case "$message" in
    "[WARN]"*)
        echo -e "\033[1;33m${message}\033[0m"
        ;;
    *)
        echo -e "\033[1;33m[WARN]\033[0m ${message}"
        ;;
esac


}

err() {
local message="$*"


case "$message" in
    "[ERROR]"*)
        echo -e "\033[1;31m${message}\033[0m"
        ;;
    *)
        echo -e "\033[1;31m[ERROR]\033[0m ${message}"
        ;;
esac

exit 1


}

# =============================================================================

# Auto elevate jika bukan root

# =============================================================================

if [[ $EUID -ne 0 ]]; then
echo -e "\033[1;33m[WARN]\033[0m Script membutuhkan akses root, mencoba sudo..."


if ! command -v sudo >/dev/null 2>&1; then
    err "sudo tidak ditemukan. Jalankan script sebagai root atau install sudo."
fi

exec sudo -E bash "$0" "$@"


fi

# =============================================================================

# Deteksi OS / Distro & Package Manager

# =============================================================================

OS_TYPE="$(uname -s)"
DISTRO=""

case "$OS_TYPE" in


Linux)

    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO="${ID:-unknown}"
    else
        err "Tidak dapat mendeteksi distribusi Linux."
    fi

    case "$DISTRO" in

        ubuntu|debian)
            PM_UPDATE=(apt-get update)
            PM_INSTALL=(apt-get install -y)
            ;;

        fedora)
            PM_UPDATE=(dnf upgrade -y)
            PM_INSTALL=(dnf install -y)
            ;;

        centos|rhel)
            PM_UPDATE=(yum update -y)
            PM_INSTALL=(yum install -y)
            ;;

        arch|manjaro)
            PM_UPDATE=(pacman -Syu --noconfirm)
            PM_INSTALL=(pacman -S --noconfirm)
            ;;

        *)
            err "Distribusi '$DISTRO' belum didukung otomatis."
            ;;

    esac
    ;;

Darwin)
    err "Script Fail2Ban ini menggunakan konfigurasi Linux (/etc/fail2ban, systemctl, iptables) dan tidak dapat dijalankan di macOS."
    ;;

*)
    err "OS '$OS_TYPE' belum didukung."
    ;;


esac

log "OS / Distro terdeteksi: $OS_TYPE / $DISTRO"

# =============================================================================

# Validasi Package Manager

# =============================================================================

if ! command -v "${PM_UPDATE[0]}" >/dev/null 2>&1; then
err "Package manager '${PM_UPDATE[0]}' tidak ditemukan."
fi

if ! command -v "${PM_INSTALL[0]}" >/dev/null 2>&1; then
err "Package manager '${PM_INSTALL[0]}' tidak ditemukan."
fi

# =============================================================================

# Tentukan user asli jika script dijalankan melalui sudo

# =============================================================================

if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
REAL_USER="$SUDO_USER"


if command -v getent >/dev/null 2>&1; then
    REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
else
    REAL_HOME="/home/$REAL_USER"
fi

if [[ -z "${REAL_HOME:-}" ]]; then
    REAL_HOME="/home/$REAL_USER"
fi


else
REAL_USER="$(id -un)"
REAL_HOME="$HOME"
fi

# =============================================================================

# Tentukan lokasi dotfiles

# =============================================================================

DOTFILES_DIR="$REAL_HOME/.dotfiles"

if [[ ! -d "$DOTFILES_DIR" ]]; then
err "Direktori dotfiles tidak ditemukan: $DOTFILES_DIR"
fi

log "Dotfiles: $DOTFILES_DIR"

# =============================================================================

# Update Repository

# =============================================================================

log "Update repository package..."

if "${PM_UPDATE[@]}"; then
log "[OK] Repository package berhasil diperbarui."
else
err "Gagal melakukan update repository package."
fi

# =============================================================================

# Install Dependencies

# =============================================================================

log "Memeriksa dependency Fail2Ban..."

PACKAGES=(
fail2ban
curl
iptables
jq
)

MISSING_PACKAGES=()

for package in "${PACKAGES[@]}"; do
case "$package" in
fail2ban)
command -v fail2ban-client >/dev/null 2>&1 || MISSING_PACKAGES+=("$package")
;;
curl|jq|iptables)
command -v "$package" >/dev/null 2>&1 || MISSING_PACKAGES+=("$package")
;;
esac
done

if [[ ${#MISSING_PACKAGES[@]} -eq 0 ]]; then
log "[SKIP] Semua dependency sudah terinstall."
else
log "Menginstall dependency: ${MISSING_PACKAGES[*]}"


if "${PM_INSTALL[@]}" "${MISSING_PACKAGES[@]}"; then
    log "[OK] Dependency berhasil diinstall."
else
    err "Gagal menginstall dependency: ${MISSING_PACKAGES[*]}"
fi


fi

# =============================================================================

# Validasi Dependency Setelah Instalasi

# =============================================================================

REQUIRED_COMMANDS=(
fail2ban-client
curl
iptables
jq
)

for command_name in "${REQUIRED_COMMANDS[@]}"; do
if ! command -v "$command_name" >/dev/null 2>&1; then
err "Command '$command_name' tidak tersedia setelah proses instalasi."
fi
done

log "[OK] Semua dependency tersedia."

# =============================================================================

# Validasi Source Configuration

# =============================================================================

FAIL2BAN_SOURCE_DIR="$DOTFILES_DIR/Fail2Ban"

if [[ ! -d "$FAIL2BAN_SOURCE_DIR" ]]; then
err "Direktori konfigurasi Fail2Ban tidak ditemukan: $FAIL2BAN_SOURCE_DIR"
fi

SOURCE_FILES=(
"$FAIL2BAN_SOURCE_DIR/Telegram.conf"
"$FAIL2BAN_SOURCE_DIR/send_telegram_notif.sh"
"$FAIL2BAN_SOURCE_DIR/Cloudflare.conf"
"$FAIL2BAN_SOURCE_DIR/Iptables.conf"
"$FAIL2BAN_SOURCE_DIR/Guacamole.conf"
"$FAIL2BAN_SOURCE_DIR/Nextcloud.conf"
"$FAIL2BAN_SOURCE_DIR/Immich.conf"
"$FAIL2BAN_SOURCE_DIR/Jail.conf"
)

for source_file in "${SOURCE_FILES[@]}"; do
if [[ ! -f "$source_file" ]]; then
err "File konfigurasi tidak ditemukan: $source_file"
fi
done

log "[OK] Semua file konfigurasi Fail2Ban ditemukan."

# =============================================================================

# Pastikan Directory Fail2Ban tersedia

# =============================================================================

mkdir -p /etc/fail2ban/action.d
mkdir -p /etc/fail2ban/filter.d
mkdir -p /etc/fail2ban/scripts

# =============================================================================

# Install & Konfigurasi Fail2Ban Actions

# =============================================================================

log "Copy action telegram.conf..."

cp -f "$DOTFILES_DIR/Fail2Ban/Telegram.conf" /etc/fail2ban/action.d/telegram.conf

log "[OK] telegram.conf terpasang."

log "Copy script send_telegram_notif.sh..."

cp -f "$DOTFILES_DIR/Fail2Ban/send_telegram_notif.sh" /etc/fail2ban/scripts/send_telegram_notif.sh

chmod +x /etc/fail2ban/scripts/send_telegram_notif.sh

log "[OK] send_telegram_notif.sh terpasang."

log "Copy action Cloudflare..."


cp -f "$DOTFILES_DIR/Fail2Ban/Cloudflare.conf" /etc/fail2ban/action.d/cloudflare-logging.conf

touch /var/log/fail2ban-cloudflare.log

chown root:root /var/log/fail2ban-cloudflare.log
chmod 640 /var/log/fail2ban-cloudflare.log

log "[OK] Cloudflare action terpasang."

log "Copy action iptables-custom..."


cp -f "$DOTFILES_DIR/Fail2Ban/Iptables.conf" /etc/fail2ban/action.d/iptables-custom.conf

touch /var/log/fail2ban-iptables.log

chown root:root /var/log/fail2ban-iptables.log
chmod 640 /var/log/fail2ban-iptables.log

log "[OK] iptables-custom action terpasang."

# =============================================================================

# Install & Konfigurasi Fail2Ban Filters

# =============================================================================

log "Copy Filter Guacamole..."

cp -f "$DOTFILES_DIR/Fail2Ban/Guacamole.conf" /etc/fail2ban/filter.d/guacamole.conf

log "[OK] Guacamole filter terpasang."

log "Copy Filter Nextcloud..."

cp -f "$DOTFILES_DIR/Fail2Ban/Nextcloud.conf" /etc/fail2ban/filter.d/nextcloud.conf

log "[OK] Nextcloud filter terpasang."

log "Copy Filter Immich..."

cp -f "$DOTFILES_DIR/Fail2Ban/Immich.conf" /etc/fail2ban/filter.d/immich.conf

log "[OK] Immich filter terpasang."

# =============================================================================

# Jail Configuration

# =============================================================================

log "Copy jail.local..."

cp -f "$DOTFILES_DIR/Fail2Ban/Jail.conf" /etc/fail2ban/jail.local

log "[OK] jail.local terpasang."

# =============================================================================

# Validasi Konfigurasi Fail2Ban

# =============================================================================

log "Validasi konfigurasi Fail2Ban..."

if fail2ban-client -t; then
log "[OK] Konfigurasi Fail2Ban valid."
else
err "Konfigurasi Fail2Ban tidak valid. Service tidak akan direstart."
fi

# =============================================================================

# Enable & Restart Fail2Ban

# =============================================================================

if command -v systemctl >/dev/null 2>&1; then


log "Enable & Restart Fail2Ban..."

if systemctl enable fail2ban >/dev/null 2>&1; then
    log "[OK] Fail2Ban berhasil di-enable."
else
    err "Gagal enable service Fail2Ban."
fi

if systemctl restart fail2ban; then
    log "[OK] Fail2Ban berhasil direstart."
else
    err "Gagal restart Fail2Ban."
fi


else


warn "[WARN] systemctl tidak tersedia."
warn "[WARN] Jalankan Fail2Ban manual: fail2ban-client start"


fi

# =============================================================================

# Verifikasi Service

# =============================================================================

if command -v systemctl >/dev/null 2>&1; then


if systemctl is-active --quiet fail2ban; then
    log "[OK] Service Fail2Ban aktif."
else
    warn "[WARN] Service Fail2Ban tidak aktif."
    systemctl status fail2ban --no-pager || true
    exit 1
fi


fi

# =============================================================================

# Status Fail2Ban

# =============================================================================

log "Status Fail2Ban:"

# =============================================================================
# Verify Fail2Ban Client
# =============================================================================

log "Memverifikasi Fail2Ban..."

FAIL2BAN_READY=false

for attempt in {1..10}; do
  if fail2ban-client ping >/dev/null 2>&1; then
    FAIL2BAN_READY=true
    break
  fi

  sleep 1
done

if [[ "$FAIL2BAN_READY" != true ]]; then
  err "Fail2Ban service aktif tetapi fail2ban-client tidak dapat terhubung."
fi

if fail2ban-client status >/dev/null 2>&1; then
  log "[OK] Fail2Ban berhasil terinstal & dikonfigurasi."
  echo "   Cek status jail dengan: fail2ban-client status"
  echo "   Rubah Cloudflare Token (cftoken) & Cloudflare Userid (cfuser)."
else
  err "Fail2Ban aktif tetapi status jail tidak dapat dibaca."
fi

