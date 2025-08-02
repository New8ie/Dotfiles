# ============================================
# 🔁 Virtualenv Management with pyenv
# ============================================
export VENV_HOME="$HOME/.config/venv"
export PROJECTS_HOME="$HOME/Projects"

# Membuat virtualenv: mkvenv nama_venv [3.10|3.11]
mkvenv() {
  local name="$1"
  local version="${2:-3.10}"
  local pybin

  if [[ -z "$name" ]]; then
    echo "🧠 Gunakan: mkvenv <nama> [versi]"
    return 1
  fi

  mkdir -p "$VENV_HOME"

  if ! pyenv versions --bare | grep -q "^${version}"; then
    echo "❌ Python ${version} belum terinstall di pyenv."
    return 1
  fi

  pybin="$(pyenv prefix ${version})/bin/python"

  echo "📦 Membuat venv '$name' dengan Python $version..."
  "$pybin" -m venv "$VENV_HOME/$name"
  echo "✅ Selesai. Gunakan: workon $name"
}

# Aktifkan venv dan auto-cd jika folder proyek ada
workon() {
  local name="$1"
  local venv_path="$VENV_HOME/$name"
  local project_path="$PROJECTS_HOME/$name"

  if [[ -z "$name" ]]; then
    echo "🧠 Gunakan: workon <nama>"
    return 1
  fi

  if [[ ! -d "$venv_path" ]]; then
    echo "❌ Venv '$name' tidak ditemukan di $VENV_HOME"
    return 1
  fi

  echo "⚡ Mengaktifkan venv '$name'..."
  source "$venv_path/bin/activate"

  if [[ -d "$project_path" ]]; then
    echo "📁 Berpindah ke direktori proyek: $project_path"
    cd "$project_path"
  fi
}

# Menghapus virtualenv
rmvenv() {
  local name="$1"
  local venv_path="$VENV_HOME/$name"

  if [[ -z "$name" || ! -d "$venv_path" ]]; then
    echo "❌ Venv '$name' tidak ditemukan."
    return 1
  fi

  echo "🗑 Menghapus venv '$name'..."
  rm -rf "$venv_path"
  echo "✅ Venv '$name' dihapus."
}

# ============================================
# 🔤 Auto-completion
# ============================================
_venv_complete() {
  compadd $(ls "$VENV_HOME")
}

compdef _venv_complete workon
compdef _venv_complete rmvenv
