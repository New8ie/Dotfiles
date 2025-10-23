#!/usr/bin/env zsh
# ~/.config/fastfetch/motd-fastfetch.sh
# Clean MOTD for Zsh + Fastfetch + iTerm2

# === PATH ===
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.local/bin:$HOME/.config/iterm2/bin:$PATH"

# === DETEKSI OS ===
os_name="$(uname -s)"
distro="$(grep -E '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')"
is_rpi=false
grep -qi 'Raspberry Pi' /proc/cpuinfo 2>/dev/null && is_rpi=true

# === LOGO SESUAI OS ===
case "$os_name" in
  Darwin) logo_name="macos-logo.png" ;;
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
  *) logo_name="unknown-logo.png" ;;
esac

image_path="$HOME/.config/fastfetch/logo/$logo_name"

# === FASTFETCH TANPA LOGO ===
fastfetch_output=$(fastfetch --disable-logging 2>/dev/null || fastfetch)
output_lines=$(echo "$fastfetch_output" | wc -l)
output_array=("${(@f)fastfetch_output}")

echo
for line in "${output_array[@]}"; do
  echo -e "$line"
done | lolcat

# === TAMPILKAN LOGO DI KANAN (iTerm2) ===
vertical_offset=$((output_lines - 2))
horizontal_offset=80
printf "\033[%dA" "$vertical_offset"
printf "\033[%dC" "$horizontal_offset"
if [[ -f "$image_path" && "$TERM" == "xterm-256color" ]] && command -v imgcat &>/dev/null; then
  imgcat "$image_path"
fi
printf "\033[%dB" "$vertical_offset"
# === PEMBATAS ===
echo "─────────────────────────────────────────────" | lolcat
# === TANGGAL & UPTIME ===
echo -e "📅  $(date '+%a, %d %b %Y %H:%M:%S %Z')" | lolcat

if [[ "$os_name" == "Darwin" ]]; then
  boot_time=$(sysctl -n kern.boottime | awk -F'[=,]' '{print $2}' | tr -d ' ')
  now=$(date +%s)
  up=$((now - boot_time))
  days=$((up / 86400))
  hours=$(((up % 86400) / 3600))
  mins=$(((up % 3600) / 60))
  echo -e "🕒  Uptime : ${days}d ${hours}h ${mins}m" | lolcat
else
  uptime -p | sed 's/^/🕒  /' | lolcat
fi

# === IP ADDRESS TANPA DOCKER ===
echo -e "🌐  IP Address :" | lolcat
ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | \
grep -Ev '^(172\.|127\.|169\.254)' | \
while read -r ip; do
  echo -e "  • ${ip}" | lolcat
done
# === LAST LOGIN ===
if command -v last >/dev/null; then
  last_login=$(last -n 1 "$USER" | head -n 1)
  echo -e "👤  Last Login : $last_login" | lolcat
fi
# === LOAD EXTERNAL FUNCTIONS ===
functions_dir="$HOME/.config/zsh/functions"
if [[ -d "$functions_dir" ]]; then
  files=("$functions_dir"/*.zsh)
  if [[ ${#files[@]} -eq 0 || ! -e "${files[1]}" ]]; then
    echo "⚙️  External functions empty" | lolcat
  else
    echo "🔧  Loaded Functions :" | lolcat
    count=0
    for func in "${files[@]}"; do
      if [[ -f "$func" && -r "$func" ]]; then
        func_name="${func:t:r}"   # basename tanpa ekstensi (zsh style)
        source "$func"
        echo "   • $func_name loaded" | lolcat
        ((count++))
      fi
    done
  fi
fi
echo "─────────────────────────────────────────────" | lolcat
echo ""
