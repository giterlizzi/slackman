# slackman-repo(8)
# NAME

slackman-repo - Display and manage Slackware repository

# SYNOPSIS

    slackman repo info REPOSITORY
    slackman repo enable REPOSITORY
    slackman repo disable REPOSITORY
    slackman repo add REPOSITORY-FILE
    slackman repo list
    slackman repo help

# DESCRIPTION

**slackman repo** display and manage Slackware repository defined in `/etc/slackman/repod.d`
directory.

# COMMANDS

    slackman repo list                   List available repositories
    slackman repo add REPOSITORY-FILE    Add new repository file into F</etc/slackman/repod.d> directory
    slackman repo enable REPOSITORY      Enable repository
    slackman repo disable REPOSITORY     Disable repository
    slackman repo info REPOSITORY        Display repository information
    slackman repo help                   Display repo command help usage

# OPTIONS

    -h, --help                           Display help and exit
    --man                                Display man pages
    --version                            Display version information
    -c, --config=FILE                    Configuration file
    --color=[always|auto|never]          Colorize the output

# EXAMPLES

List all repositories:

    slackman repo list

    --------------------------------------------------------------------------------------
    Repository ID         Description                       Status     Priority   Packages
    --------------------------------------------------------------------------------------
    slackware:extra       Slackware64-current (Extra)       Enabled    0          92
    slackware:multilib    Slackware64-current (MultiLib)    Enabled    10         181
    slackware:packages    Slackware64-current               Enabled    0          1348
    slackware:pasture     Slackware64-current (Pasture)     Disabled   0          0
    slackware:patches     Slackware64-current (Patches)     Enabled    10         0
    slackware:testing     Slackware64-current (Testing)     Disabled   -1         0

Add new repository:

    slackman repo add http://slackware.com/pub/slackman/repos.d/slackware.repo

Enable a repository:

    slackman repo enable slackware:multilib

Display repository informations:

    slackman repo info slackware:extra

    Name:                Slackware64-current (Extra)
    ID:                  slackware:extra
    Configuration:       /etc/slackman/repos.d/slackware.repo
    Mirror:              http://mirrors.slackware.com/slackware/slackware64-current/
    Status:              enabled
    Last Update:         2017-05-24 07:03:49
    Priority:            0
    Packages:            92
    
    Repository URLs:
      * packages         http://mirrors.slackware.com/slackware/slackware64-current/extra/PACKAGES.TXT
      * manifest         http://mirrors.slackware.com/slackware/slackware64-current/extra/MANIFEST.bz2
      * checksums        http://mirrors.slackware.com/slackware/slackware64-current/extra/CHECKSUMS.md5
      * gpgkey           http://mirrors.slackware.com/slackware/slackware64-current/GPG-KEY

# FILES

- /etc/slackman/slackman.conf
- /etc/slackman/repos.d/\*

# SEE ALSO

[slackman(8)](../8/slackman.md), [slackman.conf(5)](../5/slackman.conf.md), [slackman.repo(5)](../5/slackman.repo.md), [slackman-update(8)](../8/slackman-update.md)

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
