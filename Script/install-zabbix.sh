#!/usr/bin/env bash

set -euo pipefail

ZABBIX_VERSION="7.0"
LOGFILE="/var/log/zabbix_agent_install.log"

# ===== COLOR =====
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

log_info() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

log_ok() {
    echo -e "${GREEN}[OK]${RESET} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

log_step() {
    echo -e "\n${CYAN}▶ $1${RESET}"
}

exec > >(tee -a "$LOGFILE") 2>&1

echo -e "${CYAN}"
echo "======================================"
echo "        Zabbix Agent Installer"
echo "======================================"
echo -e "${RESET}"

retry_or_stop() {
    while true; do
        read -p "Retry operation? (r=retry / s=stop): " ACTION
        case "$ACTION" in
            r|R) return 0 ;;
            s|S) log_error "Stopping script"; exit 1 ;;
            *) log_warn "Invalid option";;
        esac
    done
}

# root check
if [[ $EUID -ne 0 ]]; then
    log_error "Please run as root"
    exit 1
fi

read -p "Enter Zabbix Server IP/FQDN: " ZABBIX_SERVER

if [[ -z "$ZABBIX_SERVER" ]]; then
    log_error "Server cannot be empty"
    exit 1
fi

ARCH=$(dpkg --print-architecture)
log_info "Architecture: $ARCH"

source /etc/os-release
OS=$ID
VERSION=$VERSION_ID

log_info "Detected OS: $OS $VERSION"

if [[ "$OS" == "ubuntu" ]]; then
    REPO_FILE="zabbix-release_${ZABBIX_VERSION}-1+ubuntu${VERSION}_all.deb"
    REPO_URL="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/ubuntu/pool/main/z/zabbix-release/${REPO_FILE}"

elif [[ "$OS" == "debian" ]]; then
    REPO_FILE="zabbix-release_${ZABBIX_VERSION}-1+debian${VERSION}_all.deb"
    REPO_URL="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/debian/pool/main/z/zabbix-release/${REPO_FILE}"

else
    log_error "Unsupported OS"
    exit 1
fi

log_step "Installing dependencies"

apt update -qq
apt install -y wget curl jq

log_step "Installing Zabbix repository"

wget -q "$REPO_URL"
dpkg -i "$REPO_FILE"
apt update -qq

log_step "Checking existing Zabbix agent"

AGENT_INSTALLED="none"

if dpkg -l | grep -q zabbix-agent2; then
    AGENT_INSTALLED="agent2"
    CONFIG_FILE="/etc/zabbix/zabbix_agent2.conf"
    AGENT_SERVICE="zabbix-agent2"
elif dpkg -l | grep -q zabbix-agent; then
    AGENT_INSTALLED="agent"
    CONFIG_FILE="/etc/zabbix/zabbix_agentd.conf"
    AGENT_SERVICE="zabbix-agent"
fi

if [[ "$AGENT_INSTALLED" == "none" ]]; then

    log_warn "No Zabbix agent installed"
    log_info "Installing zabbix-agent2"

    apt install -y zabbix-agent2
    CONFIG_FILE="/etc/zabbix/zabbix_agent2.conf"
    AGENT_SERVICE="zabbix-agent2"

else

    log_warn "Existing agent detected: $AGENT_SERVICE"

    echo ""
    echo "Select action:"
    echo "1) Upgrade agent"
    echo "2) Update configuration only"
    echo "3) Skip installation"

    read -p "Choice: " ACTION

    case $ACTION in

        1)
            log_info "Upgrading agent"
            apt install -y zabbix-agent2
            CONFIG_FILE="/etc/zabbix/zabbix_agent2.conf"
            AGENT_SERVICE="zabbix-agent2"
        ;;

        2)
            log_info "Updating configuration only"
        ;;

        3)
            log_warn "Skipping installation"
            exit 0
        ;;

        *)
            log_error "Invalid option"
            exit 1
        ;;

    esac
fi

# Backup config
if [[ -f "$CONFIG_FILE" ]]; then
    BACKUP="${CONFIG_FILE}.backup.$(date +%F-%H%M%S)"
    cp "$CONFIG_FILE" "$BACKUP"
    log_ok "Backup config saved: $BACKUP"
fi

HOSTNAME=$(hostname)

log_step "Configuring agent"

sed -i "s/^Server=.*/Server=${ZABBIX_SERVER}/" "$CONFIG_FILE"
sed -i "s/^ServerActive=.*/ServerActive=${ZABBIX_SERVER}/" "$CONFIG_FILE"

if grep -q "^Hostname=" "$CONFIG_FILE"; then
    sed -i "s/^Hostname=.*/Hostname=${HOSTNAME}/" "$CONFIG_FILE"
else
    echo "Hostname=${HOSTNAME}" >> "$CONFIG_FILE"
fi

systemctl enable $AGENT_SERVICE
systemctl restart $AGENT_SERVICE

log_ok "Agent service running"

echo ""
read -p "Register host to Zabbix via API? (y/n): " REGISTER

REGISTER_STATUS="Skipped"

if [[ "$REGISTER" == "y" ]]; then

read -p "Zabbix API URL: " API_URL
read -p "Zabbix username: " API_USER
read -s -p "Zabbix password: " API_PASS
echo

while true; do

log_step "Checking API connectivity"

if curl -s --connect-timeout 5 "$API_URL" >/dev/null; then
    break
else
    log_error "API not reachable"
    retry_or_stop
fi

done

while true; do

AUTH_TOKEN=$(curl -s -X POST "$API_URL" \
-H "Content-Type: application/json" \
-d "{
\"jsonrpc\":\"2.0\",
\"method\":\"user.login\",
\"params\":{
\"username\":\"$API_USER\",
\"password\":\"$API_PASS\"
},
\"id\":1
}" | jq -r '.result')

if [[ "$AUTH_TOKEN" == "null" || -z "$AUTH_TOKEN" ]]; then
    log_error "API login failed"
    retry_or_stop
else
    break
fi

done

log_ok "API login success"

IP=$(hostname -I | awk '{print $1}')

HOST_EXIST=$(curl -s -X POST "$API_URL" \
-H "Content-Type: application/json" \
-d "{
\"jsonrpc\":\"2.0\",
\"method\":\"host.get\",
\"params\":{\"filter\":{\"host\":[\"$HOSTNAME\"]}},
\"auth\":\"$AUTH_TOKEN\",
\"id\":1
}" | jq '.result | length')

if [[ "$HOST_EXIST" -gt 0 ]]; then
    log_warn "Host already exists in Zabbix"
    REGISTER_STATUS="Already exists"
else

RESPONSE=$(curl -s -X POST "$API_URL" \
-H "Content-Type: application/json" \
-d "{
\"jsonrpc\":\"2.0\",
\"method\":\"host.create\",
\"params\":{
\"host\":\"$HOSTNAME\",
\"interfaces\":[
{
\"type\":1,
\"main\":1,
\"useip\":1,
\"ip\":\"$IP\",
\"dns\":\"\",
\"port\":\"10050\"
}
],
\"groups\":[{\"groupid\":\"2\"}],
\"templates\":[{\"templateid\":\"10001\"}]
},
\"auth\":\"$AUTH_TOKEN\",
\"id\":1
}")

ERROR=$(echo "$RESPONSE" | jq -r '.error')

if [[ "$ERROR" != "null" ]]; then
    log_error "Host creation failed"
    echo "$RESPONSE" | jq
    REGISTER_STATUS="Failed"
else
    log_ok "Host successfully registered"
    REGISTER_STATUS="Success"
fi

fi
fi

echo ""
echo -e "${CYAN}======================================"
echo "          INSTALLATION SUMMARY"
echo "======================================${RESET}"

echo -e "Hostname        : ${GREEN}$HOSTNAME${RESET}"
echo -e "IP Address      : ${GREEN}$(hostname -I | awk '{print $1}')${RESET}"
echo -e "Zabbix Server   : ${GREEN}$ZABBIX_SERVER${RESET}"
echo -e "Agent Service   : ${GREEN}$AGENT_SERVICE${RESET}"
echo -e "Registration    : ${GREEN}$REGISTER_STATUS${RESET}"
echo -e "Log File        : ${GREEN}$LOGFILE${RESET}"

echo -e "${CYAN}======================================${RESET}"