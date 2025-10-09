# ======================================
# 🔄 Auto-load enabled modules
# ======================================
export FUNC_DIR="$HOME/.config/zsh/functions"

# Load manager scripts
for manager in f-list f-enable f-disable f-help; do
  [[ -f "$HOME/.config/zsh/manager/${manager}.zsh" ]] && source "$HOME/.config/zsh/manager/${manager}.zsh"
done

# Auto-load enabled modules
if [[ -d "$FUNC_DIR" ]]; then
  for marker in "$FUNC_DIR"/.*.enabled; do
    [[ -f "$marker" ]] || continue
    mod=$(basename "$marker" | sed 's/^\.//' | sed 's/\.enabled$//')
    if [[ -f "$FUNC_DIR/${mod}.zsh" ]]; then
      source "$FUNC_DIR/${mod}.zsh"
      echo "🔹 Auto-loaded: $mod"
    fi
  done
fi
