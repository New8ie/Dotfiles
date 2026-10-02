#!/usr/bin/env zsh
# ~/.config/fastfetch/motd-fastfetch.sh
# Clean MOTD for Zsh + Fastfetch + iTerm2
# Cross-platform: macOS + Linux + Raspberry Pi

# =============================================================================
# PATH
# =============================================================================

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.local/bin:$HOME/.config/iterm2/bin:$PATH"

# =============================================================================
# DETEKSI OS
# =============================================================================

os_name="$(uname -s)"

distro=""

# Linux: baca distro dari /etc/os-release
if [[ "$os_name" == "Linux" && -f /etc/os-release ]]; then
  distro="$(
  awk -F= '
    /^ID=/ {
      gsub(/"/, "", $2)
  print $2
}
' /etc/os-release 2>/dev/null
  )"
fi

# Raspberry Pi hanya dicek pada Linux
is_rpi=false

if [[ "$os_name" == "Linux" && -f /proc/cpuinfo ]]; then
  if grep -qi 'Raspberry Pi' /proc/cpuinfo 2>/dev/null; then
    is_rpi=true
  fi
fi

# =============================================================================
# LOGO SESUAI OS
# =============================================================================

case "$os_name" in

  Darwin)
    logo_name="macos-logo.png"
    ;;

  Linux)

    if [[ "$is_rpi" == true ]]; then
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

image_path="$HOME/.config/fastfetch/logo/$logo_name"

# =============================================================================
# FASTFETCH TANPA LOGO
# =============================================================================

if command -v fastfetch >/dev/null 2>&1; then

  fastfetch_output="$(fastfetch --disable-logging 2>/dev/null)"

  # Fallback apabila --disable-logging tidak didukung
  if [[ -z "$fastfetch_output" ]]; then
    fastfetch_output="$(fastfetch 2>/dev/null)"
  fi

else

  fastfetch_output="Fastfetch not installed"

fi

output_lines=$(echo "$fastfetch_output" | wc -l | tr -d ' ')

output_array=("${(@f)fastfetch_output}")

echo

for line in "${output_array[@]}"; do
  echo -e "$line"
done | lolcat

# =============================================================================
# TAMPILKAN LOGO DI KANAN (iTerm2)
# =============================================================================

vertical_offset=$((output_lines - 2))
horizontal_offset=80

printf "\033[%dA" "$vertical_offset"
printf "\033[%dC" "$horizontal_offset"

if [[ -f "$image_path" && "$TERM" == "xterm-256color" ]] \
   && command -v imgcat >/dev/null 2>&1; then

  imgcat "$image_path"

fi

printf "\033[%dB" "$vertical_offset"

# =============================================================================
# PEMBATAS
# =============================================================================

echo "─────────────────────────────────────────────" | lolcat

# =============================================================================
# TANGGAL & UPTIME
# =============================================================================

echo -e "📅  $(date '+%a, %d %b %Y %H:%M:%S %Z')" | lolcat

if [[ "$os_name" == "Darwin" ]]; then

  # ---------------------------------------------------------------------------
  # macOS Uptime
  # ---------------------------------------------------------------------------

  boot_time="$(
    sysctl -n kern.boottime 2>/dev/null |
    awk -F'[=,]' '{print $2}' |
    tr -d ' '
  )"

  now=$(date +%s)

  if [[ "$boot_time" =~ ^[0-9]+$ ]]; then

    up=$((now - boot_time))

    days=$((up / 86400))
    hours=$(((up % 86400) / 3600))
    mins=$(((up % 3600) / 60))

    echo -e "🕒  Uptime : ${days}d ${hours}h ${mins}m" | lolcat

  else

    echo -e "🕒  Uptime : unavailable" | lolcat

  fi

else

  # ---------------------------------------------------------------------------
  # Linux Uptime
  # ---------------------------------------------------------------------------

  if command -v uptime >/dev/null 2>&1; then

    if uptime -p >/dev/null 2>&1; then

      uptime -p |
        sed 's/^/🕒  /' |
        lolcat

    else

      echo -e "🕒  Uptime : $(uptime)" | lolcat

    fi

  else

    echo -e "🕒  Uptime : unavailable" | lolcat

  fi

fi

# =============================================================================
# IP ADDRESS TANPA DOCKER
# =============================================================================

echo -e "🌐  IP Address :" | lolcat

if [[ "$os_name" == "Darwin" ]]; then

  # ---------------------------------------------------------------------------
  # macOS
  #
  # macOS menggunakan BSD utilities.
  # Tidak menggunakan command "ip" dan tidak menggunakan grep -P.
  # ---------------------------------------------------------------------------

  if command -v ifconfig >/dev/null 2>&1; then

    ifconfig |
      awk '
/inet / {
  ip=$2

  if (ip !~ /^127\./ &&
    ip !~ /^169\.254\./ &&
    ip !~ /^172\.(1[6-9]|2[0-9]|3[0-1])\./) {
    print ip
  }
}
' |
        while read -r ip_address; do

          if [[ -n "$ip_address" ]]; then
            echo -e "  • ${ip_address}" | lolcat
          fi

        done

    fi

  else

    # ---------------------------------------------------------------------------
    # Linux
    #
    # Prioritas menggunakan iproute2.
    # Tidak menggunakan grep -P agar tetap portable.
    # ---------------------------------------------------------------------------

    if command -v ip >/dev/null 2>&1; then

      ip -4 addr show |
        awk '
/inet / {
  split($2, a, "/")
  ip=a[1]

  if (ip !~ /^127\./ &&
    ip !~ /^169\.254\./ &&
    ip !~ /^172\.(1[6-9]|2[0-9]|3[0-1])\./) {
    print ip
  }
}
' |
      while read -r ip_address; do

        if [[ -n "$ip_address" ]]; then
          echo -e "  • ${ip_address}" | lolcat
        fi

      done

  elif command -v ifconfig >/dev/null 2>&1; then

    # -------------------------------------------------------------------------
    # Fallback apabila Linux tidak mempunyai command "ip"
    # -------------------------------------------------------------------------

    ifconfig |
      awk '
/inet / {
  ip=$2

  if (ip !~ /^127\./ &&
    ip !~ /^169\.254\./ &&
    ip !~ /^172\.(1[6-9]|2[0-9]|3[0-1])\./) {
    print ip
  }
}
' |
