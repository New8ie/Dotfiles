#!/bin/bash

# Fungsi untuk mengonversi netmask dari heksadesimal ke desimal
convert_netmask() {
  hexmask=$(echo "$1" | sed 's/^0x//I') # Menghapus awalan 0x jika ada

  # Jika hexmask bukan heksadesimal yang valid, return nilai asli
  if [[ ! "$hexmask" =~ ^[0-9A-Fa-f]+$ ]]; then
    echo "$1"
    return
  fi

  # Pastikan selalu 8 karakter untuk menghindari error parsing
  hexmask=$(printf "%08X" $((16#$hexmask)))

  decmask=""
  for i in {0..3}; do
    octet=$((16#${hexmask:i*2:2})) # Mengonversi dua karakter heksadesimal ke desimal
    decmask="$decmask.$octet"
  done
  echo ${decmask:1} # Menghapus titik pertama
}

# Mendapatkan daftar interface, IP, dan netmask yang valid
ifconfig | awk '
  /^en[0-9]|^eth[0-9]/ { iface=$1 } 
  /inet / && !/127.0.0.1/ {print iface, $2, $4}' | while read iface ip hexmask; do

  # Jika hexmask sudah dalam format desimal (xxx.xxx.xxx.xxx), gunakan langsung
  if [[ "$hexmask" == *.* ]]; then
    netmask="$hexmask"
  elif [[ "$hexmask" == 0x* ]]; then
    hexmask=${hexmask:2}                  # Hapus hanya satu awalan 0x jika ada
    netmask=$(convert_netmask "$hexmask") # Konversi ke format desimal
  else
    continue # Lewati jika hexmask tidak valid
  fi

  # Menampilkan output dengan warna menggunakan `printf`
  printf "\e[1;36mInterface:\e[0m \e[1;32m%s\e[0m | \e[1;33mIP Address:\e[0m \e[1;35m%s\e[0m | \e[1;36mSubnet Mask:\e[0m \e[1;31m%s\e[0m\n" "$iface" "$ip" "$netmask"
done
