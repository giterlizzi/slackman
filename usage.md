# SlackMan Usage

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
