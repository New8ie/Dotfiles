# ==============================================================================
#                                PATH dan Variabel
# ==============================================================================

# PATH Base
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/home/fachmi/.local/bin/:/usr/games:"

# PATH Extras : Venv, lokal, plugin, apps , script
export PATH="$HOME/.config/venv/myvenv/bin:$PATH"
export PATH="$HOME/.config/script:$PATH"
export PATH="$HOME/.config/fastfetch/bin:$PATH"
export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.local/share/nvim/lazy-rocks/bin:$PATH"

# Path imgcat (iTerm2 utils)
export PATH="$HOME/.config/iterm2/bin:$PATH"

# Path lolcat (via Ruby gem, jika digunakan)
if [[ -d "$HOME/.gem/ruby/3.2.0/bin" ]]; then
  export PATH="$HOME/.gem/ruby/3.2.0/bin:$PATH"
fi

# Alias imgcat biar gampang dipakai
alias imgcat="$HOME/.config/iterm2/bin/imgcat"

# ============================================
# 🧱 Compiler Flags for Building Python
# ============================================
export LDFLAGS="-L/opt/homebrew/opt/zlib/lib -L/opt/homebrew/opt/sqlite/lib"
export CPPFLAGS="-I/opt/homebrew/opt/zlib/include -I/opt/homebrew/opt/sqlite/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/zlib/lib/pkgconfig:/opt/homebrew/opt/sqlite/lib/pkgconfig"

export XDG_CONFIG_HOME="$HOME/.config"
export ARCHFLAGS="-arch $(uname -m)"

# ============================================
# 🐍 PYENV: Manajemen Python
# ============================================
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

if command -v pyenv &> /dev/null; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# ============================================
# 🧪 CONDA (manual activation only)
# ============================================
if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
  . "/opt/miniconda3/etc/profile.d/conda.sh"
  conda config --set auto_activate false
fi

[[ -f "$HOME/.config/zsh/alias_venv.zsh" ]] && source "$HOME/.config/zsh/alias_venv.zsh"

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
  [[ -s "/etc/grc.zsh" ]] && source /etc/grc.zsh
elif [[ "$DISTRO" == "Arch" ]]; then
  [[ -s "/usr/share/grc/grc.zsh" ]] && source /usr/share/grc/grc.zsh
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
if [[ -x "$HOME/.config/fastfetch/motd-fastfetch.sh" ]]; then
  "$HOME/.config/fastfetch/motd-fastfetch.sh"
else
  echo "[.config/fastfetch/motd-fastfetch.sh tidak ditemukan atau tidak executable]" >&2
fi


# ==============================================================================
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
# Docker CLI completions
# ==============================================================================

fpath=(/Users/fachmi/.docker/completions $fpath)

# ==============================================================================
#                             Custom Alias File
# ==============================================================================
[[ -f "$HOME/.config/zsh/alias.zsh" ]] && source "$HOME/.config/zsh/alias.zsh"
# Load custom alias untuk venv
[[ -f "$HOME/.config/zsh/alias_venv.zsh" ]] && source "$HOME/.config/zsh/alias_venv.zsh"


# ==============================================================================  
# Load zsh completion system
autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit


if [ -f /usr/share/bash-completion/completions/service ]; then
  source /usr/share/bash-completion/completions/service
fi
# ==============================================================================  