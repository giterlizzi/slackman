# SlackMan - Slackware Package Manager ChangeLog

## [Develop]

This release introduce the automatic detection of Slackware `-current` release using the new `/etc/slackware-version` format (eg. `14.2+`). Added parsing of Slackware Announce in ChangeLog. General optimizations and reduced the `slackman` command startup by ~0.3 second.

## Added

  * Added `--terse` option for display only a single description line when install or upgrade package
  * Added `slackman clean removed` command for delete removed packages and scripts file in pkgtools directory (`/var/log/removed_{packages,scripts}`)
  * Added new entry for `00-default.renames` file
  * #11 - Added automatic detection of Slackware-current (since **14.2+** release)
  * #12 - Added `org.LotarProject.SlackMan.Announces` D-Bus method to retrieve ChangeLog announces
  * #12 - Added `slackman changelog --announces` option to retrieve Slackware ChangeLog announces
  * #13 - Added `arch` config option in `.repo` files with supported repository arch

## Changed

  * Re-added `HTTP::Tiny` support with check of SSL Perl modules (`IO::Socket::SSL` and `Net::SSLeay`)
  * Optimization for `slackman.bash` completion file
  * Changed location of required Perl module in `@INC`
  * Load `Net::DBus` module when necessary (this reduce `slackman` command startup by ~0.3 second)
  * slackman-libsupport.SlackBuild` file now use `cpanm` for download and build the required Perl modules


## [v1.3.0]

This release introduce new options (`--local` for install or upgrade from local package) and new feature (`.renames` configuration file). Now SlackMan use cURL command for download th packages and repository metadata. Added new D-Bus methods and signals and improved `slackman-notifier` client.

## Added

  * Added missing options in Bash completion script
  * Added new D-Bus methods (see `org.lotarproject.SlackMan(7)`)
  * Added `.renames` support (see `slackman.renames(5)`)
  * Added `--local` option for install, upgrade local packages
  * Added new TAP test
  * Added support of `slackman-libsupport` package

## Removed

  * Removed check of require modules
  * Drop support of `HTTP::Tiny` module
  * Drop support of "experimental" Perl feature

## Changed

  * DB schema optimization for `manifest` table
  * Use Perl sub for `REGEXP` SQLite function
  * Fire D-Bus signal after `slackman update` commands
  * Bootstrap optimizations
  * Reduced required Perl modules
  * Optimization for `SlackMan/Config.pm` module

## Fixed

  * Fixed `repos.d/slackware.repo` URL


## [v1.2.1]

This release fix an issue for SlackMan build (#10 thanks to @axpira)

## [v1.2.0]

This release introduce new features, new commands and improved the stability and performance. Added new D-Bus methods/properties and integrated SlackMan via PolicyKit.

## Added

  * #2: Add new repo via URL or via local file (`slackman repo add REPOSITORY-FILE`)
  * #3: Added `--tag` option for upgrade installed package with specified package tag (eg. `slackman upgrade --repo slackonly:packages --tag SBo`)
  * #6: Query "installed", "upgraded" and "removed" packages by timestamp
  * #7: Added check of duplicate packages for `install`, `upgrade`, `remove` and `reinstall` commands
  * #4, #5: Added `slackman list removed` & `slackman list upgraded` commands
  * #9: Added PolicyKit integration for using `slackman` via `pkexec(1)` command and for `org.lotarproject.SlackMan` D-Bus interface methods
  * Added new D-Bus methods for use Slackware Package Tools (`installpkg`, `removepkg`, `upgradepkg`) via D-Bus
  * Added new D-Bus method and signals to notify via D-Bus all installed, upgraded and removed packages using `slackman` command
  * Added new D-Bus properties to fetch SlackMan and Slackware version
  * Added `slackman-notifier` itegration for notify all installed, upgraded and removed packages using `slackman` command
  * Added package size for most list commands
  * Added package `tag` field for `slackman history` command
  * Added `Slackware::SlackMan::Pkgtools` module wrapper for Slackware Package Tools
  * Added sample script `dbus-pkgtools` to emulate Slackware PkgTools via D-Bus + PolicyKit
  * Added new options to disable GPG and MD5 check (`--no-gpg-check`, `--no-md5-check`) during download of package
  * Added new option to search a CVE (Common Vulnerabilities and Exposures) into the ChangeLogs (`--cve=CVE-YYYY-NNNN`)
  * Added `slackman repo config` command to edit via CLI repository configuration

## Fixed

  * #8: Optimizations of Slackware database parsing

## Removed

  * Removed `slackman update installed` command (merged into `slackman update history`)
  * Removed `unlink` after package upgrade and install. Remember to launch `slackman clean cache` command periodically


## [v1.1.2]

## Added

  * Added `--after` and `--before` in `slackman.bash` completion script

## Fixed

  * Fixed paser for `--after` and `--before` options
  * Fixed `notify` sub callback for `slackman-notifier` command


## [v1.1.1]

### Added

  * Added Studioware repository

### Changed

  * Changed MATE SlackBuild mirror URL

### Fixed

  * Fixed `HTTP::Tiny` warning
  * Fixed proxy initialization with `HTTP::Tiny`


## [v1.1.0]

This release introduce new features, new commands & params and new DBus service & destkop client (`slackman-notifier`). Improved speed, stability and repository support.

### Added
  * New commands (`config` get & set configuration via CLI, `log`, etc) and new options (`--new-config`, `--details`, `--Security-fix`, etc)
  * Added DBus interface to fetch latest Security Fix & ChangeLog and packages update
  * Added `slackman-notifier` DBus client to notifiy Security Fix & ChangeLog and packages upgrade via `org.freedesktop.Notification` DBus service
  * Added color output for most commands (you can disable temporary via `--color=never` option or via `slackman config main.color never` command)
  * Added informational message for new kernel upgrade
  * Added helper to create new `initrd.gz` file and install the new kernel via `lilo` (or `eliloconfig`) command
  * Added `.new` config file search in `/etc` directory (`slackpkg` like feature)
  * Added daily update metadata (packages list & ChangeLog) via cron
  * Added support for `HTTP::Tiny` module for package and repository metadata download
  * Added man pages for all commands
  * Added `make slackbuild` target for create a precompiled SlackMan package
  * Added Robby Workman repository (`rworkman:packages`)
  * Added new bugs to fix later

### Changed
  * DB structure (added new fileds and index to speedup operations)
  * DB schema update process
  * Splitted `SlackMan/Command.pm` module in different sub-modules `SlackMan/Commands/*.pm`
  * Create a symlink for repository with `file://` protocol

### Fixed
  * Fixed ChangeLog parser. Now slackman support most Slackware ChangeLog dialect (AliebBob, SlackOnly, etc)

### Removed
  * Dropped support of `curl` command for package and repository metadata download
  * Removed `Build.PL` (use `make slackbuild` instead)


## Older releases

  * [v1.0.4]
  * [v1.0.3]
  * [v1.0.2]
  * [v1.0.1]
  * [v1.0.0]

[Develop]: https://github.com/LotarProject/slackman/compare/master...develop
[v1.3.0]: https://github.com/LotarProject/slackman/compare/v1.2.1...v1.3.0
[v1.2.1]: https://github.com/LotarProject/slackman/compare/v1.2.0...v1.2.1
[v1.2.0]: https://github.com/LotarProject/slackman/compare/v1.1.1...v1.2.0
[v1.1.2]: https://github.com/LotarProject/slackman/compare/v1.1.1...v1.1.2
[v1.1.1]: https://github.com/LotarProject/slackman/compare/v1.1.0...v1.1.1
[v1.1.0]: https://github.com/LotarProject/slackman/compare/v1.0.4...v1.1.0
[v1.0.4]: https://github.com/LotarProject/slackman/compare/v1.0.3...v1.0.4
[v1.0.3]: https://github.com/LotarProject/slackman/compare/v1.0.2...v1.0.3
[v1.0.2]: https://github.com/LotarProject/slackman/compare/v1.0.1...v1.0.2
[v1.0.1]: https://github.com/LotarProject/slackman/compare/v1.0.0...v1.0.1
[v1.0.0]: https://github.com/LotarProject/slackman/compare/v1.0.0...v1.0.0
