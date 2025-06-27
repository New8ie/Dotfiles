#!/bin/bash

# ============================
# Auto Installer Zabbix Agent2 (Final Version)
# Supports: Debian, Ubuntu, Raspbian, macOS
# Author: Fachmi (Optimized by ChatGPT)
# ============================

set -euo pipefail
IFS=$'\n\t'

ZBX_SERVERS="192.168.49.2,192.168.64.3"
ZBX_PORT="10050"
ZBX_HOSTNAME="$(hostname -f 2>/dev/null || hostname)"

# ---------- Utilities ----------
log_info() { echo -e "\033[1;32m[INFO]\033[0m $*"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
log_error() { echo -e "\033[1;31m[ERROR]\033[0m $*"; }

remove_broken_mongodb_repo() {
  local files
  files=$(grep -rlE "mongodb-org/(7\.0|8\.0)" /etc/apt/sources.list.d/ 2>/dev/null || true)
  if [[ -n "$files" ]]; then
    log_warn "Menghapus repository MongoDB rusak..."
    for f in $files; do
      sudo rm -f "$f"
      log_info "Dihapus: $f"
    done
  fi
}

is_latest_zabbix_version() {
  if ! dpkg -s zabbix-agent2 &>/dev/null; then
    return 1
  fi
  local installed latest
  installed=$(dpkg-query -W -f='${Version}' zabbix-agent2)
  sudo apt-get update -qq >/dev/null
  latest=$(apt-cache policy zabbix-agent2 | awk '/Candidate:/ { print $2 }')
  if [[ "$installed" == "$latest" ]]; then
    log_info "Zabbix Agent2 sudah terinstall dan versi terbaru: $installed"
    return 0
  else
    log_warn "Versi lama terdeteksi: $installed | Versi terbaru: $latest"
    return 1
  fi
}

configure_zabbix_agent2() {
  local conf="/etc/zabbix/zabbix_agent2.conf"
  if [[ -f "$conf" ]]; then
    sudo sed -i "s|^Server=.*|Server=${ZBX_SERVERS}|" "$conf"
    sudo sed -i "s|^ServerActive=.*|ServerActive=${ZBX_SERVERS}|" "$conf"
    sudo sed -i "s|^Hostname=.*|Hostname=${ZBX_HOSTNAME}|" "$conf"
    sudo sed -i "s|^# ListenPort=.*|ListenPort=${ZBX_PORT}|" "$conf"
    log_info "Konfigurasi diperbarui di: $conf"
  else
    log_warn "Konfigurasi $conf tidak ditemukan!"
  fi
}

install_debian_family() {
  local os="$1"
  local url=""
  case "$os" in
    debian) url="https://repo.zabbix.com/zabbix/7.2/release/debian/pool/main/z/zabbix-release/zabbix-release_latest_7.2+debian12_all.deb" ;;
    ubuntu) url="https://repo.zabbix.com/zabbix/7.2/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.2+ubuntu24.04_all.deb" ;;
    raspbian) url="https://repo.zabbix.com/zabbix/7.2/release/raspbian/pool/main/z/zabbix-release/zabbix-release_latest_7.2+debian12_all.deb" ;;
    *) log_error "OS tidak didukung: $os"; exit 1 ;;
  esac

  log_info "Mengunduh dan menginstall repository Zabbix untuk $os..."
  tmpdeb="/tmp/zabbix-release.deb"
  wget -qO "$tmpdeb" "$url"
  sudo dpkg -i "$tmpdeb"
  sudo apt-get update -qq
  sudo apt-get install -y zabbix-agent2
}

install_macos() {
  if ! command -v brew &>/dev/null; then
    log_error "Homebrew belum terpasang. Silakan install Homebrew terlebih dahulu."
    exit 1
  fi

  if brew list --versions zabbix-agent2 &>/dev/null; then
    log_info "Zabbix Agent2 sudah terpasang di macOS. Melakukan upgrade..."
    brew upgrade zabbix-agent2 || true
  else
    log_info "Menginstall Zabbix Agent2 di macOS..."
    brew install zabbix-agent2
  fi

  local conf="/opt/homebrew/etc/zabbix/zabbix_agent2.conf"
  mkdir -p "$(dirname "$conf")"

  cat > "$conf" <<EOF
Server=${ZBX_SERVERS}
ServerActive=${ZBX_SERVERS}
Hostname=${ZBX_HOSTNAME}
ListenPort=${ZBX_PORT}
LogType=console
EOF

  log_info "Menjalankan Zabbix Agent2 di background..."
  pkill zabbix_agent2 || true
  nohup /opt/homebrew/sbin/zabbix_agent2 -c "$conf" > /tmp/zabbix_agent2.log 2>&1 &
  log_info "Zabbix Agent2 berjalan (log: /tmp/zabbix_agent2.log)"
}

main() {
  log_info "Deteksi sistem operasi..."
  if [[ "$(uname)" == "Darwin" ]]; then
    install_macos
    return
  fi

  if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    remove_broken_mongodb_repo

    case "$ID" in
      debian|ubuntu|raspbian)
        if is_latest_zabbix_version; then
          log_info "Memperbarui konfigurasi meskipun versi Zabbix Agent2 sudah terbaru..."
          configure_zabbix_agent2
          sudo systemctl restart zabbix-agent2
        else
          install_debian_family "$ID"
          configure_zabbix_agent2
          sudo systemctl restart zabbix-agent2
          sudo systemctl enable zabbix-agent2
        fi
        ;;
      *)
        log_error "OS tidak didukung: $ID"
        exit 1
        ;;
    esac
  else
    log_error "/etc/os-release tidak ditemukan. Gagal deteksi OS."
    exit 1
  fi
}

main
