# slackman-db(8)
# NAME

slackman-db - Display information and manage SlackMan database

# SYNOPSIS

    slackman db optimize
    slackman db info
    slackman db help

# DESCRIPTION

**slackman db** display and manage SlackMan database.

SlackMan store all informations (metadata, changelog, history, etc.) into a SQLite
database. The default location of database is `directory.lib/db.sqlite`.

To see the current location of `directory.lib` use [slackman-config(8)](../8/slackman-config.md) command:

    slackman config directory.lib

# COMMANDS

    slackman db optimize         Optimize SlackMan database
    slackman db info             Display information about SlackMan database

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

Copyright 2016-2018 Giuseppe Di Terlizzi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)
