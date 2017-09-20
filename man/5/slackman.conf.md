# NAME

**slackman.conf** - Configuration file for [slackman(8)](../8/slackman.md) Package Manager

# DESCRIPTION

The `slackman.conf` file contain the configurations for [slackman(8)](../8/slackman.md).

To get all options use `slackman config` command.

# \[main\] SECTION

**checkmd5** (default: `true`)

> Enable MD5 check for downloaded packages

**checkgpg** (default: `true`)

> Enable GPG check for downloaded packages 

**exclude** (default: ``)

> List of comma-separated packages to exclude for `slackman install` or `slackman upgrade` commands
>
> **Examples**
>
> If you want exclude kernels and all KDE l10n packages:
>
>     exclude=kernel-*,kde-l10n-*

**color** (default: `always`)

> Control output color.
>
> The possible values are:
>
>     always
>     auto
>     never

# \[logger\] SECTION

**level** (default: `info`)

> Default log level
>
> The possible values are:
>
>     debug
>     info
>     notice
>     warning
>     error
>     critical
>     alert
>     emergency

**file** (default: `/var/log/slackman.log`)

> Define SlackMan log file

**category** (default: `none`)

> Define additional SlackMan logger categories (useful for debugging)

# \[proxy\] SECTION

This section provide the proxy configuration for SlackMan.

**enable** (default: `false`)

> Enable a proxy

**protocol** (default: `http`)

> Proxy protocol type
>
> Supported protocols are:
>
>     http
>     https

**hostname**

> Proxy FQDN or IP address

**port** (default: `8080`)

> Proxy TCP port

**username** (default: ``)

> Proxy username

**password** (default: ``)

> Proxy password

# \[slackware\] SECTION

**version** (default: actual Slackware release)

> Force Slackware version. The default value is actual Slackware version in
> `/etc/slackware-release` file.
>
> **!!! ATTENTION !!!**
>
> Set `current` value "only" if you have a _-current_ Slackware release.

# \[directory\] SECTION

**cache** (default: `/var/cache/slackman`)

> Package Cache directory

**lib** (default: `/var/lib/slackman`)

> Lib directory for SlackMan database

**log** (default: `/var/log`)

> Log directory

**lock** (default: `/var/lock`)

> Lock directory

**root** (default: `/`)

> Root directory

# FILES

- /etc/slackman/slackman.conf
- /etc/slackman/repos.d/\*

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
