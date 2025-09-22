#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Auto elevate jika bukan root (macOS menggunakan sudo juga)
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
# Deteksi OS / Distro & Package Manager
# =============================================================================
OS_TYPE=$(uname -s)

case "$OS_TYPE" in
    Linux)
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
        else
            err "Tidak dapat mendeteksi distribusi Linux"
        fi

        case "$DISTRO" in
            ubuntu|debian)
                PM_UPDATE="apt update -y && apt upgrade -y"
                PM_INSTALL="apt install -y"
                ;;
            fedora)
                PM_UPDATE="dnf upgrade -y"
                PM_INSTALL="dnf install -y"
                ;;
            centos|rhel)
                PM_UPDATE="yum update -y"
                PM_INSTALL="yum install -y"
                ;;
            arch|manjaro)
                PM_UPDATE="pacman -Syu --noconfirm"
                PM_INSTALL="pacman -S --noconfirm"
                ;;
            *)
                err "Distribusi $DISTRO belum didukung otomatis"
                ;;
        esac
        ;;
    Darwin)
        PM_UPDATE="brew update && brew upgrade"
        PM_INSTALL="brew install"
        ;;
    *)
        err "OS $OS_TYPE belum didukung"
        ;;
esac

log "OS / Distro terdeteksi: $OS_TYPE / ${DISTRO:-macOS}"

# =============================================================================
# Update & Install Dependencies
# =============================================================================
log "Update repository..."
eval "$PM_UPDATE"

log "Install Fail2ban, curl, iptables, jq..."
case "$OS_TYPE" in
    Darwin)
        eval "$PM_INSTALL bash curl jq"  # iptables tidak ada di macOS
        ;;
    *)
        eval "$PM_INSTALL fail2ban curl iptables jq"
        ;;
esac

# =============================================================================
# Tentukan lokasi dotfiles
# =============================================================================
if [ -n "${SUDO_USER-}" ] && [ "$SUDO_USER" != "root" ]; then
    DOTFILES_DIR="/home/$SUDO_USER/.dotfiles"
else
    DOTFILES_DIR="$HOME/.dotfiles"
fi

# =============================================================================
# Install & Konfigurasi Fail2Ban Actions
# =============================================================================
log "Copy action telegram.conf..."
cp -f "$DOTFILES_DIR/Fail2Ban/Telegram.conf" /etc/fail2ban/action.d/telegram.conf

log "Buat folder script jika belum ada..."
mkdir -p /etc/fail2ban/scripts

log "Copy script send_telegram_notif.sh..."
cp -f "$DOTFILES_DIR/Fail2Ban/send_telegram_notif.sh" /etc/fail2ban/scripts/send_telegram_notif.sh
chmod +x /etc/fail2ban/scripts/send_telegram_notif.sh

log "Copy action Cloudflare..."
cp -f "$DOTFILES_DIR/Fail2Ban/Cloudflare.conf" /etc/fail2ban/action.d/cloudflare-logging.conf
touch /var/log/fail2ban-cloudflare.log
chown root:root /var/log/fail2ban-cloudflare.log || true
chmod 640 /var/log/fail2ban-cloudflare.log

log "Copy action iptables-custom..."
cp -f "$DOTFILES_DIR/Fail2Ban/Iptables.conf" /etc/fail2ban/action.d/iptables-custom.conf
touch /var/log/fail2ban-iptables.log
chown root:root /var/log/fail2ban-iptables.log || true
chmod 640 /var/log/fail2ban-iptables.log

# =============================================================================
# Install & Konfigurasi Fail2Ban Filters
# =============================================================================
log "Copy Filter Guacamole..."
cp -f "$DOTFILES_DIR/Fail2Ban/Guacamole.conf" /etc/fail2ban/filter.d/guacamole.conf

log "Copy Filter Nextcloud..."
cp -f "$DOTFILES_DIR/Fail2Ban/Nextcloud.conf" /etc/fail2ban/filter.d/nextcloud.conf

log "Copy Filter Immich..."
cp -f "$DOTFILES_DIR/Fail2Ban/Immich.conf" /etc/fail2ban/filter.d/immich.conf

log "Buat konfigurasi jail.local..."
cp -f "$DOTFILES_DIR/Fail2Ban/Jail.conf" /etc/fail2ban/jail.local

# =============================================================================
# Enable & Restart Fail2Ban
# =============================================================================
if command -v systemctl &>/dev/null; then
    log "Enable & Restart Fail2ban..."
    if systemctl is-enabled fail2ban &>/dev/null; then
        systemctl restart fail2ban
    else
        systemctl enable fail2ban
        systemctl start fail2ban
    fi
else
    log "Systemctl tidak tersedia, jalankan Fail2Ban manual: fail2ban-client start"
fi

log "Status Fail2ban:"
if command -v systemctl &>/dev/null; then
    systemctl status fail2ban --no-pager || true
fi

echo
log "✅ Fail2ban + Telegram berhasil terinstal & dikonfigurasi!"
echo "   Cek status dengan: fail2ban-client status"
echo "   Rubah Cloudflare Token (cftoken) & Cloudflare Userid (cfuser)."
