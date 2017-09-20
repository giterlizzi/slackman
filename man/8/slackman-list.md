# slackman-list(8)
# NAME

slackman-list - List packages and other info

# SYNOPSIS

    slackman list packages [--repo=REPOSITORY]
    slackman list installed
    slackman list removed
    slackman list upgraded
    slackman list obsoletes
    slackman list orphan
    slackman list variables
    slackman list help

# DESCRIPTION

**slackman list** display information of:

    * installed packages
    * available packages
    * orphan packages
    * obsolete packages

# COMMANDS

    slackman list obsoletes      List obsolete packages
    slackman list installed      List installed packages
    slackman list packages       List available packages
    slackman list orphan         List orphan packages installed from unknown repository
    slackman list variables      List variables for ".repo" configurations

# OPTIONS

    --after=DATE                 Filter list after date
    --before=DATE                Filter list before date
    --repo=REPOSITORY            Use specified repository
    --exclude-installed          Exclude installed packages from list
    -h, --help                   Display help and exit
    --man                        Display man pages
    --version                    Display version information
    -c, --config=FILE            Configuration file
    --color=[always|auto|never]  Colorize the output

# SEE ALSO

[slackman(8)](../8/slackman.md), [slackman.repo(5)](../5/slackman.repo.md)

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
