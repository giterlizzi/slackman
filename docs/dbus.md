# SlackMan D-Bus interface

## Service

SlackMan expose a system D-Bus service interface called  `org.lotarproject.SlackMan`
provided by `/usr/libexec/slackman/slackman-service` daemon.

## Methods, Signals & Properties

`org.lotarproject.SlackMan` D-Bus interface methods, signals and properties.

### Methods


##### org.lotarproject.SlackMan.ChangeLog

Return last ChangeLog entries from all Slackware Changelog repositories

    ARRAY of DICT<STRING,STRING> org.lotarproject.SlackMan.ChangeLog ( in STRING repo_id )

Argument   | Type   | Description
-----------|--------|------------
`repo_id`  | STRING | Repository ID


##### org.lotarproject.SlackMan.SecurityFix

Return last packages whit Security Fix from all Slackware Changelog repositories

    ARRAY of DICT<STRING,STRING> org.lotarproject.SlackMan.SecurityFix ( )


##### org.lotarproject.SlackMan.PackageInfo

Return a information of installed package

    ARRAY of DICT<STRING,STRING> org.lotarproject.SlackMan.PackageInfo ( in STRING package_name )


Argument       | Type   | Description
---------------|--------|------------
`package_name` | STRING | Package name ( eg. _mozilla-firefox_ )


##### org.lotarproject.SlackMan.CheckUpgrade

Return all available upgrades of installed packages

    ARRAY of DICT<STRING,STRING> org.lotarproject.SlackMan.CheckUpgrade ( )


##### org.lotarproject.SlackMan.Notify

Send a notification

    void org.lotarproject.SlackMan.Notify ( in STRING action,
                                            in STRING summary,
                                            in STRING body )

Argument | Type   | Description
---------|--------|------------
`action` | STRING | Action type
`summary`| STRING | Summary
`body`   | STRING | Body


##### org.lotarproject.SlackMan.GetRepository ( repo_id )

Return the repository information

    ARRAY of DICT<STRING,STRING> org.lotarproject.SlackMan.GetRepository ( in STRING repo_id )

Argument  | Type   | Description
----------|--------|------------
`repo_id` | STRING | Repository ID ( eg. _slackware:packages_ )


##### org.lotarproject.SlackMan.GetRepositories ( type )

Return a list of repositories

    ARRAY of DICT<STRING,STRING> org.lotarproject.SlackMan.GetRepositories ( in STRING type )

Argument | Type   | Description
---------|--------|------------
`type`   | STRING | Repository type ( _enabled_, _disabled_ )


##### org.lotarproject.SlackMan.GetPackages

Return a list of packages

    ARRAY of STRING org.lotarproject.SlackMan.GetPackages ( in STRING filter )

Argument | Type   | Description
---------|--------|------------
`filter` | STRING | Filter type  _( installed, removed, obsolete, orphan )_


##### org.lotarproject.SlackMan.InstallPkg

Install a package via PkgTool

    UINT32 org.lotarproject.SlackMan.InstallPkg ( in STRING package_path )

Argument       | Type   | Description
---------------|--------|------------
`package_path` | STRING | Package path


##### org.lotarproject.SlackMan.UpgradePkg

Upgrade a package via PkgTool

    UINT32 org.lotarproject.SlackMan.UpgradePkg ( in STRING package_path )

Argument       | Type   | Description
---------------|--------|------------
`package_path` | STRING | Package path


##### org.lotarproject.SlackMan.RemovePkg

Remove a package via PkgTool

    UINT32 org.lotarproject.SlackMan.RemovePkg ( in STRING package_name )

Argument       | Type   | Description
---------------|--------|------------
`package_name` | STRING | Package name ( eg. _aspell-it_ )


### Signals

##### org.lotarproject.SlackMan.PackageInstalled

This signal is emitted when a package is installed

    org.lotarproject.SlackMan.PackageInstalled ( STRING data )


##### org.lotarproject.SlackMan.PackageUpgraded

This signal is emitted when a package is upgraded

    org.lotarproject.SlackMan.PackageInstalled ( STRING data )


##### org.lotarproject.SlackMan.PackageRemoved

This signal is emitted when a package is removed

    org.lotarproject.SlackMan.PackageInstalled ( STRING data )


##### org.lotarproject.SlackMan.UpdatedChangeLog

This signal is emitted when run `slackman update` or `slackman update changelog` command

    org.lotarproject.SlackMan.UpdatedChangeLog ( STRING repo_id )


##### org.lotarproject.SlackMan.UpdatedPackages

This signal is emitted when run `slackman update` or `slackman update packages` command

    org.lotarproject.SlackMan.UpdatedPackages ( STRING repo_id )


##### org.lotarproject.SlackMan.UpdatedManifest

This signal is emitted when run `slackman update manifest` command

    org.lotarproject.SlackMan.UpdatedManifest ( STRING repo_id )


### Properties

##### org.lotarproject.SlackMan.version

Return SlackMan version

    STRING org.lotarproject.SlackMan.version

##### org.lotarproject.SlackMan.slackware

Return Slackware version ( eg, _14.2_, _current_ )

    STRING org.lotarproject.SlackMan.slackware


### IDL

    interface org.lotarproject.SlackMan {

      sequence< string > ChangeLog(string repo_id);
      sequence< string > SecurityFix();

      sequence< string > PackageInfo(string package_name);
      sequence< string > GetPackages(string type);
      sequence< string > CheckUpgrade();

      sequence< string > GetRepositories(string filter);
      sequence< string > GetRepository(string repo_id);

      void Notify (string action, string summary, string body);

      int32 InstallPkg(string package_path);
      int32 UpgradePkg(string package_path);
      int32 RemovePkg(string package_name);

      readonly attribute string slackware;
      readonly attribute string version;

      signal PackageInstalled(string data);
      signal PackageRemoved(string data);
      signal PackageUpgraded(string data);

      signal UpdatedChangeLog(string repo_id);
      signal UpdatedPackages(string repo_id);
      signal UpdatedManifest(string repo_id);

    };

## SlackMan Notifier

`slackman-notifier(1)` is user-space utility to receive a desktop notification via
D-Bus (using `org.freedesktop.Notification` service) for Slackware Security
Advisories, ChangeLogs and new packages upgrade.

  - Packages with Security Fix
  - Repositories ChangeLog updates
  - Installed packages upgrade
  - Installed, Upgraded and Removed package list from `slackman(8)` command

### SlackMan DBus service and SlackMan Notifier architecture

    +------------------------------+       +--------------+
    |   org.lotarproject.SlackMan  | ----> | D-Bus daemon | <-----------\
    |   ( D-Bus system service )   | <---- | (system bus) | -----------\ \
    +------------------------------+       +--------------+            | |
                  |                                                    | |
                  |                                                    | |
                  v                                                    | |
          +---------------+                                            | |
          |  SlackMan DB  |                                            | |
          +---------------+                                            | |
                                                                       v |
    +------------------------------+      +---------------+      +------------+
    | org.freedesktop.Notification | <--- | D-Bus daemon  | <--- |  SlackMan  |
    |  ( D-Bus session service )   |      | (session bus) |      |  Notifier  |
    +------------------------------+      +---------------+      +------------+

### Screenshots

**Slackware ChangeLogs**

![Slackware Security notification](images/dbus-notification-slackware-changelog.png)

**Slackware Security**

![Slackware Security notification](images/dbus-notification-slackware-security.png)

**Slackware Upgrade**

![Slackware Security notification](images/dbus-notification-slackware-upgrade.png)

**Slackware Installed Packages**

![Slackware Security notification](images/dbus-notification-installed-packages.png)

**Slackware Upgraded Packages**

![Slackware Security notification](images/dbus-notification-upgraded-packages.png)

**Slackware Removed Packages**

![Slackware Security notification](images/dbus-notification-removed-packages.png)
