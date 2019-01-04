# SlackMan Requirements, Install & SlackBuild

## Requirements

SlackMan is written in Perl and require this extra Perl modules installed on your machine:

Module        | Usage
--------------|-----------------------------------------------------------------
`DBD::SQLite` | SQLite library to manage SlackMan database
`Net::DBus`   | Notify new packages update and expose SlackMan methods via D-Bus
`IO::Socket::SSL`, `Net::SSLeay` | Add SSL/TLS support for `HTTP::Tiny` module

### Install required modules using slackman-libsupport package

You can use `slackman-libsupport` SlackBuild for install all required modules.

    curl -L https://raw.githubusercontent.com/LotarProject/slackman/master/slackbuilds/slackman-libsupport/slackman-libsupport.SlackBuild | sh
    upgradepkg --install-new /tmp/slackman-libsupport-x.y.z-x86_64-1_lotar.tgz

### Install required modules via sbopkg

You can download and compile the SlackBuild of required modules from [SlackBuilds.org](https://slackbuilds.org)
or via `sbopkg`:

    sbopkg -i perl-DBD-SQLite \
           -i perl-net-dbus \
           -i perl-IO-Socket-SSL \
           -i Net-SSLeay

## Create SlackBuild package

To automate a creation of SlackBuild package, run the following commands:

    perl Makefile.PL
    make slackbuild
    upgradepkg --install-new /tmp/slackman-x.y.z-noarch-1_lotar.tgz

## Install from source

To install SlackMan from source, run the following commands:

    perl Makefile.PL
    make
    make test
    make install
