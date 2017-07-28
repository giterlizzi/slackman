package Slackware::SlackMan::Command::Update;

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

use Slackware::SlackMan;
use Slackware::SlackMan::Config;

use Slackware::SlackMan::DB     qw(:all);
use Slackware::SlackMan::Repo   qw(:all);
use Slackware::SlackMan::Utils  qw(:all);
use Slackware::SlackMan::Parser qw(:all);

use Term::ANSIColor qw(color colored :constants);
use Pod::Usage;


use constant COMMANDS_DISPATCHER => {
  'help.update'      => \&call_update_help,
  'update'           => \&call_update_metadata,
  'update.all'       => \&call_update_all_metadata,
  'update.changelog' => \&call_update_repo_changelog,
  'update.gpg-key'   => \&call_update_repo_gpg_key,
  'update.help'      => \&call_update_help,
  'update.history'   => \&call_update_history,
  'update.installed' => \&call_update_installed,
  'update.manifest'  => \&call_update_repo_manifest,
  'update.packages'  => \&call_update_repo_packages,
};


sub call_update_help {

  pod2usage(
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'COMMANDS/UPDATE COMMANDS' ]
  );

}

sub call_update_repo_packages {

  STDOUT->printflush("\nUpdate repository packages metadata:\n\n");

  my @repos       = get_enabled_repositories();
  my $repo_option = $slackman_opts->{'repo'};

  if ($slackman_opts->{'repo'} && grep(/^$repo_option$/, get_enabled_repositories)) {
    @repos = ( $slackman_opts->{'repo'} );
  }

  foreach my $repo (@repos) {

    logger->info(qq/Update "$repo" repository packages/);
    my $repo_data = get_repository($repo);

    STDOUT->printflush(sprintf("  * %-30s", $repo));
    parse_packages($repo_data, \&callback_status);
    STDOUT->printflush(colored("done\n", 'green'));

  }

  print "\n";

  # Set last-metadata-update
  db_meta_set('last-metadata-update', time());

}

sub call_update_repo_gpg_key {

  STDOUT->printflush("\nUpdate repository GPG key:\n\n");

  my @repos       = get_enabled_repositories();
  my $repo_option = $slackman_opts->{'repo'};

  if ($slackman_opts->{'repo'} && grep(/^$repo_option$/, get_enabled_repositories)) {
    @repos = ( $slackman_opts->{'repo'} );
  }

  foreach my $repo (@repos) {

    logger->info(qq/Update "$repo" repository GPG-KEY/);
    my $repo_data = get_repository($repo);

    STDOUT->printflush(sprintf("  * %-30s", $repo));

    my $gpg_key_path = sprintf('%s/%s/GPG-KEY', $slackman_conf{'directory'}->{'cache'}, $repo);

    if (download_repository_metadata($repo, 'gpgkey')) {
      gpg_import_key($gpg_key_path) if (-e $gpg_key_path);
    }

    STDOUT->printflush(colored("done\n", 'green'));

  }

  print "\n";

}

sub call_update_repo_changelog {

  STDOUT->printflush("\nUpdate repository ChangeLog:\n\n");

  my @repos       = get_enabled_repositories();
  my $repo_option = $slackman_opts->{'repo'};

  if ($slackman_opts->{'repo'} && grep(/^$repo_option$/, get_enabled_repositories)) {
    @repos = ( $slackman_opts->{'repo'} );
  }

  foreach my $repo (@repos) {

    logger->info(qq/Update "$repo" repository ChangeLog/);
    my $repo_data = get_repository($repo);

    STDOUT->printflush(sprintf("  * %-30s", $repo));
    parse_changelog($repo_data, \&callback_status);
    STDOUT->printflush(colored("done\n", 'green'));

  }

  print "\n";

}

sub call_update_repo_manifest {

  STDOUT->printflush("\nUpdate repository Manifest (very slow for big repository ... be patient):\n\n");

  my @repos       = get_enabled_repositories();
  my $repo_option = $slackman_opts->{'repo'};

  if ($slackman_opts->{'repo'} && grep(/^$repo_option$/, get_enabled_repositories)) {
    @repos = ( $slackman_opts->{'repo'} );
  }

  foreach my $repo (@repos) {

    my $repo_data = get_repository($repo);

    STDOUT->printflush(sprintf("  * %-30s", $repo));
    parse_manifest($repo_data, \&callback_status);
    STDOUT->printflush(colored("done\n", 'green'));

  }

  print "\n";

}

sub call_update_installed {

  STDOUT->printflush("\nUpdate installed packages metadata: ");
  parse_history('installed', \&callback_status);
  STDOUT->printflush(colored("done\n", 'green'));

}

sub call_update_history {

  STDOUT->printflush("\nUpdate history (upgraded & removed) packages metadata: ");
  parse_history('removed', \&callback_status);
  STDOUT->printflush(colored("done\n", 'green'));

}

sub call_update_metadata {

  call_update_repo_packages();
  call_update_repo_changelog();

  call_update_installed();
  call_update_history();

  print "\n";

  # Set last-metadata-update
  db_meta_set('last-metadata-update', time());

  exit(0);

}

sub call_update_all_metadata {

  call_update_repo_gpg_key();
  call_update_repo_packages();
  call_update_repo_changelog();
  call_update_repo_manifest();

  call_update_installed();
  call_update_history();

  print "\n";

  # Set last-metadata-update
  db_meta_set('last-metadata-update', time());

  exit(0);

}

1;
