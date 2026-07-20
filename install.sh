#!/usr/bin/env bash
# Install quick-proj into ~/.local/bin and sync templates + lib modules.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_script="$script_dir/quick-proj"
source_lib_dir="$script_dir/lib"
target_dir="$HOME/.local/bin"
target_script="$target_dir/quick-proj"
share_dir="$HOME/.local/share/quick-proj"
target_lib_dir="$share_dir/lib"

config_dir="$HOME/.config/quick-proj"
config_file="$config_dir/config.env"
templates_dir="$config_dir/templates"
repo_templates_dir="$script_dir/templates"
repo_scaffold_dir="$script_dir/scaffold"

shell_integration_marker="# quick-proj shell integration (install.sh)"

if [[ ! -f "$source_script" ]]; then
  echo "Error: could not find source script at $source_script" >&2
  exit 1
fi
if [[ ! -d "$source_lib_dir" ]]; then
  echo "Error: could not find lib directory at $source_lib_dir" >&2
  exit 1
fi

mkdir -p "$target_dir" "$target_lib_dir"
install -m 0755 "$source_script" "$target_script"
cp "$source_lib_dir/"*.sh "$target_lib_dir/"

mkdir -p "$templates_dir"
bundled_dir="$config_dir/bundled"
mkdir -p "$bundled_dir"

sync_managed_templates() {
  for file_name in AGENT-COMMS.md AGENT-WORKFLOW.md; do
    if [[ -f "$repo_scaffold_dir/$file_name" ]]; then
      cp "$repo_scaffold_dir/$file_name" "$bundled_dir/$file_name"
      cp "$repo_scaffold_dir/$file_name" "$templates_dir/$file_name"
    else
      echo "Warning: missing scaffold agent file $repo_scaffold_dir/$file_name; skipped." >&2
    fi
  done
  for file_name in ARCH-HUMAN.md ARCH-LLM.md README.md AGENTS.md sz.py; do
    if [[ -f "$repo_templates_dir/$file_name" ]]; then
      cp "$repo_templates_dir/$file_name" "$templates_dir/$file_name"
    else
      echo "Warning: missing template $repo_templates_dir/$file_name; skipped." >&2
    fi
  done
  if [[ -f "$repo_templates_dir/.gitignore" ]]; then
    cp "$repo_templates_dir/.gitignore" "$templates_dir/.gitignore"
  fi
  for deprecated in DEPLOY.md TODO.md ARCHITECTURE.md KNOWLEDGE.md AGENT-UNDERSTANDING.md PROJECT-KNOWLEDGE.md; do
    rm -f "$templates_dir/$deprecated"
    rm -f "$bundled_dir/$deprecated"
  done
}

sync_managed_templates

# If an old install still points at docs/, flip it to scaffold.
if [[ -f "$config_file" ]] && grep -qE '^SCAFFOLD_DIR_NAME="docs"' "$config_file"; then
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' 's|^SCAFFOLD_DIR_NAME="docs"|SCAFFOLD_DIR_NAME="scaffold"|' "$config_file"
  else
    sed -i 's|^SCAFFOLD_DIR_NAME="docs"|SCAFFOLD_DIR_NAME="scaffold"|' "$config_file"
  fi
  echo "Config: SCAFFOLD_DIR_NAME docs → scaffold"
fi

if [[ ! -f "$config_file" ]]; then
  cat <<'EOF' >"$config_file"
SCAFFOLD_DIR_NAME="scaffold"
EOF
fi

shell_integration="$config_dir/shell-integration.zsh"
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
  if [[ -f "$zshrc" ]] && {
    grep -qF "$shell_integration_marker" "$zshrc" ||
      grep -qF 'quick-proj/shell-integration.zsh' "$zshrc"
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
echo "Libraries: $target_lib_dir"
echo "Config: $config_file"
echo "Templates: $templates_dir (synced from repo)"
if [[ -f "$shell_integration" ]]; then
  echo "Shell integration: $shell_integration"
  install_shell_integration_zshrc "$shell_integration"
  echo "  Run: source ~/.zshrc   (or open a new terminal) so quick-proj cds into new projects"
fi

if ! command -v quick-proj >/dev/null 2>&1; then
  echo 'Note: `quick-proj` is not on PATH in this shell yet.'
  echo 'Open a new terminal or run: source ~/.zshrc'
fi
