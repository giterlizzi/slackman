# SlackMan Repository

## Supported Repository

 - Slackware stable and **-current**
 - SlackOnly
 - Slackers (Conraid)
 - Slacky (Italian Slackware Community)
 - AlienBob (and **restricted** repository)
 - ktown (KDE5)
 - Cinnamon SlackBuilds
 - MATE SlackBuilds
 - Salix
 - Microlinux
 - ... and more

## Sample configuration

This is a sample .repo configuration

    [repository-id]

    # Short description of repository
    #
    name=My local repository


    # Enable or disable repository
    #   true  - enabled
    #   false - disabeld
    #
    enabled=true


    # Mirror URL
    #
    # This is the root of repository. slackman automatically detect all metadata
    # file URLs (GPG-KEY, PACKAGES.TXT, MANIFEST.bz2, etc).
    #
    # Support local (via "file" protocol) and remote url (http, https, ftp, etc.)
    #
    # Example:
    #
    #   Remote URL: https://example.org/slackware/
    #        Local: file:///srv/slackware/
    #
    mirror=http://example.org/slackware/


    # Priority (optional)
    #
    # Specify repository priority (default is 0 - "zero")
    #
    priority=1


    # Exclude packages (optional)
    #
    # Specify excluded packages for update or install (default "none")
    #
    exclude=kernel-*,kde-l10n-*,calligra-l10n-*


    # Override metadata URLs if the file is in another location

    # GPG-KEY file URL
    #
    gpgkey=http://example.org/slackware/GPG-KEY

    # Packages file URL
    #
    packages=http://example.org/slackware/PACKAGES.TXT

    # Filelist file URL
    #
    filelist=http://example.org/slackware/FILELIST.TXT

    # Changelog file URL
    #
    changelog=http://example.org/slackware/ChangeLog.txt

    # Manifest file URL
    #
    manifest=http://example.org/slackware/MANIFEST.bz2

    # Checksums file URL
    #
    chechsums=http://example.org/slackware/CHECHSUMS.md5
