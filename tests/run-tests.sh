#!/usr/bin/env bash
# Tests use isolated temp dirs; stderr from expected failures is normal.
set -uo pipefail

cd "$(dirname "$0")"
# shellcheck source=lib.sh
source ./lib.sh

# --- new-proj: usage and validation ---

test_usage_wrong_arg_count() {
  setup_new_proj_env
  local out=0
  run_new_proj 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_new_proj_env
}

test_rejects_slash_in_project_name() {
  setup_new_proj_env
  local out=0
  run_new_proj "bad/name" 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_new_proj_env
}

test_rejects_empty_project_name() {
  setup_new_proj_env
  local out=0
  run_new_proj "" 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_new_proj_env
}

test_rejects_missing_base_dir() {
  setup_new_proj_env
  export NEW_PROJ_BASE_DIR="$TEST_TMP/does-not-exist"
  local out=0
  run_new_proj "x" 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_new_proj_env
}

test_rejects_existing_project() {
  setup_new_proj_env
  seed_standard_templates
  mkdir -p "$NEW_PROJ_BASE_DIR/exists"
  local out=0
  run_new_proj "exists" 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_new_proj_env
}

test_rejects_invalid_scaffold_dir_name() {
  setup_new_proj_env
  seed_standard_templates
  export NEW_PROJ_SCAFFOLD_DIR_NAME="nested/bad"
  local out=0
  run_new_proj "x" 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_new_proj_env
}

# --- new-proj: scaffold layout ---

test_creates_scaffold_and_root_readme() {
  setup_new_proj_env
  seed_standard_templates
  run_new_proj "alpha" >/dev/null

  local root="$NEW_PROJ_BASE_DIR/alpha"
  assert_file "$root/README.md"
  assert_file "$root/.gitignore"
  assert_file "$root/docs/AGENT.md"
  assert_file "$root/docs/ARCHITECTURE.md"
  assert_file "$root/docs/DEPLOY.md"
  assert_file "$root/docs/TODO.md"
  assert_no_file "$root/docs/README.md"

  assert_eq "custom-readme" "$(tr -d '\n' <"$root/README.md")"
  assert_eq "custom-agent-rules" "$(tr -d '\n' <"$root/docs/AGENT.md")"
  assert_eq "custom-arch" "$(tr -d '\n' <"$root/docs/ARCHITECTURE.md")"
  assert_eq "node_modules/" "$(tr -d '\n' <"$root/.gitignore")"

  teardown_new_proj_env
}

test_custom_scaffold_dir_name() {
  setup_new_proj_env
  seed_standard_templates
  export NEW_PROJ_SCAFFOLD_DIR_NAME="blueprint"
  run_new_proj "beta" >/dev/null

  assert_file "$NEW_PROJ_BASE_DIR/beta/blueprint/AGENT.md"
  assert_no_file "$NEW_PROJ_BASE_DIR/beta/docs/AGENT.md"

  teardown_new_proj_env
}

test_respects_config_env_scaffold_name() {
  setup_new_proj_env
  seed_standard_templates
  printf '%s\n' 'SCAFFOLD_DIR_NAME="notes"' >"$NEW_PROJ_CONFIG_FILE"
  unset NEW_PROJ_SCAFFOLD_DIR_NAME
  run_new_proj "gamma" >/dev/null

  assert_file "$NEW_PROJ_BASE_DIR/gamma/notes/TODO.md"
  assert_no_file "$NEW_PROJ_BASE_DIR/gamma/docs/TODO.md"

  teardown_new_proj_env
}

test_seeds_agent_template_when_missing() {
  setup_new_proj_env
  run_new_proj "delta" >/dev/null

  assert_file "$NEW_PROJ_TEMPLATES_DIR/AGENT.md"
  local agent_template
  agent_template="$(<"$NEW_PROJ_TEMPLATES_DIR/AGENT.md")"
  assert_contains "$agent_template" "Indentation: 2 spaces"

  local project_agent
  project_agent="$(<"$NEW_PROJ_BASE_DIR/delta/docs/AGENT.md")"
  assert_contains "$project_agent" "Indentation: 2 spaces"

  teardown_new_proj_env
}

test_creates_default_gitignore_template_when_missing() {
  setup_new_proj_env
  printf '%s\n' 'agent' >"$NEW_PROJ_TEMPLATES_DIR/AGENT.md"
  for f in README.md ARCHITECTURE.md DEPLOY.md TODO.md; do
    : >"$NEW_PROJ_TEMPLATES_DIR/$f"
  done
  run_new_proj "epsilon" >/dev/null

  assert_file "$NEW_PROJ_TEMPLATES_DIR/.gitignore"
  local ignore
  ignore="$(<"$NEW_PROJ_TEMPLATES_DIR/.gitignore")"
  assert_contains "$ignore" "node_modules/"
  assert_contains "$(<"$NEW_PROJ_BASE_DIR/epsilon/.gitignore")" "node_modules/"

  teardown_new_proj_env
}

test_git_init_when_git_available() {
  if ! command -v git >/dev/null 2>&1; then
    echo "  SKIP: git not installed"
    return 0
  fi
  setup_new_proj_env
  seed_standard_templates
  run_new_proj "zeta" >/dev/null

  local root="$NEW_PROJ_BASE_DIR/zeta"
  assert_true "$([[ -d "$root/.git" ]] && echo 1)" "git dir exists"
  assert_eq "main" "$(git -C "$root" branch --show-current)"
  assert_eq "init" "$(git -C "$root" log -1 --format=%s)"

  teardown_new_proj_env
}

test_prints_created_paths() {
  setup_new_proj_env
  seed_standard_templates
  local output
  output="$(run_new_proj "eta")"
  assert_contains "$output" "Created project: $NEW_PROJ_BASE_DIR/eta"
  assert_contains "$output" "Scaffold folder: $NEW_PROJ_BASE_DIR/eta/docs"
  teardown_new_proj_env
}

# --- install.sh ---

test_install_copies_new_proj_binary() {
  setup_install_home
  "$INSTALL_SH" >/dev/null
  assert_file "$HOME/.local/bin/new-proj"
  assert_true "$([[ -x "$HOME/.local/bin/new-proj" ]] && echo 1)" "binary is executable"
  teardown_install_home
}

test_install_creates_config_and_templates_when_missing() {
  setup_install_home
  "$INSTALL_SH" >/dev/null
  assert_file "$HOME/.config/new-proj/config.env"
  assert_file "$HOME/.config/new-proj/templates/AGENT.md"
  assert_file "$HOME/.config/new-proj/templates/README.md"
  assert_file "$HOME/.config/new-proj/templates/.gitignore"
  local agent
  agent="$(<"$HOME/.config/new-proj/templates/AGENT.md")"
  assert_contains "$agent" "Indentation: 2 spaces"
  teardown_install_home
}

test_install_does_not_overwrite_existing_templates() {
  setup_install_home
  mkdir -p "$HOME/.config/new-proj/templates"
  printf '%s\n' 'SCAFFOLD_DIR_NAME="docs"' >"$HOME/.config/new-proj/config.env"
  printf '%s\n' 'KEEP_THIS_AGENT' >"$HOME/.config/new-proj/templates/AGENT.md"
  printf '%s\n' 'KEEP_THIS_README' >"$HOME/.config/new-proj/templates/README.md"
  "$INSTALL_SH" >/dev/null
  assert_eq "KEEP_THIS_AGENT" "$(<"$HOME/.config/new-proj/templates/AGENT.md")"
  assert_eq "KEEP_THIS_README" "$(<"$HOME/.config/new-proj/templates/README.md")"
  teardown_install_home
}

test_install_does_not_modify_repo_docs() {
  local todo_file="$ROOT/docs/TODO.md"
  local before after
  before="$(shasum -a 256 "$todo_file" | awk '{print $1}')"
  setup_install_home
  "$INSTALL_SH" >/dev/null
  after="$(shasum -a 256 "$todo_file" | awk '{print $1}')"
  assert_eq "$before" "$after" "repo docs/TODO.md changed after install"
  teardown_install_home
}

# --- runner ---

main() {
  local tests=(
    test_usage_wrong_arg_count
    test_rejects_slash_in_project_name
    test_rejects_empty_project_name
    test_rejects_missing_base_dir
    test_rejects_existing_project
    test_rejects_invalid_scaffold_dir_name
    test_creates_scaffold_and_root_readme
    test_custom_scaffold_dir_name
    test_respects_config_env_scaffold_name
    test_seeds_agent_template_when_missing
    test_creates_default_gitignore_template_when_missing
    test_git_init_when_git_available
    test_prints_created_paths
    test_install_copies_new_proj_binary
    test_install_creates_config_and_templates_when_missing
    test_install_does_not_overwrite_existing_templates
    test_install_does_not_modify_repo_docs
  )

  for t in "${tests[@]}"; do
    run_test "$t"
  done

  echo ""
  echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed ($TESTS_RUN tests)"
  if [[ "$TESTS_FAILED" -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
