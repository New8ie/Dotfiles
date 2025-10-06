# ======================================
# Wazuh Management Function
# ======================================
# Dibuat oleh Bro Fachmi
# Versi dengan fungsi bantuan (help)
# ======================================

# Lokasi log untuk aktivitas CLI
WAZUH_LOG="$HOME/.config/zsh/logs/wazuh.log"
mkdir -p "$(dirname "$WAZUH_LOG")"

# ======================================
# Fungsi Pengecekan Service
# ======================================
_check_wazuh() {
  if ! systemctl is-active --quiet wazuh-manager; then
    echo "❌ Service Wazuh Manager belum berjalan."
    echo "🧩 Jalankan: sudo systemctl start wazuh-manager"
    return 1
  fi
  return 0
}

# ======================================
# Fungsi Utama
# ======================================

# Status Wazuh Manager
wazuh-status() {
  _check_wazuh || return 1
  local DATE=$(date +"%d-%m-%Y %H:%M:%S")
  echo "🧠 Status Wazuh Manager:"
  echo "[$DATE] ▶️ wazuh-status" >> "$WAZUH_LOG"
  sudo systemctl status wazuh-manager --no-pager
}

# Restart Wazuh Manager
wazuh-restart() {
  local DATE=$(date +"%d-%m-%Y %H:%M:%S")
  echo "♻️  Me-restart Wazuh Manager..."
  echo "[$DATE] 🔄 wazuh-restart" >> "$WAZUH_LOG"
  sudo systemctl restart wazuh-manager
}

# Stop Wazuh Manager
wazuh-stop() {
  local DATE=$(date +"%d-%m-%Y %H:%M:%S")
  echo "🛑 Menghentikan Wazuh Manager..."
  echo "[$DATE] ⏹️ wazuh-stop" >> "$WAZUH_LOG"
  sudo systemctl stop wazuh-manager
}

# Start Wazuh Manager
wazuh-start() {
  local DATE=$(date +"%d-%m-%Y %H:%M:%S")
  echo "🚀 Menjalankan Wazuh Manager..."
  echo "[$DATE] ▶️ wazuh-start" >> "$WAZUH_LOG"
  sudo systemctl start wazuh-manager
}

# Lihat log Wazuh Manager realtime
wazuh-log() {
  _check_wazuh || return 1
  echo "📜 Menampilkan log Wazuh Manager..."
  sudo tail -f /var/ossec/logs/ossec.log
}

# Lihat daftar agent
wazuh-agents() {
  _check_wazuh || return 1
  echo "👥 Daftar agent terdaftar di Wazuh:"
  sudo /var/ossec/bin/agent_control -l
}

# Lihat agent detail tertentu
# Contoh: wazuh-agent-info 001
wazuh-agent-info() {
  _check_wazuh || return 1
  if [ -z "$1" ]; then
    echo "⚠️  Gunakan: wazuh-agent-info <agent_id>"
    return 1
  fi
  sudo /var/ossec/bin/agent_control -i "$1"
}

# Jalankan test rule manual
# Contoh: wazuh-test-rule /var/ossec/logs/alerts/alerts.json
wazuh-test-rule() {
  _check_wazuh || return 1
  if [ -z "$1" ]; then
    echo "⚠️  Gunakan: wazuh-test-rule <path_log>"
    return 1
  fi
  sudo /var/ossec/bin/ossec-logtest < "$1"
}

# Jalankan restart untuk agen tertentu
# Contoh: wazuh-restart-agent 001
wazuh-restart-agent() {
  _check_wazuh || return 1
  if [ -z "$1" ]; then
    echo "⚠️  Gunakan: wazuh-restart-agent <agent_id>"
    return 1
  fi
  sudo /var/ossec/bin/agent_control -R "$1"
}

# ======================================
# Fungsi Bantuan
# ======================================
wazuh-help() {
  echo "📘 Wazuh Management CLI Help"
  echo "---------------------------------------------"
  echo "🔧 Fungsi & Alias Tersedia:"
  echo ""
  echo "  wazuh-status            → Tampilkan status service Wazuh Manager"
  echo "  wazuh-start             → Jalankan Wazuh Manager"
  echo "  wazuh-stop              → Hentikan Wazuh Manager"
  echo "  wazuh-restart           → Restart Wazuh Manager"
  echo "  wazuh-log               → Lihat log realtime (ossec.log)"
  echo "  wazuh-agents            → Daftar semua agent terdaftar"
  echo "  wazuh-agent-info <id>   → Info detail agent berdasarkan ID"
  echo "  wazuh-restart-agent <id>→ Restart agent tertentu"
  echo "  wazuh-test-rule <file>  → Uji log file terhadap rule Wazuh"
  echo ""
  echo "---------------------------------------------"
  echo "🧩 Log aktivitas disimpan di:"
  echo "  $WAZUH_LOG"
  echo ""
  echo "🧰 Contoh Penggunaan:"
  echo "  wazuh-status"
  echo "  wazuh-agents"
  echo "  wazuh-agent-info 001"
  echo "  wazuh-test-rule /var/ossec/logs/alerts/alerts.json"
  echo ""
  echo "---------------------------------------------"
  echo "🕒 Dibuat: $(date +"%d-%m-%Y") oleh Bro Fachmi"
  echo "---------------------------------------------"
}

# ======================================
# Pesan konfirmasi saat fungsi dimuat
# ======================================
echo "✅ Wazuh Manager function loaded. Gunakan 'wazuh-help' untuk bantuan."
