#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_script="$script_dir/new-proj"
target_dir="$HOME/.local/bin"
target_script="$target_dir/new-proj"

config_dir="$HOME/.config/new-proj"
config_file="$config_dir/config.env"
templates_dir="$config_dir/templates"

if [[ ! -f "$source_script" ]]; then
  echo "Error: could not find source script at $source_script" >&2
  exit 1
fi

mkdir -p "$target_dir"
install -m 0755 "$source_script" "$target_script"

mkdir -p "$templates_dir"

if [[ ! -f "$config_file" ]]; then
  cat <<'EOF' > "$config_file"
SCAFFOLD_DIR_NAME="docs"
EOF
fi

for file_name in AGENT.md ARCHITECTURE.md README.md DEPLOY.md TODO.md; do
  if [[ ! -f "$templates_dir/$file_name" ]]; then
    : > "$templates_dir/$file_name"
  fi
done

if [[ ! -f "$templates_dir/.gitignore" ]]; then
  cat <<'EOF' > "$templates_dir/.gitignore"
# OS files
.DS_Store

# Environment files
.env
.env.*
!.env.example

# JavaScript / TypeScript
node_modules/
dist/
build/
coverage/

# Python
.venv/
__pycache__/
*.pyc
EOF
fi

echo "Installed: $target_script"
echo "Config: $config_file"
echo "Templates: $templates_dir"

if ! command -v new-proj >/dev/null 2>&1; then
  echo 'Note: `new-proj` is not on PATH in this shell yet.'
  echo 'Open a new terminal or run: source ~/.zshrc'
fi
