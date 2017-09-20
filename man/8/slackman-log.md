# NAME

slackman-log - Display SlackMan log

# SYNOPSIS

    slackman log clean
    slackman log tail
    slackman log help

# DESCRIPTION

**slackman config** get and set SlackMan configuration in [slackman.conf(5)](../5/slackman.conf) file.

The default location of SlackMan log is `directory.log/slackman.log`.

To see the current location of `directory.log` use [slackman-config(8)](../8/slackman-config) command:

    slackman config directory.log

# COMMANDS

    slackman log clean         Clean log file
    slackman log tail          Display log file in real time

# OPTIONS

    -h, --help                 Display help and exit
    --man                      Display man pages
    --version                  Display version information
    -c, --config=FILE          Configuration file

# SEE ALSO

[slackman(8)](../8/slackman), [slackman.conf(5)](../5/slackman.conf)

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
