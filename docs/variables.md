# SlackMan variables

A short description of all variables for SlackMan repositories configuration.


Variable         | Description
-----------------|--------------------------------------------------------------
`arch`           | Machine architeture (eg. x86_64, i686)
`arch.bit`       | Machine bit architeture (eg. 64, 32)
`arch.family`    | Machine architeture family (eg. x86_64, x86)
`release`        | Slackware version from `/etc/slackware-release` (eg. 14.2) or current (follow `slackware.version` option in `slackman.conf` file)
`release.real`   | Slackware "real" release version from  `/etc/slackware-release` file (eg. 14.2)
`release.suffix` | Slackware release suffix (eg. 64 - for Slackware64,  arm - for Slackwarearm)

# Display variables value from slackman

    # slackman list variables

    Variable             Value
    ----------------------------------------
    arch                 x86_64
    arch.bit             64
    arch.family          x86_64
    release              current
    release.real         14.2
    release.suffix       64

## Examples

Slackware-14.2
--------------

    name=Slackware{$release.suffix}-{$release} repository
    mirror=http://example.org/slackware{$release.suffix}-{$release}/

      release.suffix => 64
      release        => current

    name=Slackware64-14.2
    mirror=http://example.org/slackware64-14.2
