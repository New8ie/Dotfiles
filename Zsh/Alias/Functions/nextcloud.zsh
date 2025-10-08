#!/usr/bin/env zsh
# ======================================
# Nextcloud Function
# ======================================
# Created by Bro Fachmi
# Version with help function
# ======================================

# Default path to Nextcloud installation
NEXTCLOUD_PATH="/var/www/nextcloud"
PHP_BIN="$(command -v php)"
NC_LOG="$HOME/.config/zsh/logs/nextcloud.log"
DATE="$(date +"%d-%m-%Y %H:%M:%S")"

# Ensure log folder exists
mkdir -p "$(dirname "$NC_LOG")"

# === Color Codes ===
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# ======================================
# Main OCC function
# ======================================
occ() {
  # Check if PHP is available
  if [ -z "$PHP_BIN" ]; then
    echo "❌ PHP not found in PATH."
    echo "[$DATE] ❌ PHP not found" >> "$NC_LOG"
    return 1
  fi

  # Check if Nextcloud directory exists
  if [ ! -d "$NEXTCLOUD_PATH" ]; then
    echo "❌ Nextcloud directory not found at: $NEXTCLOUD_PATH"
    echo "[$DATE] ❌ Nextcloud directory not found: $NEXTCLOUD_PATH" >> "$NC_LOG"
    return 1
  fi

  echo "⚙️  Running OCC command as www-data..."
  echo "[$DATE] ▶️ occ $*" >> "$NC_LOG"

  sudo -u www-data "$PHP_BIN" "$NEXTCLOUD_PATH/occ" "$@"
}

# ======================================
# Additional Shortcuts (common OCC aliases)
# ======================================

# Display Nextcloud status
alias nc-status='occ status'

# Check Nextcloud system integrity
alias nc-check='occ integrity:check-core'

# Clean file cache and repair database
alias nc-maintenance='occ maintenance:repair && occ db:add-missing-indices'

# Run Nextcloud upgrade
alias nc-update='occ upgrade'

# View Nextcloud application logs
alias nc-log='sudo tail -f /var/log/nextcloud/nextcloud.log'

# View active users
alias nc-users='occ user:list'

# Enable/disable maintenance mode
alias nc-on='occ maintenance:mode --on'
alias nc-off='occ maintenance:mode --off'

# ======================================
# Help Function
# ======================================
nc-help() {
  # All help text colored green
  echo -e "${GREEN}📘 Nextcloud OCC Utility Help${NC}"
  echo -e "${GREEN}---------------------------------------------${NC}"
  echo -e "${GREEN}🔧 Available Functions & Aliases:${NC}"
  echo ""
  echo -e "${GREEN}  occ <command>          → Run an OCC command as www-data${NC}"
  echo -e "${GREEN}  nc-status              → Display Nextcloud status${NC}"
  echo -e "${GREEN}  nc-check               → Check core file integrity${NC}"
  echo -e "${GREEN}  nc-maintenance         → Clean cache & repair DB${NC}"
  echo -e "${GREEN}  nc-update              → Run the Nextcloud upgrade process${NC}"
  echo -e "${GREEN}  nc-log                 → View Nextcloud logs in realtime${NC}"
  echo -e "${GREEN}  nc-users               → Display a list of users${NC}"
  echo -e "${GREEN}  nc-on / nc-off         → Enable / disable maintenance mode${NC}"
  echo ""
  echo -e "${GREEN}---------------------------------------------${NC}"
  echo -e "${GREEN}🧩 Activity logs are saved at:${NC}"
  echo -e "${GREEN}  $NC_LOG${NC}"
  echo ""
  echo -e "${GREEN}🧰 Usage Examples:${NC}"
  echo -e "${GREEN}   occ status${NC}"
  echo -e "${GREEN}   occ maintenance:mode --on${NC}"
  echo -e "${GREEN}   nc-maintenance${NC}"
  echo -e "${GREEN}   nc-update${NC}"
  echo -e "${GREEN}   nc-log${NC}"
  echo ""
  echo -e "${GREEN}---------------------------------------------${NC}"
  echo -e "${GREEN}⚙️  Current Nextcloud directory:${NC}"
  echo -e "${GREEN}  $NEXTCLOUD_PATH${NC}"
  echo -e "${GREEN}---------------------------------------------${NC}"
}


echo -e "${GREEN}✅ Nextcloud function loaded.${NC}"