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
# Install & Konfigurasi Fail2ban
# =============================================================================
log "Update repository..."

# Tentukan lokasi dotfiles yang benar
if [ -n "${SUDO_USER-}" ] && [ "$SUDO_USER" != "root" ]; then
  DOTFILES_DIR="/home/$SUDO_USER/.dotfiles"
else
  DOTFILES_DIR="$HOME/.dotfiles"
fi

log "Copy action telegram.conf..."
cp -f "$DOTFILES_DIR/Fail2Ban/Telegram.conf" /etc/fail2ban/action.d/telegram.conf


apt update -y && apt upgrade -y

log "Install Fail2ban & curl..."
apt install -y fail2ban curl

log "Backup konfigurasi default..."
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf.bak.$(date +%Y%m%d)

# =============================================================================
# Install & Konfigurasi Fail2ban Action
# =============================================================================


log "Copy action telegram.conf..."
cp -f "$DOTFILES_DIR/Fail2Ban/Telegram.conf" /etc/fail2ban/action.d/telegram.conf

log "Buat folder script jika belum ada..."
mkdir -p /etc/fail2ban/script

log "Copy script telegram_notif..."
cp -f "$DOTFILES_DIR/Fail2Ban/send_telegram_notif.sh" /etc/fail2ban/script/send_telegram_notif.sh
chmod +x /etc/fail2ban/script/send_telegram_notif.sh


log "Copy action Cloudflare..."
cp -f "$DOTFILES_DIR/Fail2Ban/Cloudflare.conf" /etc/fail2ban/action.d/cloudflare-logging.conf
touch /var/log/fail2ban-cloudflare.log
chown root:root /var/log/fail2ban-cloudflare.log
chmod 640 /var/log/fail2ban-cloudflare.log

log "Copy action iptables-custom-logging-ipv6..."
cp -f "$DOTFILES_DIR/Fail2Ban/Iptables-custom-logging-ipv6.conf" /etc/fail2ban/action.d/iptables-custom-logging-ipv6.conf
touch /var/log/fail2ban-iptables.log
chown root:root /var/log/fail2ban-iptables.log
chmod 640 /var/log/fail2ban-iptables.log


# =============================================================================
# Install & Konfigurasi Fail2ban Filter
# =============================================================================

log "Copy Filter Guacamole..."
cp -f "$DOTFILES_DIR/Fail2Ban/Guacamole.conf" /etc/fail2ban/filter.d/guacamole.conf

log "Copy Filter Nextcloud..."
cp -f "$DOTFILES_DIR/Fail2Ban/Nextcloud.conf" /etc/fail2ban/filter.d/nextcloud.conf

log "Copy Filter Immich..."
cp -f "$DOTFILES_DIR/Fail2Ban/Immich.conf" /etc/fail2ban/filter.d/immich.conf

log "Membuat konfigurasi jail.local..."
cp -f "$DOTFILES_DIR/Fail2Ban/Jail.conf" /etc/fail2ban/jail.local

log "Enable & Restart Fail2ban..."
systemctl enable fail2ban
systemctl restart fail2ban

log "Status Fail2ban:"
systemctl status fail2ban --no-pager

echo
log "✅ Fail2ban + Telegram berhasil terinstal & dikonfigurasi!"
echo "   Cek status dengan: fail2ban-client status"
echo "   Rubah Cloudflare Token (cftoken) & Cloudflare Userid (cfuser)."
