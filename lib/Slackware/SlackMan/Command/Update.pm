package Slackware::SlackMan::Command::Update;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.1.0_10';
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
use Pod::Find qw(pod_where);


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

use constant COMMANDS_MAN => {
  'update' => \&call_update_man
};

use constant COMMANDS_HELP => {
  'update' => \&call_update_help
};


sub call_update_man {

 pod2usage(
    -input   => pod_where({-inc => 1}, __PACKAGE__),
    -exitval => 0,
    -verbose => 2
  );

}

sub call_update_help {

  pod2usage(
    -input    => pod_where({-inc => 1}, __PACKAGE__),
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'OPTIONS' ]
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
__END__
=head1 NAME

slackman-update - Perform update of repository metadata

=head1 SYNOPSIS

  slackman update installed
  slackman update history

  slackman update [--repo=REPOSITORY]
  slackman update packages  [--repo=REPOSITORY]
  slackman update changelog [--repo=REPOSITORY]
  slackman update manifest [--repo=REPOSITORY]
  slackman update gpg-key [--repo=REPOSITORY]
  slackman update all [--repo=REPOSITORY]

  slackman update help

=head1 DESCRIPTION

B<slackman update> perform update of repository metadata. This is a standard
Slackware repository structure:

    ChangeLog.txt
    PACKAGES.TXT
    MANIFEST.bz2
    GPG-KEY
    CHECHSUMS.md5
    FILE_LIST

SlackMan store this files into a repository cache and into a database.

The default location of SlackMan cache is C<directory.cache>.

To see the current location of C<directory.cache> use L<slackman-config(8)> command:

    slackman config directory.cache

=head1 COMMANDS

  slackman update                      Update repository and local history packages metadata
  slackman update installed            Update local installed metadata
  slackman update history              Update local packages history metadata
  slackman update packages             Update repository metadata (using PACKAGES.TXT file)
  slackman update changelog            Update repository ChangeLog (using ChangeLog.txt)
  slackman update manifest             Update repository Manifest (using MANIFEST.bz2)
  slackman update gpg-key              Update repository GPG-KEY
  slackman update all                  Update all metadata (packages, gpg-key, changelog, etc.)
  slackman update help                 Display update command help usage

=head1 OPTIONS

  --repo=REPOSITORY                    Use specified repository during update
  -h, --help                           Display help and exit
  --man                                Display man pages
  --version                            Display version information
  -c, --config=FILE                    Configuration file
  --color=[always|auto|never]          Colorize the output

=head1 SEE ALSO

L<slackman(8)>, L<slackman-repo(8)>, L<slackman.conf(5)>, L<slackman.repo(5)>

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
