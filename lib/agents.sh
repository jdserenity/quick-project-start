# Copy / seed scaffold agent rule files (AGENT-COMMS.md, AGENT-WORKFLOW.md).
# Source order: explicit primary_src → checkout scaffold/ → bundled/ → templates/ → embedded fallback.

write_embedded_scaffold_agent_files() {
  local dest_dir="$1"
  mkdir -p "$dest_dir"
  cat <<'EOF' >"$dest_dir/AGENT-COMMS.md"
# Documentation layout
- Project documentation lives under scaffold/: scaffold/ARCH-HUMAN.md, scaffold/ARCH-LLM.md, and scaffold/skills/.
- One home per fact: if you are going to record something in one file, do not record it in another.

# Communication with the maintainer
The maintainer is still leveling up as an engineer. Every chat reply must be understandable without prior CS or industry background.

- Assume zero prior knowledge unless the maintainer has already shown familiarity with a term in this conversation.
- Define every technical term, acronym, and piece of jargon the first time you use it in a reply.
- Do not move long explainers into scaffold/ARCH-HUMAN.md — teach in chat unless the maintainer explicitly asks for an explanation in the repo.
EOF
  cat <<EOF >"$dest_dir/AGENT-WORKFLOW.md"
# Code style
- Indentation: 2 spaces everywhere (Python and TypeScript).

# Commit Rules
- Create commits without being asked — that is normal on this project. Only push when the user explicitly asks.

# Definition of done
1. It does what we agreed it should do.
2. Automated tests cover that behavior.
3. scaffold/ARCH-LLM.md updated when facts change; scaffold/ARCH-HUMAN.md when a readable summary helps.
4. Work is committed in small logical commits — not left uncommitted, not batched at the end.

scaffold version: $EMBEDDED_SCAFFOLD_VERSION
EOF
}

write_scaffold_agent_files_to() {
  local dest_dir="$1"
  local primary_src="${2:-}"
  local workflow_src comms_src
  mkdir -p "$dest_dir"
  if [[ -n "$primary_src" && -f "$primary_src/AGENT-WORKFLOW.md" && -f "$primary_src/AGENT-COMMS.md" ]]; then
    cp "$primary_src/AGENT-COMMS.md" "$dest_dir/AGENT-COMMS.md"
    cp "$primary_src/AGENT-WORKFLOW.md" "$dest_dir/AGENT-WORKFLOW.md"
    return 0
  fi
  for workflow_src in \
    "$SCRIPT_DIR/scaffold/AGENT-WORKFLOW.md" \
    "$bundled_dir/AGENT-WORKFLOW.md" \
    "$config_dir/templates/AGENT-WORKFLOW.md"; do
    comms_src="${workflow_src%/AGENT-WORKFLOW.md}/AGENT-COMMS.md"
    if [[ -f "$workflow_src" && -f "$comms_src" ]]; then
      cp "$comms_src" "$dest_dir/AGENT-COMMS.md"
      cp "$workflow_src" "$dest_dir/AGENT-WORKFLOW.md"
      return 0
    fi
  done
  write_embedded_scaffold_agent_files "$dest_dir"
}
