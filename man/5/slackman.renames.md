# slackman.renames(5)
# NAME

**slackman.renames** - Renamed or replaced Slackware pPackages configuration for [slackman(8)](../8/slackman.md) Package Manager 

# DESCRIPTION

The `slackman.renames` file contain the configurations for renamed or replaced Slackware packages.

# SYNTAX

> old-package-name = new-package-name

# EXAMPLES

> \# Python pip
>
> pip = python-pip
>
> \# Tetex was replaced with texlive in Slackware 15.0
>
> tetex = texlive

# FILES

- /etc/slackman/renames.d/\*

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
