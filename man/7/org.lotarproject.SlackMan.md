# org.lotarproject.SlackMan(7)
# NAME

**org.lotarproject.SlackMan** - D-Bus interface for [slackman(8)](../8/slackman.md) Package Manager

# DESCRIPTION

The SlackMan service is accessed through the D-Bus object at `/org/lotarproject/SlackMan` 
which provides the following interface.

# METHODS

## ChangeLog

ChangeLog ( in: 's' _repo\_id_, out 'a{saa{ss}}' )

## Announce

Announce ( in: 's' _repo\_id_, out 'a{saa{ss}}' )

## CheckUpgrade

CheckUpgrade ( out 'a{sa{ss}}' )

## SecurityFix

SecurityFix ( out 'a{saa{ss}}' )

## GetRepository

GetPackages ( in 's' _repo\_id_, out 'a{ss}' )

## GetRepositories

GetPackages ( in 's' _type_, out 'as' )

## GetPackages

GetPackages ( in 's' _filter_, out 'a{ss}' )

## PackageInfo

PackageInfo ( in 's' _package\_name_, out 'a{ss}' )

## InstallPkg

InstallPkg ( in 's' _package\_path_, out 'i' )

Install a package using [installpkg(8)](../8/installpkg.md) command and emit `PackageInstalled` signal.

## UpgradePkg

UpgradePkg ( in 's' _package\_path_, out 'i' )

Upgrade a package using [upgradepkg(8)](../8/upgradepkg.md) command and emit `PackageUpgraded` signal.

## RemovePkg

RemovePkg ( in 's' _package\_name_, out 'i' )

Remove a package using [removepkg(8)](../8/removepkg.md) command and emit `PackageRemoved` signal.

## Notify

Notify ( in 's' _action_, in 's' _summary_, in 's' _body_)

Send notification to [slackman-service(1)](../1/slackman-service.md)

# PROPERTIES

## version

version (out 's')

Return the SlackMan version

## slackware

slackware (out 's')

Return the Slackware version (eg. _14.2_ or _current_)

## isCurrent

isCurrent (out 'b')

Return _true_ if this is _Slackware-current_

# SIGNALS

## PackageInstalled

This signal is emitted when a package is installed.

## PackageUpgraded

This signal is emitted when a package is upgraded.

## PackageRemoved

This signal is emitted when a package is removed.

## UpdatedChangeLog

This signal is emitted when run `slackman update` or `slackman update changelog` command.

## UpdatedPackages

This signal is emitted when run `slackman update` or `slackman update packages` command.

## UpdatedManifest

This signal is emitted when run `slackman update manifest` command.

# SEE ALSO

[dbus-send(1)](../1/dbus-send.md), [dbus-monitor(1)](../1/dbus-monitor.md), [slackman(8)](../8/slackman.md), [slackman-service(1)](../1/slackman-service.md), [slackman-notifier(1)](../1/slackman-notifier.md)

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
