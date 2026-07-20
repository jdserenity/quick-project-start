# Scaffold version helpers for --agent-version.
# Version lives on the last non-empty line of AGENT-WORKFLOW.md: "scaffold version: X.Y.Z"

read_agents_last_line() {
  local file="$1"
  awk 'NF { last = $0 } END { print last }' "$file"
}

read_scaffold_version_from_file() {
  local file="$1"
  local line
  if [[ ! -f "$file" ]]; then
    return 1
  fi
  line="$(read_agents_last_line "$file")"
  if [[ "$line" =~ ^scaffold\ version:\ ([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi
  # Older projects stored the version on root AGENTS.md.
  if [[ "$line" =~ ^AGENTS\.md\ version:\ ([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi
  return 1
}

# Prefer checkout scaffold/, then bundled/, then templates/, else embedded constant.
resolve_latest_workflow_path() {
  local templates_workflow
  if [[ -f "$SCRIPT_DIR/scaffold/AGENT-WORKFLOW.md" ]]; then
    printf '%s\n' "$SCRIPT_DIR/scaffold/AGENT-WORKFLOW.md"
    return 0
  fi
  if [[ -f "$bundled_dir/AGENT-WORKFLOW.md" ]]; then
    printf '%s\n' "$bundled_dir/AGENT-WORKFLOW.md"
    return 0
  fi
  templates_workflow="$config_dir/templates/AGENT-WORKFLOW.md"
  if [[ -f "$templates_workflow" && -s "$templates_workflow" ]]; then
    printf '%s\n' "$templates_workflow"
    return 0
  fi
  return 1
}

latest_scaffold_version() {
  local path version
  if path="$(resolve_latest_workflow_path)"; then
    if version="$(read_scaffold_version_from_file "$path")"; then
      printf '%s\n' "$version"
      return 0
    fi
  fi
  printf '%s\n' "$EMBEDDED_SCAFFOLD_VERSION"
}

run_agent_version() {
  local project_dir latest_ver project_file project_ver=""
  project_dir="$(find_project_root "$(pwd)")"
  latest_ver="$(latest_scaffold_version)"
  if ! project_file="$(project_workflow_file "$project_dir")"; then
    echo "project: (missing scaffold/AGENT-WORKFLOW.md)" >&2
    echo "latest: scaffold version: $latest_ver" >&2
    exit 1
  fi
  if project_ver="$(read_scaffold_version_from_file "$project_file")"; then
    echo "project: scaffold version: $project_ver" >&2
  else
    echo "project: (no version — last line: $(read_agents_last_line "$project_file"))" >&2
  fi
  echo "latest: scaffold version: $latest_ver" >&2
  if [[ -n "$project_ver" && "$project_ver" == "$latest_ver" ]]; then
    exit 0
  fi
  exit 1
}
