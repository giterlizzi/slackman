# NAME

slackman - Slackware Package Manager wrapper for pkgtools

# SYNOPSIS

    slackman [options] [commands] [...]

# DESCRIPTION

SlackMan is easy-to-use wrapper for Slackware `pkgtools` can help to install,
update Slackware packages from a standard Slackware repository (official and 3th party).

# COMMANDS

    install PACKAGE [...]        Install one or more packages
    upgrade [PACKAGE [...]]      Upgrade installed packages
    reinstall PACKAGE [...]      Reinstall one or more packages
    remove PACKAGE [...]         Remove one or more packages
    history PACKAGE              Display package history information
    info PACKAGE                 Display information about installed or available packages
    changelog [PACKAGE]          Display general or package ChangeLog
    search PATTERN               Search packages using PATTERN
    file-search PATTERN          Search files into packages using PATTERN
    new-config                   Find new configuration files
    update                       Update repository metadata
    repo                         Display and manage the repositories
    list                         Display information about packages
    clean                        Clean SlackMan database and cache
    db                           Display and manage SlackMan database
    log                          Display SlackMan log
    config                       Display and manage SlackMan configurations
    version                      Display version information
    help                         Display help
    help [COMMAND]               Display command help usage

## OPTIONS

    -h, --help                   Display help and exit
    --man                        Display man pages
    --version                    Display version information
    -c, --config=FILE            Configuration file
    --root                       Set Slackware root directory
    --color=[always|auto|never]  Colorize the output

### GLOBAL COMMANDS OPTIONS

    --after=DATE                 Filter after date
    --before=DATE                Filter before date
    --repo=REPOSITORY            Use specified repository during update or install packages
    -f, --force                  Force an action
    --download-only              Download only
    -y, --yes                    Assume yes
    -n, --no                     Assume no
    --no-gpg-check               Disable GPG verify check
    --no-md5-check               Disable MD5 checksum check

# EXAMPLES

Update repository packages list and upgrade all packages:

    slackman update && slackman upgrade -y

Force update of specific repository:

    slackman update packages --repo slackware:packages --force

Install, upgrade and remove obsolete packages from specific repository:

    slackman update
    slackman install --new-packages --repo ktown
    slackman upgrade --repo ktown
    slackman remove --obsolete-packages --repo ktown

Upgrade package excluding kernels packages

    slackman upgrade --exclude kernel-*

Search a package:

    slackman search docker

Search file using MANIFEST.bz2 repository file (`slackman update manifest`):

    slackman file-search firefox

Enable a repository:

    slackman repo enable slackware:multilib

# FILES

- /etc/slackman/slackman.conf
- /etc/slackman/repos.d/\*
- /var/log/slackman.log

# SEE ALSO

[slackman-clean(8)](../8/slackman-clean), [slackman-config(8)](../8/slackman-config), [slackman-db(8)](../8/slackman-db), [slackman-list(8)](../8/slackman-list),
[slackman-log(8)](../8/slackman-log), [slackman-package(8)](../8/slackman-package), [slackman-repo(8)](../8/slackman-repo), [slackman-update(8)](../8/slackman-update),
[slackman.conf(5)](../5/slackman.conf), [slackman.repo(5)](../5/slackman.repo), [installpkg(8)](../8/installpkg), [makepkg(8)](../8/makepkg),
[removepkg(8)](../8/removepkg), [explodepkg(8)](../8/explodepkg), [pkgtool(8)](../8/pkgtool), [upgradepkg(8)](../8/upgradepkg)

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
