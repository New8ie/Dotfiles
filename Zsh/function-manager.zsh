# ======================================
# 🔧 Function Manager: f-list
# Version: 1.0
# ======================================

# Colors
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_BLUE="\033[1;34m"
COLOR_YELLOW="\033[1;33m"
COLOR_RESET="\033[0m"

# Default function directory
: "${FUNC_DIR:=$HOME/.config/zsh/functions}"

f-list() {
  echo
  echo -e "${COLOR_BLUE}📜 Available Function Modules${COLOR_RESET}"
  echo "────────────────────────────────────────────"

  # Check directory existence
  if [[ ! -d "$FUNC_DIR" ]]; then
    echo -e "${COLOR_RED}❌ Directory not found:${COLOR_RESET} $FUNC_DIR"
    return 1
  fi

  # List .zsh or .sh modules
  local modules=($(ls "$FUNC_DIR"/*.{zsh,sh} 2>/dev/null | xargs -n1 basename | sed 's/\.\(zsh\|sh\)$//'))

  if [[ ${#modules[@]} -eq 0 ]]; then
    echo -e "${COLOR_YELLOW}⚠️  No modules found in${COLOR_RESET} $FUNC_DIR"
    return 0
  fi

  local enabled_count=0
  local disabled_count=0

  for mod in "${modules[@]}"; do
    # Check if function exists in the current shell
    if declare -F "${mod}" >/dev/null; then
      echo -e "✅ ${COLOR_GREEN}${mod}${COLOR_RESET}  (enabled)"
      ((enabled_count++))
    else
      echo -e "❌ ${COLOR_RED}${mod}${COLOR_RESET}  (disabled)"
      ((disabled_count++))
    fi
  done

  echo
  echo "────────────────────────────────────────────"
  echo -e "🗂  Module directory : ${COLOR_BLUE}${FUNC_DIR}${COLOR_RESET}"
  echo -e "📊 Status Summary    : ${COLOR_GREEN}${enabled_count} enabled${COLOR_RESET}, ${COLOR_RED}${disabled_count} disabled${COLOR_RESET}"
  echo
}
