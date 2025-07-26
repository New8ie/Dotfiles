#!/bin/bash

# Lokasi gambar
image_path="$HOME/.config/neofetch/macOS-1.png"

# Cek tinggi terminal
term_height=$(tput lines)

# Jalankan neofetch (tanpa ASCII art)
neofetch_output=$(neofetch --backend off)

# Hitung jumlah baris
output_lines=$(echo "$neofetch_output" | wc -l)
IFS=$'\n' read -rd '' -a output_array <<<"$neofetch_output"

# Print teks system info + efek lolcat
for line in "${output_array[@]}"; do
    echo -e "$line"
done | lolcat

# --- Geser kursor ke atas dan kanan untuk gambar PNG ---
# Tambah offset vertikal agar gambar agak ke bawah (misal +2 baris)
vertical_offset=$((output_lines - 2))
horizontal_offset=50  # Ubah sesuai panjang teks di kiri

# Geser kursor ke atas
printf "\033[%dA" "$vertical_offset"
# Geser kursor ke kanan
printf "\033[%dC" "$horizontal_offset"

# Tampilkan gambar (jika iTerm2)
if [[ -f "$image_path" && "$TERM_PROGRAM" == "iTerm.app" ]]; then
    imgcat "$image_path"
else
    echo "[Gambar tidak ditemukan atau imgcat tidak tersedia]"
fi

# Info tambahan
echo "" | lolcat
echo "System Uptime   : $(uptime -p)" | lolcat
echo "Today's Date    : $(date)" | lolcat

# Ambil user login terakhir
last_login=$(last -n 1 | head -n 1)
echo "Last User Login : $last_login" | lolcat

# IP remote (SSH)
remote_ip=$(who | grep "$(whoami)" | awk '{print $5}' | tr -d '()')
[ -z "$remote_ip" ] && remote_ip="Local Session"
echo "Remote IP       : $remote_ip" | lolcat