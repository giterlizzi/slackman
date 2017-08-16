# SlackMan - Slackware Package Manager ChangeLog

## [v1.1.1]

### Added

  * Added Studioware repository

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
[v1.1.1]: https://github.com/LotarProject/slackman/compare/v1.1.0...v1.1.1
[v1.1.0]: https://github.com/LotarProject/slackman/compare/v1.0.4...v1.1.0
[v1.0.4]: https://github.com/LotarProject/slackman/compare/v1.0.3...v1.0.4
[v1.0.3]: https://github.com/LotarProject/slackman/compare/v1.0.2...v1.0.3
[v1.0.2]: https://github.com/LotarProject/slackman/compare/v1.0.1...v1.0.2
[v1.0.1]: https://github.com/LotarProject/slackman/compare/v1.0.0...v1.0.1
[v1.0.0]: https://github.com/LotarProject/slackman/compare/v1.0.0...v1.0.0
