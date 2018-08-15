# slackman-update(8)
# NAME

slackman-update - Perform update of repository metadata

# SYNOPSIS

    slackman update installed
    slackman update history

    slackman update [--repo=REPOSITORY]
    slackman update packages  [--repo=REPOSITORY]
    slackman update changelog [--repo=REPOSITORY]
    slackman update manifest [--repo=REPOSITORY]
    slackman update gpg-key [--repo=REPOSITORY]
    slackman update all [--repo=REPOSITORY]

    slackman update help

# DESCRIPTION

**slackman update** perform update of repository metadata. This is a standard
Slackware repository structure:

    ChangeLog.txt
    PACKAGES.TXT
    MANIFEST.bz2
    GPG-KEY
    CHECHSUMS.md5
    FILE_LIST

SlackMan store this files into a repository cache and into a database.

The default location of SlackMan cache is `directory.cache`.

To see the current location of `directory.cache` use [slackman-config(8)](../8/slackman-config.md) command:

    slackman config directory.cache

# COMMANDS

    slackman update                      Update repository and local history packages metadata
    slackman update history              Update local packages history metadata (installed, upgraded & removed)
    slackman update packages             Update repository metadata (using PACKAGES.TXT file)
    slackman update changelog            Update repository ChangeLog (using ChangeLog.txt)
    slackman update manifest             Update repository Manifest (using MANIFEST.bz2)
    slackman update gpg-key              Update repository GPG-KEY
    slackman update all                  Update all metadata (packages, gpg-key, changelog, etc.)
    slackman update help                 Display update command help usage

# OPTIONS

    --repo=REPOSITORY                    Use specified repository during update
    -h, --help                           Display help and exit
    --man                                Display man pages
    --version                            Display version information
    -c, --config=FILE                    Configuration file
    --color=[always|auto|never]          Colorize the output

# SEE ALSO

[slackman(8)](../8/slackman.md), [slackman-repo(8)](../8/slackman-repo.md), [slackman.conf(5)](../5/slackman.conf.md), [slackman.repo(5)](../5/slackman.repo.md)

# BUGS

Please report any bugs or feature requests to 
[https://github.com/LotarProject/slackman/issues](https://github.com/LotarProject/slackman/issues) page.

# AUTHOR

Giuseppe Di Terlizzi <giuseppe.diterlizzi@gmail.com>

# COPYRIGHT AND LICENSE

Copyright 2016-2018 Giuseppe Di Terlizzi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)
