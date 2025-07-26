# ==============================================================================
#                                PATH dan Variabel
# ==============================================================================

# PATH Base
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# PATH Extras : Venv, lokal, plugin, apps , script
export PATH="$HOME/.config/venv/myvenv/bin:$PATH"
export PATH="$HOME/.config/script:$PATH"
export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.local/share/nvim/lazy-rocks/bin:$PATH"

# Path lolcat (via Ruby gem, jika digunakan)
if [[ -d "$HOME/.gem/ruby/3.2.0/bin" ]]; then
  export PATH="$HOME/.gem/ruby/3.2.0/bin:$PATH"
fi

# Python & lain-lain
export XDG_CONFIG_HOME="$HOME/.config"
export ARCHFLAGS="-arch $(uname -m)"

# ==============================================================================
#                                PYENV (Python)
# ==============================================================================
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv &> /dev/null; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# ==============================================================================
#                         Konfigurasi ZSH & Oh My Zsh
# ==============================================================================
export ZSH="$HOME/.oh-my-zsh"
export ZSH_DISABLE_COMPFIX=true
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  web-search
  zsh-you-should-use
  zsh-bat
)

source "$ZSH/oh-my-zsh.sh"
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ==============================================================================
#                            Deteksi Sistem Operasi
# ==============================================================================
OS_TYPE="$(uname -s)"
LINUX_DISTRO=""

detect_linux_distro() {
  if [[ -f /etc/debian_version ]]; then
    LINUX_DISTRO="debian"
    export DISTRO="Debian"
  elif [[ -f /etc/arch-release ]]; then
    LINUX_DISTRO="arch"
    export DISTRO="Arch"
  elif [[ -f /etc/redhat-release ]]; then
    LINUX_DISTRO="redhat"
    export DISTRO="RedHat"
  else
    export DISTRO="OtherLinux"
  fi
}

if [[ "$OS_TYPE" == "Darwin" ]]; then
  export PLATFORM="macOS"
elif [[ "$OS_TYPE" == "Linux" ]]; then
  export PLATFORM="Linux"
  detect_linux_distro
else
  export PLATFORM="Unknown"
  export DISTRO="Unknown"
fi

# ==============================================================================
#                             Custom Alias File
# ==============================================================================
[[ -f "$HOME/.config/zsh/alias.zsh" ]] && source "$HOME/.config/zsh/alias.zsh"

# ==============================================================================
#                                Integrasi Zoxide
# ==============================================================================
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

# ==============================================================================
#                     Syntax Highlighting dan Warna GRC
# ==============================================================================
if [[ "$PLATFORM" == "macOS" ]]; then
  [[ -s "/opt/homebrew/etc/grc.zsh" ]] && source "/opt/homebrew/etc/grc.zsh"
elif [[ "$DISTRO" == "Debian" ]]; then
  [[ -s "/etc/grc.zsh" ]] && source "/etc/grc.zsh"
elif [[ "$DISTRO" == "Arch" ]]; then
  [[ -s "/usr/share/grc/grc.zsh" ]] && source "/usr/share/grc/grc.zsh"
fi

# ==============================================================================
#                              Preferensi Editor
# ==============================================================================
if command -v nvim &> /dev/null; then
  export EDITOR='nvim'
elif command -v code &> /dev/null; then
  export EDITOR='code -w'
else
  export EDITOR='nano'
fi

# ==============================================================================
#                            Skrip MOTD Login
# ==============================================================================
if [[ -x "$HOME/.config/fastfetch/mod-fastfetch.sh" ]]; then
  "$HOME/.config/fastfetch/mod-fastfetch.sh"
else
  echo "[.config/fastfetch/mod-fastfetch.sh tidak ditemukan atau tidak executable]" >&2
fi
