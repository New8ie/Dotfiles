# ======================================
# Docker Utility Functions & Aliases
# ======================================
# Dibuat oleh Bro Fachmi (versi dengan logging & help)
# ======================================

DOCKER_LOG="$HOME/.config/zsh/logs/docker.log"
mkdir -p "$(dirname "$DOCKER_LOG")"

# ======================================
# Fungsi bantu logging
# ======================================
docker_log() {
  local DATE=$(date +"%d-%m-%Y %H:%M:%S")
  echo "[$DATE] $*" >> "$DOCKER_LOG"
}

# ======================================
# Cek Docker aktif
# ======================================
check_docker() {
  if ! command -v docker &>/dev/null; then
    echo "❌ Docker tidak ditemukan di sistem."
    docker_log "❌ Docker tidak ditemukan."
    return 1
  fi

  if ! pgrep -x "dockerd" &>/dev/null; then
    echo "⚠️  Service Docker belum berjalan."
    docker_log "⚠️  Service Docker belum berjalan."
    return 1
  fi
  return 0
}

# ======================================
# Fungsi & Alias Docker
# ======================================

alias dk-ps='check_docker && docker ps'
alias dk-psa='check_docker && docker ps -a'
alias dk-images='check_docker && docker images'
alias dk-prune='check_docker && docker system prune -af --volumes'
alias dk-disk='check_docker && docker system df'
alias dk-info='check_docker && docker info'
alias dk-service-log='sudo journalctl -u docker -f'

# Menampilkan log container
dk-log() {
  if [ -z "$1" ]; then
    echo "⚠️  Gunakan: dk-log <nama_container>"
    return 1
  fi
  check_docker || return 1
  docker_log "Menampilkan log container: $1"
  docker logs -f "$1"
}

# Masuk shell container
dk-sh() {
  if [ -z "$1" ]; then
    echo "⚠️  Gunakan: dk-sh <nama_container>"
    return 1
  fi
  check_docker || return 1
  docker_log "Masuk shell container: $1"
  docker exec -it "$1" /bin/bash 2>/dev/null || docker exec -it "$1" /bin/sh
}

# Restart container
dk-restart() {
  if [ -z "$1" ]; then
    echo "⚠️  Gunakan: dk-restart <nama_container>"
    return 1
  fi
  check_docker || return 1
  docker_log "Restart container: $1"
  docker restart "$1"
}

# Stop semua container
dk-stop-all() {
  check_docker || return 1
  docker_log "Stop semua container."
  docker stop $(docker ps -q)
}

# Remove semua container berhenti
dk-rm-stopped() {
  check_docker || return 1
  docker_log "Hapus container berhenti."
  docker container prune -f
}

# ======================================
# Bantuan Penggunaan (Help)
# ======================================
dk-help() {
  echo "📘 Docker Utility Help"
  echo "---------------------------------------------"
  echo "🔧 Fungsi & Alias Tersedia:"
  echo ""
  echo "  dk-ps            → Menampilkan container aktif"
  echo "  dk-psa           → Menampilkan semua container (termasuk berhenti)"
  echo "  dk-images        → Menampilkan daftar image"
  echo "  dk-prune         → Bersihkan semua resource tidak terpakai"
  echo "  dk-disk          → Menampilkan penggunaan disk Docker"
  echo "  dk-info          → Menampilkan info sistem Docker"
  echo "  dk-service-log   → Melihat log service Docker daemon"
  echo ""
  echo "  dk-log <container>    → Melihat log container tertentu"
  echo "  dk-sh <container>     → Masuk ke shell container"
  echo "  dk-restart <container>→ Restart container tertentu"
  echo "  dk-stop-all           → Hentikan semua container aktif"
  echo "  dk-rm-stopped         → Hapus container yang sudah berhenti"
  echo ""
  echo "---------------------------------------------"
  echo "🧰 Log file: $DOCKER_LOG"
  echo "🕒 Format log: [dd-mm-yyyy HH:MM:SS]"
  echo "---------------------------------------------"
  echo "Contoh penggunaan:"
  echo "  dk-ps"
  echo "  dk-sh nginx"
  echo "  dk-log nextcloud"
  echo "  dk-prune"
  echo "---------------------------------------------"
}

# ======================================
# Pesan konfirmasi saat fungsi dimuat
# ======================================
echo "✅ Docker function & alias loaded. Gunakan 'dk-help' untuk bantuan."
