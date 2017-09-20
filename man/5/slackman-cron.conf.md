# NAME

**slackman-cron.conf** - Configuration file for [slackman(8)](../8/slackman) Package Manager crontab utility

# DESCRIPTION

The `slackman-cron.conf` file contain the configurations for [slackman(8)](../8/slackman) cronta utility.

# OPTIONS

**SLACKMAN\_PARAMS** (default: ``)

> Set extra params for [slackman(8)](../8/slackman) command

**UPDATE\_METADATA** (default: `yes`)

> Update new packages and changelog metadata from the repositories

**UPDATE\_MANIFEST\_METADATA** (deefault: `no`)

> Update new manifest metadata from the repositories

**DOWNLOAD\_UPGRADED\_PACKAGES** (default: `no`)

> Download upgraded packages

# FILES

- /etc/slackman/slackman-cron.conf
- /etc/slackman/slackman.conf

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
