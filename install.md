# SlackMan Requirements, Install & SlackBuild

## Requirements

SlackMan is written in Perl and require this extra Perl modules installed on your machine:

Module            | Usage
--------------------------------------------------------------------------------
`DBD::SQLite`     | SQLite library to manage SlackMan database
`Sort::Versions`  | This module is used to compare the package version
`Net::DBus`       | Notify new packages update and expose methods via D-Bus
`IO::Socket::SSL` | SSL module for `HTTP::Tiny` module
`Net::SSLeay`     | SSL module for `HTTP::Tiny` module
`HTTP::Tiny`      | Used by SlackMan for download a package (included from Perl v5.14)

## Install from source

To install SlackMan, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

## Create SlackBuild package

To automate a creation of SlackBuild package, run the following commands:

    perl Makefile.PL
    make slackbuild
    upgradepkg --install-new /tmp/slackman-x.y.z-noarch-1_lotar.tgz
