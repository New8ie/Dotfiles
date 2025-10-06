# ======================================
# Fail2Ban Functions (dengan pengecekan service)
# ======================================
# Dibuat oleh Bro Fachmi
# Versi dengan fungsi bantuan (help)
# ======================================

# --- Fungsi pengecekan service aktif ---
_check_fail2ban() {
  if ! systemctl is-active --quiet fail2ban; then
    echo "❌ Service Fail2Ban belum berjalan."
    echo "🧩 Jalankan: sudo systemctl start fail2ban"
    return 1
  fi
  return 0
}

# --- Reload Fail2Ban ---
f2b-reload() {
  _check_fail2ban || return 1
  echo "🔄 Reload konfigurasi Fail2Ban..."
  sudo fail2ban-client reload
}

# --- Restart service Fail2Ban ---
f2b-restart() {
  echo "♻️  Restart Fail2Ban..."
  sudo systemctl restart fail2ban
}

# --- Status semua jail ---
f2b-status() {
  _check_fail2ban || return 1
  sudo fail2ban-client status
}

# --- Lihat log Fail2Ban realtime ---
f2b-log() {
  _check_fail2ban || return 1
  sudo tail -f /var/log/fail2ban.log
}

# --- Unban semua IP ---
f2b-unban-all() {
  _check_fail2ban || return 1
  echo "🔓 Membuka semua IP yang diblokir..."
  sudo fail2ban-client unban --all
}

# --- Ban IP pada jail tertentu ---
# Contoh: f2b-ban nextcloud 192.168.55.8
f2b-ban() {
  _check_fail2ban || return 1
  if [ $# -ne 2 ]; then
    echo "⚠️  Gunakan: f2b-ban <nama_jail> <ip>"
    return 1
  fi
  echo "🚫 Memblokir IP $2 di jail: $1"
  sudo fail2ban-client set "$1" banip "$2"
}

# --- Unban IP dari jail tertentu ---
# Contoh: f2b-unban nextcloud 192.168.55.8
f2b-unban() {
  _check_fail2ban || return 1
  if [ $# -ne 2 ]; then
    echo "⚠️  Gunakan: f2b-unban <nama_jail> <ip>"
    return 1
  fi
  echo "🔓 Membuka blokir IP $2 dari jail: $1"
  sudo fail2ban-client set "$1" unbanip "$2"
}

# --- Lihat daftar filter & action ---
f2b-filters() {
  _check_fail2ban || return 1
  sudo eza --icons --group-directories-first -AolhM /etc/fail2ban/filter.d
}

f2b-actions() {
  _check_fail2ban || return 1
  sudo eza --icons --group-directories-first -AolhM /etc/fail2ban/action.d
}

# ======================================
# Bantuan Penggunaan (HELP)
# ======================================
f2b-help() {
  echo "📘 Fail2Ban Utility Help"
  echo "---------------------------------------------"
  echo "🔧 Fungsi & Alias Tersedia:"
  echo ""
  echo "  f2b-status        → Menampilkan status semua jail"
  echo "  f2b-reload        → Reload konfigurasi Fail2Ban"
  echo "  f2b-restart       → Restart service Fail2Ban"
  echo "  f2b-log           → Menampilkan log Fail2Ban realtime"
  echo "  f2b-unban-all     → Membuka blokir semua IP"
  echo ""
  echo "  f2b-ban <jail> <ip>   → Memblokir IP pada jail tertentu"
  echo "  f2b-unban <jail> <ip> → Membuka blokir IP dari jail tertentu"
  echo ""
  echo "  f2b-filters       → Menampilkan daftar filter aktif"
  echo "  f2b-actions       → Menampilkan daftar action yang tersedia"
  echo ""
  echo "---------------------------------------------"
  echo "🧩 Sebelum menjalankan fungsi apapun, script akan memeriksa"
  echo "   apakah service Fail2Ban aktif. Jika tidak, tampil pesan:"
  echo "   ❌ Service Fail2Ban belum berjalan."
  echo ""
  echo "🧰 Contoh Penggunaan:"
  echo "  f2b-status"
  echo "  f2b-ban nextcloud 192.168.55.8"
  echo "  f2b-unban sshd 10.10.10.5"
  echo "  f2b-unban-all"
  echo "  f2b-log"
  echo ""
  echo "---------------------------------------------"
  echo "🕒 Dibuat: $(date +"%d-%m-%Y") oleh Bro Fachmi"
  echo "---------------------------------------------"
}

# ======================================
# Pesan konfirmasi saat fungsi dimuat
# ======================================
echo "✅ Fail2Ban function & alias loaded. Gunakan 'f2b-help' untuk bantuan."
