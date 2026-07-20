#!/usr/bin/env bash
# Tests use isolated temp dirs; stderr from expected failures is normal.
set -uo pipefail

cd "$(dirname "$0")"
# shellcheck source=lib.sh
source ./lib.sh

# --- quick-proj: usage and validation ---

test_usage_wrong_arg_count() {
  setup_quick_proj_env
  local out=0
  run_quick_proj 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_quick_proj_env
}

test_rejects_slash_in_project_name() {
  setup_quick_proj_env
  local out=0
  run_quick_proj "bad/name" 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_quick_proj_env
}

test_rejects_empty_project_name() {
  setup_quick_proj_env
  local out=0
  run_quick_proj "" 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_quick_proj_env
}

test_rejects_unknown_option() {
  setup_quick_proj_env
  local out=0
  run_quick_proj --nope "x" 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_quick_proj_env
}

test_rejects_project_name_only_flag() {
  setup_quick_proj_env
  local out=0
  run_quick_proj --no-repo 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_quick_proj_env
}

test_rejects_missing_base_dir() {
  setup_quick_proj_env
  export QUICK_PROJ_BASE_DIR="$TEST_TMP/does-not-exist"
  local out=0
  run_quick_proj "x" 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_quick_proj_env
}

test_rejects_existing_project() {
  setup_quick_proj_env
  seed_standard_templates
  mkdir -p "$QUICK_PROJ_BASE_DIR/exists"
  local out=0
  run_quick_proj "exists" 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_quick_proj_env
}

test_rejects_invalid_scaffold_dir_name() {
  setup_quick_proj_env
  seed_standard_templates
  export QUICK_PROJ_SCAFFOLD_DIR_NAME="nested/bad"
  local out=0
  run_quick_proj "x" 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_quick_proj_env
}

# --- quick-proj: scaffold layout ---

test_creates_scaffold_and_root_readme() {
  setup_quick_proj_env
  seed_standard_templates
  run_quick_proj "alpha" >/dev/null

  local root="$QUICK_PROJ_BASE_DIR/alpha"
  assert_file "$root/README.md"
  assert_file "$root/.gitignore"
  assert_file "$root/scaffold/ARCH-HUMAN.md"
  assert_file "$root/scaffold/ARCH-LLM.md"
  assert_file "$root/scaffold/PROJECT-KNOWLEDGE.md"
  assert_file "$root/scaffold/skills"
  assert_file "$root/scripts/sz.py"
  assert_eq "template-sz-marker" "$(tr -d '\n' <"$root/scripts/sz.py")"
  assert_no_file "$root/scaffold/DEPLOY.md"
  assert_no_file "$root/scaffold/TODO.md"
  assert_no_file "$root/scaffold/README.md"
  assert_file "$root/AGENTS.md"
  assert_no_file "$root/scaffold/AGENTS.md"
  assert_no_file "$root/scaffold/scripts"

  assert_eq "custom-agents-pointer" "$(tr -d '\n' <"$root/AGENTS.md")"
  assert_eq "custom-readme" "$(tr -d '\n' <"$root/README.md")"
  assert_eq "custom-agent-comms" "$(tr -d '\n' <"$root/scaffold/AGENT-COMMS.md")"
  assert_eq "custom-agent-workflow" "$(tr -d '\n' <"$root/scaffold/AGENT-WORKFLOW.md")"
  assert_eq "custom-arch-human" "$(tr -d '\n' <"$root/scaffold/ARCH-HUMAN.md")"
  assert_eq "custom-arch-llm" "$(tr -d '\n' <"$root/scaffold/ARCH-LLM.md")"
  assert_eq "custom-understanding" "$(tr -d '\n' <"$root/scaffold/PROJECT-KNOWLEDGE.md")"
  assert_eq "node_modules/" "$(tr -d '\n' <"$root/.gitignore")"

  teardown_quick_proj_env
}

test_custom_scaffold_dir_name() {
  setup_quick_proj_env
  seed_standard_templates
  export QUICK_PROJ_SCAFFOLD_DIR_NAME="blueprint"
  run_quick_proj "beta" >/dev/null

  assert_file "$QUICK_PROJ_BASE_DIR/beta/blueprint/ARCH-HUMAN.md"
  assert_file "$QUICK_PROJ_BASE_DIR/beta/AGENTS.md"
  assert_no_file "$QUICK_PROJ_BASE_DIR/beta/blueprint/README.md"

  teardown_quick_proj_env
}

test_respects_config_env_scaffold_name() {
  setup_quick_proj_env
  seed_standard_templates
  printf '%s\n' 'SCAFFOLD_DIR_NAME="notes"' >"$QUICK_PROJ_CONFIG_FILE"
  unset QUICK_PROJ_SCAFFOLD_DIR_NAME
  run_quick_proj "gamma" >/dev/null

  assert_file "$QUICK_PROJ_BASE_DIR/gamma/notes/PROJECT-KNOWLEDGE.md"
  assert_no_file "$QUICK_PROJ_BASE_DIR/gamma/scaffold/PROJECT-KNOWLEDGE.md"

  teardown_quick_proj_env
}

test_seeds_scaffold_agent_template_when_missing() {
  setup_quick_proj_env
  run_quick_proj "delta" >/dev/null

  assert_file "$QUICK_PROJ_TEMPLATES_DIR/AGENT-WORKFLOW.md"
  local workflow_template comms_template
  workflow_template="$(<"$QUICK_PROJ_TEMPLATES_DIR/AGENT-WORKFLOW.md")"
  comms_template="$(<"$QUICK_PROJ_TEMPLATES_DIR/AGENT-COMMS.md")"
  assert_contains "$workflow_template" "Indentation: 2 spaces"
  assert_contains "$comms_template" "scaffold/PROJECT-KNOWLEDGE.md"

  local project_workflow
  project_workflow="$(<"$QUICK_PROJ_BASE_DIR/delta/scaffold/AGENT-WORKFLOW.md")"
  assert_contains "$project_workflow" "Indentation: 2 spaces"

  teardown_quick_proj_env
}

test_creates_default_gitignore_template_when_missing() {
  setup_quick_proj_env
  printf '%s\n' 'agent-comms' >"$QUICK_PROJ_TEMPLATES_DIR/AGENT-COMMS.md"
  printf '%s\n' 'agent-workflow' >"$QUICK_PROJ_TEMPLATES_DIR/AGENT-WORKFLOW.md"
  for f in README.md ARCH-HUMAN.md ARCH-LLM.md PROJECT-KNOWLEDGE.md; do
    : >"$QUICK_PROJ_TEMPLATES_DIR/$f"
  done
  run_quick_proj "epsilon" >/dev/null

  assert_file "$QUICK_PROJ_TEMPLATES_DIR/.gitignore"
  local ignore
  ignore="$(<"$QUICK_PROJ_TEMPLATES_DIR/.gitignore")"
  assert_contains "$ignore" "node_modules/"
  assert_contains "$(<"$QUICK_PROJ_BASE_DIR/epsilon/.gitignore")" "node_modules/"

  teardown_quick_proj_env
}

test_git_init_when_git_available() {
  if ! command -v git >/dev/null 2>&1; then
    echo "  SKIP: git not installed"
    return 0
  fi
  setup_quick_proj_env
  seed_standard_templates
  run_quick_proj "zeta" >/dev/null

  local root="$QUICK_PROJ_BASE_DIR/zeta"
  assert_true "$([[ -d "$root/.git" ]] && echo 1)" "git dir exists"
  assert_eq "main" "$(git -C "$root" branch --show-current)"
  assert_eq "init" "$(git -C "$root" log -1 --format=%s)"

  teardown_quick_proj_env
}

test_no_repo_skips_git() {
  if ! command -v git >/dev/null 2>&1; then
    echo "  SKIP: git not installed"
    return 0
  fi
  setup_quick_proj_env
  seed_standard_templates
  run_quick_proj --no-repo "no-git-before" >/dev/null
  run_quick_proj "no-git-after" --no-repo >/dev/null

  assert_no_file "$QUICK_PROJ_BASE_DIR/no-git-before/.git"
  assert_no_file "$QUICK_PROJ_BASE_DIR/no-git-after/.git"
  assert_file "$QUICK_PROJ_BASE_DIR/no-git-before/scaffold/AGENT-WORKFLOW.md"
  assert_file "$QUICK_PROJ_BASE_DIR/no-git-after/README.md"

  teardown_quick_proj_env
}

test_prints_created_paths() {
  setup_quick_proj_env
  seed_standard_templates
  local stderr stdout
  stderr="$(run_quick_proj "eta" 2>&1 >/dev/null)"
  stdout="$(run_quick_proj "eta-print" 2>/dev/null)"
  assert_contains "$stderr" "Created project: $QUICK_PROJ_BASE_DIR/eta"
  assert_contains "$stderr" "Scaffold folder: $QUICK_PROJ_BASE_DIR/eta/scaffold"
  assert_eq "cd $QUICK_PROJ_BASE_DIR/eta-print" "$stdout"
  teardown_quick_proj_env
}

test_cds_into_new_project() {
  setup_quick_proj_env
  seed_standard_templates
  local after
  after="$(
    cd "$TEST_TMP"
    eval "$(run_quick_proj "cd-normal" 2>/dev/null)"
    pwd
  )"
  assert_eq "$QUICK_PROJ_BASE_DIR/cd-normal" "$after"
  teardown_quick_proj_env
}

test_no_repo_cds_into_new_project() {
  setup_quick_proj_env
  seed_standard_templates
  local after
  after="$(
    cd "$TEST_TMP"
    eval "$(run_quick_proj --no-repo "cd-norepo" 2>/dev/null)"
    pwd
  )"
  assert_eq "$QUICK_PROJ_BASE_DIR/cd-norepo" "$after"
  teardown_quick_proj_env
}

test_existing_does_not_emit_cd() {
  setup_quick_proj_env
  seed_standard_templates
  local root="$TEST_TMP/no-cd" stdout_file pwd_file
  stdout_file="$TEST_TMP/existing-stdout"
  pwd_file="$TEST_TMP/existing-pwd"
  mkdir -p "$root/sub"
  (
    cd "$root/sub"
    run_quick_proj --existing 2>/dev/null >"$stdout_file"
    pwd >"$pwd_file"
  )
  assert_eq "" "$(<"$stdout_file")"
  assert_eq "$root/sub" "$(<"$pwd_file")"
  teardown_quick_proj_env
}

test_existing_inserts_scaffold_and_agents() {
  setup_quick_proj_env
  seed_standard_templates
  local root="$TEST_TMP/existing"
  mkdir -p "$root/scaffold"
  printf '%s\n' 'keep-readme' >"$root/README.md"
  printf '%s\n' 'keep-ignore' >"$root/.gitignore"
  printf '%s\n' 'legacy-deploy' >"$root/scaffold/DEPLOY.md"
  printf '%s\n' 'legacy-todo' >"$root/scaffold/TODO.md"
  (
    cd "$root"
    run_quick_proj --existing >/dev/null
  )

  assert_eq "keep-readme" "$(tr -d '\n' <"$root/README.md")"
  assert_eq "keep-ignore" "$(tr -d '\n' <"$root/.gitignore")"
  assert_eq "custom-agent-comms" "$(tr -d '\n' <"$root/scaffold/AGENT-COMMS.md")"
  assert_eq "custom-arch-human" "$(tr -d '\n' <"$root/scaffold/ARCH-HUMAN.md")"
  assert_eq "custom-understanding" "$(tr -d '\n' <"$root/scaffold/PROJECT-KNOWLEDGE.md")"
  assert_eq "legacy-deploy" "$(tr -d '\n' <"$root/scaffold/DEPLOY.md")"
  assert_eq "legacy-todo" "$(tr -d '\n' <"$root/scaffold/TODO.md")"
  assert_file "$root/scaffold/skills"
  assert_no_file "$root/scaffold/README.md"

  teardown_quick_proj_env
}

test_existing_adds_readme_when_missing() {
  setup_quick_proj_env
  seed_standard_templates
  local root="$TEST_TMP/bare"
  mkdir -p "$root"
  (
    cd "$root"
    run_quick_proj --existing >/dev/null
  )

  assert_eq "custom-readme" "$(tr -d '\n' <"$root/README.md")"
  assert_eq "custom-agent-workflow" "$(tr -d '\n' <"$root/scaffold/AGENT-WORKFLOW.md")"

  teardown_quick_proj_env
}

test_existing_no_repo_skips_git() {
  if ! command -v git >/dev/null 2>&1; then
    echo "  SKIP: git not installed"
    return 0
  fi
  setup_quick_proj_env
  seed_standard_templates
  local root="$TEST_TMP/has-git"
  mkdir -p "$root"
  git -C "$root" init >/dev/null
  printf '%s\n' 'before' >"$root/foo.txt"
  git -C "$root" add foo.txt >/dev/null
  git -C "$root" commit -m "before" >/dev/null
  (
    cd "$root"
    run_quick_proj --existing --no-repo >/dev/null
  )

  assert_eq "before" "$(git -C "$root" log -1 --format=%s)" "no new commit from scaffold"
  assert_eq "1" "$(git -C "$root" rev-list --count HEAD)"
  assert_file "$root/scaffold/AGENT-WORKFLOW.md"

  teardown_quick_proj_env
}

test_existing_init_git_when_missing() {
  if ! command -v git >/dev/null 2>&1; then
    echo "  SKIP: git not installed"
    return 0
  fi
  setup_quick_proj_env
  seed_standard_templates
  local root="$TEST_TMP/no-git"
  mkdir -p "$root"
  (
    cd "$root"
    run_quick_proj --existing >/dev/null
  )

  assert_true "$([[ -d "$root/.git" ]] && echo 1)" "git dir exists"
  assert_eq "init" "$(git -C "$root" log -1 --format=%s)"
  assert_file "$root/scaffold/AGENT-WORKFLOW.md"

  teardown_quick_proj_env
}

test_existing_commits_scaffold_when_git_exists() {
  if ! command -v git >/dev/null 2>&1; then
    echo "  SKIP: git not installed"
    return 0
  fi
  setup_quick_proj_env
  seed_standard_templates
  local root="$TEST_TMP/has-git-commit"
  mkdir -p "$root"
  git -C "$root" init >/dev/null
  printf '%s\n' 'before' >"$root/foo.txt"
  git -C "$root" add foo.txt >/dev/null
  git -C "$root" commit -m "before" >/dev/null
  (
    cd "$root"
    run_quick_proj --existing >/dev/null
  )

  assert_eq "Add scaffold" "$(git -C "$root" log -1 --format=%s)"
  assert_eq "2" "$(git -C "$root" rev-list --count HEAD)"
  assert_file "$root/scaffold/AGENT-WORKFLOW.md"

  teardown_quick_proj_env
}

test_existing_creates_github_repo() {
  setup_quick_proj_env
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
    run_quick_proj --existing >/dev/null
  )

  assert_file "$log"
  assert_contains "$(<"$log")" "repo create gh-existing"
  teardown_quick_proj_env
}

test_existing_skips_gh_when_origin_exists() {
  if ! command -v git >/dev/null 2>&1; then
    echo "  SKIP: git not installed"
    return 0
  fi
  setup_quick_proj_env
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
    run_quick_proj --existing 2>&1 >/dev/null
  )"
  assert_eq "" "$(<"$log")" "gh should not run when origin exists"
  assert_contains "$stderr" "Remote origin already set"
  teardown_quick_proj_env
}

test_existing_links_github_repo_without_create() {
  if ! command -v git >/dev/null 2>&1; then
    echo "  SKIP: git not installed"
    return 0
  fi
  setup_quick_proj_env
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
    run_quick_proj --existing 2>&1 >/dev/null
  )"
  assert_eq "" "$(<"$log")" "gh repo create should not run when repo already exists"
  assert_contains "$stderr" "already exists"
  assert_eq "https://github.com/test/gh-link" "$(git -C "$root" remote get-url origin)"
  teardown_quick_proj_env
}

test_existing_pushes_when_origin_is_local_bare() {
  if ! command -v git >/dev/null 2>&1; then
    echo "  SKIP: git not installed"
    return 0
  fi
  setup_quick_proj_env
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
    run_quick_proj --existing 2>&1 >/dev/null
  )"
  assert_contains "$stderr" "Push complete"
  assert_eq "2" "$(git -C "$bare" rev-list --count main)"
  teardown_quick_proj_env
}

test_shell_integration_streams_stderr() {
  local src
  src="$(<"$ROOT/templates/shell-integration.zsh")"
  assert_contains "$src" '2>&3)" 3>&2'
}

test_shell_integration_agent_version_does_not_eval_stdout() {
  setup_quick_proj_env
  local root="$TEST_TMP/shell-agent-ver" checkout="$TEST_TMP/checkout-shell-ver"
  mkdir -p "$root" "$checkout"
  cp "$QUICK_PROJ" "$checkout/quick-proj"
  cp "$ROOT/scaffold/AGENT-WORKFLOW.md" "$checkout/AGENT-WORKFLOW.md"
  cp "$ROOT/scaffold/AGENT-COMMS.md" "$checkout/AGENT-COMMS.md"
  mkdir -p "$checkout/scaffold"
  cp "$ROOT/scaffold/AGENT-WORKFLOW.md" "$checkout/scaffold/AGENT-WORKFLOW.md"
  cp "$ROOT/scaffold/AGENT-COMMS.md" "$checkout/scaffold/AGENT-COMMS.md"
  mkdir -p "$root/scaffold"
  cp "$ROOT/scaffold/AGENT-WORKFLOW.md" "$root/scaffold/AGENT-WORKFLOW.md"
  cp "$ROOT/scaffold/AGENT-COMMS.md" "$root/scaffold/AGENT-COMMS.md"
  git -C "$root" init -q
  local out=0 combined
  combined="$(
    zsh -f -c "
      export QUICK_PROJ_BIN='$checkout/quick-proj'
      source '$ROOT/templates/shell-integration.zsh'
      cd '$root'
      quick-proj --agent-version
    " 2>&1
  )" || out=$?
  assert_eq "0" "$out"
  assert_contains "$combined" "project: scaffold version: 2.3.0"
  assert_contains "$combined" "latest: scaffold version: 2.3.0"
  if [[ "$combined" == *"command not found: project:"* ]]; then
    echo "FAIL: shell integration eval'd --agent-version stdout as shell commands"
    exit 1
  fi
  teardown_quick_proj_env
}

test_existing_prints_insert_message() {
  setup_quick_proj_env
  seed_standard_templates
  local root="$TEST_TMP/msg"
  mkdir -p "$root"
  local stderr
  stderr="$(
    cd "$root"
    run_quick_proj --existing 2>&1 >/dev/null
  )"
  assert_contains "$stderr" "Inserted scaffold into: $root"
  assert_contains "$stderr" "Scaffold folder: $root/scaffold"
  teardown_quick_proj_env
}

test_update_replaces_agents_and_adds_missing_scaffold() {
  setup_quick_proj_env
  seed_standard_templates
  local root="$TEST_TMP/update" checkout="$TEST_TMP/checkout"
  mkdir -p "$root/scaffold" "$checkout/scaffold"
  cp "$QUICK_PROJ" "$checkout/quick-proj"
  printf '%s\n' 'fresh-comms' >"$checkout/scaffold/AGENT-COMMS.md"
  printf '%s\n' 'fresh-from-repo' >"$checkout/scaffold/AGENT-WORKFLOW.md"
  printf '%s\n' 'scaffold version: 9.9.9' >>"$checkout/scaffold/AGENT-WORKFLOW.md"
  printf '%s\n' 'stale-agent-workflow' >"$root/scaffold/AGENT-WORKFLOW.md"
  printf '%s\n' 'stale-agent-comms' >"$root/scaffold/AGENT-COMMS.md"
  printf '%s\n' 'my-arch-human' >"$root/scaffold/ARCH-HUMAN.md"
  printf '%s\n' 'my-understanding' >"$root/scaffold/PROJECT-KNOWLEDGE.md"
  printf '%s\n' 'legacy-deploy' >"$root/scaffold/DEPLOY.md"
  git -C "$root" init -q
  local stderr
  stderr="$(
    cd "$root"
    "$checkout/quick-proj" --update 2>&1 >/dev/null
  )"
  assert_contains "$stderr" "Updated scaffold agent files"
  assert_contains "$stderr" "Updated AGENTS.md"
  assert_contains "$stderr" "Updated scaffold in: $(cd "$root" && pwd -P)"
  assert_contains "$(<"$root/scaffold/AGENT-WORKFLOW.md")" "fresh-from-repo"
  assert_eq "custom-agents-pointer" "$(tr -d '\n' <"$root/AGENTS.md")"
  assert_eq "my-arch-human" "$(tr -d '\n' <"$root/scaffold/ARCH-HUMAN.md")"
  assert_eq "my-understanding" "$(tr -d '\n' <"$root/scaffold/PROJECT-KNOWLEDGE.md")"
  assert_eq "legacy-deploy" "$(tr -d '\n' <"$root/scaffold/DEPLOY.md")"
  assert_eq "template-sz-marker" "$(tr -d '\n' <"$root/scripts/sz.py")"
  assert_file "$root/scaffold/skills"
  teardown_quick_proj_env
}

test_update_from_subfolder_updates_repo_root() {
  setup_quick_proj_env
  seed_standard_templates
  local root="$TEST_TMP/update-sub" checkout="$TEST_TMP/checkout-sub"
  mkdir -p "$root/src" "$root/scaffold" "$checkout/scaffold"
  cp "$QUICK_PROJ" "$checkout/quick-proj"
  printf '%s\n' 'fresh-from-repo' >"$checkout/scaffold/AGENT-WORKFLOW.md"
  printf '%s\n' 'fresh-comms' >"$checkout/scaffold/AGENT-COMMS.md"
  printf '%s\n' 'stale-agent-workflow' >"$root/scaffold/AGENT-WORKFLOW.md"
  git -C "$root" init -q
  local stderr
  stderr="$(
    cd "$root/src"
    "$checkout/quick-proj" --update 2>&1 >/dev/null
  )"
  assert_contains "$stderr" "Updated scaffold in: $(cd "$root" && pwd -P)"
  assert_contains "$(<"$root/scaffold/AGENT-WORKFLOW.md")" "fresh-from-repo"
  assert_no_file "$root/src/scaffold/AGENT-WORKFLOW.md"
  assert_file "$root/scripts/sz.py"
  teardown_quick_proj_env
}

test_update_no_git_walks_up_to_scaffold_workflow() {
  setup_quick_proj_env
  seed_standard_templates
  local root="$TEST_TMP/update-walk" bin_only="$TEST_TMP/bin-only-walk"
  export HOME="$TEST_TMP/home"
  mkdir -p "$root/src" "$root/scaffold" "$bin_only" "$HOME/.config/quick-proj/bundled"
  cp "$QUICK_PROJ" "$bin_only/quick-proj"
  printf '%s\n' 'stale-agent-workflow' >"$root/scaffold/AGENT-WORKFLOW.md"
  printf '%s\n' 'bundled-workflow' >"$HOME/.config/quick-proj/bundled/AGENT-WORKFLOW.md"
  printf '%s\n' 'bundled-comms' >"$HOME/.config/quick-proj/bundled/AGENT-COMMS.md"
  local stderr
  stderr="$(
    cd "$root/src"
    "$bin_only/quick-proj" --update 2>&1 >/dev/null
  )"
  assert_contains "$stderr" "Updated scaffold in: $(cd "$root" && pwd -P)"
  assert_eq "bundled-workflow" "$(tr -d '\n' <"$root/scaffold/AGENT-WORKFLOW.md")"
  assert_no_file "$root/src/scaffold/AGENT-WORKFLOW.md"
  teardown_quick_proj_env
}

test_update_errors_without_project_root() {
  setup_quick_proj_env
  local root="$TEST_TMP/update-missing"
  mkdir -p "$root/src"
  local out=0 stderr
  stderr="$(
    cd "$root/src"
    run_quick_proj --update 2>&1 >/dev/null
  )" || out=$?
  assert_eq "1" "$out"
  assert_contains "$stderr" "could not find project root"
  assert_no_file "$root/src/scaffold/AGENT-WORKFLOW.md"
  teardown_quick_proj_env
}

test_update_uses_bundled_when_not_in_checkout() {
  setup_quick_proj_env
  seed_standard_templates
  local root="$TEST_TMP/bundled-update" bin_only="$TEST_TMP/bin-only"
  export HOME="$TEST_TMP/home"
  mkdir -p "$root/scaffold" "$bin_only" "$HOME/.config/quick-proj/bundled"
  cp "$QUICK_PROJ" "$bin_only/quick-proj"
  printf '%s\n' 'stale-agent-workflow' >"$root/scaffold/AGENT-WORKFLOW.md"
  printf '%s\n' 'bundled-workflow' >"$HOME/.config/quick-proj/bundled/AGENT-WORKFLOW.md"
  printf '%s\n' 'bundled-comms' >"$HOME/.config/quick-proj/bundled/AGENT-COMMS.md"
  git -C "$root" init -q
  local stderr
  stderr="$(
    cd "$root"
    "$bin_only/quick-proj" --update 2>&1 >/dev/null
  )"
  assert_contains "$stderr" "Updated scaffold in: $(cd "$root" && pwd -P)"
  assert_eq "bundled-workflow" "$(tr -d '\n' <"$root/scaffold/AGENT-WORKFLOW.md")"
  teardown_quick_proj_env
}

test_update_skips_existing_scripts() {
  setup_quick_proj_env
  seed_standard_templates
  local root="$TEST_TMP/update-skip-script"
  mkdir -p "$root/scripts" "$root/scaffold"
  printf '%s\n' 'stale-agent-workflow' >"$root/scaffold/AGENT-WORKFLOW.md"
  printf '%s\n' 'stale-agent-comms' >"$root/scaffold/AGENT-COMMS.md"
  printf '%s\n' 'custom-sz' >"$root/scripts/sz.py"
  git -C "$root" init -q
  (
    cd "$root"
    run_quick_proj --update >/dev/null
  )
  assert_eq "custom-sz" "$(tr -d '\n' <"$root/scripts/sz.py")"
  teardown_quick_proj_env
}

test_update_rejects_extra_args() {
  setup_quick_proj_env
  local out=0
  run_quick_proj --update "x" 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_quick_proj_env
}

test_update_rejects_combined_flags() {
  setup_quick_proj_env
  local out=0
  run_quick_proj --update --existing 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_quick_proj_env
}

test_sz_scans_python_in_repo() {
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/src"
  printf '%s\n' 'x = 1' 'y = 2' >"$tmp/src/a.py"
  local out
  out="$(python3 "$ROOT/templates/sz.py" "$tmp")"
  assert_contains "$out" "src/a.py"
  assert_contains "$out" "total lines: 2"
  rm -rf "$tmp"
}

test_sz_skips_node_modules() {
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/node_modules/pkg"
  printf '%s\n' 'x = 1' >"$tmp/node_modules/pkg/a.py"
  printf '%s\n' 'y = 2' >"$tmp/b.py"
  local out
  out="$(python3 "$ROOT/templates/sz.py" "$tmp")"
  assert_contains "$out" "b.py"
  assert_true "$([[ "$out" != *node_modules* ]] && echo 1)" "should skip node_modules"
  rm -rf "$tmp"
}

test_install_syncs_sz_template() {
  setup_install_home
  "$INSTALL_SH" >/dev/null
  assert_file "$HOME/.config/quick-proj/templates/sz.py"
  local sz
  sz="$(<"$HOME/.config/quick-proj/templates/sz.py")"
  assert_contains "$sz" "iter_code_files"
  teardown_install_home
}

test_agent_version_shows_current_when_up_to_date() {
  setup_quick_proj_env
  local root="$TEST_TMP/agent-ver-current" checkout="$TEST_TMP/checkout-ver"
  mkdir -p "$root/scaffold" "$checkout/scaffold"
  cp "$QUICK_PROJ" "$checkout/quick-proj"
  printf '%s\n' 'scaffold version: 3.0.0' >"$checkout/scaffold/AGENT-WORKFLOW.md"
  printf '%s\n' 'scaffold version: 3.0.0' >"$root/scaffold/AGENT-WORKFLOW.md"
  git -C "$root" init -q
  local out=0 stdout
  stdout="$(
    cd "$root"
    "$checkout/quick-proj" --agent-version 2>&1
  )"
  out=$?
  assert_eq "0" "$out"
  assert_contains "$stdout" "project: scaffold version: 3.0.0"
  assert_contains "$stdout" "latest: scaffold version: 3.0.0"
  teardown_quick_proj_env
}

test_agent_version_shows_stale_and_exits_nonzero() {
  setup_quick_proj_env
  local root="$TEST_TMP/agent-ver-stale" checkout="$TEST_TMP/checkout-ver-stale"
  mkdir -p "$root/scaffold" "$checkout/scaffold"
  cp "$QUICK_PROJ" "$checkout/quick-proj"
  printf '%s\n' 'scaffold version: 2.3.0' >"$checkout/scaffold/AGENT-WORKFLOW.md"
  printf '%s\n' 'scaffold version: 1.0.0' >"$root/scaffold/AGENT-WORKFLOW.md"
  git -C "$root" init -q
  local out=0 stdout
  stdout="$(
    cd "$root"
    "$checkout/quick-proj" --agent-version 2>&1
  )" || out=$?
  assert_eq "1" "$out"
  assert_contains "$stdout" "project: scaffold version: 1.0.0"
  assert_contains "$stdout" "latest: scaffold version: 2.3.0"
  teardown_quick_proj_env
}

test_agent_version_reports_missing_version_line() {
  setup_quick_proj_env
  local root="$TEST_TMP/agent-ver-none" checkout="$TEST_TMP/checkout-ver-none"
  mkdir -p "$root/scaffold" "$checkout/scaffold"
  cp "$QUICK_PROJ" "$checkout/quick-proj"
  cp "$ROOT/scaffold/AGENT-WORKFLOW.md" "$checkout/scaffold/AGENT-WORKFLOW.md"
  cp "$ROOT/scaffold/AGENT-COMMS.md" "$checkout/scaffold/AGENT-COMMS.md"
  printf '%s\n' 'legacy-agent-workflow' >"$root/scaffold/AGENT-WORKFLOW.md"
  git -C "$root" init -q
  local out=0 stdout
  stdout="$(
    cd "$root"
    "$checkout/quick-proj" --agent-version 2>&1
  )" || out=$?
  assert_eq "1" "$out"
  assert_contains "$stdout" "project: (no version — last line: legacy-agent-workflow)"
  assert_contains "$stdout" "latest: scaffold version: 2.3.0"
  teardown_quick_proj_env
}

test_agent_version_from_subfolder() {
  setup_quick_proj_env
  local root="$TEST_TMP/agent-ver-sub" checkout="$TEST_TMP/checkout-ver-sub"
  mkdir -p "$root/src" "$checkout"
  cp "$QUICK_PROJ" "$checkout/quick-proj"
  cp "$ROOT/scaffold/AGENT-WORKFLOW.md" "$checkout/AGENT-WORKFLOW.md"
  cp "$ROOT/scaffold/AGENT-COMMS.md" "$checkout/AGENT-COMMS.md"
  mkdir -p "$checkout/scaffold"
  cp "$ROOT/scaffold/AGENT-WORKFLOW.md" "$checkout/scaffold/AGENT-WORKFLOW.md"
  cp "$ROOT/scaffold/AGENT-COMMS.md" "$checkout/scaffold/AGENT-COMMS.md"
  mkdir -p "$root/scaffold"
  cp "$ROOT/scaffold/AGENT-WORKFLOW.md" "$root/scaffold/AGENT-WORKFLOW.md"
  cp "$ROOT/scaffold/AGENT-COMMS.md" "$root/scaffold/AGENT-COMMS.md"
  git -C "$root" init -q
  local out=0 stdout
  stdout="$(
    cd "$root/src"
    "$checkout/quick-proj" --agent-version 2>&1
  )"
  out=$?
  assert_eq "0" "$out"
  assert_contains "$stdout" "project: scaffold version: 2.3.0"
  assert_contains "$stdout" "latest: scaffold version: 2.3.0"
  teardown_quick_proj_env
}

test_agent_version_rejects_combined_flags() {
  setup_quick_proj_env
  local out=0
  run_quick_proj --agent-version --existing 2>&1 >/dev/null || out=$?
  assert_eq "1" "$out"
  teardown_quick_proj_env
}

test_install_refreshes_bundled_scaffold_agents() {
  setup_install_home
  mkdir -p "$HOME/.config/quick-proj/bundled"
  printf '%s\n' 'old-bundled' >"$HOME/.config/quick-proj/bundled/AGENT-WORKFLOW.md"
  "$INSTALL_SH" >/dev/null
  local bundled
  bundled="$(<"$HOME/.config/quick-proj/bundled/AGENT-WORKFLOW.md")"
  assert_contains "$bundled" "Indentation: 2 spaces"
  assert_contains "$bundled" "Create commits without being asked"
  teardown_install_home
}

# --- install.sh ---

test_install_copies_quick_proj_binary() {
  setup_install_home
  "$INSTALL_SH" >/dev/null
  assert_file "$HOME/.local/bin/quick-proj"
  assert_true "$([[ -x "$HOME/.local/bin/quick-proj" ]] && echo 1)" "binary is executable"
  assert_no_file "$HOME/.local/bin/new-proj"
  assert_file "$HOME/.config/quick-proj/shell-integration.zsh"
  teardown_install_home
}

test_install_migrates_legacy_new_proj() {
  setup_install_home
  mkdir -p "$HOME/.config/new-proj/templates" "$HOME/.local/bin"
  printf '%s\n' 'SCAFFOLD_DIR_NAME="legacy"' >"$HOME/.config/new-proj/config.env"
  printf '%s\n' 'legacy-marker' >"$HOME/.config/new-proj/templates/README.md"
  printf '%s\n' '#!/bin/sh' 'echo old' >"$HOME/.local/bin/new-proj"
  chmod +x "$HOME/.local/bin/new-proj"
  printf '%s\n' '# new-proj shell integration (install.sh)' 'source "$HOME/.config/new-proj/shell-integration.zsh"' >"$HOME/.zshrc"
  "$INSTALL_SH" >/dev/null
  assert_file "$HOME/.config/quick-proj/config.env"
  assert_no_file "$HOME/.config/new-proj/config.env"
  assert_contains "$(<"$HOME/.config/quick-proj/config.env")" 'legacy'
  assert_contains "$(<"$HOME/.config/quick-proj/templates/README.md")" 'Brief description'
  assert_no_file "$HOME/.local/bin/new-proj"
  local zshrc
  zshrc="$(<"$HOME/.zshrc")"
  assert_contains "$zshrc" "# quick-proj shell integration (install.sh)"
  assert_contains "$zshrc" '.config/quick-proj/shell-integration.zsh'
  teardown_install_home
}

test_install_adds_shell_integration_to_zshrc() {
  setup_install_home
  : >"$HOME/.zshrc"
  "$INSTALL_SH" >/dev/null
  local zshrc
  zshrc="$(<"$HOME/.zshrc")"
  assert_contains "$zshrc" "# quick-proj shell integration (install.sh)"
  assert_contains "$zshrc" "shell-integration.zsh"
  teardown_install_home
}

test_install_does_not_duplicate_zshrc_entry() {
  setup_install_home
  printf '%s\n' '# quick-proj shell integration (install.sh)' 'source "x"' >"$HOME/.zshrc"
  local before
  before="$(<"$HOME/.zshrc")"
  "$INSTALL_SH" >/dev/null
  assert_eq "$before" "$(<"$HOME/.zshrc")"
  teardown_install_home
}

test_shell_integration_loads_in_zsh() {
  zsh -f -c "source '$ROOT/templates/shell-integration.zsh'; whence quick-proj" >/dev/null
}

test_install_skips_when_source_line_elsewhere_in_zshrc() {
  setup_install_home
  printf '%s\n' 'export PATH=/bin' 'source "$HOME/.config/quick-proj/shell-integration.zsh"' 'alias ll=ls -l' >"$HOME/.zshrc"
  local before
  before="$(<"$HOME/.zshrc")"
  "$INSTALL_SH" >/dev/null
  assert_eq "$before" "$(<"$HOME/.zshrc")"
  teardown_install_home
}

test_install_creates_config_and_templates_when_missing() {
  setup_install_home
  "$INSTALL_SH" >/dev/null
  assert_file "$HOME/.config/quick-proj/config.env"
  assert_file "$HOME/.config/quick-proj/templates/AGENT-WORKFLOW.md"
  assert_file "$HOME/.config/quick-proj/templates/AGENT-COMMS.md"
  assert_file "$HOME/.config/quick-proj/templates/AGENTS.md"
  assert_file "$HOME/.config/quick-proj/templates/README.md"
  assert_file "$HOME/.config/quick-proj/templates/.gitignore"
  local workflow comms
  workflow="$(<"$HOME/.config/quick-proj/templates/AGENT-WORKFLOW.md")"
  comms="$(<"$HOME/.config/quick-proj/templates/AGENT-COMMS.md")"
  assert_contains "$workflow" "Indentation: 2 spaces"
  assert_contains "$comms" "scaffold/PROJECT-KNOWLEDGE.md"
  teardown_install_home
}

test_install_refreshes_templates_on_every_run() {
  setup_install_home
  mkdir -p "$HOME/.config/quick-proj/templates"
  printf '%s\n' 'SCAFFOLD_DIR_NAME="scaffold"' >"$HOME/.config/quick-proj/config.env"
  printf '%s\n' 'STALE_WORKFLOW' >"$HOME/.config/quick-proj/templates/AGENT-WORKFLOW.md"
  printf '%s\n' 'STALE_README' >"$HOME/.config/quick-proj/templates/README.md"
  "$INSTALL_SH" >/dev/null
  local workflow comms readme understanding
  workflow="$(<"$HOME/.config/quick-proj/templates/AGENT-WORKFLOW.md")"
  comms="$(<"$HOME/.config/quick-proj/templates/AGENT-COMMS.md")"
  readme="$(<"$HOME/.config/quick-proj/templates/README.md")"
  understanding="$(<"$HOME/.config/quick-proj/templates/PROJECT-KNOWLEDGE.md")"
  assert_contains "$workflow" "scaffold version: 2.3.0"
  assert_contains "$comms" "scaffold/PROJECT-KNOWLEDGE.md"
  assert_contains "$comms" "One home per fact"
  assert_contains "$readme" "Brief description"
  assert_contains "$understanding" "Hard-won lessons"
  teardown_install_home
}

test_install_removes_deprecated_template_files() {
  setup_install_home
  mkdir -p "$HOME/.config/quick-proj/templates"
  printf '%s\n' 'old' >"$HOME/.config/quick-proj/templates/DEPLOY.md"
  printf '%s\n' 'old' >"$HOME/.config/quick-proj/templates/TODO.md"
  "$INSTALL_SH" >/dev/null
  assert_no_file "$HOME/.config/quick-proj/templates/DEPLOY.md"
  assert_no_file "$HOME/.config/quick-proj/templates/TODO.md"
  teardown_install_home
}

test_install_does_not_modify_repo_scaffold() {
  local arch_file="$ROOT/scaffold/ARCH-LLM.md"
  local before after
  before="$(shasum -a 256 "$arch_file" | awk '{print $1}')"
  setup_install_home
  "$INSTALL_SH" >/dev/null
  after="$(shasum -a 256 "$arch_file" | awk '{print $1}')"
  assert_eq "$before" "$after" "repo scaffold/ARCH-LLM.md changed after install"
  teardown_install_home
}

test_existing_preserves_agents_and_understanding_when_present() {
  setup_quick_proj_env
  seed_standard_templates
  local root="$TEST_TMP/existing-keep"
  mkdir -p "$root/scaffold"
  printf '%s\n' 'keep-comms' >"$root/scaffold/AGENT-COMMS.md"
  printf '%s\n' 'keep-workflow' >"$root/scaffold/AGENT-WORKFLOW.md"
  printf '%s\n' 'keep-understanding' >"$root/scaffold/PROJECT-KNOWLEDGE.md"
  (
    cd "$root"
    run_quick_proj --existing >/dev/null
  )
  assert_eq "keep-comms" "$(tr -d '\n' <"$root/scaffold/AGENT-COMMS.md")"
  assert_eq "keep-workflow" "$(tr -d '\n' <"$root/scaffold/AGENT-WORKFLOW.md")"
  assert_eq "keep-understanding" "$(tr -d '\n' <"$root/scaffold/PROJECT-KNOWLEDGE.md")"
  assert_eq "custom-arch-human" "$(tr -d '\n' <"$root/scaffold/ARCH-HUMAN.md")"
  assert_file "$root/scaffold/skills"
  teardown_quick_proj_env
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
    test_seeds_scaffold_agent_template_when_missing
    test_creates_default_gitignore_template_when_missing
    test_git_init_when_git_available
    test_no_repo_skips_git
    test_prints_created_paths
    test_cds_into_new_project
    test_no_repo_cds_into_new_project
    test_existing_does_not_emit_cd
    test_existing_inserts_scaffold_and_agents
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
    test_update_replaces_agents_and_adds_missing_scaffold
    test_update_from_subfolder_updates_repo_root
    test_update_no_git_walks_up_to_scaffold_workflow
    test_update_errors_without_project_root
    test_update_uses_bundled_when_not_in_checkout
    test_update_skips_existing_scripts
    test_update_rejects_extra_args
    test_update_rejects_combined_flags
    test_sz_scans_python_in_repo
    test_sz_skips_node_modules
    test_install_syncs_sz_template
    test_agent_version_shows_current_when_up_to_date
    test_agent_version_shows_stale_and_exits_nonzero
    test_agent_version_reports_missing_version_line
    test_agent_version_from_subfolder
    test_agent_version_rejects_combined_flags
    test_install_refreshes_bundled_scaffold_agents
    test_install_copies_quick_proj_binary
    test_install_migrates_legacy_new_proj
    test_install_adds_shell_integration_to_zshrc
    test_shell_integration_loads_in_zsh
    test_install_does_not_duplicate_zshrc_entry
    test_install_skips_when_source_line_elsewhere_in_zshrc
    test_install_creates_config_and_templates_when_missing
    test_install_refreshes_templates_on_every_run
    test_install_removes_deprecated_template_files
    test_existing_preserves_agents_and_understanding_when_present
    test_install_does_not_modify_repo_scaffold
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
