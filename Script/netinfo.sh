#!/bin/sh

echo "╭─ Network Information ─────────────────────────"

OS="$(uname -s)"

echo "│ Hostname    : $(hostname)"

# =========================
# Public IPv4
# =========================
PUBLIC_IP="$(curl -4 -s --max-time 5 ifconfig.me 2>/dev/null)"

if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP="N/A"
fi

echo "│ Public IPv4 : $PUBLIC_IP"

# =========================
# macOS
# =========================
if [ "$OS" = "Darwin" ]; then

    GATEWAY="$(route -n get default 2>/dev/null | awk '/gateway:/{print $2}')"
    INTERFACE="$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')"
    LOCAL_IP="$(ipconfig getifaddr "$INTERFACE" 2>/dev/null)"

    echo "│ Local IPv4  : ${LOCAL_IP:-N/A}"
    echo "│ Gateway     : ${GATEWAY:-N/A}"
    echo "│ Interface   : ${INTERFACE:-N/A}"

    echo "│ DNS         :"
    scutil --dns 2>/dev/null |
        awk '/nameserver\[[0-9]+\]/{print $3}' |
        sort -u |
        sed 's/^/│               /'

# =========================
# Linux
# =========================
elif [ "$OS" = "Linux" ]; then

    INTERFACE="$(ip route 2>/dev/null | awk '/default/{print $5; exit}')"
    GATEWAY="$(ip route 2>/dev/null | awk '/default/{print $3; exit}')"
    LOCAL_IP="$(ip -4 addr show "$INTERFACE" 2>/dev/null |
        awk '/inet /{print $2}' |
        cut -d/ -f1 |
        head -n1)"

    echo "│ Local IPv4  : ${LOCAL_IP:-N/A}"
    echo "│ Gateway     : ${GATEWAY:-N/A}"
    echo "│ Interface   : ${INTERFACE:-N/A}"

    echo "│ DNS         :"

    if command -v resolvectl >/dev/null 2>&1; then
        resolvectl dns 2>/dev/null |
            awk '{for(i=3;i<=NF;i++) print $i}' |
            sort -u |
            sed 's/^/│               /'
    else
        awk '/^nameserver/{print $2}' /etc/resolv.conf 2>/dev/null |
            sort -u |
            sed 's/^/│               /'
    fi

else
    echo "│ OS          : $OS"
    echo "│ Unsupported operating system"
fi

echo "╰──────────────────────────────────────────────"