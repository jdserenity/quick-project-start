# Config paths, scaffold folder naming, and project-root discovery.
# "docs" is a legacy folder name — we always prefer/create "scaffold" instead.

config_dir="${QUICK_PROJ_CONFIG_DIR:-$HOME/.config/quick-proj}"
bundled_dir="$config_dir/bundled"
config_file="${QUICK_PROJ_CONFIG_FILE:-$config_dir/config.env}"

# Canonical scaffold folder name from config/env.
# Legacy name "docs" is rewritten to "scaffold" so old configs stop creating docs/.
read_config_scaffold_dir_name() {
  local name="scaffold"
  if [[ -f "$config_file" ]]; then
    # shellcheck disable=SC1090
    . "$config_file"
    name="${QUICK_PROJ_SCAFFOLD_DIR_NAME:-${SCAFFOLD_DIR_NAME:-scaffold}}"
  fi
  if [[ "$name" == "docs" ]]; then
    name="scaffold"
  fi
  if [[ -z "$name" || "$name" == */* ]]; then
    return 1
  fi
  printf '%s\n' "$name"
}

load_scaffold_config() {
  if [[ -f "$config_file" ]]; then
    # shellcheck disable=SC1090
    . "$config_file"
  fi
  scaffold_dir_name="${QUICK_PROJ_SCAFFOLD_DIR_NAME:-${SCAFFOLD_DIR_NAME:-scaffold}}"
  if [[ "$scaffold_dir_name" == "docs" ]]; then
    scaffold_dir_name="scaffold"
  fi
  templates_dir="${QUICK_PROJ_TEMPLATES_DIR:-${TEMPLATES_DIR:-$config_dir/templates}}"
  if [[ -z "$scaffold_dir_name" || "$scaffold_dir_name" == */* ]]; then
    echo "Error: scaffold folder name must be a single directory name." >&2
    return 1
  fi
}

# If an old project still has docs/ and no scaffold/, rename it.
migrate_docs_folder_if_needed() {
  local project_dir="$1"
  if [[ -d "$project_dir/docs" && ! -e "$project_dir/scaffold" ]]; then
    mv "$project_dir/docs" "$project_dir/scaffold"
    echo "Renamed docs/ → scaffold/" >&2
  fi
}

# Walk up (or use git toplevel) to find the project root.
# Recognizes scaffold/, legacy docs/, or root AGENTS.md.
find_project_root() {
  local start="$1" scaffold_name root=""
  scaffold_name="$(read_config_scaffold_dir_name)" || {
    echo "Error: invalid scaffold folder name in config." >&2
    return 1
  }
  if command -v git >/dev/null 2>&1 && git -C "$start" rev-parse --show-toplevel >/dev/null 2>&1; then
    root="$(git -C "$start" rev-parse --show-toplevel)"
  else
    local cur="$start"
    while [[ "$cur" != "/" ]]; do
      if [[ -f "$cur/$scaffold_name/AGENT-WORKFLOW.md" || -f "$cur/docs/AGENT-WORKFLOW.md" || -f "$cur/AGENTS.md" ]]; then
        root="$cur"
        break
      fi
      cur="$(dirname "$cur")"
    done
  fi
  if [[ -z "$root" ]]; then
    echo "Error: could not find project root (not in a git repository and no scaffold/AGENT-WORKFLOW.md or AGENTS.md above current directory)." >&2
    return 1
  fi
  (cd "$root" && pwd -P)
}

project_workflow_file() {
  local project_dir="$1" scaffold_name
  scaffold_name="$(read_config_scaffold_dir_name)" || return 1
  if [[ -f "$project_dir/$scaffold_name/AGENT-WORKFLOW.md" ]]; then
    printf '%s\n' "$project_dir/$scaffold_name/AGENT-WORKFLOW.md"
    return 0
  fi
  if [[ -f "$project_dir/docs/AGENT-WORKFLOW.md" ]]; then
    printf '%s\n' "$project_dir/docs/AGENT-WORKFLOW.md"
    return 0
  fi
  if [[ -f "$project_dir/AGENTS.md" ]]; then
    printf '%s\n' "$project_dir/AGENTS.md"
    return 0
  fi
  return 1
}
