# ======================================
# Fail2Ban Functions (with service check)
# ======================================


# --- Function to check if service is active ---
_check_fail2ban() {
  if ! systemctl is-active --quiet fail2ban; then
    echo "❌ Fail2Ban service is not running."
    echo "🧩 Run: sudo systemctl start fail2ban"
    return 1
  fi
  return 0
}

# === Color Codes ===
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# --- Reload Fail2Ban ---
f2b-reload() {
  _check_fail2ban || return 1
  echo "🔄 Reloading Fail2Ban configuration..."
  sudo fail2ban-client reload
}

# --- Restart Fail2Ban service ---
f2b-restart() {
  echo "♻️  Restarting Fail2Ban..."
  sudo systemctl restart fail2ban
}

# --- Status of all jails ---
f2b-status() {
  _check_fail2ban || return 1
  sudo fail2ban-client status
}

# --- View default Fail2Ban log realtime ---
f2b-log-default() {
  _check_fail2ban || return 1
  echo "📜 Viewing default Fail2Ban log (fail2ban.log)..."
  sudo tail -f /var/log/fail2ban.log
}

# --- View Cloudflare Fail2Ban log realtime ---
f2b-log-cloudflare() {
  _check_fail2ban || return 1
  echo "📜 Viewing Fail2Ban Cloudflare log (fail2ban-cloudflare.log)..."
  sudo tail -f /var/log/fail2ban-cloudflare.log
}

# --- Unban all IPs ---
f2b-unban-all() {
  _check_fail2ban || return 1
  echo "🔓 Unbanning all blocked IPs..."
  sudo fail2ban-client unban --all
}

# --- Ban IP in a specific jail ---
# Example: f2b-ban nextcloud 192.168.55.8
f2b-ban() {
  _check_fail2ban || return 1
  if [ $# -ne 2 ]; then
    echo "⚠️  Usage: f2b-ban <jail_name> <ip>"
    return 1
  fi
  echo "🚫 Blocking IP $2 in jail: $1"
  sudo fail2ban-client set "$1" banip "$2"
}

# --- Unban IP from a specific jail ---
# Example: f2b-unban nextcloud 192.168.55.8
f2b-unban() {
  _check_fail2ban || return 1
  if [ $# -ne 2 ]; then
    echo "⚠️  Usage: f2b-unban <jail_name> <ip>"
    return 1
  fi
  echo "🔓 Unblocking IP $2 from jail: $1"
  sudo fail2ban-client set "$1" unbanip "$2"
}

# --- View list of filters ---
f2b-filters() {
  _check_fail2ban || return 1
  echo "📄 Available Filters:"
  sudo eza --icons --group-directories-first -AolhM /etc/fail2ban/filter.d
}

# --- View list of actions ---
f2b-actions() {
  _check_fail2ban || return 1
  echo "📄 Available Actions:"
  sudo eza --icons --group-directories-first -AolhM /etc/fail2ban/action.d
}

# ======================================
# Usage Help (HELP)
# ======================================
f2b-help() {
  # All help text colored green
  echo -e "${GREEN}📘 Fail2Ban Utility Help${NC}"
  echo -e "${GREEN}---------------------------------------------${NC}"
  echo -e "${GREEN}🔧 Available Functions & Aliases:${NC}"
  echo ""
  echo -e "${GREEN}  f2b-status         → Display status of all jails${NC}"
  echo -e "${GREEN}  f2b-reload         → Reload Fail2Ban configuration${NC}"
  echo -e "${GREEN}  f2b-restart        → Restart Fail2Ban service${NC}"
  echo -e "${GREEN}  f2b-log-default    → View default Fail2Ban log realtime${NC}"
  echo -e "${GREEN}  f2b-log-cloudflare → View Fail2Ban Cloudflare log realtime${NC}"
  echo -e "${GREEN}  f2b-unban-all      → Unban all IPs${NC}"
  echo ""
  echo -e "${GREEN}  f2b-ban <jail> <ip>    → Block IP in a specific jail${NC}"
  echo -e "${GREEN}  f2b-unban <jail> <ip>  → Unblock IP from a specific jail${NC}"
  echo ""
  echo -e "${GREEN}  f2b-filters            → Display available filters${NC}"
  echo -e "${GREEN}  f2b-actions            → Display available actions${NC}"
  echo ""
  echo -e "${GREEN}---------------------------------------------${NC}"
  echo -e "${GREEN}🧩 Before running any function, the script will check${NC}"
  echo -e "${GREEN}   if the Fail2Ban service is active. If not, the message is:${NC}"
  echo -e "${GREEN}   ❌ Fail2Ban service is not running.${NC}"
  echo ""
  echo -e "${GREEN}🧰 Usage Examples:${NC}"
  echo -e "${GREEN}   f2b-status${NC}"
  echo -e "${GREEN}   f2b-ban nextcloud 192.168.55.8${NC}"
  echo -e "${GREEN}   f2b-unban sshd 10.10.10.5${NC}"
  echo -e "${GREEN}   f2b-unban-all${NC}"
  echo -e "${GREEN}   f2b-log-default${NC}"
  echo -e "${GREEN}   f2b-log-cloudflare${NC}"
  echo ""
  echo -e "${GREEN}---------------------------------------------${NC}"
}

echo -e "${GREEN}✅ Fail2Ban function alias loaded.${NC}"