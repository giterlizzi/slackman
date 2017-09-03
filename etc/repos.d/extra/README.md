# Extra SlackMan repository

SlackMan support different Slackware repository:

 - Slackware stable and **-current**
 - SlackOnly
 - Slackers (Conraid)
 - Slacky (Italian Slackware Community)
 - AlienBob (and **restricted** repository)
 - Robby Workman
 - ktown (KDE5)
 - Cinnamon SlackBuilds
 - MATE SlackBuilds
 - Salix
 - Microlinux
 - Studioware
 - ... and more

## Install

Copy your preferred repository in `/etc/slackman/repos.d` directory or use
`slackman repo add REPOSITORY-FILE` command:

    # slackman repo add /etc/slackman/repos.d/extra/slackonly.repo

## Enable Repository

To enable the repository edit `.repo` file and change `enable` flag from `false`
to `true` or use `slackman repo enable REPOSITORY` command.
