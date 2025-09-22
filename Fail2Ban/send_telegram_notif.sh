# Add to the /etc/fail2ban/jail.conf:
# [sshd]
# ***
# action  = iptables[name=SSH, port=22, protocol=tcp]
#           telegram

# Create a new file in /etc/fail2ban/action.d with the following information:
# [Definition]
# actionstart = /etc/fail2ban/scripts/send_telegram_notif.sh -a start
# actionstop = /etc/fail2ban/scripts/send_telegram_notif.sh -a stop
# actioncheck =
# actionban = /etc/fail2ban/scripts/send_telegram_notif.sh -n <name> -b <ip>
# actionunban = /etc/fail2ban/scripts/send_telegram_notif.sh -n <name> -u <ip>
#
# [Init]
# init = 123
#!/bin/bash

# Konfigurasi
TELEGRAM_BOT_TOKEN="AAABBBCcccDDDeeeFFFGGGHHHCCCKLLLLL"
TELEGRAM_CHAT_ID="-1234567890"
SERVER_NAME='HOSTNAME'
DOMAIN_HOST='hostname.thisdomains.com'
LOG_FILE="/var/log/fail2ban.log"


# Fungsi untuk mengirim pesan ke Telegram
send_telegram_alert() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$message" \
        -d parse_mode="Markdown" > /dev/null 2>&1
}

# Menangani argumen
if [ $# -eq 0 ]; then
    echo "Usage: $0 -a (start|stop) || -b <IP> || -u <IP>"
    exit 1
fi

while getopts "a:n:b:u:" opt; do
    case "$opt" in
        a) action=$OPTARG ;;
        n) JAIL_NAME=$OPTARG ;;
        b) BANNED_IP=$OPTARG ; ban=y ;;
        u) UNBANNED_IP=$OPTARG ; unban=y ;;
        \?) echo "Invalid option -$OPTARG" ; exit 1 ;;
    esac
done

# Eksekusi berdasarkan opsi
# Lock file untuk mencegah duplikasi notifikasi
LOCK_FILE="/tmp/fail2ban_status.lock"

# Cek status sebelumnya
if [[ -f "$LOCK_FILE" ]]; then
    PREV_STATUS=$(cat "$LOCK_FILE")
else
    PREV_STATUS=""
fi

# Eksekusi berdasarkan opsi
if [[ -n $action ]]; then
    case "$action" in
        start)
            if [[ "$PREV_STATUS" != "started" ]]; then
                send_telegram_alert "🔔 Fail2Ban HomeLabs 🏠  $SERVER_NAME started ✅"
                echo "started" > "$LOCK_FILE"
            fi
        ;;
        stop)
            if [[ "$PREV_STATUS" != "stopped" ]]; then
                send_telegram_alert "⚠️  Fail2Ban HomeLabs 🏠  $SERVER_NAME stopped 🚫"
                echo "stopped" > "$LOCK_FILE"
            fi
        ;;
        *)
            echo "Incorrect option"
            exit 1
        ;;
    esac
elif [[ $ban == "y" ]]; then
    message="🚨 Fail2Ban Alert! 🚨%0A%0A"
    message+="🔹 Jail: $JAIL_NAME%0A"
    message+="🔹 IP: $BANNED_IP%0A"
    message+="🔹 Time: $(date +'%Y-%m-%d %H:%M:%S')%0A"
    message+="🔹 Log: $(grep "$BANNED_IP" "$LOG_FILE" | tail -n 5 | sed ':a;N;$!ba;s/\n/%0A/g')"
    send_telegram_alert "$message"
    exit 0
elif [[ $unban == "y" ]]; then
    message="✅ 🧯 Fail2Ban HomeLabs 🏠 🔊%0A"
    message+="🔹 Jail: $JAIL_NAME%0A"
    message+="🔹 Unbanned IP: $UNBANNED_IP%0A"
    message+="🔹 Server: $SERVER_NAME%0A"
    send_telegram_alert "$message"
    exit 0
else
    echo "No valid option provided."
    exit 1
fi