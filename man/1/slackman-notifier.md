# slackman-notifier(1)
# NAME

slackman-notifier - SlackMan Notification Tool

# SYNOPSIS

    /usr/libexec/slackman/slackman-notifier [-d|--daemon] [-h|--help] [-v|--version]

# DESCRIPTION

**slackman-notifier** is user-space utility to receive a desktop notification via
D-Bus (using **org.freedesktop.Notification** service) for Slackware Security
Advisories, ChangeLogs, new packages upgrade and post-install/upgrade/remove summary.

# OPTIONS

    --action=[listner,notifier]  Execute in listner or notifier mode
    -h, --help                   Display help and exit
    --man                        Display man page
    --version                    Display version information

# SEE ALSO

[slackman(8)](../8/slackman.md), [slackman-service(1)](../1/slackman-service.md), [dbus-monitor(1)](../1/dbus-monitor.md)

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
