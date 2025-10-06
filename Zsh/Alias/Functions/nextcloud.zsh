# ======================================
# Nextcloud Function
# ======================================
# Dibuat oleh Bro Fachmi
# Versi dengan fungsi bantuan (help)
# ======================================

# Path default ke instalasi Nextcloud
NEXTCLOUD_PATH="/var/www/nextcloud"
PHP_BIN="$(command -v php)"
NC_LOG="$HOME/.config/zsh/logs/nextcloud.log"

# Pastikan folder log ada
mkdir -p "$(dirname "$NC_LOG")"

# ======================================
# Fungsi utama OCC
# ======================================
occ() {
  local DATE=$(date +"%d-%m-%Y %H:%M:%S")

  # Cek apakah PHP tersedia
  if [ -z "$PHP_BIN" ]; then
    echo "❌ PHP tidak ditemukan di PATH."
    echo "[$DATE] ❌ PHP tidak ditemukan" >> "$NC_LOG"
    return 1
  fi

  # Cek apakah direktori Nextcloud ada
  if [ ! -d "$NEXTCLOUD_PATH" ]; then
    echo "❌ Direktori Nextcloud tidak ditemukan di: $NEXTCLOUD_PATH"
    echo "[$DATE] ❌ Direktori Nextcloud tidak ditemukan: $NEXTCLOUD_PATH" >> "$NC_LOG"
    return 1
  fi

  echo "⚙️  Menjalankan OCC command sebagai www-data..."
  echo "[$DATE] ▶️ occ $*" >> "$NC_LOG"

  sudo -u www-data "$PHP_BIN" "$NEXTCLOUD_PATH/occ" "$@"
}

# ======================================
# Shortcut tambahan (alias OCC umum)
# ======================================

# Menampilkan status Nextcloud
alias nc-status='occ status'

# Memeriksa integritas sistem Nextcloud
alias nc-check='occ integrity:check-core'

# Membersihkan cache file dan memperbaiki database
alias nc-maintenance='occ maintenance:repair && occ db:add-missing-indices'

# Menjalankan upgrade Nextcloud
alias nc-update='occ upgrade'

# Melihat log aplikasi Nextcloud
alias nc-log='sudo tail -f /var/log/nextcloud/nextcloud.log'

# Melihat pengguna aktif
alias nc-users='occ user:list'

# Menjalankan perintah maintenance mode
alias nc-on='occ maintenance:mode --on'
alias nc-off='occ maintenance:mode --off'

# ======================================
# Fungsi Bantuan
# ======================================
nc-help() {
  echo "📘 Nextcloud OCC Utility Help"
  echo "---------------------------------------------"
  echo "🔧 Fungsi & Alias Tersedia:"
  echo ""
  echo "  occ <perintah>           → Jalankan perintah OCC sebagai www-data"
  echo "  nc-status                → Menampilkan status Nextcloud"
  echo "  nc-check                 → Memeriksa integritas file inti"
  echo "  nc-maintenance           → Membersihkan cache & memperbaiki DB"
  echo "  nc-update                → Menjalankan proses upgrade Nextcloud"
  echo "  nc-log                   → Melihat log Nextcloud realtime"
  echo "  nc-users                 → Menampilkan daftar user"
  echo "  nc-on / nc-off           → Aktifkan / matikan mode maintenance"
  echo ""
  echo "---------------------------------------------"
  echo "🧩 Log Aktivitas disimpan di:"
  echo "  $NC_LOG"
  echo ""
  echo "🧰 Contoh Penggunaan:"
  echo "  occ status"
  echo "  occ maintenance:mode --on"
  echo "  nc-maintenance"
  echo "  nc-update"
  echo "  nc-log"
  echo ""
  echo "---------------------------------------------"
  echo "⚙️  Direktori Nextcloud saat ini:"
  echo "  $NEXTCLOUD_PATH"
  echo "---------------------------------------------"
  echo "🕒 Dibuat: $(date +"%d-%m-%Y") oleh Bro Fachmi"
  echo "---------------------------------------------"
}

# ======================================
# Pesan konfirmasi saat fungsi dimuat
# ======================================
echo "✅ Nextcloud OCC function loaded. Gunakan 'nc-help' untuk bantuan."
