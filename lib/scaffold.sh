# Creating / inserting scaffold files into a project directory.

copy_scaffold_scripts() {
  local project_dir="$1" skip_existing="$2" announce="$3"
  local file_name template_file target_file
  for file_name in sz.py; do
    template_file="$templates_dir/$file_name"
    target_file="$project_dir/scripts/$file_name"
    [[ -f "$template_file" ]] || continue
    if [[ "$skip_existing" -eq 1 && -f "$target_file" ]]; then continue; fi
    mkdir -p "$project_dir/scripts"
    cp "$template_file" "$target_file"
    if [[ "$announce" -eq 1 ]]; then echo "Added: scripts/$file_name" >&2; fi
  done
}

ensure_gitignore_template() {
  local gitignore_template="$1"
  if [[ ! -f "$gitignore_template" ]]; then
    cat <<'EOF' > "$gitignore_template"
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
}

ensure_template_stubs() {
  local file_name template_file
  # Agent rules are seeded into projects from templates/ (or bundled/); stubs are for blank docs only.
  for file_name in "${SCAFFOLD_DOC_FILES[@]}" README.md AGENTS.md; do
    template_file="$templates_dir/$file_name"
    if [[ ! -f "$template_file" ]]; then
      : >"$template_file"
    fi
  done
}

# Populate scaffold/ (and root helpers) for a new or --existing project.
apply_scaffold_to_project() {
  local project_dir="$1"
  local existing_mode="$2" # 1 = --existing (preserve some files)
  local scaffold_dir root_files file_name template_file target_file agent_skip
  local gitignore_template gitignore_target

  migrate_docs_folder_if_needed "$project_dir"
  scaffold_dir="$project_dir/$scaffold_dir_name"

  mkdir -p "$templates_dir" "$scaffold_dir" "$scaffold_dir/skills"
  ensure_template_stubs

  root_files=(README.md AGENTS.md)
  for file_name in "${root_files[@]}"; do
    template_file="$templates_dir/$file_name"
    target_file="$project_dir/$file_name"
    if [[ ! -f "$template_file" ]]; then : >"$template_file"; fi
    if [[ "$existing_mode" -eq 1 && -f "$target_file" ]]; then
      case "$file_name" in
        README.md|AGENTS.md) continue ;;
      esac
    fi
    cp "$template_file" "$target_file"
  done

  agent_skip=0
  if [[ "$existing_mode" -eq 1 && -f "$scaffold_dir/AGENT-COMMS.md" && -f "$scaffold_dir/AGENT-WORKFLOW.md" ]]; then
    agent_skip=1
  fi
  if [[ "$agent_skip" -eq 0 ]]; then
    write_scaffold_agent_files_to "$scaffold_dir"
  fi

  for file_name in "${SCAFFOLD_DOC_FILES[@]}"; do
    template_file="$templates_dir/$file_name"
    target_file="$scaffold_dir/$file_name"
    if [[ ! -f "$template_file" ]]; then : >"$template_file"; fi
    if [[ -f "$target_file" ]]; then continue; fi
    cp "$template_file" "$target_file"
  done

  copy_scaffold_scripts "$project_dir" 0 0

  gitignore_template="$templates_dir/.gitignore"
  gitignore_target="$project_dir/.gitignore"
  ensure_gitignore_template "$gitignore_template"
  if [[ "$existing_mode" -eq 0 || ! -f "$gitignore_target" ]]; then
    cp "$gitignore_template" "$gitignore_target"
  fi

  printf '%s\n' "$scaffold_dir"
}
