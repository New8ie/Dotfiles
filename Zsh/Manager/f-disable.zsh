# ======================================
# 🧩 Function Manager: f-disable
# Version: 1.0
# ======================================

f-disable() {
  local module="$1"

  if [[ -z "$module" ]]; then
    echo "⚠️  Usage: f-disable <module>"
    return 1
  fi

  # Hapus marker file
  local marker="$FUNC_DIR/.${module}.enabled"
  [[ -f "$marker" ]] && rm -f "$marker"

  # Hapus fungsi aktif di shell saat ini
  if declare -F "$module" >/dev/null; then
    unset -f "$module"
    echo "🧹 Disabled: $module"
  else
    echo "⚠️  Module '$module' not currently loaded."
  fi
}
