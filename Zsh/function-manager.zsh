# ======================================
# 🔧 Function Manager: f-list
# Version: 1.5 (Fix: multi-select, direct-number input, numeric mapping)
# ======================================

# Colors
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_BLUE="\033[1;34m"
COLOR_YELLOW="\033[1;33m"
COLOR_RESET="\033[0m"

# Default function directory (change if needed)
: "${FUNC_DIR:=$HOME/.config/zsh/functions}"

# Initialize session state for loaded modules
if ! typeset -p F_LIST_LOADED >/dev/null 2>&1; then
  typeset -gA F_LIST_LOADED
fi

# Helper: build global array F_LIST_MODULES (1-based indexing)
f-list__get_modules() {
  typeset -g -a F_LIST_MODULES
  setopt localoptions null_glob
  local files
  files=("$FUNC_DIR"/*.{zsh,sh})
  F_LIST_MODULES=()
  for file in "${files[@]}"; do
    [[ -f "$file" ]] || continue
    F_LIST_MODULES+=("${file:t:r}")
  done
}

# f-load: accepts module name or numeric index (1-based)
f-load() {
  local arg="$1"
  if [[ -z "$arg" ]]; then
    echo -e "${COLOR_YELLOW}⚠️  Usage:${COLOR_RESET} f-load <module_name|index>"
    return 1
  fi

  f-list__get_modules

  local mod file
  if [[ "$arg" == <-> ]]; then
    # Numeric argument -> map to module name
    if (( arg >= 1 && arg <= ${#F_LIST_MODULES[@]} )); then
      mod="${F_LIST_MODULES[$arg]}"
    else
      echo -e "${COLOR_YELLOW}⚠️  Invalid index:${COLOR_RESET} $arg"
      return 1
    fi
  else
    mod="$arg"
  fi

  file="$FUNC_DIR/$mod.zsh"
  [[ -r "$file" ]] || file="$FUNC_DIR/$mod.sh"
  if [[ ! -r "$file" ]]; then
    echo -e "❌ ${COLOR_RED}Module file not found:${COLOR_RESET} $mod"
    return 1
  fi

  # Source the module file
  source "$file"

  # Mark as loaded in this session
  F_LIST_LOADED[$mod]=1

  # Display success message (do not assume function name == file name)
  echo -e "✅ ${COLOR_GREEN}${mod}${COLOR_RESET} loaded successfully."
}

# f-list: show module list + interactive prompt (accepts Y/N, numbers, or names)
f-list() {
  echo
  echo -e "${COLOR_BLUE}📜 Available Function Modules${COLOR_RESET}"
  echo "────────────────────────────────────────────"

  # Ensure directory exists
  if [[ ! -d "$FUNC_DIR" ]]; then
    echo -e "${COLOR_RED}❌ Directory not found:${COLOR_RESET} $FUNC_DIR"
    return 1
  fi

  f-list__get_modules

  if (( ${#F_LIST_MODULES[@]} == 0 )); then
    echo -e "${COLOR_YELLOW}⚠️  No modules found in${COLOR_RESET} $FUNC_DIR"
    return 0
  fi

  local enabled_count=0 disabled_count=0
  local i mod

  echo -e "${COLOR_YELLOW}#️⃣  Index | Module Name | Status${COLOR_RESET}"
  echo "────────────────────────────────────────────"

  for ((i=1; i<=${#F_LIST_MODULES[@]}; i++)); do
    mod=${F_LIST_MODULES[i]}
    if [[ -n ${F_LIST_LOADED[$mod]} ]]; then
      echo -e " ${i}) ✅ ${COLOR_GREEN}${mod}${COLOR_RESET}  (enabled)"
      ((enabled_count++))
    else
      echo -e " ${i}) ❌ ${COLOR_RED}${mod}${COLOR_RESET}  (ready, not loaded)"
      ((disabled_count++))
    fi
  done

  echo
  echo "────────────────────────────────────────────"
  echo -e "🗂  Module directory : ${COLOR_BLUE}${FUNC_DIR}${COLOR_RESET}"
  echo -e "📊 Status Summary    : ${COLOR_GREEN}${enabled_count} enabled${COLOR_RESET}, ${COLOR_RED}${disabled_count} ready but not loaded${COLOR_RESET}"
  echo

  # Prompt: accept y/n or direct list of numbers/names
  echo -ne "${COLOR_YELLOW}💡 Load specific module(s)? (y/n) or enter number/name (e.g. 1 4 or fail2ban): ${COLOR_RESET}"
  read -r answer
  [[ -z "$answer" ]] && return 0

  local selection_arr
  if [[ "$answer" == [Yy] ]]; then
    echo -ne "Enter module number(s) or name(s), separated by space: "
    read -A selection_arr
    (( ${#selection_arr[@]} == 0 )) && return 0
  else
    # Treat input as list (split by whitespace)
    selection_arr=(${=answer})
  fi

  for item in "${selection_arr[@]}"; do
    f-load "$item" || true
  done

  echo
}
