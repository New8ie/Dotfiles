#!/bin/bash
# ======================================================================
# Script Instalasi & Konfigurasi Fail2ban dengan Telegram & Cloudflare
# Debian/Ubuntu
# Author : Fachmi Homelab
# ======================================================================

set -e  # hentikan script jika ada error

# Pastikan dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
   echo "⚠️  Harus dijalankan sebagai root (gunakan sudo)." 
   exit 1
fi

echo "===> Update repository & upgrade paket..."
apt update -y && apt upgrade -y

echo "===> Install Fail2ban & curl..."
apt install -y fail2ban curl

echo "===> Backup konfigurasi default jail.conf..."
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf.bak.$(date +%F)

echo "===> Deploy konfigurasi action Telegram..."
cp -f ~/.dotfiles/Fail2Ban/Telegram.conf /etc/fail2ban/action.d/telegram.conf

echo "===> Buat folder script jika belum ada..."
mkdir -p /etc/fail2ban/script

echo "===> Deploy script notifikasi Telegram..."
cp -f ~/.dotfiles/Fail2Ban/send_telegram_notif.sh /etc/fail2ban/script/send_telegram_notif.sh
chmod +x /etc/fail2ban/script/send_telegram_notif.sh

echo "===> Deploy konfigurasi action Cloudflare..."
cp -f ~/.dotfiles/Fail2Ban/Cloudflare.conf /etc/fail2ban/action.d/cloudflare.conf 

echo "===> Deploy konfigurasi jail.local..."
cp -f ~/.dotfiles/Fail2Ban/Jail.conf /etc/fail2ban/jail.local

echo "===> Enable & restart Fail2ban..."
systemctl enable fail2ban
systemctl restart fail2ban

echo "===> Status Fail2ban:"
systemctl status fail2ban --no-pager || true

echo
echo "✅ Fail2ban berhasil terinstal & dikonfigurasi!"
echo "ℹ️  Cek status: fail2ban-client status"
echo "⚙️  Jangan lupa ubah Cloudflare Token (cftoken) & Cloudflare UserID (cfuser) di /etc/fail2ban/action.d/cloudflare.conf"
