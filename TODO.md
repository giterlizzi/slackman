# SlackMan TODO

 - [ ] Check dependencies command (eg. `slackman check-deps PACKAGE`)
 - [ ] Remove package and all "directed" dependencies (`slackman remove routersploit --remove-dependencies`)
 - [ ] Display installed date in `slackman history` for packages installed and removed (never upgraded). Now dsplay only the removed date
 - [ ] Add option `--append` (or `-A`) for `slackman config` and `slackman repo config` for append a text in config file
 - [ ] Notify the user of changed or installed `/etc/rc.d`
 - [ ] Follow logger category for logging
 - [ ] Plugin system (via hooks / events)
 - [ ] Restyling `slackman update` output
 - [ ] Move all repo config in `/usr/share/slackman/repos.d`
 - [ ] Add option to force downgrade with local package
 - [ ] Add `slackman download PACKAGE` command for download only the package (alias of `slackman install --download-only PACKAGE` and `slackman upgrade --download-only PACKAGE`)
 - [ ] Unload DBUS module when Slackware is started in 0 runlevel or in container (Docker)
 - [ ] Add excluded package from command line `slackman excluded add kernel*`
 - [ ] Remove excluded package from command line `slackman excluded remove kernel*`
 - [ ] List excluded package `slackman excluded list` or `slackman list excluded`

## SlackMan 1.1

 - [x] D-BUS notification/service of available packages upgrade, security fix and ChangeLog
 - [x] Crontab script (send mail for new updates, download packages, etc)
 - [x] Makefile for automate build of package
 - [x] Speedup slackman bootstrap
 - [x] List packages by repo `slackman list packages --repo REPOSITORY`
 - [x] Using Perl module instead of `curl` command for downloading (`LWP` or `HTTP::Tiny`)
 - [x] Create a command plug-in system
 - [x] Move commands code into individual modules
 - [x] Create `slackpkg new-config` like feature
 - [x] Check last SlackMan update metadata. Display message after 24h to remember to launch "slackman update"


## SlackMan 1.2

 - [x] #2 - Add new repo via URL or via local file (`slackman repo add http://example.org/slackware.repo`)
 - [x] #3 - Upgrade installed packages with particular tag (`slackman upgrade --repo slackonly:packages --tag SBo`)
 - [x] #4 - List removed packages (`slackman list removed`)
 - [x] #5 - List upgraded packages (`slackman list upgraded`)
 - [x] #6 - Query `installed`, `upgraded` and `removed` packages by timestamp (`slackman list removed --after=7days`)
 - [x] #7 - Check duplicate packages name
 - [x] #8 - Optimizations of Slackware database parsing (`/var/log/{removed_,}packages`)
 - [x] #9 - Integrate SlackMan with PolicyKit (for pkexec and D-Bus interface)
 - [x] Display package "tag" on `slackman history` command
 - [x] Display extended download error ( eg. **404** ) in package summary
 - [x] Set repo config via CLI (eg. set new mirror url `slackman repo set slackware:packages mirror file:///srv/mirror/slackware`)


## SlackMan 1.3

 - [x] Trigger via D-Bus signal the end of SlackMan repository update (packages, manifest, and changelog)
 - [x] Reload SlackMan Notifier check (updates, security fix, etc) on D-Bus signal
 - [x] Add renamed or aliased package support (eg. `/etc/slackman/renames.d/00-default.renamed`)
 - [x] Add local package install/upgrade using `--local FILE` option (eg. `slackman install --local /tmp/foo-1.2-noarch-1`)
 - [x] Add option `d` in answer when using `slackman install` & `slackman upgrade` commands for download the packages (eg. `Perform upgrade of selected packages? [Y/N/d]`)
 - [x] Increase SlackMan bootstrap and module loading


## SlackMan 1.4

 - [x] #11 - Use `/etc/slackware-version` to automatically detect Slackware -current (post 14.2)
 - [x] #11 - Add `--terse` options for `slackman` command
 - [x] #12 - Parse announces in ChangeLog
 - [x] #12 - Add option for display the announces (eg. `slackman changelog --announces`) or create new command (eg. `slackman announces`)
 - [x] #12 - Expose a new D-Bus methods to retrieve the announces (eg. `org.LotarProject.SlackMan.Announces`)
 - [x] #13 - Add `arch` config option in `.repo` file with supported repository arch

