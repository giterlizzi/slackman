# SlackMan Requirements, Install & SlackBuild

## Requirements

SlackMan is written in Perl and require this extra Perl modules installed on your machine:

Module            | Usage
------------------|-------------------------------------------------------------
`DBD::SQLite`     | SQLite library to manage SlackMan database
`Sort::Versions`  | This module is used to compare the package version
`Net::DBus`       | Notify new packages update and expose methods via D-Bus
`IO::Socket::SSL` | SSL module for `HTTP::Tiny` module
`Net::SSLeay`     | SSL module for `HTTP::Tiny` module
`HTTP::Tiny`      | Used by SlackMan for download a package (included from Perl v5.14)

You can download and compile the SlackBuild of this package from [SlackBuilds.org](https://slackbuilds.org)
or via `sbopkg`:

    sbopkg -i perl-DBD-SQLite \
           -i perl-Sort-Versions \
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
