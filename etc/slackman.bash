# Bash Completion for SlackMan

_slackman_list_repos() {

  local repos=$(slackman list repo | grep ":" | awk '{ print $1 }')
  local repos_short=$(echo $repos | awk -F ":" '{ print $1 }' | sort -u)

  echo "$repos_short $repos"

}

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

  slackman_options="-h --help --man --version -c --config --root --repo --quiet
                    --download-only --new-packages --obsolete-packages -x --exclude
                    --show-files --no-priority --no-excludes -y --yes -n --no"

  slackman_commands="update upgrade install reinstall check-update remove repo db
                     changelog search file-search history config help clean list"

  if [[ "$cur" == -* ]]; then
    COMPREPLY=( $( compgen -W "$slackman_options" -- "$cur" ) )
    return 0
  fi

  case "${prev}" in

    list)
      COMPREPLY=( $( compgen -W 'installed obsoletes packages repo orphan variables' -- "$cur" ) )
      return 0
    ;;

    db)
      COMPREPLY=( $( compgen -W 'info optimize' -- "$cur" ) )
      return 0
    ;;

    update)
      COMPREPLY=( $( compgen -W 'history packages changelog manifest gpg-key all' -- "$cur" ) )
      return 0
    ;;

    repo)
      COMPREPLY=( $( compgen -W 'list info enable disable' -- "$cur" ) )
      return 0
    ;;

    clean)
      COMPREPLY=( $( compgen -W 'cache metadata manifest all' -- "$cur" ) )
      return 0
    ;;

    info|disable|enable)

      if [[ "$command" == "repo" ]]; then
        repos=$(_slackman_list_repos)
        COMPREPLY=( $(compgen -W "$repos" -- ${cur}) )
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
