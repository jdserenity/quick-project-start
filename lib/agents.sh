# Copy / seed scaffold agent rule files (AGENT-COMMS.md, AGENT-WORKFLOW.md).
# Product source in this repo: templates/AGENT-COMMS.md + templates/AGENT-WORKFLOW.md.
# Source order: checkout templates/ → templates_dir → bundled/ (legacy) → embedded stub.

write_embedded_scaffold_agent_files() {
  local dest_dir="$1"
  mkdir -p "$dest_dir"
  cat <<'EOF' >"$dest_dir/AGENT-COMMS.md"
# Missing agent rules
Agent rule files were not found in checkout templates/ or the installed templates directory.
Run `./install.sh` from the quick-project-start repo, then `quick-proj --update` in this project.
EOF
  cat <<'EOF' >"$dest_dir/AGENT-WORKFLOW.md"
# Missing agent rules
Run ./install.sh from the quick-project-start repo.

scaffold version: 0.0.0
EOF
}

# Resolve the directory that holds the latest AGENT-COMMS.md + AGENT-WORKFLOW.md.
resolve_agent_rules_src() {
  local installed_templates="${templates_dir:-$config_dir/templates}"
  if [[ -f "$SCRIPT_DIR/templates/AGENT-WORKFLOW.md" && -f "$SCRIPT_DIR/templates/AGENT-COMMS.md" ]]; then
    printf '%s\n' "$SCRIPT_DIR/templates"
    return 0
  fi
  if [[ -f "$installed_templates/AGENT-WORKFLOW.md" && -f "$installed_templates/AGENT-COMMS.md" ]]; then
    printf '%s\n' "$installed_templates"
    return 0
  fi
  # Legacy path from older installs.
  if [[ -f "$bundled_dir/AGENT-WORKFLOW.md" && -f "$bundled_dir/AGENT-COMMS.md" ]]; then
    printf '%s\n' "$bundled_dir"
    return 0
  fi
  return 1
}

write_scaffold_agent_files_to() {
  local dest_dir="$1"
  local src_dir
  mkdir -p "$dest_dir"
  if src_dir="$(resolve_agent_rules_src)"; then
    cp "$src_dir/AGENT-COMMS.md" "$dest_dir/AGENT-COMMS.md"
    cp "$src_dir/AGENT-WORKFLOW.md" "$dest_dir/AGENT-WORKFLOW.md"
    return 0
  fi
  write_embedded_scaffold_agent_files "$dest_dir"
}
