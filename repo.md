# SlackMan Repository

## Supported Repository

SlackMan support different Slackware repository including:

 - Slackware stable and **-current**
 - SlackOnly
 - Slackers (Conraid)
 - Slacky (Italian Slackware Community)
 - AlienBob (and **restricted** repository)
 - Robby Workman
 - ktown (KDE5)
 - Cinnamon SlackBuilds
 - MATE SlackBuilds
 - Salix
 - Microlinux
 - ... and more

For more information see [supported repositories](supported-repo.md) page.

## Add new repository

Copy your preferred repository in `/etc/slackman/repos.d` directory or use
`slackman repo add REPOSITORY-FILE` command:

    # slackman repo add /etc/slackman/repos.d/extra/slackonly.repo

## Enable a repository

To enable the repository edit `.repo` file and change `enable` flag from `false`
to `true` or use `slackman repo enable REPOSITORY` command.

## Create manually a new .repo file

You can create a new **.repo** file for all compatible Slackware repository.
Follow this easy steps:

 * Create new text file with **.repo** (eg. **custom.repo** ) extension into `/etc/slackman/repos.d` directory
 * Copy and paste the below text into new **.repo** file


    [packages]
    name=My personal repository
    enabled=true
    mirror=http://example.org/my-personal-repository


 * Update the repository metadata using `slackman update --repo custom:packages`
 * Enjoy!

**NOTE** SlackMan provide a sample repository file `/etc/slackman/repos.d/extra/repo.sample`.


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
    enabled=false


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
