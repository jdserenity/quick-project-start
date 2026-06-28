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

test_rejects_unknown_option() {
  setup_new_proj_env
  local out=0
  run_new_proj --nope "x" 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_new_proj_env
}

test_rejects_project_name_only_flag() {
  setup_new_proj_env
  local out=0
  run_new_proj --no-repo 2>&1 >/dev/null || out=$?
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
  assert_file "$root/AGENTS.md"
  assert_file "$root/docs/ARCHITECTURE.md"
  assert_file "$root/docs/DEPLOY.md"
  assert_file "$root/docs/TODO.md"
  assert_no_file "$root/docs/README.md"
  assert_no_file "$root/docs/AGENTS.md"

  assert_eq "custom-readme" "$(tr -d '\n' <"$root/README.md")"
  assert_eq "custom-agent-rules" "$(tr -d '\n' <"$root/AGENTS.md")"
  assert_eq "custom-arch" "$(tr -d '\n' <"$root/docs/ARCHITECTURE.md")"
  assert_eq "node_modules/" "$(tr -d '\n' <"$root/.gitignore")"

  teardown_new_proj_env
}

test_custom_scaffold_dir_name() {
  setup_new_proj_env
  seed_standard_templates
  export NEW_PROJ_SCAFFOLD_DIR_NAME="blueprint"
  run_new_proj "beta" >/dev/null

  assert_file "$NEW_PROJ_BASE_DIR/beta/AGENTS.md"
  assert_file "$NEW_PROJ_BASE_DIR/beta/blueprint/ARCHITECTURE.md"
  assert_no_file "$NEW_PROJ_BASE_DIR/beta/blueprint/AGENTS.md"
  assert_no_file "$NEW_PROJ_BASE_DIR/beta/docs/AGENTS.md"

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

test_seeds_agents_template_when_missing() {
  setup_new_proj_env
  run_new_proj "delta" >/dev/null

  assert_file "$NEW_PROJ_TEMPLATES_DIR/AGENTS.md"
  local agents_template
  agents_template="$(<"$NEW_PROJ_TEMPLATES_DIR/AGENTS.md")"
  assert_contains "$agents_template" "Indentation: 2 spaces"
  assert_contains "$agents_template" "docs/ARCHITECTURE.md"

  local project_agents
  project_agents="$(<"$NEW_PROJ_BASE_DIR/delta/AGENTS.md")"
  assert_contains "$project_agents" "Indentation: 2 spaces"

  teardown_new_proj_env
}

test_creates_default_gitignore_template_when_missing() {
  setup_new_proj_env
  printf '%s\n' 'agent' >"$NEW_PROJ_TEMPLATES_DIR/AGENTS.md"
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

test_no_repo_skips_git() {
  if ! command -v git >/dev/null 2>&1; then
    echo "  SKIP: git not installed"
    return 0
  fi
  setup_new_proj_env
  seed_standard_templates
  run_new_proj --no-repo "no-git-before" >/dev/null
  run_new_proj "no-git-after" --no-repo >/dev/null

  assert_no_file "$NEW_PROJ_BASE_DIR/no-git-before/.git"
  assert_no_file "$NEW_PROJ_BASE_DIR/no-git-after/.git"
  assert_file "$NEW_PROJ_BASE_DIR/no-git-before/AGENTS.md"
  assert_file "$NEW_PROJ_BASE_DIR/no-git-after/README.md"

  teardown_new_proj_env
}

test_prints_created_paths() {
  setup_new_proj_env
  seed_standard_templates
  local stderr stdout
  stderr="$(run_new_proj "eta" 2>&1 >/dev/null)"
  stdout="$(run_new_proj "eta-print" 2>/dev/null)"
  assert_contains "$stderr" "Created project: $NEW_PROJ_BASE_DIR/eta"
  assert_contains "$stderr" "Scaffold folder: $NEW_PROJ_BASE_DIR/eta/docs"
  assert_eq "cd $NEW_PROJ_BASE_DIR/eta-print" "$stdout"
  teardown_new_proj_env
}

test_cds_into_new_project() {
  setup_new_proj_env
  seed_standard_templates
  local after
  after="$(
    cd "$TEST_TMP"
    eval "$(run_new_proj "cd-normal" 2>/dev/null)"
    pwd
  )"
  assert_eq "$NEW_PROJ_BASE_DIR/cd-normal" "$after"
  teardown_new_proj_env
}

test_no_repo_cds_into_new_project() {
  setup_new_proj_env
  seed_standard_templates
  local after
  after="$(
    cd "$TEST_TMP"
    eval "$(run_new_proj --no-repo "cd-norepo" 2>/dev/null)"
    pwd
  )"
  assert_eq "$NEW_PROJ_BASE_DIR/cd-norepo" "$after"
  teardown_new_proj_env
}

test_existing_does_not_emit_cd() {
  setup_new_proj_env
  seed_standard_templates
  local root="$TEST_TMP/no-cd" stdout_file pwd_file
  stdout_file="$TEST_TMP/existing-stdout"
  pwd_file="$TEST_TMP/existing-pwd"
  mkdir -p "$root/sub"
  (
    cd "$root/sub"
    run_new_proj --existing 2>/dev/null >"$stdout_file"
    pwd >"$pwd_file"
  )
  assert_eq "" "$(<"$stdout_file")"
  assert_eq "$root/sub" "$(<"$pwd_file")"
  teardown_new_proj_env
}

test_existing_inserts_docs_and_agents() {
  setup_new_proj_env
  seed_standard_templates
  local root="$TEST_TMP/existing"
  mkdir -p "$root"
  printf '%s\n' 'keep-readme' >"$root/README.md"
  printf '%s\n' 'keep-ignore' >"$root/.gitignore"
  (
    cd "$root"
    run_new_proj --existing >/dev/null
  )

  assert_eq "keep-readme" "$(tr -d '\n' <"$root/README.md")"
  assert_eq "keep-ignore" "$(tr -d '\n' <"$root/.gitignore")"
  assert_eq "custom-agent-rules" "$(tr -d '\n' <"$root/AGENTS.md")"
  assert_eq "custom-arch" "$(tr -d '\n' <"$root/docs/ARCHITECTURE.md")"
  assert_eq "custom-deploy" "$(tr -d '\n' <"$root/docs/DEPLOY.md")"
  assert_eq "custom-todo" "$(tr -d '\n' <"$root/docs/TODO.md")"
  assert_no_file "$root/docs/README.md"

  teardown_new_proj_env
}

test_existing_adds_readme_when_missing() {
  setup_new_proj_env
  seed_standard_templates
  local root="$TEST_TMP/bare"
  mkdir -p "$root"
  (
    cd "$root"
    run_new_proj --existing >/dev/null
  )

  assert_eq "custom-readme" "$(tr -d '\n' <"$root/README.md")"
  assert_eq "custom-agent-rules" "$(tr -d '\n' <"$root/AGENTS.md")"

  teardown_new_proj_env
}

test_existing_no_repo_skips_git() {
  if ! command -v git >/dev/null 2>&1; then
    echo "  SKIP: git not installed"
    return 0
  fi
  setup_new_proj_env
  seed_standard_templates
  local root="$TEST_TMP/has-git"
  mkdir -p "$root"
  git -C "$root" init >/dev/null
  printf '%s\n' 'before' >"$root/foo.txt"
  git -C "$root" add foo.txt >/dev/null
  git -C "$root" commit -m "before" >/dev/null
  (
    cd "$root"
    run_new_proj --existing --no-repo >/dev/null
  )

  assert_eq "before" "$(git -C "$root" log -1 --format=%s)" "no new commit from scaffold"
  assert_eq "1" "$(git -C "$root" rev-list --count HEAD)"
  assert_file "$root/AGENTS.md"

  teardown_new_proj_env
}

test_existing_init_git_when_missing() {
  if ! command -v git >/dev/null 2>&1; then
    echo "  SKIP: git not installed"
    return 0
  fi
  setup_new_proj_env
  seed_standard_templates
  local root="$TEST_TMP/no-git"
  mkdir -p "$root"
  (
    cd "$root"
    run_new_proj --existing >/dev/null
  )

  assert_true "$([[ -d "$root/.git" ]] && echo 1)" "git dir exists"
  assert_eq "init" "$(git -C "$root" log -1 --format=%s)"
  assert_file "$root/AGENTS.md"

  teardown_new_proj_env
}

test_existing_commits_scaffold_when_git_exists() {
  if ! command -v git >/dev/null 2>&1; then
    echo "  SKIP: git not installed"
    return 0
  fi
  setup_new_proj_env
  seed_standard_templates
  local root="$TEST_TMP/has-git-commit"
  mkdir -p "$root"
  git -C "$root" init >/dev/null
  printf '%s\n' 'before' >"$root/foo.txt"
  git -C "$root" add foo.txt >/dev/null
  git -C "$root" commit -m "before" >/dev/null
  (
    cd "$root"
    run_new_proj --existing >/dev/null
  )

  assert_eq "Add docs scaffold" "$(git -C "$root" log -1 --format=%s)"
  assert_eq "2" "$(git -C "$root" rev-list --count HEAD)"
  assert_file "$root/AGENTS.md"

  teardown_new_proj_env
}

test_existing_creates_github_repo() {
  setup_new_proj_env
  seed_standard_templates
  local root="$TEST_TMP/gh-existing" log="$TEST_TMP/gh-calls.log"
  mkdir -p "$root"
  cat >"$TEST_TMP/fake-bin/gh" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "auth" && "\${2:-}" == "status" ]]; then exit 0; fi
if [[ "\${1:-}" == "repo" && "\${2:-}" == "view" ]]; then exit 1; fi
if [[ "\${1:-}" == "repo" && "\${2:-}" == "create" ]]; then
  echo "\$*" >> "$log"
  exit 0
fi
exit 1
EOF
  chmod +x "$TEST_TMP/fake-bin/gh"
  (
    cd "$root"
    run_new_proj --existing >/dev/null
  )

  assert_file "$log"
  assert_contains "$(<"$log")" "repo create gh-existing"
  teardown_new_proj_env
}

test_existing_skips_gh_when_origin_exists() {
  if ! command -v git >/dev/null 2>&1; then
    echo "  SKIP: git not installed"
    return 0
  fi
  setup_new_proj_env
  seed_standard_templates
  local root="$TEST_TMP/has-origin" log="$TEST_TMP/gh-calls.log"
  mkdir -p "$root"
  git -C "$root" init -q
  git -C "$root" branch -M main
  printf '%s\n' 'before' >"$root/foo.txt"
  git -C "$root" add foo.txt >/dev/null
  git -C "$root" commit -m "before" >/dev/null
  git -C "$root" remote add origin "https://github.com/example/existing.git"
  : >"$log"
  cat >"$TEST_TMP/fake-bin/gh" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$log"
exit 1
EOF
  chmod +x "$TEST_TMP/fake-bin/gh"
  local stderr
  stderr="$(
    cd "$root"
    run_new_proj --existing 2>&1 >/dev/null
  )"
  assert_eq "" "$(<"$log")" "gh should not run when origin exists"
  assert_contains "$stderr" "Remote origin already set"
  teardown_new_proj_env
}

test_existing_links_github_repo_without_create() {
  if ! command -v git >/dev/null 2>&1; then
    echo "  SKIP: git not installed"
    return 0
  fi
  setup_new_proj_env
  seed_standard_templates
  local root="$TEST_TMP/gh-link" log="$TEST_TMP/gh-calls.log"
  mkdir -p "$root"
  : >"$log"
  cat >"$TEST_TMP/fake-bin/gh" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "auth" && "\${2:-}" == "status" ]]; then exit 0; fi
if [[ "\${1:-}" == "repo" && "\${2:-}" == "view" ]]; then
  if [[ "\${7:-}" == ".url" ]]; then
    echo "https://github.com/test/gh-link"
  elif [[ "\${4:-}" == "--json" || "\${3:-}" == "--json" ]]; then
    echo '{"url":"https://github.com/test/gh-link"}'
  fi
  exit 0
fi
if [[ "\${1:-}" == "repo" && "\${2:-}" == "create" ]]; then
  echo "create \$*" >> "$log"
  exit 0
fi
exit 1
EOF
  chmod +x "$TEST_TMP/fake-bin/gh"
  local stderr
  stderr="$(
    cd "$root"
    run_new_proj --existing 2>&1 >/dev/null
  )"
  assert_eq "" "$(<"$log")" "gh repo create should not run when repo already exists"
  assert_contains "$stderr" "already exists"
  assert_eq "https://github.com/test/gh-link" "$(git -C "$root" remote get-url origin)"
  teardown_new_proj_env
}

test_existing_pushes_when_origin_is_local_bare() {
  if ! command -v git >/dev/null 2>&1; then
    echo "  SKIP: git not installed"
    return 0
  fi
  setup_new_proj_env
  seed_standard_templates
  local root="$TEST_TMP/push-origin" bare="$TEST_TMP/bare.git"
  git init --bare -q "$bare"
  mkdir -p "$root"
  git -C "$root" init -q
  git -C "$root" branch -M main
  printf '%s\n' 'before' >"$root/foo.txt"
  git -C "$root" add foo.txt >/dev/null
  git -C "$root" commit -m "before" >/dev/null
  git -C "$root" remote add origin "$bare"
  local stderr
  stderr="$(
    cd "$root"
    run_new_proj --existing 2>&1 >/dev/null
  )"
  assert_contains "$stderr" "Push complete"
  assert_eq "2" "$(git -C "$bare" rev-list --count main)"
  teardown_new_proj_env
}

test_shell_integration_streams_stderr() {
  local src
  src="$(<"$ROOT/templates/shell-integration.zsh")"
  assert_contains "$src" '2>&3)" 3>&2'
}

test_shell_integration_agent_version_does_not_eval_stdout() {
  setup_new_proj_env
  local root="$TEST_TMP/shell-agent-ver" checkout="$TEST_TMP/checkout-shell-ver"
  mkdir -p "$root" "$checkout"
  cp "$NEW_PROJ" "$checkout/new-proj"
  cp "$ROOT/AGENTS.md" "$checkout/AGENTS.md"
  cp "$ROOT/AGENTS.md" "$root/AGENTS.md"
  git -C "$root" init -q
  local out=0 combined
  combined="$(
    zsh -f -c "
      export NEW_PROJ_BIN='$checkout/new-proj'
      source '$ROOT/templates/shell-integration.zsh'
      cd '$root'
      new-proj --agent-version
    " 2>&1
  )" || out=$?
  assert_eq "0" "$out"
  assert_contains "$combined" "project: AGENTS.md version: 1.0.0"
  assert_contains "$combined" "latest: AGENTS.md version: 1.0.0"
  if [[ "$combined" == *"command not found: project:"* ]]; then
    echo "FAIL: shell integration eval'd --agent-version stdout as shell commands"
    exit 1
  fi
  teardown_new_proj_env
}

test_existing_prints_insert_message() {
  setup_new_proj_env
  seed_standard_templates
  local root="$TEST_TMP/msg"
  mkdir -p "$root"
  local stderr
  stderr="$(
    cd "$root"
    run_new_proj --existing 2>&1 >/dev/null
  )"
  assert_contains "$stderr" "Inserted docs scaffold into: $root"
  assert_contains "$stderr" "Scaffold folder: $root/docs"
  teardown_new_proj_env
}

test_agent_upgrade_replaces_agents_at_repo_root() {
  setup_new_proj_env
  local root="$TEST_TMP/upgrade" checkout="$TEST_TMP/checkout"
  mkdir -p "$root" "$checkout"
  cp "$NEW_PROJ" "$checkout/new-proj"
  printf '%s\n' 'fresh-from-repo' >"$checkout/AGENTS.md"
  printf '%s\n' 'stale-agent-rules' >"$root/AGENTS.md"
  git -C "$root" init -q
  local stderr
  stderr="$(
    cd "$root"
    "$checkout/new-proj" --agent-upgrade 2>&1 >/dev/null
  )"
  assert_contains "$stderr" "Updated AGENTS.md in: $(cd "$root" && pwd -P)"
  assert_contains "$(<"$root/AGENTS.md")" "fresh-from-repo"
  assert_no_file "$root/docs/ARCHITECTURE.md"
  teardown_new_proj_env
}

test_agent_upgrade_from_subfolder_updates_repo_root() {
  setup_new_proj_env
  local root="$TEST_TMP/upgrade-sub" checkout="$TEST_TMP/checkout-sub"
  mkdir -p "$root/src" "$checkout"
  cp "$NEW_PROJ" "$checkout/new-proj"
  printf '%s\n' 'fresh-from-repo' >"$checkout/AGENTS.md"
  printf '%s\n' 'stale-agent-rules' >"$root/AGENTS.md"
  git -C "$root" init -q
  local stderr
  stderr="$(
    cd "$root/src"
    "$checkout/new-proj" --agent-upgrade 2>&1 >/dev/null
  )"
  assert_contains "$stderr" "Updated AGENTS.md in: $(cd "$root" && pwd -P)"
  assert_contains "$(<"$root/AGENTS.md")" "fresh-from-repo"
  assert_no_file "$root/src/AGENTS.md"
  teardown_new_proj_env
}

test_agent_upgrade_no_git_walks_up_to_agents_md() {
  setup_new_proj_env
  local root="$TEST_TMP/upgrade-walk" bin_only="$TEST_TMP/bin-only-walk"
  export HOME="$TEST_TMP/home"
  mkdir -p "$root/src" "$bin_only" "$HOME/.config/new-proj/bundled"
  cp "$NEW_PROJ" "$bin_only/new-proj"
  printf '%s\n' 'stale-agent-rules' >"$root/AGENTS.md"
  printf '%s\n' 'bundled-agents' >"$HOME/.config/new-proj/bundled/AGENTS.md"
  local stderr
  stderr="$(
    cd "$root/src"
    "$bin_only/new-proj" --agent-upgrade 2>&1 >/dev/null
  )"
  assert_contains "$stderr" "Updated AGENTS.md in: $(cd "$root" && pwd -P)"
  assert_eq "bundled-agents" "$(tr -d '\n' <"$root/AGENTS.md")"
  assert_no_file "$root/src/AGENTS.md"
  teardown_new_proj_env
}

test_agent_upgrade_errors_without_project_root() {
  setup_new_proj_env
  local root="$TEST_TMP/upgrade-missing"
  mkdir -p "$root/src"
  local out=0 stderr
  stderr="$(
    cd "$root/src"
    run_new_proj --agent-upgrade 2>&1 >/dev/null
  )" || out=$?
  assert_eq "1" "$out"
  assert_contains "$stderr" "could not find project root"
  assert_no_file "$root/src/AGENTS.md"
  teardown_new_proj_env
}

test_agent_upgrade_uses_bundled_when_not_in_checkout() {
  setup_new_proj_env
  local root="$TEST_TMP/bundled-upgrade" bin_only="$TEST_TMP/bin-only"
  export HOME="$TEST_TMP/home"
  mkdir -p "$root" "$bin_only" "$HOME/.config/new-proj/bundled"
  cp "$NEW_PROJ" "$bin_only/new-proj"
  printf '%s\n' 'stale-agent-rules' >"$root/AGENTS.md"
  printf '%s\n' 'bundled-agents' >"$HOME/.config/new-proj/bundled/AGENTS.md"
  git -C "$root" init -q
  local stderr
  stderr="$(
    cd "$root"
    "$bin_only/new-proj" --agent-upgrade 2>&1 >/dev/null
  )"
  assert_contains "$stderr" "Updated AGENTS.md in: $(cd "$root" && pwd -P)"
  assert_eq "bundled-agents" "$(tr -d '\n' <"$root/AGENTS.md")"
  teardown_new_proj_env
}

test_agent_upgrade_rejects_extra_args() {
  setup_new_proj_env
  local out=0
  run_new_proj --agent-upgrade "x" 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_new_proj_env
}

test_agent_upgrade_rejects_combined_flags() {
  setup_new_proj_env
  local out=0
  run_new_proj --agent-upgrade --existing 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_new_proj_env
}

test_agent_version_shows_current_when_up_to_date() {
  setup_new_proj_env
  local root="$TEST_TMP/agent-ver-current" checkout="$TEST_TMP/checkout-ver"
  mkdir -p "$root" "$checkout"
  cp "$NEW_PROJ" "$checkout/new-proj"
  printf '%s\n' 'AGENTS.md version: 3.0.0' >"$checkout/AGENTS.md"
  printf '%s\n' 'AGENTS.md version: 3.0.0' >"$root/AGENTS.md"
  git -C "$root" init -q
  local out=0 stdout
  stdout="$(
    cd "$root"
    "$checkout/new-proj" --agent-version 2>&1
  )"
  out=$?
  assert_eq "0" "$out"
  assert_contains "$stdout" "project: AGENTS.md version: 3.0.0"
  assert_contains "$stdout" "latest: AGENTS.md version: 3.0.0"
  teardown_new_proj_env
}

test_agent_version_shows_stale_and_exits_nonzero() {
  setup_new_proj_env
  local root="$TEST_TMP/agent-ver-stale" checkout="$TEST_TMP/checkout-ver-stale"
  mkdir -p "$root" "$checkout"
  cp "$NEW_PROJ" "$checkout/new-proj"
  printf '%s\n' 'AGENTS.md version: 2.0.0' >"$checkout/AGENTS.md"
  printf '%s\n' 'AGENTS.md version: 1.0.0' >"$root/AGENTS.md"
  git -C "$root" init -q
  local out=0 stdout
  stdout="$(
    cd "$root"
    "$checkout/new-proj" --agent-version 2>&1
  )" || out=$?
  assert_eq "1" "$out"
  assert_contains "$stdout" "project: AGENTS.md version: 1.0.0"
  assert_contains "$stdout" "latest: AGENTS.md version: 2.0.0"
  teardown_new_proj_env
}

test_agent_version_reports_missing_version_line() {
  setup_new_proj_env
  local root="$TEST_TMP/agent-ver-none" checkout="$TEST_TMP/checkout-ver-none"
  mkdir -p "$root" "$checkout"
  cp "$NEW_PROJ" "$checkout/new-proj"
  cp "$ROOT/AGENTS.md" "$checkout/AGENTS.md"
  printf '%s\n' 'legacy-agent-rules' >"$root/AGENTS.md"
  git -C "$root" init -q
  local out=0 stdout
  stdout="$(
    cd "$root"
    "$checkout/new-proj" --agent-version 2>&1
  )" || out=$?
  assert_eq "1" "$out"
  assert_contains "$stdout" "project: (no version — last line: legacy-agent-rules)"
  assert_contains "$stdout" "latest: AGENTS.md version: 1.0.0"
  teardown_new_proj_env
}

test_agent_version_from_subfolder() {
  setup_new_proj_env
  local root="$TEST_TMP/agent-ver-sub" checkout="$TEST_TMP/checkout-ver-sub"
  mkdir -p "$root/src" "$checkout"
  cp "$NEW_PROJ" "$checkout/new-proj"
  cp "$ROOT/AGENTS.md" "$checkout/AGENTS.md"
  cp "$ROOT/AGENTS.md" "$root/AGENTS.md"
  git -C "$root" init -q
  local out=0 stdout
  stdout="$(
    cd "$root/src"
    "$checkout/new-proj" --agent-version 2>&1
  )"
  out=$?
  assert_eq "0" "$out"
  assert_contains "$stdout" "project: AGENTS.md version: 1.0.0"
  assert_contains "$stdout" "latest: AGENTS.md version: 1.0.0"
  teardown_new_proj_env
}

test_agent_version_rejects_combined_flags() {
  setup_new_proj_env
  local out=0
  run_new_proj --agent-version --existing 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_new_proj_env
}

test_install_refreshes_bundled_agents() {
  setup_install_home
  mkdir -p "$HOME/.config/new-proj/bundled"
  printf '%s\n' 'old-bundled' >"$HOME/.config/new-proj/bundled/AGENTS.md"
  "$INSTALL_SH" >/dev/null
  local bundled
  bundled="$(<"$HOME/.config/new-proj/bundled/AGENTS.md")"
  assert_contains "$bundled" "Indentation: 2 spaces"
  assert_contains "$bundled" "Create commits without being asked"
  teardown_install_home
}

# --- install.sh ---

test_install_copies_new_proj_binary() {
  setup_install_home
  "$INSTALL_SH" >/dev/null
  assert_file "$HOME/.local/bin/new-proj"
  assert_true "$([[ -x "$HOME/.local/bin/new-proj" ]] && echo 1)" "binary is executable"
  assert_file "$HOME/.config/new-proj/shell-integration.zsh"
  teardown_install_home
}

test_install_adds_shell_integration_to_zshrc() {
  setup_install_home
  : >"$HOME/.zshrc"
  "$INSTALL_SH" >/dev/null
  local zshrc
  zshrc="$(<"$HOME/.zshrc")"
  assert_contains "$zshrc" "# new-proj shell integration (install.sh)"
  assert_contains "$zshrc" "shell-integration.zsh"
  teardown_install_home
}

test_install_does_not_duplicate_zshrc_entry() {
  setup_install_home
  printf '%s\n' '# new-proj shell integration (install.sh)' 'source "x"' >"$HOME/.zshrc"
  local before
  before="$(<"$HOME/.zshrc")"
  "$INSTALL_SH" >/dev/null
  assert_eq "$before" "$(<"$HOME/.zshrc")"
  teardown_install_home
}

test_shell_integration_loads_in_zsh() {
  zsh -f -c "source '$ROOT/templates/shell-integration.zsh'; whence new-proj" >/dev/null
}

test_install_skips_when_source_line_elsewhere_in_zshrc() {
  setup_install_home
  printf '%s\n' 'export PATH=/bin' 'source "$HOME/.config/new-proj/shell-integration.zsh"' 'alias ll=ls -l' >"$HOME/.zshrc"
  local before
  before="$(<"$HOME/.zshrc")"
  "$INSTALL_SH" >/dev/null
  assert_eq "$before" "$(<"$HOME/.zshrc")"
  teardown_install_home
}

test_install_creates_config_and_templates_when_missing() {
  setup_install_home
  "$INSTALL_SH" >/dev/null
  assert_file "$HOME/.config/new-proj/config.env"
  assert_file "$HOME/.config/new-proj/templates/AGENTS.md"
  assert_file "$HOME/.config/new-proj/templates/README.md"
  assert_file "$HOME/.config/new-proj/templates/.gitignore"
  local agents
  agents="$(<"$HOME/.config/new-proj/templates/AGENTS.md")"
  assert_contains "$agents" "Indentation: 2 spaces"
  assert_contains "$agents" "docs/ARCHITECTURE.md"
  teardown_install_home
}

test_install_does_not_overwrite_existing_templates() {
  setup_install_home
  mkdir -p "$HOME/.config/new-proj/templates"
  printf '%s\n' 'SCAFFOLD_DIR_NAME="docs"' >"$HOME/.config/new-proj/config.env"
  printf '%s\n' 'KEEP_THIS_AGENTS' >"$HOME/.config/new-proj/templates/AGENTS.md"
  printf '%s\n' 'KEEP_THIS_README' >"$HOME/.config/new-proj/templates/README.md"
  "$INSTALL_SH" >/dev/null
  assert_eq "KEEP_THIS_AGENTS" "$(<"$HOME/.config/new-proj/templates/AGENTS.md")"
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
    test_rejects_unknown_option
    test_rejects_project_name_only_flag
    test_rejects_missing_base_dir
    test_rejects_existing_project
    test_rejects_invalid_scaffold_dir_name
    test_creates_scaffold_and_root_readme
    test_custom_scaffold_dir_name
    test_respects_config_env_scaffold_name
    test_seeds_agents_template_when_missing
    test_creates_default_gitignore_template_when_missing
    test_git_init_when_git_available
    test_no_repo_skips_git
    test_prints_created_paths
    test_cds_into_new_project
    test_no_repo_cds_into_new_project
    test_existing_does_not_emit_cd
    test_existing_inserts_docs_and_agents
    test_existing_adds_readme_when_missing
    test_existing_no_repo_skips_git
    test_existing_init_git_when_missing
    test_existing_commits_scaffold_when_git_exists
    test_existing_creates_github_repo
    test_existing_skips_gh_when_origin_exists
    test_existing_links_github_repo_without_create
    test_existing_pushes_when_origin_is_local_bare
    test_shell_integration_streams_stderr
    test_shell_integration_agent_version_does_not_eval_stdout
    test_existing_prints_insert_message
    test_agent_upgrade_replaces_agents_at_repo_root
    test_agent_upgrade_from_subfolder_updates_repo_root
    test_agent_upgrade_no_git_walks_up_to_agents_md
    test_agent_upgrade_errors_without_project_root
    test_agent_upgrade_uses_bundled_when_not_in_checkout
    test_agent_upgrade_rejects_extra_args
    test_agent_upgrade_rejects_combined_flags
    test_agent_version_shows_current_when_up_to_date
    test_agent_version_shows_stale_and_exits_nonzero
    test_agent_version_reports_missing_version_line
    test_agent_version_from_subfolder
    test_agent_version_rejects_combined_flags
    test_install_refreshes_bundled_agents
    test_install_copies_new_proj_binary
    test_install_adds_shell_integration_to_zshrc
    test_shell_integration_loads_in_zsh
    test_install_does_not_duplicate_zshrc_entry
    test_install_skips_when_source_line_elsewhere_in_zshrc
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
