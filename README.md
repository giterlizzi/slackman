[![Release](https://img.shields.io/github/release/LotarProject/slackman.svg)](https://github.com/LotarProject/slackman/releases) [![Build Status](https://travis-ci.org/LotarProject/slackman.svg)](https://travis-ci.org/LotarProject/slackman) [![License](https://img.shields.io/github/license/LotarProject/slackman.svg)](https://github.com/LotarProject/slackman) [![Starts](https://img.shields.io/github/stars/LotarProject/slackman.svg)](https://github.com/LotarProject/slackman) [![Forks](https://img.shields.io/github/forks/LotarProject/slackman.svg)](https://github.com/LotarProject/slackman) [![Issues](https://img.shields.io/github/issues/LotarProject/slackman.svg)](https://github.com/LotarProject/slackman/issues)

# slackman

SlackMan - Slackware Package Manager

SlackMan is easy-to-use wrapper for Slackware ``pkgtools`` can help to install,
update Slackware packages from a standard Slackware repository (official and 3th party).

## Features

 - Multiple repository support
 - Dependency resolution
 - Bash Completion support
 - More configurable
 - Flexible configuration via variables
 - DBus interface
 - Userspace DBus client to notify update & changelogs (via `org.freedesktop.Notification`)
 - ... and more

## Installation

**[INSTALL.md](INSTALL.md)** file provide instructions on how to install SlackMan.

## Supported Repository

SlackMan support different SlackWare repository including:

 - Slackware stable and **-current**
 - SlackOnly
 - Slackers (Conraid)
 - Slacky (Italian Slackware Community)
 - AlienBob
 - ktown (KDE5)
 - Cinnamon SlackBuilds
 - MATE SlackBuilds
 - Salix
 - Microlinux
 - ... and more


## Examples

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

Add new repository:

    # slackman repo add http://slackware.com/pub/slackman/repos.d/slackware.repo

Display the ChangeLog:

    # slackman changelog --repo slackware:packages

Bash Completion:

    # slackman repo info sla<TAB><TAB>
    slackware:extra        slackware:multilib     slackware:packages
    slackware:pasture      slackware:patches      slackware:testing


## Copyright

 - Copyright 2016-2018 © Giuseppe Di Terlizzi
 - Slackware® is a Registered Trademark of Patrick Volkerding
 - Linux is a Registered Trademark of Linus Torvalds
