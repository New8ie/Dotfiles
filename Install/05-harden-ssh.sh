#!/usr/bin/env bash

set -Eeuo pipefail

log() {
    printf '\033[1;36m[INFO]\033[0m %s\n' "$*"
}

ok() {
    printf '\033[1;32m[OK]\033[0m %s\n' "$*"
}

warn() {
    printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2
}

die() {
    printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2
    exit 1
}

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    die "Jalankan dengan root, misalnya: sudo bash $0"
fi

if [[ $(uname -s) != Linux ]]; then
    die "Skrip ini hanya mendukung Linux."
fi

for command_name in sshd systemctl mktemp cp mv rm chmod date awk grep; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        die "Command '$command_name' tidak ditemukan."
    fi
done

CONFIG="/etc/ssh/sshd_config"
DROPIN_DIR="/etc/ssh/sshd_config.d"
DROPIN="$DROPIN_DIR/00-local-hardening.conf"

[[ -f "$CONFIG" ]] || die "File konfigurasi SSH tidak ditemukan: $CONFIG"
[[ -d "$DROPIN_DIR" ]] || die "Direktori drop-in tidak ditemukan: $DROPIN_DIR"
[[ ! -L "$DROPIN" ]] || die "$DROPIN adalah symbolic link; tidak akan ditimpa."

if grep -Fq '# SSHD HARDENED CONFIG (Auto-Managed)' "$CONFIG"; then
    die "sshd_config tampaknya ditimpa versi skrip lama. Tinjau $CONFIG dan /etc/ssh/sshd_config.backup, lalu pulihkan konfigurasi asli sebelum menjalankan versi ini."
fi

if ! sshd -t -f "$CONFIG"; then
    die "Konfigurasi SSH saat ini tidak valid; tidak ada perubahan yang dilakukan."
fi

SERVICE=""
FALLBACK_SERVICE=""
for unit in ssh.service sshd.service; do
    load_state="$(systemctl show -p LoadState --value "$unit" 2>/dev/null || true)"
    if [[ "$load_state" == loaded ]]; then
        if systemctl is-active --quiet "$unit"; then
            SERVICE="$unit"
            break
        fi
        if [[ -z "$FALLBACK_SERVICE" ]]; then
            FALLBACK_SERVICE="$unit"
        fi
    fi
done

if [[ -z "$SERVICE" ]]; then
    SERVICE="$FALLBACK_SERVICE"
fi
[[ -n "$SERVICE" ]] || die "Unit systemd ssh.service atau sshd.service tidak ditemukan."

HAD_DROPIN=false
CHANGES_APPLIED=false
DROPIN_BACKUP=""
TEMP_FILE=""

if [[ -e "$DROPIN" ]]; then
    if ! grep -Fq '# Managed by Install/05-harden-ssh.sh.' "$DROPIN"; then
        die "$DROPIN sudah ada dan bukan milik skrip ini; tidak akan ditimpa."
    fi

    HAD_DROPIN=true
    DROPIN_BACKUP="$DROPIN_DIR/.00-local-hardening.conf.backup.$(date +%Y%m%d%H%M%S).$$"
    cp -p "$DROPIN" "$DROPIN_BACKUP"
    chmod 600 "$DROPIN_BACKUP"
    log "Backup drop-in sebelumnya: $DROPIN_BACKUP"
fi

rollback() {
    local rollback_file

    warn "Memulihkan konfigurasi SSH sebelumnya..."
    if [[ "$HAD_DROPIN" == true ]]; then
        rollback_file="$(mktemp "$DROPIN_DIR/.rollback.XXXXXX")" || {
            warn "Tidak dapat membuat file sementara untuk rollback."
            return 1
        }
        if ! cp -p "$DROPIN_BACKUP" "$rollback_file" || ! mv -f "$rollback_file" "$DROPIN"; then
            rm -f "$rollback_file"
            warn "Pemulihan drop-in gagal. Backup tersedia di: $DROPIN_BACKUP"
            return 1
        fi
    elif ! rm -f "$DROPIN"; then
        warn "Tidak dapat menghapus drop-in baru: $DROPIN"
        return 1
    fi

    if sshd -t -f "$CONFIG" &&
        systemctl restart "$SERVICE" &&
        systemctl is-active --quiet "$SERVICE"; then
        ok "Konfigurasi sebelumnya dipulihkan dan $SERVICE berhasil direstart."
        return 0
    fi

    warn "Konfigurasi dipulihkan, tetapi validasi atau restart $SERVICE gagal."
    return 1
}

on_exit() {
    local status=$?
    trap - EXIT

    if [[ -n "$TEMP_FILE" && -e "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE" || true
    fi

    if [[ $status -ne 0 && "$CHANGES_APPLIED" == true ]]; then
        rollback || true
    fi

    exit "$status"
}
trap on_exit EXIT

TEMP_FILE="$(mktemp "$DROPIN_DIR/.00-local-hardening.XXXXXX")"
chmod 600 "$TEMP_FILE"
cat > "$TEMP_FILE" <<'EOF'
# Managed by Install/05-harden-ssh.sh.
# Authentication and listen-address policies are intentionally left unchanged.

PermitRootLogin no
MaxAuthTries 5
MaxSessions 3
IgnoreRhosts yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UseDNS no

AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no
PermitTunnel no

ClientAliveInterval 300
ClientAliveCountMax 2
MaxStartups 3:30:60
LogLevel VERBOSE
EOF

mv -f "$TEMP_FILE" "$DROPIN"
TEMP_FILE=""
CHANGES_APPLIED=true
log "Drop-in hardening ditulis: $DROPIN"

log "Memvalidasi konfigurasi SSH..."
sshd -t -f "$CONFIG" || die "Konfigurasi SSH tidak valid."

effective_config="$(sshd -T -f "$CONFIG")" || die "Tidak dapat membaca konfigurasi SSH efektif."
effective_value() {
    awk -v key="$1" '$1 == key { print $2; exit }' <<< "$effective_config"
}

assert_value() {
    local key="$1"
    local expected="$2"
    local actual
    actual="$(effective_value "$key")"
    [[ "$actual" == "$expected" ]] || die "Nilai efektif $key adalah '${actual:-tidak ditemukan}', seharusnya '$expected'. Drop-in mungkin tidak dimuat atau ditimpa konfigurasi lain."
}

assert_maximum() {
    local key="$1"
    local maximum="$2"
    local actual
    actual="$(effective_value "$key")"
    [[ "$actual" =~ ^[0-9]+$ ]] || die "Nilai efektif $key tidak valid: '${actual:-tidak ditemukan}'."
    (( actual <= maximum )) || die "Nilai efektif $key ($actual) lebih longgar dari batas $maximum."
}

assert_value permitrootlogin no
assert_value ignorerhosts yes
assert_value permitemptypasswords no
assert_value kbdinteractiveauthentication no
assert_value allowagentforwarding no
assert_value allowtcpforwarding no
assert_value x11forwarding no
assert_value permittunnel no
assert_maximum maxauthtries 5
assert_maximum maxsessions 3

ok "Konfigurasi efektif memenuhi pemeriksaan hardening."

log "Me-restart $SERVICE..."
systemctl restart "$SERVICE"
systemctl is-active --quiet "$SERVICE" || die "$SERVICE tidak aktif setelah restart."

sshd -t -f "$CONFIG" || die "Validasi akhir konfigurasi SSH gagal."

CHANGES_APPLIED=false
ok "Hardening SSH berhasil diterapkan."
printf '\nConfig : %s\nDrop-in: %s\nService: %s\n' "$CONFIG" "$DROPIN" "$SERVICE"
if [[ "$HAD_DROPIN" == true ]]; then
    printf 'Backup : %s\n' "$DROPIN_BACKUP"
fi
printf '\nPasswordAuthentication dan alamat listen tidak diubah oleh skrip ini.\n'
printf 'Uji koneksi SSH baru sebelum menutup sesi yang sedang aktif.\n'
