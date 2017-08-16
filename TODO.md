# SlackMan TODO

 - [ ] Number of installed packages in `slackman repo info REPOSITORY` command
 - [x] D-BUS notification/service of available packages upgrade, security fix and ChangeLog
 - [x] Crontab script (send mail for new updates, download packages, etc)
 - [x] Makefile for automate build of package
 - [x] Speedup slackman bootstrap
 - [ ] Installed packages by repo `slackman list installed --repo REPOSITORY`
 - [x] List packages by repo `slackman list packages --repo REPOSITORY`
 - [x] Using Perl module instead of `curl` command for downloading (`LWP` or `HTTP::Tiny`)
 - [x] Create a command plug-in system
 - [x] Move commands code into individual subs
 - [x] Create `slackpkg new-config` like feature
 - [x] Check last SlackMan update metadata. Display message after 24h to remember to launch "slackman update"
 - [ ] Check dependencies command (eg. `slackman check-deps PACKAGE`)
 - [ ] Integrate SlackMan with PolicyKit
 - [ ] Add new repository via URL
 - [ ] Arch rule in `.repo` file ( 32bit -> i386 directory)
 - [ ] Upgrade packages only with particular tag (`slackman upgrade --repo slackonly:packages --tag SBo`)
 
