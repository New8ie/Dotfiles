#!/bin/bash

# Deteksi nama distribusi OS saat ini
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    distro="macos"
elif [[ -f /etc/os-release ]]; then
    # Linux (termasuk Raspberry Pi OS)
    distro=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
    # Deteksi khusus Raspberry Pi
    if grep -qi "raspbian" /etc/os-release || grep -qi "raspberry" /proc/cpuinfo; then
        distro="raspbian"
    fi
else
    # Fallback
    distro=$(uname -s | tr '[:upper:]' '[:lower:]')
fi

# Tampilkan informasi sistem dan logo dengan neofetch + lolcat
neofetch --ascii_distro "${distro}_small" | lolcat

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
