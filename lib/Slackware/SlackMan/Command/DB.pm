package Slackware::SlackMan::Command::DB;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.2.1';
  @ISA         = qw(Exporter);
  @EXPORT_OK   = qw();
  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Slackware::SlackMan;
use Slackware::SlackMan::DB    qw(:all);
use Slackware::SlackMan::Utils qw(:all);

use Term::ANSIColor qw(color colored :constants);
use Pod::Usage;


use constant COMMANDS_DISPATCHER => {
  'help.db'     => \&call_db_help,
  'db'          => \&call_db_help,
  'db.help'     => \&call_db_help,
  'db.info'     => \&call_db_info,
  'db.optimize' => \&call_db_optimize,
};

use constant COMMANDS_MAN => {
  'db' => \&call_db_man
};

use constant COMMANDS_HELP => {
  'db' => \&call_db_help
};

sub call_db_man {

 pod2usage(
    -input   => __FILE__,
    -exitval => 0,
    -verbose => 2
  );

}

sub call_db_help {

  pod2usage(
    -input    => __FILE__,
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'OPTIONS' ]
  );

}

sub call_db_optimize {

  STDOUT->printflush("Reindex tables...");
  db_reindex();
  STDOUT->printflush(colored("\tdone\n", 'green'));

  STDOUT->printflush("Compact database...");
  db_compact();
  STDOUT->printflush(colored("\tdone\n", 'green'));

  exit(0);

}

sub call_db_info {

  my $db_path = $slackman_conf->{'directory'}->{'lib'} . '/db.sqlite';

  my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,
      $atime, $mtime, $ctime, $blksize, $blocks) = stat($db_path);

  print sprintf("%-20s %s\n",     'Path:', $db_path);
  print sprintf("%-20s %.1f M\n", 'Size:', ($size/1024/1024));

  my $user_version = ($dbh->selectrow_arrayref('PRAGMA user_version', undef))->[0];
  print sprintf("%-20s %s\n", 'Schema Version:', $user_version);

  my $quick_check  = ($dbh->selectrow_arrayref('PRAGMA quick_check', undef))->[0];
  print sprintf("%-20s %s\n", 'Quick check:', uc($quick_check));

  my $integrity_check = ($dbh->selectrow_arrayref('PRAGMA integrity_check', undef))->[0];
  print sprintf("%-20s %s\n", 'Integrity check:', uc($integrity_check));

}

1;
__END__
=head1 NAME

slackman-db - Display information and manage SlackMan database

=head1 SYNOPSIS

  slackman db optimize
  slackman db info
  slackman db help

=head1 DESCRIPTION

B<slackman db> display and manage SlackMan database.

SlackMan store all informations (metadata, changelog, history, etc.) into a SQLite
database. The default location of database is C<directory.lib/db.sqlite>.

To see the current location of C<directory.lib> use L<slackman-config(8)> command:

    slackman config directory.lib

=head1 COMMANDS

  slackman db optimize         Optimize SlackMan database
  slackman db info             Display information about SlackMan database

=head1 OPTIONS

  -h, --help                   Display help and exit
  --man                        Display man pages
  --version                    Display version information
  -c, --config=FILE            Configuration file
  --color=[always|auto|never]  Colorize the output

=head1 SEE ALSO

L<slackman(8)>, L<slackman.conf(5)>

=head1 BUGS

Please report any bugs or feature requests to 
L<https://github.com/LotarProject/slackman/issues> page.

=head1 AUTHOR

Giuseppe Di Terlizzi <giuseppe.diterlizzi@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2016-2017 Giuseppe Di Terlizzi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
