# SlackMan D-Bus interface

## Service

SlackMan expose a system D-Bus service interface called  `org.lotarproject.SlackMan`
provided by `/usr/libexec/slackman/slackman-service` daemon.

## D-Bus interface (methods, signals & properties)

This section describe the `org.lotarproject.SlackMan` D-Bus interface (methods, signals and properties).

### IDL (Interface Definition Language)

    interface org.lotarproject.SlackMan {

      /** Methods */

      arrayOfString ChangeLog(string repo_id);
      arrayOfString SecurityFix();

      arrayOfString PackageInfo(string package_name);
      arrayOfString GetPackages(string type);
      arrayOfString CheckUpgrade();

      arrayOfString GetRepositories(string filter);
      arrayOfString GetRepository(string repo_id);

      void Notify (string action, string summary, string body);

      int32 InstallPkg(string package_path);
      int32 UpgradePkg(string package_path);
      int32 RemovePkg(string package_name);

      /** Properties */

      readonly attribute string slackware;
      readonly attribute string version;

      /** Signals */

      void PackageInstalled(string data);
      void PackageRemoved(string data);
      void PackageUpgraded(string data);

      void UpdatedChangeLog(string repo_id);
      void UpdatedPackages(string repo_id);
      void UpdatedManifest(string repo_id);

    };


### D-Bus XML interface

    <!DOCTYPE node PUBLIC "-//freedesktop//DTD D-BUS Object Introspection 1.0//EN"
    "http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd">
    <node name="/org/lotarproject/SlackMan">
      <interface name="org.freedesktop.DBus.Introspectable">
        <method name="Introspect">
          <arg type="s" direction="out"/>
        </method>
      </interface>
      <interface name="org.freedesktop.DBus.Properties">
        <method name="Get">
          <arg type="s" direction="in"/>
          <arg type="s" direction="in"/>
          <arg type="v" direction="out"/>
        </method>
        <method name="GetAll">
          <arg type="s" direction="in"/>
          <arg type="a{sv}" direction="out"/>
        </method>
        <method name="Set">
          <arg type="s" direction="in"/>
          <arg type="s" direction="in"/>
          <arg type="v" direction="in"/>
        </method>
      </interface>
      <interface name="org.lotarproject.SlackMan">
        <method name="ChangeLog">
          <arg name="repo_id" type="s" direction="in"/>
          <arg type="a{saa{ss}}" direction="out"/>
        </method>
        <method name="CheckUpgrade">
          <arg type="a{sa{ss}}" direction="out"/>
        </method>
        <method name="GetPackages">
          <arg name="filter" type="s" direction="in"/>
          <arg type="as" direction="out"/>
        </method>
        <method name="GetRepositories">
          <arg name="type" type="s" direction="in"/>
          <arg type="as" direction="out"/>
        </method>
        <method name="GetRepository">
          <arg name="repo_id" type="s" direction="in"/>
          <arg type="a{ss}" direction="out"/>
        </method>
        <method name="InstallPkg">
          <arg name="package_path" type="s" direction="in"/>
          <arg type="q" direction="out"/>
        </method>
        <method name="Notify">
          <arg name="action" type="s" direction="in"/>
          <arg name="summary" type="s" direction="in"/>
          <arg name="body" type="s" direction="in"/>
          <annotation name="org.freedesktop.DBus.Method.NoReply" value="true"/>
        </method>
        <method name="PackageInfo">
          <arg name="package_name" type="s" direction="in"/>
          <arg type="a{ss}" direction="out"/>
        </method>
        <method name="RemovePkg">
          <arg name="package_name" type="s" direction="in"/>
          <arg type="q" direction="out"/>
        </method>
        <method name="SecurityFix">
          <arg type="a{saa{ss}}" direction="out"/>
        </method>
        <method name="UpgradePkg">
          <arg name="package_path" type="s" direction="in"/>
          <arg type="q" direction="out"/>
        </method>
        <signal name="PackageInstalled">
          <arg type="s"/>
        </signal>
        <signal name="PackageRemoved">
          <arg type="s"/>
        </signal>
        <signal name="PackageUpgraded">
          <arg type="s"/>
        </signal>
        <signal name="UpdatedChangeLog">
          <arg type="s"/>
        </signal>
        <signal name="UpdatedManifest">
          <arg type="s"/>
        </signal>
        <signal name="UpdatedPackages">
          <arg type="s"/>
        </signal>
        <property name="slackware" type="s" access="read"/>
        <property name="version" type="s" access="read"/>
      </interface>
    </node>


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
