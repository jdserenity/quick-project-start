# new-proj shell integration — source from ~/.zshrc or ~/.bashrc
new-proj() {
  local bin="${NEW_PROJ_BIN:-$HOME/.local/bin/new-proj}"
  local cd_cmd rc
  cd_cmd="$("$bin" "$@" 2>&3)" 3>&2
  rc=$?
  if (( rc != 0 )); then
    return "$rc"
  fi
  if [[ -n "$cd_cmd" ]]; then
    eval "$cd_cmd"
  fi
}
