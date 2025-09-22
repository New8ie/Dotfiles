# Add to the /etc/fail2ban/jail.conf:
# [sshd]
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
#!/bin/sh
# =================================================================
# Fail2Ban Telegram Notification Script
# Compatible with sh and bash
# =================================================================
TELEGRAM_BOT_TOKEN="AAABBBCcccDDDeeeFFFGGGHHHCCCKLLLLL"
TELEGRAM_CHAT_ID="-1234567890"
SERVER_NAME='Zabbix'
DOMAIN_HOST='zabbix.thismydomains.com'
LOG_FILE="/var/log/fail2ban.log"

# Fungsi untuk mengirim pesan ke Telegram
send_telegram_alert() {
    MESSAGE="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$MESSAGE" \
        -d parse_mode="Markdown" >/dev/null 2>&1
}

# Cek argumen
if [ $# -eq 0 ]; then
    echo "Usage: $0 -a (start|stop) -n <JAIL_NAME> || -b <IP> || -u <IP>"
    exit 1
fi

# Inisialisasi variabel
action=""
JAIL_NAME=""
BANNED_IP=""
UNBANNED_IP=""
ban="n"
unban="n"

# Parse opsi
while getopts "a:n:b:u:" opt; do
    case "$opt" in
        a) action="$OPTARG" ;;
        n) JAIL_NAME="$OPTARG" ;;
        b) BANNED_IP="$OPTARG"; ban="y" ;;
        u) UNBANNED_IP="$OPTARG"; unban="y" ;;
        \?) echo "Invalid option -$OPTARG"; exit 1 ;;
    esac
done

# File lock untuk status
LOCK_FILE="/tmp/fail2ban_status.lock"
if [ -f "$LOCK_FILE" ]; then
    PREV_STATUS=$(cat "$LOCK_FILE")
else
    PREV_STATUS=""
fi

# Eksekusi berdasarkan action
if [ -n "$action" ]; then
    case "$action" in
        start)
            if [ "$PREV_STATUS" != "started" ]; then
                send_telegram_alert "🔔 Fail2Ban HomeLabs 🏠 $SERVER_NAME started ✅"
                echo "started" > "$LOCK_FILE"
            fi
            ;;
        stop)
            if [ "$PREV_STATUS" != "stopped" ]; then
                send_telegram_alert "⚠️ Fail2Ban HomeLabs 🏠 $SERVER_NAME stopped 🚫"
                echo "stopped" > "$LOCK_FILE"
            fi
            ;;
        *)
            echo "Incorrect option"
            exit 1
            ;;
    esac
elif [ "$ban" = "y" ]; then
    MESSAGE="🚨 Fail2Ban Alert! 🚨%0A%0A"
    MESSAGE="$MESSAGE🔹 Jail: $JAIL_NAME%0A"
    MESSAGE="$MESSAGE🔹 IP: $BANNED_IP%0A"
    MESSAGE="$MESSAGE🔹 Time: $(date +'%Y-%m-%d %H:%M:%S')%0A"
    MESSAGE="$MESSAGE🔹 Log: $(grep "$BANNED_IP" "$LOG_FILE" | tail -n 5 | sed ':a;N;$!ba;s/\n/%0A/g')"
    send_telegram_alert "$MESSAGE"
    exit 0
elif [ "$unban" = "y" ]; then
    MESSAGE="✅ 🧯 Fail2Ban HomeLabs 🏠 🔊%0A"
    MESSAGE="$MESSAGE🔹 Jail: $JAIL_NAME%0A"
    MESSAGE="$MESSAGE🔹 Unbanned IP: $UNBANNED_IP%0A"
    MESSAGE="$MESSAGE🔹 Server: $SERVER_NAME%0A"
    send_telegram_alert "$MESSAGE"
    exit 0
else
    echo "No valid option provided."
    exit 1
fi
