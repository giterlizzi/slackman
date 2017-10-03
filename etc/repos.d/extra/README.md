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

## Install new repository

Copy your preferred repository in `/etc/slackman/repos.d` directory or use
`slackman repo add REPOSITORY-FILE` command:

    # slackman repo add /etc/slackman/repos.d/extra/slackonly.repo

## Enable a repository

To enable the repository edit `.repo` file and change `enable` flag from `false`
to `true` or use `slackman repo enable REPOSITORY` command.

## Create manually a new .repo file

You can create a new **.repo** file for all compatible Slackware repository.
Follow this easy steps:

 * Create new text file with **.repo** (eg. **custom.repo** ) extension into `/etc/slackman/repos.d` directory
 * Copy and paste the below text into new **.repo** file

    [packages]
    name=My personal repository
    enabled=true
    mirror=http://example.org/my-personal-repository

 * Update the repository metadata using `slackman update --repo custom:packages`
 * Enjoy!

**NOTE** SlackMan provide a sample repository file `/etc/slackman/repos.d/extra/repo.sample`.
