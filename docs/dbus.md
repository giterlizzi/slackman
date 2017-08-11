# SlackMan D-Bus interface

## Service

SlackMan expose a system D-Bus service called `org.lotarproject.SlackMan`
provided by `/usr/libexec/slackman/slackman-service` daemon.

## Methods

`org.lotarproject.SlackMan` D-Bus methods:

Method                                 | Description
---------------------------------------|----------------------------------------
`org.lotarproject.Changelog(void)`     | Return last ChangeLog entries from all Slackware Changelog repositories
`org.lotarproject.SecurityFix(void)`   | Return last packages whit Security Fix from all Slackware Changelog repositories
`org.lotarproject.PackageInfo(string)` | Return a information of installed package
`org.lotarproject.CheckUpgrade(void)`  | Return all available upgrades of installed packages

## SlackMan Notifier

`slackman-notifier(1)` is user-space utility to receive a desktop notification via
D-Bus (using `org.freedesktop.Notification` service) for Slackware Security
Advisories, ChangeLogs and new packages upgrade.

  - Packages with Security Fix
  - Repositories ChangeLog updates
  - Installed packages upgrade

### SlackMan DBus service and SlackMan Notifier architecture

    +------------------------------+       +--------------+
    |   org.lotarproject.SlackMan  | ----> | D-Bus daemon | <-----------\
    |   ( D-Bus system service )   | <---- | (system bus) | -----------\ \
    +------------------------------+       +--------------+            | |
                  |                                                    | |
                  |                                                    | |
                  v                                                    | |
           +--------------+                                            | |
           |  SlackMan DB |                                            | |
           +--------------+                                            | |
                                                                       v |
    +------------------------------+      +---------------+      +-------------+
    | org.freedesktop.Notification | <--- | D-Bus daemon  | <--- |  SlackMan   |
    |  ( D-Bus session service )   |      | (session bus) |      |   Notifier  |
    +------------------------------+      +---------------+      +-------------+
