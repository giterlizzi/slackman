# SlackMan Repository

## Supported Repository

SlackMan support different SlackWare repository including:

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
    mirror=https://example.org/slackware/


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
    gpgkey=$mirror/GPG-KEY

    # Packages file URL
    #
    packages=$mirror/PACKAGES.TXT

    # Filelist file URL
    #
    filelist=$mirror/FILELIST.TXT

    # Changelog file URL
    #
    changelog=$mirror/ChangeLog.txt

    # Manifest file URL
    #
    manifest=$mirror/MANIFEST.bz2

    # Checksums file URL
    #
    chechsums=$mirror/CHECHSUMS.md5
