# SlackMan Install & Build

## Installation

To install SlackMan, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

## Create SlackBuild package

To automate a creation of SlackBuild package use `Build.PL` script:

    # cd slackbuilds
    # perl Build.pl
    [...]
    # upgradepkg --install-new slackman-x.y.z-noarch-1_lotar.tgz
