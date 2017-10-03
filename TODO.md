# SlackMan TODO

 - [ ] Check dependencies command (eg. `slackman check-deps PACKAGE`)
 - [ ] Add rule in `.repo` file for 32-bit or ARM directory variant (i386, i486, i586, i686, x86, armv5, armv7, armel, etc.)
 - [ ] Add rule in `.repo` file to allow the repository only for particular arch (eg. `slackware:multilib` is only for `x86_64` arch)
 - [ ] Remove package and all "directed" dependencies (`slackman remove routersploit --remove-dependencies`)

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
