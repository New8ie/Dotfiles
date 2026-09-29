#!/bin/bash

# Direktori SSH pengguna
SSH_DIR="$HOME/.ssh"

# Pastikan direktori ~/.ssh ada
if [ ! -d "$SSH_DIR" ]; then
  echo "📂 Membuat direktori .ssh..."
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
fi

# Pastikan file authorized_keys ada
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
if [ ! -f "$AUTHORIZED_KEYS" ]; then
  echo "📝 Membuat file authorized_keys..."
  touch "$AUTHORIZED_KEYS"
  chmod 600 "$AUTHORIZED_KEYS"
fi

# Path public key
PUBLIC_KEY_1="$HOME/HomeLabs/Keys/SSH/MyID-MacMini.pub"
PUBLIC_KEY_2="$HOME/HomeLabs/Keys/SSH/mFachmi-key.pub"

# Cek jumlah public key yang tersedia
HAS_KEY_1=false
HAS_KEY_2=false

if [ -f "$PUBLIC_KEY_1" ]; then
  HAS_KEY_1=true
fi

if [ -f "$PUBLIC_KEY_2" ]; then
  HAS_KEY_2=true
fi

# Jika tidak ada public key, keluar dari skrip
if [ "$HAS_KEY_1" = false ] && [ "$HAS_KEY_2" = false ]; then
  echo "❌ Tidak ada public key yang ditemukan! Harap pastikan ada setidaknya satu public key."
  exit 1
fi

# Ambil hostname/IP dari parameter pertama
HOST=$1
if [ -z "$HOST" ]; then
  echo "❌ Tidak ada IP atau hostname yang diberikan! Gunakan: sshcpid.sh <ipserver>"
  exit 1
fi

# Menyalin public key ke server dalam satu sesi SSH
echo "🚀 Menyalin public key ke server..."
ssh "$HOST" <<EOF
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  touch ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
  
  [ "$HAS_KEY_1" = true ] && grep -qxF "$(<"$PUBLIC_KEY_1")" ~/.ssh/authorized_keys || echo "$(<"$PUBLIC_KEY_1")" >> ~/.ssh/authorized_keys
  [ "$HAS_KEY_2" = true ] && grep -qxF "$(<"$PUBLIC_KEY_2")" ~/.ssh/authorized_keys || echo "$(<"$PUBLIC_KEY_2")" >> ~/.ssh/authorized_keys
EOF

if [ $? -eq 0 ]; then
  echo "✅ Public key berhasil ditambahkan ke server!"
  echo "🔹 Sekarang Anda bisa login dengan 'ssh $HOST' tanpa password."
else
  echo "❌ Gagal menambahkan public key. Periksa koneksi atau izin akses."
  exit 1
fi
