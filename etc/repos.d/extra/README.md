# Extra SlackMan repository

SlackMan support different Slackware repository:

 - SlackOnly
 - Slackers (Conraid)
 - Slacky (Italian Slackware Community)
 - AlienBob
 - ktown (KDE5)
 - Cinnamon SlackBuilds
 - MATE SlackBuilds
 - Salix
 - Microlinux
 - and more...

## Install

Copy your preferred repository in `/etc/slackman/repos.d` directory.

## Enable Repository

To enable the repository edit `.repo` file and change `enable` flag from `false`
to `true` or use `slackman repo enable REPOSITORY` command.
