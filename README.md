[![Release](https://img.shields.io/github/release/LotarProject/slackman.svg)](https://github.com/LotarProject/slackman/releases) [![Build Status](https://travis-ci.org/LotarProject/slackman.svg)](https://travis-ci.org/LotarProject/slackman) [![License](https://img.shields.io/github/license/LotarProject/slackman.svg)](https://github.com/LotarProject/slackman) [![Starts](https://img.shields.io/github/stars/LotarProject/slackman.svg)](https://github.com/LotarProject/slackman) [![Forks](https://img.shields.io/github/forks/LotarProject/slackman.svg)](https://github.com/LotarProject/slackman) [![Issues](https://img.shields.io/github/issues/LotarProject/slackman.svg)](https://github.com/LotarProject/slackman/issues)

# slackman

SlackMan - Slackware Package Manager

SlackMan is easy-to-use wrapper for Slackware ``pkgtools`` can help to install,
update Slackware packages from a standard Slackware repository (official and 3th party).

## Features

 - Multiple repository support
 - Dependency resolution
 - Bash Completion support
 - More configurable
 - Flexible configuration via variables
 - DBus interface
 - Userspace DBus client to notify update & changelogs (via `org.freedesktop.Notification`)
 - ... and more

## Installation

**[INSTALL.md](INSTALL.md)** file provide instructions on how to install SlackMan.

## Supported Repository

SlackMan support different SlackWare repository including:

 - Slackware stable and **-current**
 - SlackOnly
 - Slackers (Conraid)
 - Slacky (Italian Slackware Community)
 - AlienBob
 - ktown (KDE5)
 - Cinnamon SlackBuilds
 - MATE SlackBuilds
 - Salix
 - Microlinux
 - ... and more

## Usage

    Usage:
          slackman [options] [commands] [...]

    Commands:
          install PACKAGE [...]        Install one or more packages
          upgrade [PACKAGE [...]]      Update installed packages
          reinstall PACKAGE [...]      Reinstall one or more packages
          remove PACKAGE [...]         Remove one or more packages
          history PACKAGE              Display package history information
          info PACKAGE                 Display information about installed or available packages

          changelog [PACKAGE]          Display general or package ChangeLog
          search PATTERN               Search packages using PATTERN
          file-search PATTERN          Search files into packages using PATTERN
          new-config                   Find new configuration files

          version                      Display version information
          help                         Display help
          help [COMMAND]               Display command help usage

      Repository Commands:
          repo list                    List available repositories
          repo enable REPOSITORY       Enable repository
          repo disable REPOSITORY      Disable repository
          repo info REPOSITORY         Display repository information
          repo help                    Display repo command help usage

      List Commands:
          list obsoletes               List obsolete packages
          list installed               List installed packages
          list packages                List available packages
          list repo                    List available repositories
          list orphan                  List orphan packages installed from unknown repository
          list variables               List variables for ".repo" configurations
          list help                    Display list command help usage

      Update Commands:
          update                       Update repository and local history packages metadata
          update history               Update local packages history metadata
          update packages              Update repository metadata (using PACKAGES.TXT file)
          update changelog             Update repository ChangeLog (using ChangeLog.txt)
          update manifest              Update repository Manifest (using MANIFEST.bz2)
          update gpg-key               Update repository GPG-KEY
          update all                   Update all metadata (packages, gpg-key, changelog, etc.)
          update help                  Display update command help usage

      Clean Commands:
          clean cache                  Clean cache package download directory
          clean metadata               Clean database metadata (packages, changelog, manifest)
          clean db                     Clean database file
          clean all                    Clean database file and cache directory
          clean help                   Display clean command help usage

      Database Commands:
          db optimize                  Optimize slackman database
          db info                      Display information about SlackMan database
          db help                      Display db command help usage

      log Commands:
          log clean                    Clean log file
          log tail                     Display log file in real time
          log help                     Display log command help usage

      Config Commands:
          config                       Display SlackMan configuration
          config [OPTION]              Query SlackMan config option
          config [OPTION] [VALUE]      Set SlackMan config option
          config help                  Display config command help usage

      Options:
          -h, --help                   Display help and exit
          --man                        Display man pages
          --version                    Display version information
          -c, --config                 Configuration file
          --root                       Set Slackware root directory
          --color=[always|auto|never]  Colorize the output

      Commands Options:
          --repo                       Use specified repo during update or install packages
          --details                    Display ChangeLog details
          --security-fix               Display only ChangeLog Security Fix
          -f, --force                  Force action
          --download-only              Download only
          --new-packages               Check for new packages
          --obsolete-packages          Check for obsolete packages
          --exclude-installed          Exclude installed packages from list
          -x, --exclude PACKAGE        Exclude package
          --show-files                 Show file lists
          --no-priority                Disable repository priority check
          --no-excludes                Disable exclude repo configuration
          --no-deps                    Disable dependency check
          -y, --yes                    Assume yes
          -n, --no                     Assume no
          --quiet                      Quiet


## Examples

Update repository packages and upgrade all packages:

    # slackman update && slackman upgrade -y

Install, update and remove obsolete packages from specific repository:

    # slackman update
    # slackman install --new-packages --repo ktown
    # slackman upgrade --repo ktown
    # slackman remove --obsolete-packages --repo ktown

Update package excluding kernels packages

    # slackman upgrade --exclude kernel-*

Search package:

    # slackman search docker

Search file using MANIFEST.bz2 repository file (`slackman update manifest`):

    # slackman file-search firefox

Enable a repository:

    # slackman repo enable slackware:multilib

Display the ChangeLog:

    # slackman changelog --repo slackware:packages

Bash Completion:

    # slackman repo info sla<TAB><TAB>
    slackware:extra        slackware:multilib     slackware:packages
    slackware:pasture      slackware:patches      slackware:testing

## Copyright

 - Copyright 2016-2017 © Giuseppe Di Terlizzi
 - Slackware® is a Registered Trademark of Patrick Volkerding
 - Linux is a Registered Trademark of Linus Torvalds
