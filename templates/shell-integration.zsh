# quick-proj shell integration — source from ~/.zshrc or ~/.bashrc
quick-proj() {
  local bin="${QUICK_PROJ_BIN:-$HOME/.local/bin/quick-proj}"
  case " $* " in
    *' --agent-version '*|*' --update '*|*' --existing '*|*' -h '*|*' --help '*)
      "$bin" "$@"
      return $?
      ;;
  esac
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
