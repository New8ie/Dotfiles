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
  alias cpuinfo="system_profiler SPHardwareDataType | grep Cores" ## MacOS
  alias gpuinfo="system_profiler SPDisplaysDataType Graphics/Displays:" ## MacOS
  alias sysinfo="top -o cpu" ## menampilkan proses dengan penggunaan CPU tertinggi MacOS
  alias listservices="launchctl list" ## menampilkan daftar layanan yang berjalan di MacOS
  alias runningapps="ps aux | grep -v grep | grep -i" ## melihat proses aplikasi yang berjalan MacOS
  alias showroute="netstat -nr -f inet" ## untuk melihat routing table MacOS
  alias listport="sudo lsof -i -P -n | grep LISTEN" ## melihat port yang sedang listening MacOS
  alias flushdns="sudo killall -HUP mDNSResponder" ## MacOS

  # Brew
  alias pkg-update='brew update && brew upgrade' ## MacOS update & upgrade package
  alias pkg-install='brew install' ## MacOS install package
  alias pkg-remove='brew uninstall' ## MacOS uninstall package
  alias pkg-clean='brew cleanup' ## MacOS cleanup package
  alias pkg-search='brew search' ## MacOS search package

  # =========================
  # ALIAS UNTUK LINUX
  # =========================
elif [[ "$PLATFORM" == "Linux" ]]; then
  # Aliases untuk Linux Sama dengan macOS
  alias showroute='ip route show' ## melihat route table
  alias listport='ss -tlupn' ## melihat port yang sedang listening linux
  alias sysinfo='top -o %CPU' ## menampilkan proses dengan penggunaan CPU tertinggi linux
  alias runningapps='ps aux | grep -v grep | grep -i' ## melihat proses aplikasi yang berjalan linux
  alias cpuinfo='lscpu | egrep "CPU\(s\)|Core|Thread|Socket"' ## menampilkan informasi CPU linux
  alias cpwd='pwd | tr -d "\n" | xclip -selection clipboard' ## menyalin path direktori saat ini linux

  if [[ "$DISTRO" == "Debian" ]]; then
    alias pkg-update='sudo apt update && sudo apt upgrade -y' ## debian update & upgrade package
    alias pkg-install='sudo apt install -y' ## debian install package
    alias pkg-remove='sudo apt remove -y' ## debian uninstall package
    alias pkg-clean='sudo apt autoremove -y && sudo apt autoclean -y' ## debian cleanup package
    alias pkg-search='sudo apt search' ## debian search package

    alias flushdns='sudo systemd-resolve --flush-caches' ## debian

  elif [[ "$DISTRO" == "Arch" ]]; then
    alias pkg-update='sudo pacman -Syu' ## arch update & upgrade package
    alias pkg-install='sudo pacman -S' ## arch install package
    alias pkg-remove='sudo pacman -Rns' ### arch uninstall package
    alias pkg-clean='sudo pacman -Sc' ## arch cleanup package
    alias pkg-list='pacman -Q' ## arch list package
    alias pkg-search='sudo pacman -Ss' ## arch search package
    alias flushdns='sudo systemctl restart systemd-resolved' ## arch

  elif [[ "$DISTRO" == "RedHat" ]]; then
    alias pkg-update='sudo dnf update -y' ## redhat update & upgrade package
    alias pkg-install='sudo dnf install -y' ## redhat install package
    alias pkg-remove='sudo dnf remove -y' ## redhat uninstall package
    alias pkg-clean='sudo dnf autoremove -y && sudo dnf clean all' ## redhat cleanup package
    alias pkg-search='sudo dnf search' ## redhat search package
    alias flushdns='sudo systemctl restart NetworkManager' ## redhat
  fi
fi

# Aliases Global
# =========================
alias cfm="$HOME/.config/script/cloudflare_manager.sh" ## Menampilkan,menambakan dan mengapus banned ip di cloudflare
alias sshcpid="$HOME/.config/script/sshcpid.sh" ## menyalin SSH public key dengan script bash
alias static-route="$HOME/.config/script/static_route.sh" ## menambahkan static route dengan script bash
alias ipconfig="$HOME/.config/script/mylocalip.sh" ## menampilkan IP lokal dengan script bash
alias myip="$HOME/.config/script/netinfo.sh" ## menampilkan IP PUBLC,DNS,GATEWAY dengan script bash
alias reload="source ~/.zshrc" ## Memuat kembali konfigurasi ZSH dengan mengeksekusi file ~/.zshrc
alias clearall='clear && history -c' ## Menghapus isi direktori dan menghapus riwayat perintah
alias killapp="pkill -f" ## Menghentikan proses aplikasi dengan nama tertentu
alias lss='ls -lhG' ## Menampilkan isi direktori dengan ukuran file dalam format yang lebacakan
alias clr="clear" ## Membersihkan layar terminal
alias quit="exit" ## Keluar dari terminal
alias du="du -sh ./*" ## Menampilkan ukuran direktori dan file dalam format yang lebih mudah dibaca
alias df="df -h" ## Menampilkan penggunaan disk dalam format yang lebih mudah dibaca
alias h="history" ## Menampilkan riwayat perintah yang telah dijalankan
alias j="jobs" ## Menampilkan daftar pekerjaan yang sedang berjalan di background
alias now='date +"%T"' ## Menampilkan waktu saat ini dalam format jam:menit:detik
alias today='date +"%A, %B %d, %Y"' ## Menampilkan tanggal saat ini dalam format hari, bulan, tanggal, tahun
alias pwdl="pwd -P" ## Memeriksa semua perintah yang tersedia dengan cara mengeksekusi script bash

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
    ss -tlupnH | awk '{ proto=$1; local=$5; proc=$7; gsub("\\[","",local); gsub("\\]","",local); split(local,a,":"); port=a[length(a)]; addr=local; sub(":"port,"",addr); app="-"; pid="-"; if (match(proc,/"[^"]+"/)) { app=substr(proc,RSTART+1,RLENGTH-
    2)}; if (match(proc,/pid=[0-9]+/)) { pid=substr(proc,RSTART+4,RLENGTH-4)}; print app "|" pid "|" port "|" proto "|" addr }' | sort -u | while IFS='|' read -r app pid port proto addr; do
      service=$(get_service "$port" "$proto")
      printf "${GREEN}%-30s${YELLOW}%-8s${BLUE}%-7s${MAGENTA}%-7s${CYAN}%-24s${WHITE}%-14s${RESET}\n" "$app" "$pid" "$port" "$proto" "$addr" "${service:--}"
    done | sort -k3 -n
  fi
}
# ========================= Konfigurasi bat (Pengganti cat) =========================

if command -v bat &> /dev/null; then
  alias cat="bat" ## Menggunakan bat sebagai pengganti cat
  alias rcat="/bin/cat" ## Menggunakan cat asli
  export BAT_THEME="Dracula"
  export BAT_STYLE="snip"
  alias cat-l="bat --style=numbers" ## Menampilkan isi file dengan nomor baris
else
  alias cat="command cat" ## Menggunakan cat asli
fi

# ========================= Konfigurasi eza (Pengganti ls) =========================
if command -v eza &>/dev/null; then
  alias ls="eza $eza_params --icons --group-directories-first" ## Menggunakan eza sebagai pengganti ls
  alias ll="eza --icons --group-directories-first -AolhM" ## Menampilkan isi direktori dengan format panjang, termasuk file tersembunyi, ukuran total, dan ikon
  alias lt="eza --icons -AiolbM --total-size --tree --level=2" ## Menampilkan isi direktori dalam format pohon dengan level 2, termasuk file tersembunyi, ukuran total, dan ikon
  alias lg="eza --icons -lbGF --git" ## Menampilkan isi direktori dengan format panjang, termasuk file tersembunyi, ukuran total, ikon, dan informasi Git
  alias la="eza -lbhHgUmuSao --total-size --group-directories-first --icons" ## Menampilkan isi direktori dengan format panjang, hide files, ukuran total, ikon, dan pengelompokan direktori
fi

# ================================= Grc Curl ======================================
if command -v grc >/dev/null 2>&1; then
  curl() {
    grc --pty /usr/bin/curl "$@"
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
  alias fzf-history='history | fzf' ## Menampilkan riwayat perintah dengan fzf
  alias fcd='cd "$(fd --type d | fzf)"' ## Memilih direktori dengan fzf dan berpindah ke direktori tersebut
  alias frun='fzf --preview "bat --style=numbers --color=always {} 2>/dev/null || cat {}" | xargs -r $SHELL' ## Memilih file dengan fzf dan menjalankan perintah di dalamnya
  alias fkill="ps aux | fzf --preview 'echo {}' | awk '{print \$2}' | xargs kill -9" ## Memilih proses dengan fzf dan menghentikannya
  alias fe='fzf --preview "bat --style=numbers --color=always --line-range :100 {}" | xargs -r $EDITOR' ## Memilih file dengan fzf dan membukanya di editor
fi

# Deteksi zoxide
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  alias zf='zoxide query -l | fzf'             ## pilih direktori dari daftar zoxide
  alias zj='cd "$(zoxide query -l | fzf)"'     ## cd ke direktori pilihan
  alias zz='zoxide query -l | fzf --preview "ls -la {}"' ## preview isi dir
fi

# ======================================
# Aliases untuk penggunaan astro
# ======================================
alias astrodev="astro dev" ## Menjalankan server pengembangan Astro
alias astrob="astro build" ## Membangun proyek Astro untuk produksi
alias astroc="astro check" ## Memeriksa kesalahan dan peringatan dalam proyek Astro
alias astronew="npm create astro@latest" ## Membuat proyek Astro baru dengan npm

# ======================================
# Aliases untuk penggunaan Node.js
# ======================================

alias difffile="diff <(cat file1.txt) <(cat file2.txt)" ## Memeriksa perbedaan antara dua versi file dengan mengeksekusi script bash
alias np='npm' ## Mengeksekusi Node.js dan NPM secara pakai dengan alih-alih ke direktori file yang diinginkan
alias n='node' ## Mengeksekusi Node.js dan NPM secara pakai dengan alih-alih ke direktori file yang diinginkan
alias ndev="node -v" ## Menampilkan versi Node.js yang terpasang
alias ninsstall="npm install" ## Menginstal dependensi proyek Node.js
alias nstart="npm start" ## Menjalankan skrip "start" yang didefinisikan dalam package.json
alias nbuild="npm run build" ## Menjalankan skrip "build" yang didefinisikan dalam package.json
alias ntest="npm test" ## Menjalankan skrip "test" yang didefinisikan dalam package.json

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
alias crtfp='openssl x509 -noout -fingerprint -sha256 -in' ## Menampilkan fingerprint SHA256 dari sertifikat

# 6. Subject Alternative Name
alias crtsan='openssl x509 -noout -ext subjectAltName -in' ## Menampilkan Subject Alternative Name (SAN) dari sertifikat

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

# =============================================================================
# ZSH - ALIAS AUDIT
# =============================================================================

zsh-alias-audit() {
  local custom="$HOME/.config/zsh/alias.zsh"
  local tmp_custom
  local tmp_active
  local tmp_plugin
  local tmp_custom_names
  local tmp_active_meta
  local plugin
  local file
  local name

  local -a plugins=(
  git
  zsh-completions
  zsh-autosuggestions
  zsh-you-should-use
  zsh-bat
  web-search
  fzf-tab
  zsh-syntax-highlighting
  )

  # ---------------------------------------------------------------------------
  # TEMP FILES
  # ---------------------------------------------------------------------------

  tmp_custom=$(mktemp)
  tmp_active=$(mktemp)
  tmp_plugin=$(mktemp)
  tmp_custom_names=$(mktemp)
  tmp_active_meta=$(mktemp)
  # ---------------------------------------------------------------------------
  # CUSTOM ALIAS
  # ---------------------------------------------------------------------------
  # Hanya membaca deklarasi:
  #
  #   alias foo='command' ## komentar
  #
  # Komentar ## dipertahankan untuk ditampilkan.
  # ---------------------------------------------------------------------------

  grep -hE \
    '^[[:space:]]*alias[[:space:]]+[A-Za-z_][A-Za-z0-9_!.-]*[[:space:]]*=' \
    "$custom" 2>/dev/null |
    sed -E \
    's/^[[:space:]]*alias[[:space:]]+//' |
    awk '
      {
        pos = index($0, "=")

        if (pos > 0) {
          name = substr($0, 1, pos - 1)
          value = substr($0, pos + 1)

          gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)

          printf "%s → %s\n", name, value
        }
      }
    ' |
    sort -u > "$tmp_custom"
  # ---------------------------------------------------------------------------
  # ACTIVE ALIAS
  # ---------------------------------------------------------------------------

  alias -L |
    sed -E 's/^alias[[:space:]]+//' |
    awk '{
      pos = index($0, "=")

      if (pos > 0) {
        name = substr($0, 1, pos - 1)
        value = substr($0, pos + 1)

        gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
        gsub(/^'\''|'\''$/, "", value)

        printf "%s → %s\n", name, value
      }
    }' |
    sort -u > "$tmp_active"

  # ---------------------------------------------------------------------------
  # PLUGIN ALIAS
  # ---------------------------------------------------------------------------

  for plugin in "${plugins[@]}"; do
    for file in \
      "$ZSH_CUSTOM/plugins/$plugin/$plugin.plugin.zsh" \
      "$ZSH/plugins/$plugin/$plugin.plugin.zsh"
    do
      [[ -f "$file" ]] || continue

      grep -hE \
        '^[[:space:]]*alias[[:space:]]+[A-Za-z_][A-Za-z0-9_!.-]*[[:space:]]*=' \
        "$file" |
        sed -E \
        's/^[[:space:]]*alias[[:space:]]+([^=]+)=.*/\1/' \
        >> "$tmp_plugin"

      break
    done
  done

  sort -u "$tmp_plugin" -o "$tmp_plugin"

  # ---------------------------------------------------------------------------
  # CUSTOM ALIAS NAMES
  # ---------------------------------------------------------------------------

  sed -E 's/[[:space:]]+→.*$//' "$tmp_custom" |
    sort -u > "$tmp_custom_names"

  # ---------------------------------------------------------------------------
  # CUSTOM ALIAS
  # ---------------------------------------------------------------------------

  printf '\n\033[1;35mCUSTOM ALIAS\033[0m\n'
  printf '%s\n' '────────────────────────────────────────'

  if [[ -s "$tmp_custom" ]]; then
    awk '
      {
        pos = index($0, " → ")

        if (pos > 0) {
          name = substr($0, 1, pos - 1)
          value = substr($0, pos + 4)

          comment = ""
          cpos = index(value, " ## ")

          if (cpos > 0) {
            comment = substr(value, cpos)
            value = substr(value, 1, cpos - 1)
          }

          printf "\033[1;36m%-16s\033[0m → %s", name, value

          if (comment != "") {
            printf " \033[1;33m%s\033[0m", comment
          }

          printf "\n"
        }
      }
    ' "$tmp_custom"
  else
    printf '%s\n' '(none)'
  fi
  # ---------------------------------------------------------------------------
  # ACTIVE ALIAS METADATA
  # ---------------------------------------------------------------------------
  # Menghubungkan:
  #
  #   nama alias
  #   command
  #   komentar ## ...
  #
  # dari alias.zsh
  #
  # Tujuannya agar ACTIVE ALIAS dapat menampilkan komentar source.
  # ---------------------------------------------------------------------------

  awk '
    /^[[:space:]]*alias[[:space:]]+[A-Za-z_][A-Za-z0-9_!.-]*[[:space:]]*=/ {

      line = $0

      # Buang indentation + "alias "
      sub(/^[[:space:]]*alias[[:space:]]+/, "", line)

      # Pisahkan nama dan value
      pos = index(line, "=")

      if (pos > 0) {
        name = substr(line, 1, pos - 1)
        value = substr(line, pos + 1)

        gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)

        comment = ""

        # Ambil komentar ## ...
        cpos = index(value, " ## ")

        if (cpos > 0) {
          comment = substr(value, cpos)
          value = substr(value, 1, cpos - 1)
          gsub(/[[:space:]]+$/, "", value)
        }

        printf "%s\t%s\t%s\n", name, value, comment
      }
    }
  ' "$custom" > "$tmp_active_meta"
  # ---------------------------------------------------------------------------
  # ACTIVE ALIAS
  # ---------------------------------------------------------------------------

  printf '\n\033[1;35mACTIVE ALIAS\033[0m\n'
  printf '%s\n' '────────────────────────────────────────'

  if [[ -s "$tmp_active" ]]; then

    while IFS= read -r line; do

      [[ -n "$line" ]] || continue

      name="${line%% → *}"
      value="${line#* → }"

      comment=""

      # Cari source alias berdasarkan nama + command.
      while IFS=$'\t' read -r meta_name meta_value meta_comment; do

        [[ "$meta_name" == "$name" ]] || continue

        # Normalisasi quote sederhana agar:
        #   "bat"
        #   'bat'
        #   bat
        # dapat dibandingkan.
        clean_active="${value#\'}"
        clean_active="${clean_active%\'}"
        clean_active="${clean_active#\"}"
        clean_active="${clean_active%\"}"

        clean_meta="${meta_value#\'}"
        clean_meta="${clean_meta%\'}"
        clean_meta="${clean_meta#\"}"
        clean_meta="${clean_meta%\"}"

        if [[ "$clean_active" == "$clean_meta" ]]; then
          comment="$meta_comment"
          break
        fi

      done < "$tmp_active_meta"

      printf "\033[1;32m%-16s\033[0m → %s" "$name" "$value"

      if [[ -n "$comment" ]]; then
        printf " \033[1;33m%s\033[0m" "$comment"
      fi

      printf '\n'

    done < "$tmp_active"

  else
    printf '%s\n' '(none)'
  fi

  # ---------------------------------------------------------------------------
  # OVERRIDE / DUPLICATE
  # ---------------------------------------------------------------------------

  printf '\n\033[1;35mOVERRIDE / DUPLICATE\033[0m\n'
  printf '%s\n' '────────────────────────────────────────'

  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    printf '\033[1;31m%-16s\033[0m → custom + OMZ/plugin\n' "$name"
  done < <(comm -12 "$tmp_custom_names" "$tmp_plugin")

  # ---------------------------------------------------------------------------
  # CLEANUP
  # ---------------------------------------------------------------------------

  rm -f \
    "$tmp_custom" \
    "$tmp_active" \
    "$tmp_plugin" \
    "$tmp_custom_names" \
    "$tmp_active_meta"
}
# =============================================================================
# SHOW ALIAS AUDIT
# =============================================================================

show-alias() {
  zsh-alias-audit | less -R
}
alias help='show-alias' ## Menampilkan daftar alias yang tersedia dengan bantuan
