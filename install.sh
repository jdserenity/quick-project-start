#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_script="$script_dir/new-proj"
target_dir="$HOME/.local/bin"
target_script="$target_dir/new-proj"

config_dir="$HOME/.config/new-proj"
config_file="$config_dir/config.env"
templates_dir="$config_dir/templates"
repo_templates_dir="$script_dir/templates"

if [[ ! -f "$source_script" ]]; then
  echo "Error: could not find source script at $source_script" >&2
  exit 1
fi

mkdir -p "$target_dir"
install -m 0755 "$source_script" "$target_script"

mkdir -p "$templates_dir"
bundled_dir="$config_dir/bundled"
mkdir -p "$bundled_dir"

sync_managed_templates() {
  if [[ -f "$script_dir/AGENTS.md" ]]; then
    cp "$script_dir/AGENTS.md" "$bundled_dir/AGENTS.md"
    cp "$script_dir/AGENTS.md" "$templates_dir/AGENTS.md"
  else
    echo "Warning: could not sync AGENTS.md (missing $script_dir/AGENTS.md)." >&2
  fi
  for file_name in ARCHITECTURE.md KNOWLEDGE.md README.md; do
    if [[ -f "$repo_templates_dir/$file_name" ]]; then
      cp "$repo_templates_dir/$file_name" "$templates_dir/$file_name"
    else
      echo "Warning: missing template $repo_templates_dir/$file_name; skipped." >&2
    fi
  done
  if [[ -f "$repo_templates_dir/.gitignore" ]]; then
    cp "$repo_templates_dir/.gitignore" "$templates_dir/.gitignore"
  fi
  if [[ -d "$repo_templates_dir/scripts" ]]; then
    mkdir -p "$templates_dir/scripts"
    cp -R "$repo_templates_dir/scripts/." "$templates_dir/scripts/"
  fi
  for deprecated in DEPLOY.md TODO.md; do
    rm -f "$templates_dir/$deprecated"
  done
}

sync_managed_templates

if [[ ! -f "$config_file" ]]; then
  cat <<'EOF' >"$config_file"
SCAFFOLD_DIR_NAME="docs"
EOF
fi

shell_integration="$config_dir/shell-integration.zsh"
shell_integration_marker="# new-proj shell integration (install.sh)"
if [[ -f "$script_dir/templates/shell-integration.zsh" ]]; then
  install -m 0644 "$script_dir/templates/shell-integration.zsh" "$shell_integration"
else
  echo "Warning: missing $script_dir/templates/shell-integration.zsh; skipped shell integration." >&2
fi

install_shell_integration_zshrc() {
  local integration_file="$1"
  local zshrc="$HOME/.zshrc"
  if [[ ! -f "$integration_file" ]]; then
    return 0
  fi
  # Fixed-string grep only (no zsh parsing). Skip append if marker or source line exists anywhere in the file.
  if [[ -f "$zshrc" ]] && {
    grep -qF "$shell_integration_marker" "$zshrc" ||
    grep -qF 'new-proj/shell-integration.zsh' "$zshrc"
  }; then
    echo "Shell integration: already in ~/.zshrc"
    return 0
  fi
  if [[ ! -f "$zshrc" ]]; then
    touch "$zshrc"
  fi
  {
    echo ""
    echo "$shell_integration_marker"
    printf 'source %q\n' "$integration_file"
  } >>"$zshrc"
  echo "Shell integration: added to ~/.zshrc"
}

echo "Installed: $target_script"
echo "Config: $config_file"
echo "Templates: $templates_dir (synced from repo)"
if [[ -f "$shell_integration" ]]; then
  echo "Shell integration: $shell_integration"
  install_shell_integration_zshrc "$shell_integration"
  echo "  Run: source ~/.zshrc   (or open a new terminal) so new-proj cds into new projects"
fi

if ! command -v new-proj >/dev/null 2>&1; then
  echo 'Note: `new-proj` is not on PATH in this shell yet.'
  echo 'Open a new terminal or run: source ~/.zshrc'
fi
