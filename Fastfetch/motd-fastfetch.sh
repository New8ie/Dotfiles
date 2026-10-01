#!/usr/bin/env zsh
# ~/.config/fastfetch/motd-fastfetch.sh

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# =============================================================================
# PATH
# =============================================================================
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.local/bin:$HOME/.config/iterm2/bin:$PATH"

# =============================================================================
# DETEKSI OS & DISTRO
# =============================================================================
os_name="$(uname -s)"
distro=""
is_rpi=false

if [[ "$os_name" == "Linux" ]]; then
  [[ -f /etc/os-release ]] && distro="$(awk -F= '/^ID=/ {gsub(/"/, "", $2); print $2}' /etc/os-release 2>/dev/null)"
  [[ -f /proc/cpuinfo ]] && grep -qi 'Raspberry Pi' /proc/cpuinfo 2>/dev/null && is_rpi=true
fi

# =============================================================================
# FASTFETCH
# =============================================================================
echo
if command -v fastfetch >/dev/null 2>&1; then
  fastfetch 2>/dev/null | lolcat
else
  echo "Fastfetch not installed" | lolcat
fi

# =============================================================================
# PEMBATAS
# =============================================================================
echo "----------------------------------------------------" | lolcat

# =============================================================================
# TANGGAL & UPTIME
# =============================================================================
echo -e "📅  $(date '+%a, %d %b %Y %H:%M:%S %Z')" | lolcat

if [[ "$os_name" == "Darwin" ]]; then
  boot_time="$(sysctl -n kern.boottime 2>/dev/null | awk -F'[=,]' '{print $2}' | tr -d ' ')"
  now=$(date +%s)
  if [[ "$boot_time" =~ ^[0-9]+$ ]]; then
    up=$((now - boot_time))
    echo -e "🕒  Uptime : $((up / 86400))d $(((up % 86400) / 3600))h $(((up % 3600) / 60))m" | lolcat
  fi
else
  if command -v uptime >/dev/null 2>&1; then
    up_text="$(uptime -p 2>/dev/null || uptime)"
    echo -e "🕒  Uptime : ${up_text}" | lolcat
  fi
fi

# =============================================================================
# IP ADDRESS (Direct AWK without pipe hangs)
# =============================================================================
echo -e "🌐  IP Address :" | lolcat

if [[ "$os_name" == "Darwin" ]]; then
  ifconfig | awk '/inet / && $2 !~ /^127\./ && $2 !~ /^169\.254\./ {print "  • " $2}' | lolcat
else
  ip -4 addr show 2>/dev/null | awk '/inet / && $2 !~ /^127\./ && $2 !~ /^169\.254\./ {split($2, a, "/"); print "  • " a[1]}' | awk '{print "  • " $0}' | lolcat
fi

# =============================================================================
# LAST LOGIN
# =============================================================================
if command -v last >/dev/null 2>&1; then
  last_login="$(last -n 1 "$USER" 2>/dev/null | head -n 1)"
  [[ -n "$last_login" ]] && echo -e "👤  Last Login : $last_login" | lolcat
fi

# =============================================================================
# LOAD EXTERNAL FUNCTIONS
# =============================================================================
functions_dir="$HOME/.config/zsh/functions"

if [[ -d "$functions_dir" ]]; then
  files=("$functions_dir"/*.zsh(N))

  if [[ ${#files[@]} -gt 0 ]]; then
    echo "🔧  Loaded Functions :" | lolcat
    for func in "${files[@]}"; do
      if [[ -f "$func" && -r "$func" ]]; then
        source "$func" 2>/dev/null
        echo "   • ${func:t:r} loaded" | lolcat
      fi
    done
  fi
fi

# =============================================================================
# FOOTER
# =============================================================================
echo "----------------------------------------------------" | lolcat