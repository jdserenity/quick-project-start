# Copy base skills from templates/skills/ into a project's scaffold/skills/.
# Product source in this repo: templates/skills/<skill-name>/
# Source order: checkout templates/skills → installed templates_dir/skills.
# Overwrites matching managed skill names; never deletes project-local skills.

resolve_skills_src() {
  local installed_templates="${templates_dir:-$config_dir/templates}"
  if [[ -d "$SCRIPT_DIR/templates/skills" ]]; then
    printf '%s\n' "$SCRIPT_DIR/templates/skills"
    return 0
  fi
  if [[ -d "$installed_templates/skills" ]]; then
    printf '%s\n' "$installed_templates/skills"
    return 0
  fi
  return 1
}

# Copy each top-level entry from src skills dir into dest, replacing same-named entries.
copy_scaffold_skills_to() {
  local dest_skills="$1"
  local src_skills entry name
  mkdir -p "$dest_skills"
  if ! src_skills="$(resolve_skills_src)"; then
    return 0
  fi
  shopt -s nullglob dotglob
  for entry in "$src_skills"/*; do
    name="$(basename "$entry")"
    [[ "$name" == "." || "$name" == ".." ]] && continue
    if [[ -d "$entry" ]]; then
      rm -rf "$dest_skills/$name"
      cp -R "$entry" "$dest_skills/$name"
    elif [[ -f "$entry" ]]; then
      cp "$entry" "$dest_skills/$name"
    fi
  done
  shopt -u nullglob dotglob
}
