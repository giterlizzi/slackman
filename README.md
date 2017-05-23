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
 - ... and more

## Installation

**[INSTALL.md](INSTALL.md)** file provide instructions on how to install SlackMan.

## Supported Repository

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
          install PACKAGE [...]     Install one or more packages
          upgrade [PACKAGE [...]]   Update installed packages
          reinstall PACKAGE [...]   Reinstall one or more packages
          remove PACKAGE [...]      Remove one or more packages

          check-update              Check packages updates
          changelog                 Display repository ChangeLogs
          search PATTERN            Search packages using PATTERN
          file-search PATTERN       Search files into packages using PATTERN
          info PACKAGE              Display information about installed or available packages
          history PACKAGE           Display package history information
          config                    Display configuration
          help COMMAND              Display command usage

      Repository Commands:
          repo list                 List available repositories
          repo enable REPOSITORY    Enable repository
          repo disable REPOSITORY   Disable repository
          repo info REPOSITORY      Display repository information

      List Commands:
          list obsolete             List obsolete packages
          list installed            List installed packages
          list packages             List available packages
          list repo                 List available repositories
          list orphan               List orphan packages installed from unknown repository
          list variables            List variables for repos.d/* configurations

      Update Commands:
          update                    Update repository and local history packages metadata
          update history            Update local packages history metadata
          update packages           Update repository metadata
          update changelog          Update repository ChangeLog
          update manifest           Update repository Manifest
          update gpg-key            Update repository GPG-KEY
          update all                Update all metadata (packages, gpg-key, changelog, etc.)

      Clean Commands:
          clean cache               Clean cache package download directory
          clean metadata            Clean database metadata
          clean manifest            Clean manifest data
          clean all                 Clean metadata and cache directory

      Database Commands:
          db optimize               Optimize slackman database
          db info                   Display information about slackman database

      Options:
          -h, --help                Display help and exit
          --man                     Display man pages
          --version                 Display version information
          -c, --config              Configuration file
          --root                    Set Slackware root directory
          --repo                    Use specified repo during update or install packages
          --download-only           Download only
          --new-packages            Check for new packages
          --obsolete-packages       Check for obsolete packages
          -x, --exclude PACKAGE     Exclude package
          --show-files              Show file lists
          --no-priority             Disable repository priority check
          --no-excludes             Disable exclude repo configuration
          -y, --yes                 Assume yes
          -n, --no                  Assume no
          --quiet                   Quiet

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

Bash Completion:

    # slackman repo info sla<TAB><TAB>
    slackware:extra        slackware:multilib     slackware:packages
    slackware:pasture      slackware:patches      slackware:testing

## Copyright

 - Copyright 2016-2017 © Giuseppe Di Terlizzi
 - Slackware® is a Registered Trademark of Patrick Volkerding
 - Linux is a Registered Trademark of Linus Torvalds
