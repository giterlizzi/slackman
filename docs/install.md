# SlackMan Install & SlackBuild

## Installation

To install SlackMan, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

## Create SlackBuild package

To automate a creation of SlackBuild package, run the following commands:

    perl Makefile.PL
    make
    make slackbuild
    upgradepkg --install-new /tmp/slackman-x.y.z-noarch-1_lotar.tgz
