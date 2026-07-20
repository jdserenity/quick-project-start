# Copy / seed scaffold agent rule files (AGENT-COMMS.md, AGENT-WORKFLOW.md).
# Single source of truth in the repo: scaffold/AGENT-COMMS.md + scaffold/AGENT-WORKFLOW.md.
# Source order: checkout scaffold/ → ~/.config/quick-proj/bundled/ → embedded stub.

write_embedded_scaffold_agent_files() {
  local dest_dir="$1"
  mkdir -p "$dest_dir"
  cat <<'EOF' >"$dest_dir/AGENT-COMMS.md"
# Missing agent rules
Agent rule files were not found in checkout scaffold/ or ~/.config/quick-proj/bundled/.
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
  if [[ -f "$SCRIPT_DIR/scaffold/AGENT-WORKFLOW.md" && -f "$SCRIPT_DIR/scaffold/AGENT-COMMS.md" ]]; then
    printf '%s\n' "$SCRIPT_DIR/scaffold"
    return 0
  fi
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
