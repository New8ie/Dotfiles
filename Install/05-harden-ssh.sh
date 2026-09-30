#!/usr/bin/env bash

set -euo pipefail

# =============================================================================
# Logging
# =============================================================================

log() {
    echo -e "\033[1;36m[INFO]\033[0m $*"
}

ok() {
    echo -e "\033[1;32m[OK]\033[0m $*"
}

warn() {
    echo -e "\033[1;33m[WARN]\033[0m $*"
}

err() {
    echo -e "\033[1;31m[ERROR]\033[0m $*"
    exit 1
}

# =============================================================================
# Auto Elevate
# =============================================================================

if [[ $EUID -ne 0 ]]; then
    echo -e "\033[1;33m[WARN]\033[0m Script membutuhkan akses root, mencoba sudo..."

    if ! command -v sudo >/dev/null 2>&1; then
        err "sudo tidak ditemukan. Jalankan script sebagai root atau install sudo."
    fi

    exec sudo -E bash "$0" "$@"
fi

# =============================================================================
# Validasi OS
# =============================================================================

OS_TYPE="$(uname -s)"

if [[ "$OS_TYPE" != "Linux" ]]; then
    err "Script ini hanya mendukung Linux. OS terdeteksi: $OS_TYPE"
fi

# =============================================================================
# Validasi Command
# =============================================================================

REQUIRED_COMMANDS=(
    sshd
    systemctl
    cp
    chmod
)

for command_name in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        err "Command '$command_name' tidak ditemukan."
    fi
done

# =============================================================================
# Path Config
# =============================================================================

CONFIG="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.backup"

# =============================================================================
# Validasi SSH Config
# =============================================================================

if [[ ! -f "$CONFIG" ]]; then
    err "File konfigurasi SSH tidak ditemukan: $CONFIG"
fi

# =============================================================================
# Backup hanya sekali
# =============================================================================

if [[ ! -f "$BACKUP" ]]; then

    log "Membuat backup SSH configuration..."

    cp "$CONFIG" "$BACKUP"
    chmod 600 "$BACKUP"

    ok "Backup dibuat: $BACKUP"

else

    log "Backup lama ditemukan: $BACKUP"
    log "Backup tidak ditimpa."

fi

# =============================================================================
# Generate Config Baru
# =============================================================================

log "Menulis konfigurasi SSH hardened..."

cat > "$CONFIG" <<'EOF'
# =============================================================================
# SSHD HARDENED CONFIG (Auto-Managed)
# =============================================================================

Include /etc/ssh/sshd_config.d/*.conf

# =============================================================================
# Listen Interface
# =============================================================================

ListenAddress 0.0.0.0

# =============================================================================
# Host Keys
# =============================================================================

HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# =============================================================================
# Login Rules
# =============================================================================

PermitRootLogin no
MaxAuthTries 5
MaxSessions 3

PubkeyAuthentication yes
IgnoreRhosts yes
IgnoreUserKnownHosts no

PasswordAuthentication yes
PermitEmptyPasswords no

KbdInteractiveAuthentication no
UsePAM yes

PrintMotd no

# =============================================================================
# Banner
# =============================================================================

Banner none
DebianBanner no

# =============================================================================
# Environment
# =============================================================================

AcceptEnv LANG LC_*

# =============================================================================
# SFTP
# =============================================================================

Subsystem sftp /usr/lib/openssh/sftp-server

# =============================================================================
# Hardening
# =============================================================================

AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no
PermitTunnel no

VersionAddendum none
PrintLastLog yes

ClientAliveInterval 300
ClientAliveCountMax 2

MaxStartups 3:30:60

UseDNS no

# =============================================================================
# Logging
# =============================================================================

SyslogFacility AUTH
LogLevel VERBOSE

# =============================================================================
# Crypto Hardening
# =============================================================================

Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256

KexAlgorithms mlkem768x25519-sha256,sntrup761x25519-sha512,curve25519-sha256

# =============================================================================
# END
# =============================================================================
EOF

chmod 644 "$CONFIG"

ok "Konfigurasi SSH berhasil ditulis."

# =============================================================================
# Check Config
# =============================================================================

log "Memvalidasi konfigurasi SSH..."

if sshd -t; then

    ok "Konfigurasi SSH valid."

else

    warn "Konfigurasi SSH tidak valid."
    warn "Melakukan rollback ke backup..."

    cp "$BACKUP" "$CONFIG"
    chmod 644 "$CONFIG"

    if sshd -t; then
        ok "Rollback berhasil. Konfigurasi lama tetap aman."
    else
        err "Rollback gagal. Backup juga menghasilkan konfigurasi SSH yang tidak valid."
    fi

    exit 1
fi

# =============================================================================
# Restart SSH
# =============================================================================

log "Restart service SSH..."

SSH_RESTARTED=false

if systemctl restart ssh; then
    SSH_RESTARTED=true
    ok "Service SSH berhasil direstart."
elif systemctl restart sshd; then
    SSH_RESTARTED=true
    ok "Service SSH berhasil direstart menggunakan sshd."
fi

if [[ "$SSH_RESTARTED" != true ]]; then

    warn "Restart SSH gagal."
    warn "Melakukan rollback konfigurasi..."

    cp "$BACKUP" "$CONFIG"
    chmod 644 "$CONFIG"

    if sshd -t; then

        ok "Rollback konfigurasi berhasil."

        if systemctl restart ssh; then
            ok "Service SSH berhasil direstart menggunakan konfigurasi backup."
        elif systemctl restart sshd; then
            ok "Service SSH berhasil direstart menggunakan konfigurasi backup."
        else
            err "Rollback berhasil tetapi service SSH tidak dapat direstart."
        fi

    else

        err "Rollback menghasilkan konfigurasi SSH yang tidak valid."
    fi

    exit 1
fi

# =============================================================================
# Verify SSH Service
# =============================================================================

log "Memverifikasi status service SSH..."

if systemctl is-active --quiet ssh; then

    ok "Service SSH aktif."

elif systemctl is-active --quiet sshd; then

    ok "Service SSHD aktif."

else

    warn "Service SSH tidak terdeteksi aktif."
    systemctl status ssh --no-pager || true
    systemctl status sshd --no-pager || true

    err "Verifikasi service SSH gagal."
fi

# =============================================================================
# Final Validation
# =============================================================================

log "Melakukan validasi akhir konfigurasi..."

if sshd -t; then
    ok "Validasi akhir konfigurasi SSH berhasil."
else
    err "Validasi akhir konfigurasi SSH gagal."
fi

# =============================================================================
# Finish
# =============================================================================

echo
echo "============================================================================="
ok "Hardening SSH berhasil diterapkan."
echo "============================================================================="
echo
echo "Config : $CONFIG"
echo "Backup : $BACKUP"
echo
echo "Backup hanya dibuat sekali dan tidak akan ditimpa oleh eksekusi berikutnya."
echo

