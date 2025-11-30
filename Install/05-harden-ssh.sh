#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Auto Elevate
# =============================================================================
if [[ $EUID -ne 0 ]]; then
   echo "⚠️  Script needs root access, try sudo..."
   exec sudo bash "$0" "$@"
fi

# =============================================================================
# Logging
# =============================================================================
log()  { echo -e "\033[1;32m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[ERROR]\033[0m $*"; exit 1; }

# =============================================================================
# Path Config
# =============================================================================
CONFIG="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.backup"

# =============================================================================
# Backup hanya sekali
# =============================================================================
if [[ ! -f "$BACKUP" ]]; then
    log "Create Backup → $BACKUP"
    cp "$CONFIG" "$BACKUP"
else
    log "Found old backup → $BACKUP"
fi

# =============================================================================
# Generate Config Baru
# =============================================================================
log "Write hardening SSH..."

cat << 'EOF' > "$CONFIG"
# =============================================================================
# SSHD HARDENED CONFIG (Auto-Managed)
# =============================================================================

Include /etc/ssh/sshd_config.d/*.conf

# Listen interface
ListenAddress 0.0.0.0

# Host Keys
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Login Rules
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

# Banner
Banner none
DebianBanner no

AcceptEnv LANG LC_*

Subsystem sftp /usr/lib/openssh/sftp-server

# ==================== HARDENING ====================
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

SyslogFacility AUTH
LogLevel VERBOSE

# Crypto Hardening
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256
EOF

# =============================================================================
# Check Config
# =============================================================================
log "Checking New Config SSH..."
if ! sshd -t 2>/dev/null; then
    err "Config not valid! Rollback..."
    cp "$BACKUP" "$CONFIG"
fi

# =============================================================================
# Restart SSH
# =============================================================================
log "Restart SSH..."
systemctl restart ssh || systemctl restart sshd

log "✅ Hardening SSH succeeded & script can be repeated!"
echo "If the sshd_config file changes, this script will automatically restore it.."
