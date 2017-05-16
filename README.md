# slackman
SlackMan - Slackware Package Manager

SlackMan is easy-to-use wrapper for Slackware ``pkgtools`` can help to install,
update Slackware packages from a standard Slackware repository (official and 3th party).

## Installation

**INSTALL.md** file provide instructions on how to install SlackMan.

## Usage

    Usage: slackman [command] [options]

    Commands:

      install PACKAGE [...]     Install one or more packages
      upgrade [PACKAGE [...]]   Update installed packages
      reinstall PACKAGE [...]   Reinstall one or more packages
      remove PACKAGE [...]      Remove one or more packages
      update                    Update repository and local history packages metadata
      update history            Update local packages history metadata
      update packages           Update repository metadata
      update changelog          Update repository ChangeLog
      update manifest           Update repository Manifest
      update gpg-key            Update repository GPG-KEY
      update all                Update all metadata (packages, gpg-key, changelog, etc.)
      repo list                 List available repositories
      repo info [REPOSITORY]    Display repository information
      list obsolete             List obsolete packages
      list installed            List installed packages
      list packages             List available packages
      list repo                 List available repositories
      list orphan               List orphan packages installed from unknown repository
      list variables            List variables for repos.d/* configurations
      clean                     Clean metadata and download cache
      clean metadata            Clean metadata
      clean cache               Clean download cache
      db optimize               Optimize slackman database
      db info                   Display slackman database info
      search PATTERN            Search packages using PATTERN
      file-search PATTERN       Search files into packages using PATTERN
      info PACKAGE              Display information about installed or available packages
      history PACKAGE           Display package history information
      config                    Display configuration


    Options:

      -h, --help                Display this screen and exit
      --version                 Display version information
      --root                    Set slackware root directory
      --repo                    Use specified repo during update or install package
      --download-only           Download only
      --new-packages            Check new packages
      --obsolete-packages       Check for obsolete packages
      --no-priority             Disable repository priority check
      --disable-md5-check       Disable MD5 check
      --disable-gpg-check       Disable GPG check
      -y, --yes                 Assume yes
      -n, --no                  Assume no
