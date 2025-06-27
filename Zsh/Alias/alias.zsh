# ~/.config/zsh/alias.zsh

# =========================
# ALIAS UNTUK macOS
# =========================
if [[ "$PLATFORM" == "macOS" ]]; then
  
  alias rsdock="defaults write com.apple.dock ResetLaunchPad -bool true && killall Dock" ## reset Launchpad di Mac
  alias flushdns="sudo killall -HUP mDNSResponder" ## flush DNS cache
  alias cpwd='pwd | tr -d "\n" | pbcopy' ## menyalin path direktori saat ini
  alias caff="caffeinate -ism" ## mencegah Mac masuk ke mode tidur
  alias cl="fc -e -|pbcopy" ## menyalin output perintah terakhir
  alias cleanDS="find . -type f -name '*.DS_Store' -ls -delete" ## menghapus file .DS_Store
  alias showHidden='defaults write com.apple.finder AppleShowAllFiles TRUE' ## menampilkan file tersembunyi
  alias hideHidden='defaults write com.apple.finder AppleShowAllFiles FALSE' ## menyembunyikan file tersembunyi
  alias capc="screencapture -c" ## menangkap layar ke clipboard
  alias capic="screencapture -i -c" ## menangkap layar secara interaktif ke clipboard
  alias capiwc="screencapture -i -w -c" ## menangkap layar interaktif dengan window
  alias myip='curl ifconfig.me' ## menampilkan IP publik
  alias ipconfig="~/.local/bin/mylocalip.sh" ## menampilkan IP lokal dengan script bash
  alias mute="osascript -e 'set volume output muted true'" ## menonaktifkan suara
  alias unmute="osascript -e 'set volume output muted false'" ## mengaktifkan suara kembali
  alias restartfinder="killall Finder" ## me-restart Finder
  alias restartdock="killall Dock" ## me-restart Dock
  alias backupdock="defaults export com.apple.dock ~/Desktop/dock-backup.plist" ## menyimpan pengaturan Dock sebelum restart
  alias restoredock="defaults import com.apple.dock ~/Desktop/dock-backup.plist; killall Dock" ## mengembalikan pengaturan Dock setelah restart 
  alias wifi-status="networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print \$NF}' | xargs -I{} networksetup -getairportpower {}" ## melihat status Wi-Fi dengan mendeteksi antarmuka yang benar
  alias wifi-on="networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print \$NF}' | xargs -I{} networksetup -setairportpower {} on" ## mengaktifkan Wi-Fi secara otomatis di antarmuka yang benar
  alias wifi-off="networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print \$NF}' | xargs -I{} networksetup -setairportpower {} off" ## menonaktifkan Wi-Fi secara otomatis di antarmuka yang benar
  alias openhere="open ." ## membuka folder saat ini di Finder
  alias cleanup="rm -rf ~/Library/Caches/* && sudo purge" ## membersihkan file sementara dan cache
  
  # Aliases untuk macOS sama dengan linux

  alias listservices="launchctl list" ## menampilkan daftar layanan yang berjalan di macOS
  alias runningapps="ps aux | grep -v grep | grep -i" ## melihat proses aplikasi yang berjalan
  alias showroute="netstat -nr -f inet" ## untuk melihat routing table
  alias listport="sudo lsof -i -P -n | grep LISTEN" ## melihat port yang sedang listening
  alias killapp="pkill -f" ## menutup aplikasi secara paksa
  alias sysinfo="top -o cpu" ## menampilkan proses dengan penggunaan CPU tertinggi

  # Brew
  alias update="brew update && brew upgrade"
  alias inst="brew install"
  alias remove="brew uninstall"
  alias cleanup="brew cleanup"  # overwrite alias cleanup di atas untuk konsistensi

# =========================
# ALIAS UNTUK LINUX
# =========================
elif [[ "$PLATFORM" == "Linux" ]]; then
  # Aliases untuk Linux Sama dengan macOS 
  alias showroute="ip route show"
  alias myip="hostname -I | awk '{print \$1}'"
  alias listport="sudo lsof -i -P -n | grep LISTEN"
  alias netport="netstat -tulpn | grep LISTEN"
  alias sysinfo="top -o %CPU"
  alias runningapps="ps aux | grep -v grep | grep -i"
  alias killapp="pkill -f"

  if [[ "$DISTRO" == "Debian" ]]; then
    alias update="sudo apt update && sudo apt upgrade -y"
    alias inst="sudo apt install -y"
    alias remove="sudo apt remove -y"
    alias cleanup="sudo apt autoremove -y && sudo apt autoclean -y"
    alias flushdns="sudo systemd-resolve --flush-caches"

  elif [[ "$DISTRO" == "Arch" ]]; then
    alias update="sudo pacman -Syu"
    alias inst="sudo pacman -S"
    alias remove="sudo pacman -Rns"
    alias cleanup="sudo pacman -Sc"
    alias flushdns="sudo systemctl restart systemd-resolved"

  elif [[ "$DISTRO" == "RedHat" ]]; then
    alias update="sudo dnf update -y"
    alias inst="sudo dnf install -y"
    alias remove="sudo dnf remove -y"
    alias cleanup="sudo dnf autoremove -y && sudo dnf clean all"
    alias flushdns="sudo systemctl restart NetworkManager"
  fi
fi

# Aliases Global
# =========================

alias sshcpid="/usr/local/bin/sshcpid.sh" ## menyalin SSH public key dengan script bash
alias reload="source ~/.zshrc" # Memuat kembali konfigurasi ZSH dengan mengeksekusi file ~/.zshrc
alias clearall='clear && history -c' # Menghapus isi direktori dan menghapus riwayat perintah
alias lss='ls -lhG' # Menampilkan isi direktori dengan ukuran file dalam format yang lebacakan
alias clr="clear"
alias quit="exit"
alias du="du -sh *" 
alias df="df -h"
alias h="history"
alias j="jobs"
alias now='date +"%T"'
alias today='date +"%A, %B %d, %Y"'
alias pwdl="pwd -P" # Memeriksa semua perintah yang tersedia dengan cara mengeksekusi script bash
alias allcom='compgen -c' # Memeriksa daftar semua alias yang ada
alias showaliases="alias | less"

# ========================= Konfigurasi bat (Pengganti cat) =========================

if command -v bat &> /dev/null; then
  alias cat="bat"
  export BAT_THEME="Dracula"
  export BAT_STYLE="snip"
  alias cat-l="bat --style=numbers"
else
  alias cat="command cat" ## Menggunakan perintah cat asli jika bat tidak tersedia
fi


# ========================= Konfigurasi eza (Pengganti ls) =========================
if command -v eza &> /dev/null; then
  alias ls="eza $eza_params --icons --group-directories-first"
  alias ll="eza --icons --group-directories-first -AolhM"
  alias lt="eza --icons -AiolbM --tree --level=2"
  alias lg="eza --icons -lbGF --git"
  alias la="eza -lbhHgUmuSao --group-directories-first --icons"
else
  alias ls="ls" ## kembali ke default ls jika eza tidak ditemukan
fi

# =========================
# KONFIGURASI FZF (Fuzzy Finder)
# =========================
if command -v fzf &>/dev/null; then

  # Jika 'fd' tersedia, gunakan sebagai backend pencarian (lebih cepat dari find)
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  else
    export FZF_DEFAULT_COMMAND='find . -type f'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='find . -type d'
  fi

  # Opsi tampilan fzf
  export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border --preview "bat --style=numbers --color=always --line-range :500 {} 2>/dev/null || cat {}"'
  # --height=40%      → fzf hanya menempati 40% tinggi terminal
  # --layout=reverse  → hasil pencarian muncul dari bawah ke atas
  # --border          → tampilkan border di sekeliling fzf
  # --preview         → tampilkan isi file secara real-time dengan 'bat' atau fallback ke 'cat'

  # =========================
  # ALIAS FZF 
  # =========================

alias fzf-history='history | fzf' # 🔍 Pencarian riwayat perintah sebelumnya dengan fzf
alias fcd='cd "$(fd --type d | fzf)"' # 📁 Pindah ke direktori hasil pencarian dengan fzf (menggunakan fd)
alias frun='fzf --preview "bat --style=numbers --color=always {} 2>/dev/null || cat {}" | xargs -r $SHELL' # 🚀 Menjalankan file hasil pencarian langsung di shell
alias fkill="ps aux | fzf --preview 'echo {}' | awk '{print \$2}' | xargs kill -9" # ❌ Memilih dan mematikan proses (dengan preview proses)
alias fe='fzf --preview "bat --style=numbers --color=always --line-range :100 {}" | xargs -r $EDITOR' # ✍️  Memilih file via fzf dan membukanya di editor (nvim/vim/code tergantung $EDITOR)

fi

# Deteksi zoxide
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  alias zf='zoxide query -l | fzf'             # pilih direktori dari daftar zoxide
  alias zj='cd "$(zoxide query -l | fzf)"'     # cd ke direktori pilihan
  alias zz='zoxide query -l | fzf --preview "ls -la {}"' # preview isi dir
fi

alias zf='zoxide query -l | fzf'
alias zj='cd "$(zoxide query -l | fzf)"' # Pindah ke direktori yang dipilih dengan fzf
alias zz='zoxide query -l | fzf --preview "ls -la {}"' # Preview isi direktori dengan fzf


# Aliases untuk penggunaan Git
# ============================

alias gitdiffall="git diff $(git branch | sed -e 's/^[*\ ]/git checkout /')" # Memeriksa perubahan di semua branch yang ada di repository Git
alias gitzero='git add --all; git commit -m "zero"; git push && git checkout .' # Menghapus semua file yang tidak terisi dari directory Git
alias giteach='git show-ref | cut -f1 | xargs -I{} git checkout {} && git pull && echo "On branch {}"; git branch --list' # Mengeksekusi perintah untuk setiap branch di repository Git
alias gitdiffbranch="git diff `git branch | sed -e 's/^\*//'` master" # Memeriksa perbedaan antara dua cabang di repositori Git
alias gitall='git --help' # Menampilkan daftar semua perintah yang tersedia untuk Git
alias gitreset='git config --global --edit' # Mereset pengaturan dan konfigurasi global Git

# Aliases untuk penggunaan Node.js
# ============================

alias difffile="diff <(cat file1.txt) <(cat file2.txt)" # Memeriksa perbedaan antara dua versi file dengan mengeksekusi script bash
alias np='npm "$1"' # Mengeksekusi Node.js dan NPM secara pakai dengan alih-alih ke direktori file yang diinginkan
alias n='node "$1"' # Mengeksekusi Node.js dan NPM secara pakai dengan alih-alih ke direktori file yang diinginkan

# Aliases untuk penggunaan Python
# ============================

# Mengeksekusi script Python dengan mengeksekusi perintah yang berbeda
alias py='python3 "$1"'

