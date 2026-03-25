# ~/.config/zsh/alias.zsh

# =========================
# ALIAS UNTUK macOS
# =========================
if [[ "$PLATFORM" == "macOS" ]]; then
  
  alias dock-reset="defaults write com.apple.dock ResetLaunchPad -bool true && killall Dock" ## reset Launchpad di Mac
  alias cpwd='pwd | tr -d "\n" | pbcopy' ## menyalin path direktori saat ini
  alias caff="caffeinate -ism" ## mencegah Mac masuk ke mode tidur
  alias clip-last='fc -e -|pbcopy' ## menyalin output perintah terakhir
  alias showHidden='defaults write com.apple.finder AppleShowAllFiles TRUE' ## menampilkan file tersembunyi
  alias hideHidden='defaults write com.apple.finder AppleShowAllFiles FALSE' ## menyembunyikan file tersembunyi
  alias screen-copy='screencapture -c' ## menangkap layar ke clipboard
  alias screen-interactive='screencapture -i -c' ## menangkap layar secara interaktif ke clipboard
  alias screen-window='screencapture -i -w -c' ## menangkap layar interaktif dengan window
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
  alias cleanCache="rm -rf ~/Library/Caches/* && sudo purge" ## membersihkan file sementara dan cache

  # === Keyboard KeyRepeat Control ===
  alias keyrepeat-fast='defaults write NSGlobalDomain KeyRepeat -int 1 && defaults write NSGlobalDomain InitialKeyRepeat -int 10 && killall Dock && echo "✅ KeyRepeat diatur ke cepat (1)"'
  alias keyrepeat-normal='defaults write NSGlobalDomain KeyRepeat -int 2 && defaults write NSGlobalDomain InitialKeyRepeat -int 15 && killall Dock && echo "✅ KeyRepeat diatur ke normal (2)"'
  alias keyrepeat-slow='defaults write NSGlobalDomain KeyRepeat -int 10 && defaults write NSGlobalDomain InitialKeyRepeat -int 25 && killall Dock && echo "✅ KeyRepeat diatur ke lambat (10)"'
  alias keyrepeat-default='defaults delete NSGlobalDomain KeyRepeat && defaults delete NSGlobalDomain InitialKeyRepeat && killall Dock && echo "♻️ KeyRepeat dikembalikan ke default sistem"'
  
  # Aliases untuk macOS sama dengan linux
  alias cpuinfo="system_profiler SPHardwareDataType | grep Cores"
  alias gpuinfo="system_profiler SPDisplaysDataType Graphics/Displays:"
  alias sysinfo="top -o cpu" ## menampilkan proses dengan penggunaan CPU tertinggi
  alias listservices="launchctl list" ## menampilkan daftar layanan yang berjalan di macOS
  alias runningapps="ps aux | grep -v grep | grep -i" ## melihat proses aplikasi yang berjalan
  alias showroute="netstat -nr -f inet" ## untuk melihat routing table
  alias listport="sudo lsof -i -P -n | grep LISTEN" ## melihat port yang sedang listening
  alias flushdns="sudo killall -HUP mDNSResponder" ## flush DNS cache
  
  # Brew
  alias pkg-update='brew update && brew upgrade'
  alias pkg-install='brew install'
  alias pkg-remove='brew uninstall'
  alias pkg-clean='brew cleanup'
  alias pkg-search='brew search'

# =========================
# ALIAS UNTUK LINUX
# =========================
elif [[ "$PLATFORM" == "Linux" ]]; then
  # Aliases untuk Linux Sama dengan macOS 
  alias showroute='ip route show'
  alias myip='hostname -I | awk "{print \$1}"'
  alias listport='ss -tlupn'
  alias sysinfo='top -o %CPU'
  alias runningapps='ps aux | grep -v grep | grep -i'
  alias cpuinfo='lscpu | egrep "CPU\(s\)|Core|Thread|Socket"'
  alias cpwd='pwd | tr -d "\n" | xclip -selection clipboard'

  if [[ "$DISTRO" == "Debian" ]]; then
    alias pkg-update='sudo apt update && sudo apt upgrade -y'
    alias pkg-install='sudo apt install -y'
    alias pkg-remove='sudo apt remove -y'
    alias pkg-clean='sudo apt autoremove -y && sudo apt autoclean -y'
    alias pkg-search='sudo apt search'

    alias flushdns='sudo systemd-resolve --flush-caches'

  elif [[ "$DISTRO" == "Arch" ]]; then
    alias pkg-update='sudo pacman -Syu'
    alias pkg-install='sudo pacman -S'
    alias pkg-remove='sudo pacman -Rns'
    alias pkg-clean='sudo pacman -Sc'
    alias pkg-search='sudo pacman -Ss'
    alias flushdns='sudo systemctl restart systemd-resolved'

  elif [[ "$DISTRO" == "RedHat" ]]; then
    alias pkg-update='sudo dnf update -y'
    alias pkg-install='sudo dnf install -y'
    alias pkg-remove='sudo dnf remove -y'
    alias pkg-clean='sudo dnf autoremove -y && sudo dnf clean all'
    alias pkg-search='sudo dnf search'
    alias flushdns='sudo systemctl restart NetworkManager'
  fi
fi

# Aliases Global
# =========================
alias cfm="$HOME/.config/script/cloudflare_manager.sh" ## Menampilkan,menambakan dan mengapus banned ip di cloudflare
alias sshcpid="$HOME/.config/script/sshcpid.sh" ## menyalin SSH public key dengan script bash
alias static-route="$HOME/.config/script/static_route.sh"
alias ipconfig="$HOME/.config/script/mylocalip.sh" ## menampilkan IP lokal dengan script bash
alias reload="source ~/.zshrc" ## Memuat kembali konfigurasi ZSH dengan mengeksekusi file ~/.zshrc
alias clearall='clear && history -c' ## Menghapus isi direktori dan menghapus riwayat perintah
alias killapp="pkill -f"
alias lss='ls -lhG' ## Menampilkan isi direktori dengan ukuran file dalam format yang lebacakan
alias clr="clear"
alias quit="exit"
alias du="du -sh ./*/" 
alias df="df -h"
alias h="history"
alias j="jobs"
alias now='date +"%T"'
alias today='date +"%A, %B %d, %Y"'
alias pwdl="pwd -P" ## Memeriksa semua perintah yang tersedia dengan cara mengeksekusi script bash
alias allcom='compgen -c' ## Memeriksa daftar semua alias yang ada
alias showalias="alias | less"

# ========================= Clean Dot Macos Files =========================

cleanDotMacFiles() {
    find . -type f -name "._*" -print0 | while IFS= read -r -d '' file; do
        echo "Deleting $file"
        rm "$file"
    done
}
alias cleanDS="find . -type f -name '*.DS_Store' -ls -delete" ## menghapus file .DS_Store


# ========================= Netapps =========================
netapps() {
  local GREEN="\033[32m" YELLOW="\033[33m" BLUE="\033[34m" MAGENTA="\033[35m" CYAN="\033[36m" WHITE="\033[97m" RESET="\033[0m"

  printf "${GREEN}%-30s${YELLOW}%-8s${BLUE}%-7s${MAGENTA}%-7s${CYAN}%-24s${WHITE}%-14s${RESET}\n" \
    APP PID PORT PROTO ADDRESS SERVICE

  get_service() {
    local port="$1" proto="$2"
    grep -E "^[^#].*[[:space:]]$port/$proto" /etc/services 2>/dev/null | awk '{print $1}' | head -n1
  }

  if [[ "$OSTYPE" == "darwin"* ]]; then
    sudo lsof -nP -iTCP -sTCP:LISTEN -iUDP -Fpcn 2>/dev/null | awk '
      /^p/ {pid=substr($0,2)}
      /^c/ {app=substr($0,2); gsub(/\\x20/," ",app)}
      /^n/ {addr=substr($0,2); split(addr,a,":"); port=a[length(a)]; sub(":"port,"",addr); proto="tcp"; if (addr ~ /->/) proto="udp"; print app "|" pid "|" port "|" proto "|" addr}
    ' | sort -u | while IFS='|' read -r app pid port proto addr; do
      service=$(get_service "$port" "$proto")
      printf "${GREEN}%-30s${YELLOW}%-8s${BLUE}%-7s${MAGENTA}%-7s${CYAN}%-24s${WHITE}%-14s${RESET}\n" "$app" "$pid" "$port" "$proto" "$addr" "${service:--}"
    done | sort -k3 -n
  else
    ss -tlupnH | awk '{ proto=$1; local=$5; proc=$7; gsub("\\[","",local); gsub("\\]","",local); split(local,a,":"); port=a[length(a)]; addr=local; sub(":"port,"",addr); app="-"; pid="-"; if (match(proc,/"[^"]+"/)) { app=substr(proc,RSTART+1,RLENGTH-2)}; if (match(proc,/pid=[0-9]+/)) { pid=substr(proc,RSTART+4,RLENGTH-4)}; print app "|" pid "|" port "|" proto "|" addr }' | sort -u | while IFS='|' read -r app pid port proto addr; do
      service=$(get_service "$port" "$proto")
      printf "${GREEN}%-30s${YELLOW}%-8s${BLUE}%-7s${MAGENTA}%-7s${CYAN}%-24s${WHITE}%-14s${RESET}\n" "$app" "$pid" "$port" "$proto" "$addr" "${service:--}"
    done | sort -k3 -n
  fi
}
#========================= Konfigurasi bat (Pengganti cat) =========================

  export BAT_THEME="Dracula"
  export BAT_STYLE="snip"
  alias cat-l="batcat --style=numbers"

# ========================= Konfigurasi eza (Pengganti ls) =========================
if command -v eza &> /dev/null; then
  alias ls="eza $eza_params --icons --group-directories-first"
  alias ll="eza --icons --group-directories-first -AolhM"
  alias lt="eza --icons -AiolbM --total-size --tree --level=2"
  alias lg="eza --icons -lbGF --git"
  alias la="eza -lbhHgUmuSao --total-size --group-directories-first --icons"
else
  alias ls="ls" ## kembali ke default ls jika eza tidak ditemukan
fi

# ================================= Grc Curl ======================================
if command -v grc >/dev/null 2>&1; then
  curl() {
    grc --pty command curl "$@"
  }
fi

# =========================
# KONFIGURASI FZF (Fuzzy Finder)
# =========================
if command -v fzf &>/dev/null; then
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  else
    export FZF_DEFAULT_COMMAND='find . -type f'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='find . -type d'
  fi

  export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border --preview "bat --style=numbers --color=always --line-range :500 {} 2>/dev/null || cat {}"'
  alias fzf-history='history | fzf'
  alias fcd='cd "$(fd --type d | fzf)"'
  alias frun='fzf --preview "bat --style=numbers --color=always {} 2>/dev/null || cat {}" | xargs -r $SHELL'
  alias fkill="ps aux | fzf --preview 'echo {}' | awk '{print \$2}' | xargs kill -9"
  alias fe='fzf --preview "bat --style=numbers --color=always --line-range :100 {}" | xargs -r $EDITOR'
fi


# Deteksi zoxide
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  alias zf='zoxide query -l | fzf'             ## pilih direktori dari daftar zoxide
  alias zj='cd "$(zoxide query -l | fzf)"'     ## cd ke direktori pilihan
  alias zz='zoxide query -l | fzf --preview "ls -la {}"' # preview isi dir
fi


# ======================================
# Aliases untuk penggunaan astro
# ======================================
alias astrodev="astro dev"
alias astrob="astro build"
alias astroc="astro check"
alias astronew="npm create astro@latest"


# ======================================
# Aliases untuk penggunaan Node.js
# ======================================

alias difffile="diff <(cat file1.txt) <(cat file2.txt)" ## Memeriksa perbedaan antara dua versi file dengan mengeksekusi script bash
alias np='npm "$1"' ## Mengeksekusi Node.js dan NPM secara pakai dengan alih-alih ke direktori file yang diinginkan
alias n='node "$1"' ## Mengeksekusi Node.js dan NPM secara pakai dengan alih-alih ke direktori file yang diinginkan
alias ndev="node -v"
alias ninsstall="npm install"
alias nstart="npm start"
alias nbuild="npm run build"
alias ntest="npm test"

# ======================================
# Ollama
# ======================================

alias ollist="ollama list"
alias ollrun="ollama run"
alias ollpull="ollama pull"
alias ollrm="ollama rm"
alias olllog="ollama logs"
alias ollserve="ollama serve"

## ------------------
## Source user function directory 
## ------------------

FUNC_DIR="$HOME/.config/zsh/functions"
if [ -d "$FUNC_DIR" ]; then
  for f in "$FUNC_DIR"/*.zsh; do
    [ -r "$f" ] && source "$f"
  done
else
  echo "⚠️ Direktori fungsi tidak ditemukan: $FUNC_DIR"
fi

# ======================================
# openssl
# ======================================
# 5. Fingerprint SHA256
alias crtfp='openssl x509 -noout -fingerprint -sha256 -in'


# 6. Subject Alternative Name
alias crtsan='openssl x509 -noout -ext subjectAltName -in'


# 7. Validasi cert vs private key
crtmatch() {
if [[ $# -ne 2 ]]; then
echo "Usage: crtmatch <cert.crt> <private.key>"
return 1
fi


openssl x509 -noout -modulus -in "$1" | openssl md5
openssl rsa -noout -modulus -in "$2" | openssl md5
}


# 8. Scan semua cert di folder
crtcheckdir() {
for f in *.crt *.pem; do
[[ -f "$f" ]] || continue
echo "===== $f ====="
openssl x509 -noout -subject -enddate -in "$f"
echo
done
}


# 9. Cek certificate remote HTTPS
crtremote() {
if [[ -z "$1" ]]; then
echo "Usage: crtremote <hostname>"
return 1
fi


echo | openssl s_client -connect "$1:443" -servername "$1" 2>/dev/null \
| openssl x509 -noout -subject -issuer -startdate -enddate
}


# 10. All-in-one summary
crtall() {
if [[ -z "$1" ]]; then
echo "Usage: crtall <file.crt>"
return 1
fi


echo "Subject :"
openssl x509 -noout -subject -in "$1"


echo "
Issuer :"
openssl x509 -noout -issuer -in "$1"


echo "
Validity :"
openssl x509 -noout -startdate -enddate -in "$1"


echo "
SAN :"
openssl x509 -noout -ext subjectAltName -in "$1" 2>/dev/null


echo "
Fingerprint (SHA256) :"
openssl x509 -noout -fingerprint -sha256 -in "$1"
}


# 11. Help / bantuan
crthelp() {
cat << 'EOF'
Zsh Certificate Toolkit - Help


cekcrt <file.crt> : cek expired date
crtinfo <file.crt> : subject, issuer, expired
crtinfofull <file.crt> : info lengkap
crtleft <file.crt> : sisa hari
crtfp <file.crt> : fingerprint SHA256
crtsan <file.crt> : SAN
crtmatch <crt> <key> : validasi cert vs key
crtcheckdir : scan cert di folder
crtremote <host> : cek cert HTTPS remote
crtall <file.crt> : ringkasan lengkap
crthelp : tampilkan help
EOF
}
# ===============================

alias UpdateDotfiles='[ -d "$HOME/.dotfiles/.git" ] && git -C "$HOME/.dotfiles" pull || git clone https://github.com/New8ie/Dotfiles.git "$HOME/.dotfiles"'
