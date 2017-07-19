package Slackware::SlackMan::Command::Clean;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.1.0_09';
  @ISA         = qw(Exporter);
  @EXPORT_OK   = qw();
  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Slackware::SlackMan::Config;
use Slackware::SlackMan::DB    qw(:all);
use Slackware::SlackMan::Utils qw(:all);

use File::Path      qw(make_path remove_tree);
use Term::ANSIColor qw(color colored :constants);
use Pod::Usage;


use constant COMMANDS_DISPATCHER => {
  'help:clean'      => \&call_clean_help,
  'clean'           => \&call_clean_help,
  'clean:cache'     => \&call_clean_cache,
  'clean:db'        => \&call_clean_db,
  'clean:help'      => \&call_clean_help,
  'clean:manifest'  => \&call_clean_metadata_manifest,
  'clean:metadata'  => \&call_clean_metadata,
  'clean:all'       => \&call_clean_all,
};

sub call_clean_help {

  pod2usage(
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'COMMANDS/CLEAN COMMANDS' ]
  );

}

sub call_clean_all {

  call_clean_db();
  call_clean_cache();

  exit(0);

}

sub call_clean_db {

  my $lib_dir = $slackman_conf{'directory'}->{'lib'};
  my $db_file = "$lib_dir/db.sqlite";

  logger->debug(qq/Clear database file "$db_file"/);

  STDOUT->printflush("\nClear database... ");
  unlink($db_file) or warn("Unable to delete file: $!");
  STDOUT->printflush(colored("done\n", 'green'));

}

sub call_clean_cache {

  my $cache_dir = $slackman_conf{'directory'}->{'cache'};
  logger->debug(qq/Clear packages cache directory "$cache_dir"/);

  STDOUT->printflush("\nClean packages download cache... ");
  remove_tree($cache_dir, { keep_root => 1 });
  STDOUT->printflush(colored("done\n", 'green'));


}

sub call_clean_metadata {

  my ($table) = @_;

  STDOUT->printflush("\nClean database metadata... ");

  db_wipe_tables();

  db_reindex();
  db_compact();

  STDOUT->printflush(colored("done\n", 'green'));

}

1;
