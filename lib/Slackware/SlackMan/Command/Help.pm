package Slackware::SlackMan::Command::Help;

use strict;
use warnings;

no if ($] >= 5.018), 'warnings' => 'experimental';
use feature "switch";

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.1.0-beta3';
  @ISA         = qw(Exporter);
  @EXPORT_OK   = qw(
    call_clean_help
    call_db_help
    call_help
    call_list_help
    call_repo_help
    call_update_help
  );
  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}


use Pod::Usage;


sub call_help {

  print "SlackMan - Slackware Package Manager $VERSION\n\n";

  pod2usage(
  -exitval  => 0,
  -verbose  => 99,
  -sections => 'SYNOPSIS|COMMANDS|OPTIONS',
  );

}

sub call_list_help {

  pod2usage(
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'COMMANDS/LIST COMMANDS' ]
  );

}

sub call_clean_help {

  pod2usage(
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'COMMANDS/CLEAN COMMANDS' ]
  );

}

sub call_update_help {

  pod2usage(
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'COMMANDS/UPDATE COMMANDS' ]
  );

}

sub call_repo_help {

  pod2usage(
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'COMMANDS/REPOSITORY COMMANDS' ]
  );

}

sub call_db_help {

  pod2usage(
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'COMMANDS/DATABASE COMMANDS' ]
  );

}

1;
