# Bash Completion for SlackMan

_slackman_complete_options() {

  case "$2" in

    --repo)
      local repos=$(slackman list repo | grep ":" | awk '{ print $1 }')
      local repos_short=$(echo $repos | awk -F ":" '{ print $1 }' | sort -u)
      COMPREPLY=( $(compgen -W "$repos_short $repos" -- ${cur}) )
      return 0
    ;;

    *)
    ;;

  esac

  return 1

}

_slackman() {

  local cur prev opts

  COMPREPLY=()

  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  local command="${COMP_WORDS[COMP_CWORD-2]}"

  slackman_options="-h,--help --man --version -c,--config --root --repo 
                    --download-only --new-packages --obsolete-packages
                    -x --exclude --show-files --no-priority --no-excludes
                    --no-md5-check --no-gpg-check -y --yes -n --no --quiet"

  slackman_commands="update upgrade install reinstall check-update remove repo
                     changelog search file-search history config help clean list"

  if [[ "$cur" == -* ]]; then
    COMPREPLY=( $( compgen -W "$slackman_options" -- "$cur" ) )
    return 0
  fi

  case "${prev}" in

    list)
      if [[ "$2" == "$prev" ]]; then
        COMPREPLY=( $( compgen -W 'installed obsoletes packages repo orphan variables' -- "$cur" ) )
        return 0
      fi
    ;;

    update)
      COMPREPLY=( $( compgen -W 'history packages changelog manifest gpg-key all' -- "$cur" ) )
      return 0
    ;;

    repo)
      COMPREPLY=( $( compgen -W 'list info' -- "$cur" ) )
      return 0
    ;;

    clean)
      COMPREPLY=( $( compgen -W 'cache metadata manifest all' -- "$cur" ) )
      return 0
    ;;

    info)

      if [[ "$command" == "repo" ]]; then
        local repos=$(slackman list repo | grep ":" | awk '{ print $1 }')
        local repos_short=$(echo $repos | awk -F ":" '{ print $1 }' | sort -u)
        COMPREPLY=( $(compgen -W "$repos_short $repos" -- ${cur}) )
        return 0
      fi

    ;;

    *)
    ;;

  esac

  _slackman_complete_options "$cur" "$prev" && return 0

  COMPREPLY=($(compgen -W "${slackman_commands}" -- ${cur}))
  return 0

}

complete -F _slackman slackman
