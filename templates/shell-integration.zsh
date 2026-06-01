# new-proj shell integration — source from ~/.zshrc or ~/.bashrc
new-proj() {
  local bin="${NEW_PROJ_BIN:-$HOME/.local/bin/new-proj}"
  local cd_cmd stderr
  stderr="$(mktemp)"
  cd_cmd="$("$bin" "$@" 2>"$stderr")"
  local rc=$?
  if [[ -s "$stderr" ]]; then
    cat "$stderr" >&2
  fi
  rm -f "$stderr"
  if (( rc != 0 )); then
    return "$rc"
  fi
  if [[ -n "$cd_cmd" ]]; then
    eval "$cd_cmd"
  fi
}
