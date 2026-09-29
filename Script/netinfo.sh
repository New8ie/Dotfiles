#!/bin/sh

# Use colors interactively, but keep redirected output readable.
if [ -t 1 ]; then
    RESET='\033[0m'
    BOLD='\033[1m'
    CYAN='\033[36m'
    BLUE='\033[34m'
    GREEN='\033[32m'
    YELLOW='\033[33m'
else
    RESET=''
    BOLD=''
    CYAN=''
    BLUE=''
    GREEN=''
    YELLOW=''
fi

printf '%b\n' "${CYAN}${BOLD}╭─ Network Information ─────────────────────────╮${RESET}"

OS="$(uname -s)"

printf '%b\n' "${CYAN}│${RESET} ${BLUE}Host${RESET}       : ${BOLD}$(hostname)${RESET}"
printf '%b\n' "${CYAN}├─ Public Network ──────────────────────────────┤${RESET}"

# =========================
# Public IPv4
# =========================
PUBLIC_IP="$(curl -4 -s --max-time 5 ifconfig.me 2>/dev/null)"

if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP="N/A"
fi

if [ "$PUBLIC_IP" = "N/A" ]; then
    PUBLIC_COLOR="$YELLOW"
else
    PUBLIC_COLOR="$GREEN"
fi
printf '%b\n' "${CYAN}│${RESET} ${BLUE}Public IPv4${RESET} : ${PUBLIC_COLOR}${BOLD}$PUBLIC_IP${RESET}"

# =========================
# macOS
# =========================
if [ "$OS" = "Darwin" ]; then

    GATEWAY="$(route -n get default 2>/dev/null | awk '/gateway:/{print $2}')"
    INTERFACE="$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')"
    LOCAL_IP="$(ipconfig getifaddr "$INTERFACE" 2>/dev/null)"

    printf '%b\n' "${CYAN}├─ Local Network ───────────────────────────────┤${RESET}"
    printf '%b\n' "${CYAN}│${RESET} ${BLUE}Local IPv4${RESET}  : ${GREEN}${LOCAL_IP:-N/A}${RESET}"
    printf '%b\n' "${CYAN}│${RESET} ${BLUE}Gateway${RESET}     : ${GREEN}${GATEWAY:-N/A}${RESET}"
    printf '%b\n' "${CYAN}│${RESET} ${BLUE}Interface${RESET}   : ${GREEN}${INTERFACE:-N/A}${RESET}"

    printf '%b\n' "${CYAN}│${RESET} ${BLUE}DNS${RESET}         :"
    scutil --dns 2>/dev/null |
        awk '/nameserver\[[0-9]+\]/{print $3}' |
        sort -u |
        while IFS= read -r dns; do
            [ -n "$dns" ] && printf '%b\n' "${CYAN}│${RESET}               ${GREEN}$dns${RESET}"
        done

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

    printf '%b\n' "${CYAN}├─ Local Network ───────────────────────────────┤${RESET}"
    printf '%b\n' "${CYAN}│${RESET} ${BLUE}Local IPv4${RESET}  : ${GREEN}${LOCAL_IP:-N/A}${RESET}"
    printf '%b\n' "${CYAN}│${RESET} ${BLUE}Gateway${RESET}     : ${GREEN}${GATEWAY:-N/A}${RESET}"
    printf '%b\n' "${CYAN}│${RESET} ${BLUE}Interface${RESET}   : ${GREEN}${INTERFACE:-N/A}${RESET}"

    printf '%b\n' "${CYAN}│${RESET} ${BLUE}DNS${RESET}         :"

    {
        if command -v resolvectl >/dev/null 2>&1; then
            resolvectl dns 2>/dev/null |
                awk '{for(i=3;i<=NF;i++) print $i}'
        else
            awk '/^nameserver/{print $2}' /etc/resolv.conf 2>/dev/null
        fi
    } | sort -u |
        while IFS= read -r dns; do
            [ -n "$dns" ] && printf '%b\n' "${CYAN}│${RESET}               ${GREEN}$dns${RESET}"
        done

else
    printf '%b\n' "${CYAN}│${RESET} ${BLUE}OS${RESET}          : ${YELLOW}$OS${RESET}"
    printf '%b\n' "${CYAN}│${RESET} ${YELLOW}Unsupported operating system${RESET}"
fi

printf '%b\n' "${CYAN}╰──────────────────────────────────────────────╯${RESET}"