#!/bin/bash
#
# bash completion file for slackman commands
#
# This script provides completion of:
#  - commands and their options
#  - repo id
#
# To enable the completions either:
#  - place this file in /etc/bash_completion.d
#  or
#  - copy this file to e.g. ~/.slackman-completion.sh and add the line
#    below to your .bashrc after bash completion features are loaded
#    . ~/.slackman-completion.sh


__slackman_previous_extglob_setting=$(shopt -p extglob)
shopt -s extglob


__slackman_to_extglob() {

  local string="$1"
  local extglob=${string// /|}

  echo "@($extglob)"

}


__slackman_subcommands() {

  local subcommands="$1"
  local counter=$(($command_pos + 1))

  while [ $counter -lt $cword ]; do

    case "${words[$counter]}" in
      $(__slackman_to_extglob "$subcommands"))
        subcommand_pos=$counter
        local subcommand=${words[$counter]}
        local completions_func=_slackman_${command}_${subcommand//-/_}
        declare -F $completions_func >/dev/null && $completions_func
        return 0
        ;;
      esac
      (( counter++ ))
  done
  return 1

}

__slackman_list_config() {
  echo $(slackman config | awk -F "=" '{ print $1 }')
}

__slackman_list_installed_packages() {
  echo $(slackman list installed | grep ":" | awk '{ print $1 }')
}


__slackman_list_packages() {
  echo $(slackman list packages | grep ":" | awk '{ print $1 }')
}


__slackman_list_no_installed_packages() {
  echo $(slackman list packages --exclude-installed | grep ":" | awk '{ print $1 }')
}


__slackman_list_repos() {

  local slackman_cmd="slackman repo list --color=never"

  case "$1" in
    enabled)
      echo $($slackman_cmd | grep -i enabled | grep ":" | awk '{ print $1 }')
      ;;
    disabled)
      echo $($slackman_cmd | grep -i disabled | grep ":" | awk '{ print $1 }')
      ;;
    *)
      echo $($slackman_cmd | grep ":" | awk '{ print $1 }')
  esac

  return

}


__slackman_complete_options() {

  case "$2" in

    --repo)
      __slackman_complete_repos "enabled"
      return 0
    ;;

    *)
    ;;

  esac

  return 1

}

__slackman_complete_repos() {
  COMPREPLY=( $(compgen -W "$(__slackman_list_repos "$@")" -- "$cur") )
  __ltrim_colon_completions "$cur"
}

__slackman_complete_config() {
  COMPREPLY=( $(compgen -W "$(__slackman_list_config "$@")" -- "$cur") )
  __ltrim_colon_completions "$cur"
}

_slackman_slackman() {

  local slackman_options slackman_commands

  slackman_options="-h --help --man --version -c --config --root --color"
  slackman_commands="changelog clean config db file-search help history install
                     list log new-config reinstall remove repo search update upgrade"

  if [[ "$cur" == -* ]]; then
    COMPREPLY=( $( compgen -W "$slackman_options" -- "$cur" ) )
    return
  fi

  COMPREPLY=($(compgen -W "$slackman_commands" -- ${cur}))
  return

}


_slackman_repo_disable() {
  __slackman_complete_repos "enabled"
}


_slackman_repo_enable() {
  __slackman_complete_repos "disabled"
}


_slackman_repo_info() {
  __slackman_complete_repos
}


_slackman_repo() {

  local subcommands="help list info disable enable"
  __slackman_subcommands "$subcommands" && return
  COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )

}


_slackman_log() {

  local subcommands="help clean tail"
  __slackman_subcommands "$subcommands" && return
  COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )

}

_slackman_config() {
  __slackman_complete_config
}

_slackman_info() {

  local slackman_options="--show-files"

  __slackman_complete_options "$cur" "$prev" && return

  if [[ "$cur" == -* ]]; then
    COMPREPLY=( $( compgen -W "$slackman_options" -- "$cur" ) )
    return 0
  fi

  COMPREPLY=( $(compgen -W "$(__slackman_list_packages "$@")" -- "$cur") )
  __ltrim_colon_completions "$cur"

}


_slackman_update() {

  local subcommands="help packages history changelog manifest gpg-key all"

  if [[ "$cur" == -* ]]; then
    COMPREPLY=( $( compgen -W "--repo --force" -- "$cur" ) )
    return 0
  fi

  __slackman_complete_options "$cur" "$prev" && return
  __slackman_subcommands "$subcommands" && return

  COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )

}


_slackman_upgrade() {

  local slackman_options="--repo --exclude --download-only --summary --no-deps"

  __slackman_complete_options "$cur" "$prev" && return

  if [[ "$cur" == -* ]]; then
    COMPREPLY=( $( compgen -W "$slackman_options" -- "$cur" ) )
    return 0
  fi

  COMPREPLY=( $(compgen -W "$(__slackman_list_installed_packages "$@")" -- "$cur") )
  __ltrim_colon_completions "$cur"

}


_slackman_changelog() {

  local slackman_options="--repo --limit --details --security-fix"

  __slackman_complete_options "$cur" "$prev" && return

  if [[ "$cur" == -* ]]; then
    COMPREPLY=( $( compgen -W "$slackman_options" -- "$cur" ) )
    return 0
  fi

}


_slackman_install() {

  local slackman_options="--repo --exclude --download-only --new-packages --no-deps"

  __slackman_complete_options "$cur" "$prev" && return

  if [[ "$cur" == -* ]]; then
    COMPREPLY=( $( compgen -W "$slackman_options" -- "$cur" ) )
    return 0
  fi

  COMPREPLY=( $(compgen -W "$(__slackman_list_no_installed_packages "$@")" -- "$cur") )
  __ltrim_colon_completions "$cur"

  __slackman_complete_options "$cur" "$prev" && return

}


_slackman_reinstall() {

  local slackman_options="--repo --exclude --download-only"

  __slackman_complete_options "$cur" "$prev" && return

  if [[ "$cur" == -* ]]; then
    COMPREPLY=( $( compgen -W "$slackman_options" -- "$cur" ) )
    return 0
  fi

  COMPREPLY=( $(compgen -W "$(__slackman_list_installed_packages "$@")" -- "$cur") )
  __ltrim_colon_completions "$cur"

}


_slackman_remove() {

  local slackman_options="--obsolete-packages"

  if [[ "$cur" == -* ]]; then
    COMPREPLY=( $( compgen -W "$slackman_options" -- "$cur" ) )
    return 0
  fi

  COMPREPLY=( $(compgen -W "$(__slackman_list_installed_packages "$@")" -- "$cur") )
  __ltrim_colon_completions "$cur"

}


_slackman_db() {

  local subcommands="help info optimize"
  __slackman_subcommands "$subcommands" && return
  COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )

}


_slackman_help() {

  local subcommands="list repo db update log clean"
  __slackman_subcommands "$subcommands" && return
  COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )

}


_slackman_list() {

  local slackman_options="--exclude-installed"

  __slackman_complete_options "$cur" "$prev" && return

  if [[ "$cur" == -* ]]; then
    COMPREPLY=( $( compgen -W "$slackman_options" -- "$cur" ) )
    return 0
  fi

  local subcommands="installed obsoletes packages repo orphan variables"
  __slackman_subcommands "$subcommands" && return
  COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )

}


_slackman_clean() {

  local subcommands="help cache metadata db all"
  __slackman_subcommands "$subcommands" && return
  COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )

}


_slackman() {

  local previous_extglob_setting=$(shopt -p extglob)
  shopt -s extglob

  COMPREPLY=()

  local cur prev words cword
  _get_comp_words_by_ref -n : cur prev words cword

  local counter=1
  local command='slackman' command_pos=0 subcommand_pos

  while [ $counter -lt $cword ]; do
    case "${words[$counter]}" in
      *)
        command="${words[$counter]}"
        command_pos=$counter
        break
        ;;
    esac
    (( counter++ ))
  done

  local completions_func=_slackman_${command//-/_}
  declare -F $completions_func >/dev/null && $completions_func

  eval "$previous_extglob_setting"
  return 0

}


eval "$__slackman_previous_extglob_setting"
unset __slackman_previous_extglob_setting

complete -F _slackman slackman
