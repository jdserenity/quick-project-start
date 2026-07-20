# --update: refresh agent rules + AGENTS.md; add any missing scaffold files; never delete.

run_project_update() {
  local project_dir scaffold_dir file_name template_file target_file
  local gitignore_template gitignore_target agents_template

  project_dir="$(find_project_root "$(pwd)")"
  load_scaffold_config || exit 1
  migrate_docs_folder_if_needed "$project_dir"
  scaffold_dir="$project_dir/$scaffold_dir_name"

  mkdir -p "$templates_dir" "$scaffold_dir" "$scaffold_dir/skills"
  ensure_template_stubs

  write_scaffold_agent_files_to "$scaffold_dir"
  echo "Updated scaffold agent files" >&2

  agents_template="$templates_dir/AGENTS.md"
  if [[ ! -f "$agents_template" ]]; then : >"$agents_template"; fi
  cp "$agents_template" "$project_dir/AGENTS.md"
  echo "Updated AGENTS.md" >&2

  for file_name in README.md "${SCAFFOLD_DOC_FILES[@]}"; do
    template_file="$templates_dir/$file_name"
    if [[ "$file_name" == "README.md" ]]; then target_file="$project_dir/$file_name"
    else target_file="$scaffold_dir/$file_name"; fi
    if [[ -f "$target_file" ]]; then continue; fi
    if [[ ! -f "$template_file" ]]; then : >"$template_file"; fi
    cp "$template_file" "$target_file"
    echo "Added: ${target_file#$project_dir/}" >&2
  done

  gitignore_template="$templates_dir/.gitignore"
  gitignore_target="$project_dir/.gitignore"
  ensure_gitignore_template "$gitignore_template"
  if [[ ! -f "$gitignore_target" ]]; then
    cp "$gitignore_template" "$gitignore_target"
    echo "Added: .gitignore" >&2
  fi

  copy_scaffold_scripts "$project_dir" 1 1

  echo "Updated scaffold in: $project_dir" >&2
}
