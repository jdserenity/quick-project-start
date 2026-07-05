#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NEW_PROJ="$ROOT/new-proj"
INSTALL_SH="$ROOT/install.sh"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST=""

fail() {
  echo "  FAIL: $1" >&2
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

pass() {
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-}"
  if [[ "$expected" == "$actual" ]]; then
    pass
  else
    fail "${msg}expected='$expected' actual='$actual'"
  fi
}

assert_ne() {
  local not_expected="$1"
  local actual="$2"
  local msg="${3:-}"
  if [[ "$not_expected" != "$actual" ]]; then
    pass
  else
    fail "${msg}should not equal '$not_expected'"
  fi
}

assert_true() {
  local msg="${2:-}"
  if [[ "${1:-}" == "1" || "${1:-}" == "yes" || "${1:-}" == "true" ]]; then
    pass
  else
    fail "$msg"
  fi
}

assert_file() {
  local path="$1"
  local msg="${2:-}"
  if [[ -e "$path" ]]; then
    pass
  else
    fail "${msg}missing file: $path"
  fi
}

assert_no_file() {
  local path="$1"
  local msg="${2:-}"
  if [[ ! -e "$path" ]]; then
    pass
  else
    fail "${msg}unexpected file: $path"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="${3:-}"
  if [[ "$haystack" == *"$needle"* ]]; then
    pass
  else
    fail "${msg}output does not contain '$needle': $haystack"
  fi
}

run_test() {
  local name="$1"
  local failed_before=$TESTS_FAILED
  CURRENT_TEST="$name"
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "TEST: $name"
  if ! "$name"; then
    echo "  FAIL: test function exited with error" >&2
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return
  fi
  if [[ "$TESTS_FAILED" -gt "$failed_before" ]]; then
    echo "  FAIL" >&2
  else
    echo "  ok"
  fi
}

setup_new_proj_env() {
  TEST_TMP="$(mktemp -d)"
  export TEST_TMP
  export PATH="$TEST_TMP/fake-bin:$PATH"
  mkdir -p "$TEST_TMP/fake-bin"
  cat >"$TEST_TMP/fake-bin/gh" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "auth" && "${2:-}" == "status" ]]; then
  exit 1
fi
exit 1
EOF
  chmod +x "$TEST_TMP/fake-bin/gh"

  export NEW_PROJ_BASE_DIR="$TEST_TMP/projects"
  export NEW_PROJ_TEMPLATES_DIR="$TEST_TMP/templates"
  export NEW_PROJ_CONFIG_FILE="$TEST_TMP/config.env"
  mkdir -p "$NEW_PROJ_BASE_DIR" "$NEW_PROJ_TEMPLATES_DIR"
  printf '%s\n' 'SCAFFOLD_DIR_NAME="docs"' >"$NEW_PROJ_CONFIG_FILE"
}

seed_standard_templates() {
  printf '%s\n' 'custom-agent-rules' >"$NEW_PROJ_TEMPLATES_DIR/AGENTS.md"
  printf '%s\n' 'custom-readme' >"$NEW_PROJ_TEMPLATES_DIR/README.md"
  printf '%s\n' 'custom-arch' >"$NEW_PROJ_TEMPLATES_DIR/ARCHITECTURE.md"
  printf '%s\n' 'custom-knowledge' >"$NEW_PROJ_TEMPLATES_DIR/KNOWLEDGE.md"
  printf '%s\n' 'node_modules/' >"$NEW_PROJ_TEMPLATES_DIR/.gitignore"
}

teardown_new_proj_env() {
  if [[ -n "${TEST_TMP:-}" && -d "$TEST_TMP" ]]; then
    rm -rf "$TEST_TMP"
  fi
  unset TEST_TMP NEW_PROJ_BASE_DIR NEW_PROJ_TEMPLATES_DIR NEW_PROJ_CONFIG_FILE NEW_PROJ_SCAFFOLD_DIR_NAME
}

run_new_proj() {
  "$NEW_PROJ" "$@"
}

setup_install_home() {
  INSTALL_TMP="$(mktemp -d)"
  export INSTALL_TMP
  export HOME="$INSTALL_TMP"
}

teardown_install_home() {
  if [[ -n "${INSTALL_TMP:-}" && -d "$INSTALL_TMP" ]]; then
    rm -rf "$INSTALL_TMP"
  fi
  unset INSTALL_TMP
}
