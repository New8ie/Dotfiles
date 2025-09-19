#!/bin/bash

# Jalankan dengan hak sudo
if [[ "$EUID" -ne 0 ]]; then
  echo "Jalankan dengan sudo!"
  exit 1
fi

# Cari semua partisi bertipe NTFS dari disk eksternal
ntfs_disks=$(diskutil list | awk '/external/ {ext=1} /internal/ {ext=0} ext && /Windows_NTFS/ {print $NF}')

if [[ -z "$ntfs_disks" ]]; then
  echo "Tidak ada partisi NTFS eksternal terdeteksi."
  exit 0
fi

for disk in $ntfs_disks; do
  dev_path="/dev/$disk"
  volume_name=$(diskutil info "$dev_path" | awk -F: '/Volume Name/ {gsub(/^ +/, "", $2); print $2}')
  mount_point="/Volumes/${volume_name}_RW"

  echo "⏏️ Unmounting $dev_path..."
  diskutil unmount "$dev_path"

  echo "📁 Membuat mount point di $mount_point"
  mkdir -p "$mount_point"

  echo "📦 Mounting $dev_path ke $mount_point"
  /opt/homebrew/bin/ntfs-3g "$dev_path" "$mount_point" -o local -o allow_other -o auto_xattr -o auto_cache || echo "❌ Gagal mount $dev_path"
done

echo "✅ Semua partisi NTFS eksternal telah diproses."
