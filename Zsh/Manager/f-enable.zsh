# ======================================
# 🚀 Function Manager: f-enable
# Version: 1.0
# ======================================

f-enable() {
  local module="$1"

  if [[ -z "$module" ]]; then
    echo "⚠️  Usage: f-enable <module>"
    return 1
  fi

  local file_zsh="$FUNC_DIR/${module}.zsh"
  local file_sh="$FUNC_DIR/${module}.sh"
  local target_file=""

  if [[ -f "$file_zsh" ]]; then
    target_file="$file_zsh"
  elif [[ -f "$file_sh" ]]; then
    target_file="$file_sh"
  else
    echo "❌ Module not found: $module"
    return 1
  fi

  # Source file
  source "$target_file" && echo "✅ Loaded: $module"

  # Marker file (persistent status)
  touch "$FUNC_DIR/.${module}.enabled"
}
