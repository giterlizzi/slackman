# NAME

slackman-clean - Clean and control SlackMan cache

# SYNOPSIS

    slackman clean cache
    slackman clean metadata
    slackman clean db
    slackman clean all
    slackman clean help

# DESCRIPTION

**slackman clean** clean and control SlackMan cache.

# COMMANDS

    slackman clean cache       Clean cache package download directory
    slackman clean metadata    Clean database metadata (packages, changelog, manifest)
    slackman clean db          Clean database file
    slackman clean all         Clean database file and cache directory
    slackman clean help        Display clean command help usage

# OPTIONS

    -h, --help                   Display help and exit
    --man                        Display man pages
    --version                    Display version information
    -c, --config=FILE            Configuration file
    --color=[always|auto|never]  Colorize the output

# SEE ALSO

[slackman(8)](../8/slackman.md), [slackman.conf(5)](../5/slackman.conf.md)

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
