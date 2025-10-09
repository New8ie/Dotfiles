# ======================================
# 🔧 Zsh Function Manager Loader
# ======================================

export FUNC_DIR="$HOME/.config/zsh/functions"
export FUNC_MGR_DIR="$HOME/.config/zsh/manager"

# Load manager scripts
for mgr in f-enable f-disable f-list f-help; do
  [[ -f "$FUNC_MGR_DIR/${mgr}.zsh" ]] && source "$FUNC_MGR_DIR/${mgr}.zsh"
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
