package Slackware::SlackMan::Command::DB;

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
    call_db_optimize
    call_db_info
  );
  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Slackware::SlackMan::DB    qw(:all);
use Slackware::SlackMan::Utils qw(:all);
use Term::ANSIColor qw(color colored :constants);

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

  my $db_path = get_conf('directory')->{lib} . '/db.sqlite';

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
