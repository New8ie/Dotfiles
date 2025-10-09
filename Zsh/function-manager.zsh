# ======================================
# Zsh Function Manager
# Manually enable, disable, list, and help for function modules
# ======================================

FUNC_DIR="$HOME/.config/zsh/functions"

# ------------------------------
# Show help menu
# ------------------------------
f-help() {
  cat <<EOF

🧩 Zsh Function Manager Commands
────────────────────────────────────────
f-enable <name>   → Enable a function module (e.g. f-enable docker)
f-disable <name>  → Disable a loaded function
f-list            → List all available function modules
f-help            → Show this help message

Modules are located in:
  $FUNC_DIR

Example:
  f-enable fail2ban
  f-disable docker
EOF
}

# ------------------------------
# Enable a function
# ------------------------------
f-enable() {
  local name="$1"
  local func_file="$FUNC_DIR/${name}.zsh"

  if [ -z "$name" ]; then
    echo "⚠️ Usage: f-enable <name>"
    return 1
  fi

  if [ ! -r "$func_file" ]; then
    echo "❌ Function file not found: $func_file"
    return 1
  fi

  # Source the function file
  source "$func_file" && echo "✅ Function '$name' enabled."
}

# ------------------------------
# Disable a function
# ------------------------------
f-disable() {
  local name="$1"

  if [ -z "$name" ]; then
    echo "⚠️ Usage: f-disable <name>"
    return 1
  fi

  unset -f "$name" 2>/dev/null
  unalias "$name" 2>/dev/null

  echo "🚫 Function '$name' disabled."
}

# ------------------------------
# List available functions
# ------------------------------
f-list() {
  if [ ! -d "$FUNC_DIR" ]; then
    echo "⚠️ Function directory not found: $FUNC_DIR"
    return 1
  fi

  echo "📜 Available function modules:"
  echo "───────────────────────────────"

  local file
  for file in "$FUNC_DIR"/*.zsh; do
    local name
    name=$(basename "$file" .zsh)

    if whence -w "$name" &>/dev/null; then
      echo "✅ $name (enabled)"
    else
      echo "❌ $name (disabled)"
    fi
  done
}

# ------------------------------
# Startup message
# ------------------------------
echo "🧩 Zsh Function Manager loaded. Use 'f-help' for available commands."
