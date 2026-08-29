# bash completion for ari-flash-launcher. Installed by the ari-flash-launcher
# formula. Game slugs are completed live from `list-installed --porcelain`.
#
# NOTE: the command list below is mirrored in bin/ari-flash-launcher (main()
# dispatch) and completions/_ari-flash-launcher — update all three together.

_ari_flash_launcher() {
  local cur cmd
  cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=()

  _ari_flash_slugs() {
    ari-flash-launcher list-installed --porcelain 2>/dev/null | cut -f1
  }

  if [[ $COMP_CWORD -eq 1 ]]; then
    local cmds="list-installed list ls list-upstream launch help version"
    COMPREPLY=($(compgen -W "$cmds $(_ari_flash_slugs)" -- "$cur"))
    # .swf files complete at the top level too (bare-launch form).
    COMPREPLY+=($(compgen -f -X '!*.swf' -- "$cur"))
    return 0
  fi

  cmd=${COMP_WORDS[1]}
  case "$cmd" in
    launch)
      COMPREPLY=($(compgen -W "$(_ari_flash_slugs) -h --help" -- "$cur"))
      COMPREPLY+=($(compgen -f -X '!*.swf' -- "$cur"))
      ;;
    list-installed | list | ls)
      COMPREPLY=($(compgen -W "--porcelain -h --help" -- "$cur"))
      ;;
    list-upstream)
      COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
      ;;
  esac
  return 0
}

complete -F _ari_flash_launcher ari-flash-launcher
