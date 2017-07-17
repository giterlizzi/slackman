# SlackMan Examples

Update repository packages and upgrade all packages:

    # slackman update && slackman upgrade -y

Install, update and remove obsolete packages from specific repository:

    # slackman update
    # slackman install --new-packages --repo ktown
    # slackman upgrade --repo ktown
    # slackman remove --obsolete-packages --repo ktown

Update package excluding kernels packages

    # slackman upgrade --exclude kernel-*

Search package:

    # slackman search docker

Search file using MANIFEST.bz2 repository file (`slackman update manifest`):

    # slackman file-search firefox

Enable a repository:

    # slackman repo enable slackware:multilib

Display the ChangeLog:

    # slackman changelog --repo slackware:packages

Bash Completion:

    # slackman repo info sla<TAB><TAB>
    slackware:extra        slackware:multilib     slackware:packages
    slackware:pasture      slackware:patches      slackware:testing
