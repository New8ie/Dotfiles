#!/bin/bash
# cloudflare_manager.sh
# Manajemen block/unblock IP di Cloudflare via API
# Versi dengan logging (format tanggal dd-mm-yyyy)
# ==================================================

# === LOAD KONFIGURASI ===
ENV_FILE="$HOME/.env/cloudflare"

if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
else
  echo "❌ File konfigurasi tidak ditemukan di $ENV_FILE"
  exit 1
fi

# === SIAPKAN LOG FILE ===
LOG_DIR="$HOME/.cache"
LOG_FILE="$LOG_DIR/cloudflare_manager.log"
mkdir -p "$LOG_DIR"

# Simpan output dan error ke log (tetap tampil di layar juga)
exec > >(tee -a "$LOG_FILE") 2>&1

# Format tanggal dd-mm-yyyy
DATE_NOW=$(date '+%d-%m-%Y %H:%M:%S')

echo "📅 $DATE_NOW - Menjalankan $0 $*" 
echo "-----------------------------------------------------"

# === HEADER AUTENTIKASI ===
HEADER_AUTH=(-H "X-Auth-Email: $CF_EMAIL" -H "X-Auth-Key: $API_KEY" -H "Content-Type: application/json")
CF_API="https://api.cloudflare.com/client/v4"

# === FUNGSI ===
list_banned() {
  echo "📋 Daftar IP yang diblokir:"
  curl -s -X GET "$CF_API/zones/$ZONE_ID/firewall/access_rules/rules" "${HEADER_AUTH[@]}" | \
    jq -r '.result[] | "\(.configuration.value) \(.configuration.target) \(.mode) - \(.notes)"'
}

ban_ip() {
  IP=$1
  if [ -z "$IP" ]; then
    echo "⚠️  Gunakan: $0 ban <IP>"
    exit 1
  fi

  if [[ $IP == *:* ]]; then
    TARGET="ip6"
  else
    TARGET="ip"
  fi

  echo "🚫 Memblokir IP: $IP"
  curl -s -X POST "$CF_API/zones/$ZONE_ID/firewall/access_rules/rules" \
    "${HEADER_AUTH[@]}" \
    --data "{\"mode\":\"block\",\"configuration\":{\"target\":\"$TARGET\",\"value\":\"$IP\"},\"notes\":\"Banned via script\"}" | jq .
}

unban_ip() {
  IP=$1
  if [ -z "$IP" ]; then
    echo "⚠️  Gunakan: $0 unban <IP>"
    exit 1
  fi

  if [[ $IP == *:* ]]; then
    TARGET="ip6"
  else
    TARGET="ip"
  fi

  RULE_ID=$(curl -s -X GET "$CF_API/zones/$ZONE_ID/firewall/access_rules/rules" "${HEADER_AUTH[@]}" | jq -r ".result[] | select(.configuration.value==\"$IP\" and .configuration.target==\"$TARGET\") | .id")
  if [ -z "$RULE_ID" ]; then
    echo "❌ IP $IP tidak ditemukan di daftar blokir."
    exit 1
  fi

  echo "✅ Membuka blokir IP: $IP"
  curl -s -X DELETE "$CF_API/zones/$ZONE_ID/firewall/access_rules/rules/$RULE_ID" "${HEADER_AUTH[@]}" | jq .
}

unban_all() {
  echo "⚠️ Membuka semua blokir IP (Zone + Account level)..."

  fetch_ids() {
    local endpoint="$1"
    local page=1
    local ids=""
    while :; do
      resp=$(curl -s -G "${HEADER_AUTH[@]}" --data-urlencode "page=$page" --data-urlencode "per_page=100" "$endpoint")
      page_ids=$(echo "$resp" | jq -r '.result[] | select(.configuration.target=="ip" or .configuration.target=="ip6") | .id' 2>/dev/null)
      if [ -n "$page_ids" ]; then
        ids="$ids"$'\n'"$page_ids"
      fi
      total_pages=$(echo "$resp" | jq -r '.result_info.total_pages // 1' 2>/dev/null)
      if [ -z "$resp" ] || [ "$page" -ge "$total_pages" ]; then
        break
      fi
      page=$((page+1))
    done
    echo "$ids" | sed '/^\s*$/d' | sort -u
  }

  delete_each() {
    local base="$1"
    local ids="$2"
    if [ -z "$ids" ]; then
      echo "ℹ️ Tidak ada rule untuk dihapus pada endpoint: $base"
      return
    fi
    while IFS= read -r id; do
      [ -z "$id" ] && continue
      echo "🗑️ Menghapus rule $id dari $base ..."
      resp_del=$(curl -s -X DELETE "${HEADER_AUTH[@]}" "$base/$id")
      ok=$(echo "$resp_del" | jq -r '.success' 2>/dev/null)
      if [ "$ok" = "true" ]; then
        echo "✅ Rule $id dihapus."
      else
        echo "❌ Gagal menghapus $id. API response:"
        echo "$resp_del" | jq -c '.errors, .messages' 2>/dev/null || echo "$resp_del"
      fi
      sleep 0.2
    done <<< "$ids"
  }

  zone_endpoint="$CF_API/zones/$ZONE_ID/firewall/access_rules/rules"
  echo "› Mengambil rule di level ZONE..."
  ZONE_IDS=$(fetch_ids "$zone_endpoint")
  delete_each "$zone_endpoint" "$ZONE_IDS"

  account_endpoint="$CF_API/user/firewall/access_rules/rules"
  echo "› Mengambil rule di level ACCOUNT..."
  ACCOUNT_IDS=$(fetch_ids "$account_endpoint")
  delete_each "$account_endpoint" "$ACCOUNT_IDS"

  echo "🎉 Selesai memproses semua rule (zone & account)."
}

check_connection() {
  echo "🔍 Mengecek koneksi ke Cloudflare..."
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$CF_API/zones/$ZONE_ID" "${HEADER_AUTH[@]}")
  if [ "$RESPONSE" -eq 200 ]; then
    echo "✅ Koneksi berhasil! Email dan API Key valid."
  else
    echo "❌ Koneksi gagal! HTTP status code: $RESPONSE"
  fi
}

show_help() {
  echo "📖 Cloudflare Manager"
  echo ""
  echo "Penggunaan: $0 <command> [argumen]"
  echo ""
  echo "Command yang tersedia:"
  echo "  list            - Menampilkan daftar IP yang diblokir"
  echo "  ban <IP>        - Memblokir IP tertentu"
  echo "  unban <IP>      - Membuka blokir IP tertentu"
  echo "  unban_all       - Membuka blokir semua IP"
  echo "  check           - Mengecek koneksi ke Cloudflare"
  echo "  help            - Menampilkan bantuan ini"
  echo ""
  echo "Contoh:"
  echo "  $0 ban 1.2.3.4"
  echo "  $0 unban 1.2.3.4"
  echo "  $0 unban_all"
  echo "  $0 check"
}

# === ROUTER COMMAND ===
case "$1" in
list) list_banned ;;
ban) ban_ip "$2" ;;
unban) unban_ip "$2" ;;
unban_all) unban_all ;;
check) check_connection ;;
help | "") show_help ;;
*)
  echo "❌ Command tidak dikenal: $1"
  show_help ;;
esac

echo "-----------------------------------------------------"
echo ""
