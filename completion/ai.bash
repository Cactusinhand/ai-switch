# bash completion for ai
_ai_complete() {
  local cur prev words cword
  _init_completion || return
  local cmds="list current switch add edit doctor version"
  if [[ ${COMP_CWORD} -eq 1 ]]; then
    COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
    return
  fi
  case ${COMP_WORDS[1]} in
    switch|edit)
      local profs
      profs=$(ai list 2>/dev/null | tail -n +2)
      COMPREPLY=( $(compgen -W "$profs" -- "$cur") )
      ;;
    add)
      COMPREPLY=( $(compgen -W "--force --switch --from-current" -- "$cur") )
      ;;
  esac
}
complete -F _ai_complete ai
