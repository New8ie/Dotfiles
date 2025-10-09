# ======================================
# 📖 Function Manager: f-help
# Version: 1.0
# ======================================

f-help() {
  echo
  echo "🧩 Zsh Function Manager"
  echo "────────────────────────────────────────────"
  echo "📦 Commands:"
  echo "  f-list             → List available modules & status"
  echo "  f-enable <name>    → Enable a module (e.g. f-enable docker)"
  echo "  f-disable <name>   → Disable a loaded module"
  echo "  f-help             → Show this help menu"
  echo
  echo "⚙️  Module Directory: $FUNC_DIR"
  echo "💾 Persistent State : .<module>.enabled marker"
  echo
  echo "Example:"
  echo "  f-enable fail2ban"
  echo "  f-disable docker"
  echo
}
