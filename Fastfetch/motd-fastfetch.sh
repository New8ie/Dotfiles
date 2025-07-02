#!/bin/bash

# === Tambahkan PATH untuk environment tertentu ===
export PATH="/snap/bin:/usr/local/bin:$PATH"

# === DETEKSI OS & DISTRO ===
os_name="$(uname -s)"
distro="$(grep -E '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')"
arch="$(uname -m)"
is_rpi=false

# Deteksi Raspberry Pi
if grep -qi 'Raspberry Pi' /proc/cpuinfo 2>/dev/null; then
    is_rpi=true
fi

# === TENTUKAN LOGO SESUAI OS ===
case "$os_name" in
    Darwin)
        logo_name="macos-logo.png"
        ;;
    Linux)
        if [ "$is_rpi" = true ]; then
            logo_name="raspberrypi-logo.png"
        elif [[ "$distro" == "ubuntu" ]]; then
            logo_name="ubuntu-logo.png"
        elif [[ "$distro" == "debian" ]]; then
            logo_name="debian-logo.png"
        else
            logo_name="linux-generic-logo.png"
        fi
        ;;
    *)
        logo_name="unknown-logo.png"
        ;;
esac

# === LOKASI LOGO (ubah ke direktori fastfetch) ===
image_path="$HOME/.config/fastfetch/logo/$logo_name"

# === CETAK FASTFETCH TANPA LOGO ===
fastfetch_output=$(fastfetch --logo none)
output_lines=$(echo "$fastfetch_output" | wc -l)
IFS=$'\n' read -rd '' -a output_array <<<"$fastfetch_output"

# Tampilkan output fastfetch dengan lolcat
for line in "${output_array[@]}"; do
    echo -e "$line"
done | lolcat

# === HITUNG OFFSET UNTUK POSISI GAMBAR DI KANAN ===
vertical_offset=$((output_lines - 2))     # naik ke atas
horizontal_offset=50                      # geser ke kanan

printf "\033[%dA" "$vertical_offset"
printf "\033[%dC" "$horizontal_offset"

# === TAMPILKAN LOGO GAMBAR JIKA TERSEDIA ===
if [[ -f "$image_path" ]]; then
    if command -v imgcat &>/dev/null; then
        imgcat "$image_path"
    elif command -v /usr/local/bin/imgcat &>/dev/null; then
        /usr/local/bin/imgcat "$image_path"
    elif command -v viu &>/dev/null; then
        viu -w 30 -h 15 "$image_path"
    elif command -v chafa &>/dev/null; then
        chafa "$image_path"
    else
        echo "[imgcat/viu/chafa tidak tersedia]" >&2
    fi
else
    echo "[Logo '$logo_name' tidak ditemukan di $image_path]" >&2
fi


# 3️⃣ Informasi tambahan
echo -e "📅  $(date)"| lolcat

if [[ "$(uname)" == "Darwin" ]]; then
  boot_time=$(sysctl -n kern.boottime | awk -F'[=,]' '{print $2}' | tr -d ' ')
  now=$(date +%s)
  up=$((now - boot_time))
  days=$((up / 86400))
  hours=$(( (up % 86400) / 3600 ))
  mins=$(( (up % 3600) / 60 ))
  echo -e "🕒  Uptime: ${days}d ${hours}h ${mins}m" | lolcat
fi

echo -e "📡  IP Address :" | lolcat
for iface in en0 en1; do
  ip=$(ipconfig getifaddr "$iface" 2>/dev/null)
  [[ -n "$ip" ]] && echo "   $iface: $ip" | lolcat
done

if command -v last >/dev/null; then
  last_login=$(last -n 1 "$USER" | head -n 1)
  echo -e "👤  Last Login : $last_login" | lolcat
fi
