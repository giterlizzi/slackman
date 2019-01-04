package Slackware::SlackMan::Command::Update;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.4.1';
  @ISA         = qw(Exporter);
  @EXPORT_OK   = qw();
  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Slackware::SlackMan;

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
  'update.history'   => \&call_update_pkgtools,
  'update.pkgtools'  => \&call_update_pkgtools,
  'update.manifest'  => \&call_update_repo_manifest,
  'update.packages'  => \&call_update_repo_packages,
  'update.test'      => \&_update_metadata,
};

use constant COMMANDS_MAN => {
  'update' => \&call_update_man
};

use constant COMMANDS_HELP => {
  'update' => \&call_update_help
};


sub call_update_man {

 pod2usage(
    -input   => __FILE__,
    -exitval => 0,
    -verbose => 2
  );

}

sub call_update_help {

  pod2usage(
    -input    => __FILE__,
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'OPTIONS' ]
  );

}


sub call_update_repo_packages {

  _update_metadata('Packages');
  _update_pkgtools();

  exit(0);

}


sub call_update_repo_gpg_key {

  _update_metadata('GPG-KEY');
  exit(0);

}


sub call_update_repo_changelog {

  _update_metadata('ChangeLog');
  exit(0);

}


sub call_update_repo_manifest {

  _update_metadata('Manifest');
  exit(0);

}


sub _update_pkgtools {

  STDOUT->printflush("Update pkgtools (installed, upgraded & removed packages) metadata: ");
  parse_history(\&callback_status);
  STDOUT->printflush(colored("done\n", 'green'));
  STDOUT->printflush("\n");

}


sub call_update_metadata {

  _update_metadata('Packages', 'ChangeLog');
  _update_pkgtools();

  exit(0);

}


sub call_update_pkgtools {

  _update_pkgtools();
  exit(0);

}


sub call_update_all_metadata {

  _update_metadata('Packages', 'ChangeLog', 'Manifest', 'GPG-KEY');
  _update_pkgtools();

  exit(0);

}


sub _update_packages {

  my ($repo_data) = @_;

  STDOUT->printflush(sprintf("  - %-15s", 'Packages'));
  parse_packages($repo_data, \&callback_status);
  STDOUT->printflush(colored("done\n", 'green'));

}


sub _update_changelog {

  my ($repo_data) = @_;

  STDOUT->printflush(sprintf("  - %-15s", 'ChangeLog'));
  parse_changelog($repo_data, \&callback_status);
  STDOUT->printflush(colored("done\n", 'green'));

}


sub _update_manifest {

  my ($repo_data) = @_;

  STDOUT->printflush(sprintf("  - %-15s", 'Manifest'));
  parse_manifest($repo_data, \&callback_status);
  STDOUT->printflush(colored("done\n", 'green'));

}


sub _update_gpg_key {

  my ($repo) = @_;

  STDOUT->printflush(sprintf("  - %-15s", 'GPG-KEY'));

  if (download_repository_metadata($repo, 'gpgkey')) {
    my $gpg_key_path = sprintf('%s/%s/GPG-KEY', $slackman_conf->{'directory'}->{'cache'}, $repo);
    gpg_import_key($gpg_key_path) if (-e $gpg_key_path);
  }

  STDOUT->printflush(colored("done\n", 'green'));

}


sub _update_metadata {

  my (@metadata) = @_;

  return 0 unless (@metadata);

  STDOUT->printflush("\nUpdate repository metadata (". commify_series(@metadata) ."):\n\n");

  my @repos       = get_enabled_repositories();
  my $repo_option = $slackman_opts->{'repo'};

  if ($slackman_opts->{'repo'} && grep(/^$repo_option$/, get_enabled_repositories)) {
    @repos = ( $slackman_opts->{'repo'} );
  }

  foreach my $repo (@repos) {

    if ($repo_option) {
      next unless ($repo =~ /^$repo_option/);
    }

    my $repo_data = get_repository($repo);

    STDOUT->printflush(colored("$repo\n", 'bold'));

    _update_packages($repo_data)   if (grep(/packages/i,  @metadata));
    _update_changelog($repo_data)  if (grep(/changelog/i, @metadata));
    _update_manifest($repo_data)   if (grep(/manifest/i,  @metadata));
    _update_gpg_key($repo)         if (grep(/gpg-key/i,   @metadata));

    STDOUT->printflush("\n");

  }

  # Notify update via D-Bus
  dbus_slackman->Notify( 'UpdatedPackages',  undef, undef )  if (grep(/packages/i,  @metadata));
  dbus_slackman->Notify( 'UpdatedChangeLog', undef, undef )  if (grep(/changelog/i, @metadata));
  dbus_slackman->Notify( 'UpdatedManifest',  undef, undef )  if (grep(/manifest/i,  @metadata));

  # Set last-metadata-update
  db_meta_set('last-metadata-update', time());

}


1;
__END__
=head1 NAME

slackman-update - Perform update of repository metadata

=head1 SYNOPSIS

  slackman update [--repo=REPOSITORY]
  slackman update packages  [--repo=REPOSITORY]
  slackman update changelog [--repo=REPOSITORY]
  slackman update manifest [--repo=REPOSITORY]
  slackman update gpg-key [--repo=REPOSITORY]
  slackman update all [--repo=REPOSITORY]

  slackman update pkgtools
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

  slackman update                      Update repository and local pkgtools (installed, upgraded & removed packages) metadata
  slackman update pkgtools             Update local pkgtools metadata (installed, upgraded & removed packages)
  slackman update packages             Update repository metadata (using PACKAGES.TXT file)
  slackman update changelog            Update repository ChangeLog (using ChangeLog.txt file)
  slackman update manifest             Update repository Manifest (using MANIFEST.bz2 file)
  slackman update gpg-key              Update repository GPG-KEY
  slackman update all                  Update all metadata (Packages, GPG-KEY, ChangeLog, etc.)
  slackman update help                 Display update command help usage

=head1 OPTIONS

  --repo=REPOSITORY                    Use specified repository during update
  -f, --force                          Force update
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

Copyright 2016-2018 Giuseppe Di Terlizzi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
