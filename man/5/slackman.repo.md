# slackman.repo(5)
# NAME

**slackman.repo** - Configuration file for slackman repository

# DESCRIPTION

SlackMan support official and 3th party Slackware repository. All repository
configuration are placed into `/etc/slackman/repos.d/` directory.

# REPO FILE

A single `.repo` file support multiple repositories (see `/etc/slackman/repos.d/slackware.repo`
file) identified with a specific section:

    # Local repository
    [local]
    [...]

    # Testing repository
    [testing]
    [...]

**NOTE** SlackMan identify a repository from `.repo` filename + repository section
(eg. `slackware:packages`, `alienbob:restricted`, etc)

## OPTIONS

**name**

> Short description of repository
>
> **Example**
>
>     name=My local repository

**enabled**

> Enable or disable repository
>
> **Example**
>
>     enabled=true

**mirror**

> Mirror URL
>
> This is the root of repository. slackman automatically detect all metadata
> file URLs (`GPG-KEY`, `PACKAGES.TXT`, `MANIFEST.bz2`, etc).
>
> Support local (via "file" protocol) and remote url (http, https, ftp, etc.)
>
> **Example**
>
>     mirror=http://example.org/slackware/

**priority**

> Priority (optional) 
>
> Specify repository priority (default is `0` - "zero")
>
> **Example**
>
>     priority=1

**exclude**

> Exclude packages (optional)
>
> Specify excluded packages for update or install (default ``)
>
> **Example**
>
>     exclude=kernel-*,kde-l10n-*,calligra-l10n-*

## OPTIONS TO OVERRIDE METADATA URLs

SlackMan detect automatically all metadata URLs from `mirror` option but some
repository require a little extra configuration to point at the correct metadata URLs.

**NOTE** With this options you can use `$mirror` variable.

**gpgkey**

> GPG-KEY file URL
>
> **Example**
>
>     gpgkey=http://example.org/slackware/GPG-KEY

**packages**

> Packages file URL
>
> **Example**
>
>     packages=http://example.org/slackware/PACKAGES.TXT

**filelist**

> Filelist file URL
>
> **Example**
>
>     filelist=http://example.org/slackware/FILELIST.TXT

**changelog**

> Changelog file URL
>
> **Example**
>
>     changelog=http://example.org/slackware/ChangeLog.txt

**manifest**

> Manifest file URL
>
> **Example**
>
>     manifest=http://example.org/slackware/MANIFEST.bz2

**checksums**

> Checksums file URL
>
> **Example**
>
>     chechsums=http://example.org/slackware/CHECHSUMS.md5

## VARIABLES

SlackMan support special variables for extend the configuration of `.repo` file:

For display all variable values use `slackman list variables` command:

    # slackman list variables

    Variable             Value
    ----------------------------------------
    arch                 x86_64
    arch.bit             64
    arch.family          x86_64
    release              current
    release.real         14.2
    release.suffix       64

`arch`

> Machine architecture (eg. `x86_64`, `i686`)

`arch.bit`

> Machine bit architecture (eg. `64`, `32`)

`arch.family`

> Machine architecture family (eg. `x86_64`, `x86`)

`mirror`

> Mirror URL from `mirror` config option (see above)

`release`

> Slackware version from `/etc/slackware-release` (eg. `14.2`) or `current`
> (this variable follow the _slackware.version_ option in [slackman.conf(5)](../5/slackman.conf.md) file)

`release.real`

> Slackware "real" release version from  `/etc/slackware-release` file (eg. `14.2`)

`release.suffix`

> Slackware release suffix (eg. `64` - for Slackware64,  `arm` - for Slackwarearm)

### EXAMPLES

**Slackware-14.2 (32-bit)**

    name=Slackware{$release.suffix}-{$release.real} repository
    mirror=http://example.org/slackware{$release.suffix}-{$release.real}/

      release.suffix => 
      release.real   => 14.2

    name=Slackware64-14.2
    mirror=http://example.org/slackware-14.2

**Slackware64-current (64-bit)**

    name=Slackware{$release.suffix}-{$release} repository
    mirror=http://example.org/slackware{$release.suffix}-{$release}/

      release.suffix => 64
      release        => current

    name=Slackware64-current
    mirror=http://example.org/slackware64-current

# DISPLAY REPOSITORY CONFIGURATION

To display repository configuration you can use `slackman repo list` and
`slackman repo info REPOSITORY` commands:

    # slackman repo list

    --------------------------------------------------------------------------------------
    Repository ID         Description                       Status     Priority   Packages
    --------------------------------------------------------------------------------------
    slackware:extra       Slackware64-current (Extra)       Enabled    0          92
    slackware:multilib    Slackware64-current (MultiLib)    Enabled    10         181
    slackware:packages    Slackware64-current               Enabled    0          1348
    slackware:pasture     Slackware64-current (Pasture)     Disabled   0          0
    slackware:patches     Slackware64-current (Patches)     Enabled    10         0
    slackware:testing     Slackware64-current (Testing)     Disabled   -1         0


    # slackman repo info slackware:extra

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
