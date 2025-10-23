# ======================================
# Wazuh Management Function
# ======================================


# Log location for CLI activity
WAZUH_LOG="$HOME/.config/zsh/logs/wazuh.log"
mkdir -p "$(dirname "$WAZUH_LOG")"

# === Color Codes ===
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# ======================================
# Service Check Function
# ======================================
_check_wazuh() {
  if ! systemctl is-active --quiet wazuh-manager; then
    echo "❌ Wazuh Manager service is not running."
    echo "🧩 Run: sudo systemctl start wazuh-manager"
    return 1
  fi
  return 0
}

# ======================================
# Main Functions
# ======================================

# Wazuh Manager Status
wazuh-status() {
  _check_wazuh || return 1
  local DATE=$(date +"%d-%m-%Y %H:%M:%S")
  echo "🧠 Wazuh Manager Status:"
  echo "[$DATE] ▶️ wazuh-status" >> "$WAZUH_LOG"
  sudo systemctl status wazuh-manager --no-pager
}

# Restart Wazuh Manager
wazuh-restart() {
  local DATE=$(date +"%d-%m-%Y %H:%M:%S")
  echo "♻️ Restarting Wazuh Manager..."
  echo "[$DATE] 🔄 wazuh-restart" >> "$WAZUH_LOG"
  sudo systemctl restart wazuh-manager
}

# Stop Wazuh Manager
wazuh-stop() {
  local DATE=$(date +"%d-%m-%Y %H:%M:%S")
  echo "🛑 Stopping Wazuh Manager..."
  echo "[$DATE] ⏹️ wazuh-stop" >> "$WAZUH_LOG"
  sudo systemctl stop wazuh-manager
}

# Start Wazuh Manager
wazuh-start() {
  local DATE=$(date +"%d-%m-%Y %H:%M:%S")
  echo "🚀 Starting Wazuh Manager..."
  echo "[$DATE] ▶️ wazuh-start" >> "$WAZUH_LOG"
  sudo systemctl start wazuh-manager
}

# View Wazuh Manager logs in realtime
wazuh-log() {
  _check_wazuh || return 1
  echo "📜 Displaying Wazuh Manager log..."
  sudo tail -f /var/ossec/logs/ossec.log
}

# View list of agents
wazuh-agents() {
  _check_wazuh || return 1
  echo "👥 List of agents registered with Wazuh:"
  sudo /var/ossec/bin/agent_control -l
}

# View detail for a specific agent
# Example: wazuh-agent-info 001
wazuh-agent-info() {
  _check_wazuh || return 1
  if [ -z "$1" ]; then
    echo "⚠️ Usage: wazuh-agent-info <agent_id>"
    return 1
  fi
  sudo /var/ossec/bin/agent_control -i "$1"
}

# Run manual rule test
# Example: wazuh-test-rule /var/ossec/logs/alerts/alerts.json
wazuh-test-rule() {
  _check_wazuh || return 1
  if [ -z "$1" ]; then
    echo "⚠️ Usage: wazuh-test-rule <log_path>"
    return 1
  fi
  # Read log content and pipe it to ossec-logtest for rule testing
  sudo /var/ossec/bin/ossec-logtest < "$1"
}

# Run restart for a specific agent
# Example: wazuh-restart-agent 001
wazuh-restart-agent() {
  _check_wazuh || return 1
  if [ -z "$1" ]; then
    echo "⚠️ Usage: wazuh-restart-agent <agent_id>"
    return 1
  fi
  sudo /var/ossec/bin/agent_control -R "$1"
}

# ======================================
# Help Function
# ======================================
wazuh-help() {
  # All help text colored green
  echo -e "${GREEN}📘 Wazuh Management CLI Help${NC}"
  echo -e "${GREEN}---------------------------------------------${NC}"
  echo -e "${GREEN}🔧 Available Functions & Aliases:${NC}"
  echo ""
  echo -e "${GREEN}  wazuh-status             → Display Wazuh Manager service status${NC}"
  echo -e "${GREEN}  wazuh-start              → Start Wazuh Manager${NC}"
  echo -e "${GREEN}  wazuh-stop               → Stop Wazuh Manager${NC}"
  echo -e "${GREEN}  wazuh-restart            → Restart Wazuh Manager${NC}"
  echo -e "${GREEN}  wazuh-log                → View realtime log (ossec.log)${NC}"
  echo -e "${GREEN}  wazuh-agents             → List all registered agents${NC}"
  echo -e "${GREEN}  wazuh-agent-info <id>    → Detailed info for agent by ID${NC}"
  echo -e "${GREEN}  wazuh-restart-agent <id> → Restart a specific agent${NC}"
  echo -e "${GREEN}  wazuh-test-rule <file>   → Test a log file against Wazuh rules${NC}"
  echo ""
  echo -e "${GREEN}---------------------------------------------${NC}"
  echo -e "${GREEN}🧩 Activity logs are saved at:${NC}"
  echo -e "${GREEN}  $WAZUH_LOG${NC}"
  echo ""
  echo -e "${GREEN}🧰 Usage Examples:${NC}"
  echo -e "${GREEN}   wazuh-status${NC}"
  echo -e "${GREEN}   wazuh-agents${NC}"
  echo -e "${GREEN}   wazuh-agent-info 001${NC}"
  echo -e "${GREEN}   wazuh-test-rule /var/ossec/logs/alerts/alerts.json${NC}"
  echo ""
  echo -e "${GREEN}---------------------------------------------${NC}"
}

echo -e "${GREEN}✅ Wazuh function loaded.${NC}"