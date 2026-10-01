#!/usr/bin/env zsh

# =============================================================================
# MOTD FASTFETCH
# =============================================================================
# Clean MOTD for Zsh + Fastfetch + optional iTerm2 image
#
# Supported:
#   - macOS
#   - Debian
#   - Ubuntu
#   - Raspberry Pi / Raspberry Pi OS
#
# Design goals:
#   - Safe for SSH
#   - Safe for root and normal users
#   - No shell-state modification
#   - No Linux cursor positioning
#   - iTerm2 image only on macOS
#   - Fastfetch version independent
# =============================================================================

# =============================================================================
# ZSH OPTIONS
# =============================================================================

# Jangan error hanya karena glob tidak menemukan file.
setopt NO_NOMATCH

# =============================================================================
# PATH
# =============================================================================

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.local/bin:$HOME/.config/iterm2/bin:$PATH"

# =============================================================================
# SCRIPT DIRECTORY
# =============================================================================
#
# Logo dicari relatif terhadap lokasi script.
# Ini penting agar:
#
#   /home/fachmi/.config/fastfetch/motd-fastfetch.sh
#
# tetap bisa mencari:
#
#   /home/fachmi/.config/fastfetch/logo/*.png
#
# walaupun script dijalankan sebagai root.
# =============================================================================

script_dir="${0:A:h}"

logo_dir="$script_dir/logo"

# =============================================================================
# OPTIONAL COLORS / LOLCAT
# =============================================================================

if (( $+commands[lolcat] )); then
  use_lolcat=true
else
  use_lolcat=false
fi

# =============================================================================
# OUTPUT HELPER
# =============================================================================

print_line() {
  local text="$1"

  if [[ "$use_lolcat" == true ]]; then
    printf '%s\n' "$text" | lolcat
  else
    printf '%s\n' "$text"
  fi
}

# =============================================================================
# DETEKSI OS
# =============================================================================

os_name="$(uname -s 2>/dev/null)"

distro=""

if [[ "$os_name" == "Linux" && -r /etc/os-release ]]; then

  distro="$(
    awk -F= '
      /^ID=/ {
        gsub(/"/, "", $2)
        print tolower($2)
        exit
      }
    ' /etc/os-release 2>/dev/null
  )"

fi

# =============================================================================
# DETEKSI RASPBERRY PI
# =============================================================================

is_rpi=false

if [[ "$os_name" == "Linux" ]]; then

  if [[ -r /proc/device-tree/model ]]; then

    if grep -qi 'raspberry pi' /proc/device-tree/model 2>/dev/null; then
      is_rpi=true
    fi

  elif [[ -r /proc/cpuinfo ]]; then

    if grep -qi 'raspberry pi' /proc/cpuinfo 2>/dev/null; then
      is_rpi=true
    fi

  fi

fi

# =============================================================================
# LOGO
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

image_path="$logo_dir/$logo_name"

# =============================================================================
# FASTFETCH
# =============================================================================
#
# Jangan menggunakan:
#
#   fastfetch --disable-logging
#
# karena opsi tersebut tidak tersedia pada Fastfetch 2.69.0.
#
# Fastfetch dijalankan langsung dan output ditangkap.
# =============================================================================

if (( $+commands[fastfetch] )); then

  fastfetch_output="$(fastfetch 2>/dev/null)"

  fastfetch_exit=$?

  if (( fastfetch_exit != 0 || -z "$fastfetch_output" )); then
    fastfetch_output="Fastfetch failed"
  fi

else

  fastfetch_output="Fastfetch not installed"

fi

# =============================================================================
# FASTFETCH OUTPUT
# =============================================================================

output_array=("${(@f)fastfetch_output}")

output_lines=${#output_array[@]}

printf '\n'

for line in "${output_array[@]}"; do

  if [[ "$use_lolcat" == true ]]; then
    printf '%s\n' "$line" | lolcat
  else
    printf '%s\n' "$line"
  fi

done

# =============================================================================
# iTERm2 IMAGE
# =============================================================================
#
# PENTING:
#
# Fitur ini HANYA dijalankan pada macOS.
#
# Tidak ada:
#
#   ESC[...A
#   ESC[...C
#   ESC[...B
#
# pada Linux / Debian / Ubuntu / Raspberry Pi.
#
# Ini mencegah cursor terminal SSH rusak.
# =============================================================================

if [[ "$os_name" == "Darwin" &&
      "$TERM" == "xterm-256color" &&
      -f "$image_path" ]]; then

  imgcat_path=""

  # Prioritas path milik konfigurasi user.
  if [[ -x "$HOME/.config/iterm2/bin/imgcat" ]]; then

    imgcat_path="$HOME/.config/iterm2/bin/imgcat"

  elif [[ -x "$HOME/.iterm2/imgcat" ]]; then

    imgcat_path="$HOME/.iterm2/imgcat"

  elif [[ -x "/opt/homebrew/bin/imgcat" ]]; then

    imgcat_path="/opt/homebrew/bin/imgcat"

  elif [[ -x "/usr/local/bin/imgcat" ]]; then

    imgcat_path="/usr/local/bin/imgcat"

  fi

  if [[ -n "$imgcat_path" ]]; then

    vertical_offset=$((output_lines - 2))

    if (( vertical_offset > 0 )); then

      horizontal_offset=80

      printf '\033[%dA' "$vertical_offset"
      printf '\033[%dC' "$horizontal_offset"

      "$imgcat_path" "$image_path" 2>/dev/null

      printf '\033[%dB' "$vertical_offset"

    fi

  fi

fi

# =============================================================================
# PEMBATAS
# =============================================================================

print_line "─────────────────────────────────────────────"

# =============================================================================
# TANGGAL
# =============================================================================

print_line "📅  $(date '+%a, %d %b %Y %H:%M:%S %Z')"

# =============================================================================
# UPTIME
# =============================================================================

if [[ "$os_name" == "Darwin" ]]; then

  # ---------------------------------------------------------------------------
  # macOS
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

    print_line "🕒  Uptime : ${days}d ${hours}h ${mins}m"

  else

    print_line "🕒  Uptime : unavailable"

  fi

else

  # ---------------------------------------------------------------------------
  # Linux
  # ---------------------------------------------------------------------------

  if (( $+commands[uptime] )); then

    uptime_output="$(uptime -p 2>/dev/null)"

    if [[ -n "$uptime_output" ]]; then

      print_line "🕒  ${uptime_output}"

    else

      print_line "🕒  Uptime : $(uptime 2>/dev/null)"

    fi

  else

    print_line "🕒  Uptime : unavailable"

  fi

fi

# =============================================================================
# IP ADDRESS
# =============================================================================

print_line "🌐  IP Address :"

if [[ "$os_name" == "Darwin" ]]; then

  # ---------------------------------------------------------------------------
  # macOS
  # ---------------------------------------------------------------------------

  if (( $+commands[ifconfig] )); then

    ifconfig 2>/dev/null |
      awk '
        /inet / {
          ip=$2

          if (
            ip !~ /^127\./ &&
            ip !~ /^169\.254\./ &&
            ip !~ /^172\.(1[6-9]|2[0-9]|3[0-1])\./
          ) {
            print ip
          }
        }
      ' |
      while IFS= read -r ip_address; do

        [[ -z "$ip_address" ]] && continue

        print_line "  • ${ip_address}"

      done

  fi

else

  # ---------------------------------------------------------------------------
  # Linux
  #
  # Menggunakan interface name agar alamat Docker/container tidak ikut.
  # ---------------------------------------------------------------------------

  if (( $+commands[ip] )); then

    ip -4 -o addr show scope global 2>/dev/null |
      awk '
        {
          interface=$2
          address=$4
          sub(/\/.*/, "", address)

          if (
            interface !~ /^(docker|br-|veth|cni|flannel|virbr|podman)/ &&
            address !~ /^127\./ &&
            address !~ /^169\.254\./
          ) {
            print address
          }
        }
      ' |
      while IFS= read -r ip_address; do

        [[ -z "$ip_address" ]] && continue

        print_line "  • ${ip_address}"

      done

  elif (( $+commands[ifconfig] )); then

    # -------------------------------------------------------------------------
    # Linux fallback
    # -------------------------------------------------------------------------

    ifconfig 2>/dev/null |
      awk '
        /inet / {
          ip=$2

          if (
            ip !~ /^127\./ &&
            ip !~ /^169\.254\./ &&
            ip !~ /^172\.(1[6-9]|2[0-9]|3[0-1])\./
          ) {
            print ip
          }
        }
      ' |
      while IFS= read -r ip_address; do

        [[ -z "$ip_address" ]] && continue

        print_line "  • ${ip_address}"

      done

  fi

fi

# =============================================================================
# LAST LOGIN
# =============================================================================

if (( $+commands[last] )); then

  last_login="$(last -n 1 "$USER" 2>/dev/null | head -n 1)"

  if [[ -n "$last_login" ]]; then

    print_line "👤  Last Login : $last_login"

  fi

fi

# =============================================================================
# EXTERNAL FUNCTIONS
# =============================================================================
#
# MOTD dijalankan sebagai CHILD PROCESS.
#
# Karena itu "source" function di sini tidak akan membuat function tersedia
# di shell induk (.zshrc).
#
# Kita hanya menampilkan function files yang tersedia.
#
# Tidak source file function di sini agar function tersebut tidak bisa
# mengubah environment, FD, PATH, alias, option Zsh, atau output MOTD.
# =============================================================================

functions_dir="$HOME/.config/zsh/functions"

if [[ -d "$functions_dir" ]]; then

  files=("$functions_dir"/*.zsh)

  valid_function_count=0

  for func in "${files[@]}"; do

    if [[ -f "$func" && -r "$func" ]]; then

      ((valid_function_count++))

    fi

  done

  if (( valid_function_count == 0 )); then

    print_line "⚙️  External functions empty"

  else

    print_line "🔧  Loaded Functions :"

    for func in "${files[@]}"; do

      if [[ -f "$func" && -r "$func" ]]; then

        func_name="${func:t:r}"

        print_line "   • ${func_name} available"

      fi

    done

  fi

fi

# =============================================================================
# FOOTER
# =============================================================================

print_line "─────────────────────────────────────────────"

printf '\n'

exit 0