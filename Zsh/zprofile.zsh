# Deteksi OS
OS_TYPE=$(uname)

################# Source grc.zsh jika tersedia #################

# Path default grc.zsh
if [ "$OS_TYPE" = "Darwin" ]; then
  # macOS: grc biasanya dipasang via Homebrew
  if [ -f "/opt/homebrew/etc/grc.zsh" ]; then
    source "/opt/homebrew/etc/grc.zsh"
  fi
elif [ "$OS_TYPE" = "Linux" ]; then
  # Linux: lokasi standar
  if [ -f "/etc/grc.zsh" ]; then
    source "/etc/grc.zsh"
  fi
fi

################# Inisialisasi Brew (macOS) #################

if [ "$OS_TYPE" = "Darwin" ]; then
  # Inisialisasi Homebrew environment
  if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

################# Jalankan Skrip Animasi Login #################

MOTD_SCRIPT="$HOME/.config/neofetch/motd-script.sh"
if [ -f "$MOTD_SCRIPT" ]; then
  bash "$MOTD_SCRIPT"
fi