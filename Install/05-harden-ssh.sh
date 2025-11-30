#!/bin/bash

set -e

CONFIG="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.backup-$(date +%F-%H%M%S)"

echo "[+] Membuat backup konfigurasi lama: $BACKUP"
cp "$CONFIG" "$BACKUP"

echo "[+] Menulis konfigurasi hardening ke $CONFIG"

cat << 'EOF' > /etc/ssh/sshd_config
# This is the sshd server system-wide configuration file.

Include /etc/ssh/sshd_config.d/*.conf

# Listen pada dua subnet
ListenAddress 192.168.55.0/28
ListenAddress 192.168.60.0/28

# Host Keys
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Hardening Tambahan
PermitRootLogin no
MaxAuthTries 5
MaxSessions 3

PubkeyAuthentication yes

IgnoreRhosts yes
PasswordAuthentication yes
KbdInteractiveAuthentication no

UsePAM yes
PrintMotd no

Banner none
DebianBanner none

AcceptEnv LANG LC_*

Subsystem sftp /usr/lib/openssh/sftp-server

# --------------------------
# Hardening Tambahan
# --------------------------

# Nonaktifkan Agent Forwarding
AllowAgentForwarding no

# Nonaktifkan TCP Forwarding
AllowTcpForwarding no

# Nonaktifkan X11
X11Forwarding no

# Timeout sesi idle
ClientAliveInterval 300
ClientAliveCountMax 2

# Batasi koneksi awal (anti brute force ringan)
MaxStartups 3:30:60

# Percepat login, hindari DNS lookup
UseDNS no

# Logging detail untuk audit
SyslogFacility AUTH
LogLevel VERBOSE

# Cipher & MAC modern
Ciphers aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512,hmac-sha2-256
KexAlgorithms curve25519-sha256,ecdh-sha2-nistp521

EOF

echo "[+] Mengecek konfigurasi SSH..."
sshd -t
if [ $? -ne 0 ]; then
    echo "[!] Konfigurasi error. Mengembalikan file backup..."
    cp "$BACKUP" "$CONFIG"
    exit 1
fi

echo "[+] Restart SSH service..."
systemctl restart ssh || systemctl restart sshd

echo "[✓] Hardening SSH selesai."
echo "[i] Backup tersimpan di: $BACKUP"
