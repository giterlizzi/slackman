# SlackMan Examples

Update repository packages and upgrade all packages:

    # slackman update && slackman upgrade -y

Install, upgrade and remove obsolete packages from specific repository:

    # slackman update
    # slackman install --new-packages --repo ktown
    # slackman upgrade --repo ktown
    # slackman remove --obsolete-packages --repo ktown

Upgrade package excluding kernels packages

    # slackman upgrade --exclude kernel-*

Search package:

    # slackman search docker

Search file using MANIFEST.bz2 repository file (`slackman update manifest`):

    # slackman file-search firefox

Add new repository:

    # slackman repo add http://slackware.com/pub/slackman/repos.d/slackware.repo

Enable a repository:

    # slackman repo enable slackware:multilib

Display the ChangeLog:

    # slackman changelog --repo slackware:packages

Search a CVE into the ChangeLog and display the detail:

    # slackman changelog --cve CVE-2017-1000251 --details

Bash Completion:

    # slackman repo info sla<TAB><TAB>
    slackware:extra        slackware:multilib     slackware:packages
    slackware:pasture      slackware:patches      slackware:testing
