#!/usr/bin/env bash

set -euo pipefail

ZABBIX_VERSION="7.0"
LOGFILE="/var/log/zabbix_agent_install.log"

exec > >(tee -a "$LOGFILE") 2>&1

echo "======================================"
echo " Zabbix Agent Installer"
echo "======================================"

retry_or_stop() {
    while true; do
        read -p "Retry operation? (r=retry / s=stop): " ACTION
        case "$ACTION" in
            r|R) return 0 ;;
            s|S) echo "Stopping script"; exit 1 ;;
            *) echo "Invalid option";;
        esac
    done
}

# Root check
if [[ $EUID -ne 0 ]]; then
    echo "Please run as root"
    exit 1
fi

read -p "Enter Zabbix Server IP/FQDN: " ZABBIX_SERVER

if [[ -z "$ZABBIX_SERVER" ]]; then
    echo "Server cannot be empty"
    exit 1
fi

ARCH=$(dpkg --print-architecture)
echo "Architecture: $ARCH"

source /etc/os-release
OS=$ID
VERSION=$VERSION_ID

echo "Detected OS: $OS $VERSION"

if [[ "$OS" == "ubuntu" ]]; then
    REPO_FILE="zabbix-release_${ZABBIX_VERSION}-1+ubuntu${VERSION}_all.deb"
    REPO_URL="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/ubuntu/pool/main/z/zabbix-release/${REPO_FILE}"

elif [[ "$OS" == "debian" ]]; then
    REPO_FILE="zabbix-release_${ZABBIX_VERSION}-1+debian${VERSION}_all.deb"
    REPO_URL="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/debian/pool/main/z/zabbix-release/${REPO_FILE}"

else
    echo "Unsupported OS"
    exit 1
fi

apt update -qq
apt install -y wget curl jq

echo "Installing Zabbix repository"

wget -q "$REPO_URL"
dpkg -i "$REPO_FILE"
apt update -qq

echo ""
echo "Checking existing Zabbix agent..."

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

    echo "No Zabbix agent installed"
    echo "Installing zabbix-agent2"

    apt install -y zabbix-agent2
    CONFIG_FILE="/etc/zabbix/zabbix_agent2.conf"
    AGENT_SERVICE="zabbix-agent2"

else

    echo "Existing agent detected: $AGENT_SERVICE"

    echo ""
    echo "Select action:"
    echo "1) Upgrade agent"
    echo "2) Update configuration only"
    echo "3) Skip installation"

    read -p "Choice: " ACTION

    case $ACTION in

        1)
            echo "Upgrading agent"
            apt install -y zabbix-agent2
            CONFIG_FILE="/etc/zabbix/zabbix_agent2.conf"
            AGENT_SERVICE="zabbix-agent2"
        ;;

        2)
            echo "Updating configuration only"
        ;;

        3)
            echo "Skipping installation"
            exit 0
        ;;

        *)
            echo "Invalid option"
            exit 1
        ;;

    esac
fi

# Backup config
if [[ -f "$CONFIG_FILE" ]]; then
    BACKUP="${CONFIG_FILE}.backup.$(date +%F-%H%M%S)"
    cp "$CONFIG_FILE" "$BACKUP"
    echo "Backup config saved: $BACKUP"
fi

HOSTNAME=$(hostname)

echo "Configuring agent"

sed -i "s/^Server=.*/Server=${ZABBIX_SERVER}/" "$CONFIG_FILE"
sed -i "s/^ServerActive=.*/ServerActive=${ZABBIX_SERVER}/" "$CONFIG_FILE"

if grep -q "^Hostname=" "$CONFIG_FILE"; then
    sed -i "s/^Hostname=.*/Hostname=${HOSTNAME}/" "$CONFIG_FILE"
else
    echo "Hostname=${HOSTNAME}" >> "$CONFIG_FILE"
fi

systemctl enable $AGENT_SERVICE
systemctl restart $AGENT_SERVICE

echo "Agent ready"

echo ""
read -p "Register host to Zabbix via API? (y/n): " REGISTER

if [[ "$REGISTER" != "y" ]]; then
    echo "Skipping registration"
    exit 0
fi

read -p "Zabbix API URL: " API_URL
read -p "Zabbix username: " API_USER
read -s -p "Zabbix password: " API_PASS
echo

# API connectivity
while true; do

    echo "Checking API connectivity..."

    if curl -s --connect-timeout 5 "$API_URL" >/dev/null; then
        break
    else
        echo "API not reachable"
        retry_or_stop
    fi

done

# API login
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
    echo "API login failed"
    retry_or_stop
else
    break
fi

done

echo "API login success"

IP=$(hostname -I | awk '{print $1}')

echo "Checking if host already exists"

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
    echo "Host already exists in Zabbix"
    exit 0
fi

echo "Creating host"

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
    echo "Host creation failed"
    echo "$RESPONSE" | jq
    exit 1
fi

echo "Host successfully registered"

echo ""
echo "======================================"
echo "Installation completed"
echo "Hostname : $HOSTNAME"
echo "IP       : $IP"
echo "Server   : $ZABBIX_SERVER"
echo "Log file : $LOGFILE"
echo "======================================"
