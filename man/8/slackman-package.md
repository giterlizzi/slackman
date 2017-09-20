# NAME

slackman-package - Install, upgrade and display information of Slackware packages

# SYNOPSIS

    slackman install PACKAGE [...]
    slackman upgrade [PACKAGE [...]]
    slackman reinstall PACKAGE [...]
    slackman remove PACKAGE [...]
    slackman history PACKAGE
    slackman info PACKAGE

    slackman changelog [PACKAGE]
    slackman search PATTERN
    slackman file-search PATTERN
    slackman new-config

# DESCRIPTION

# COMMANDS

    slackman install PACKAGE [...]        Install one or more packages
    slackman upgrade [PACKAGE [...]]      Upgrade installed packages
    slackman reinstall PACKAGE [...]      Reinstall one or more packages
    slackman remove PACKAGE [...]         Remove one or more packages
    slackman history PACKAGE              Display package history information
    slackman info PACKAGE                 Display information about installed or available packages

    slackman changelog [PACKAGE]          Display general or package ChangeLog
    slackman search PATTERN               Search packages using PATTERN
    slackman file-search PATTERN          Search files into packages using PATTERN
    slackman new-config                   Find new configuration files

# OPTIONS

    --repo=REPOSITORY                     Use specified repo during upgrade or install packages
    -h, --help                            Display help and exit
    --man                                 Display man pages
    --version                             Display version information
    -c, --config=FILE                     Configuration file
    --root                                Set Slackware root directory
    --color=[always|auto|never]           Colorize the output

## CHANGELOG OPTIONS

    --after=DATE                          Filter changelog after date
    --before=DATE                         Filter changelog before date
    --details                             Display ChangeLog details
    --security-fix                        Display only ChangeLog Security Fix
    --cve=CVE-YYYY-NNNNNN                 Search a CVE identifier into ChangeLogs

## INFO OPTIONS

    --show-files                          Show file lists

## INSTALL, UPGRADE, REMOVE, REINSTALL OPTIONS

    --category=CATEGORY                   Use a category
    -f, --force                           Force action
    --download-only                       Download only
    --new-packages                        Check for new packages
    --obsolete-packages                   Check for obsolete packages
    -x, --exclude=PACKAGE                 Exclude package
    --tag=TAG                             Force upgrade of installed package with specified tag
    --no-priority                         Disable repository priority check
    --no-excludes                         Disable exclude repo configuration
    --no-deps                             Disable dependency check
    -y, --yes                             Assume yes
    -n, --no                              Assume no
    --no-gpg-check                        Disable GPG verify check
    --no-md5-check                        Disable MD5 checksum check

# EXAMPLES

Update repository packages list and upgrade all packages:

    slackman update && slackman upgrade -y

Install, upgrade and remove obsolete packages from specific repository:

    slackman install --new-packages --repo ktown
    slackman upgrade --repo ktown
    slackman remove --obsolete-packages --repo ktown

Upgrade package excluding kernels packages

    slackman upgrade --exclude kernel-*

Search a package:

    slackman search docker

Search file using MANIFEST.bz2 repository file (`slackman update manifest`):

    slackman file-search firefox

Display a ChangeLog:

    slackman changelog --repo slackware:packages

Search a CVE into the ChangeLog and display the detail:

    slackman changelog --cve CVE-2017-1000251 --details

# SEE ALSO

[slackman(8)](../8/slackman.md), [slackman-repo(8)](../8/slackman-repo.md), [slackman-update(8)](../8/slackman-update.md), [slackman.conf(5)](../5/slackman.conf.md),
[slackman.repo(5)](../5/slackman.repo.md)

# BUGS

Please report any bugs or feature requests to 
[https://github.com/LotarProject/slackman/issues](https://github.com/LotarProject/slackman/issues) page.

# AUTHOR

Giuseppe Di Terlizzi <giuseppe.diterlizzi@gmail.com>

# COPYRIGHT AND LICENSE

Copyright 2016-2017 Giuseppe Di Terlizzi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)
