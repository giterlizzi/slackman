package Slackware::SlackMan::Repo;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.0.2';
  @ISA         = qw(Exporter);

  @EXPORT_OK   = qw{
    get_repositories
    get_repository
    get_enabled_repositories
    get_disabled_repositories
    disable_repository
    enable_repository
  };

  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Data::Dumper;
use File::Basename;

use Slackware::SlackMan::Config qw(:all);
use Slackware::SlackMan::Utils  qw(:all);
use Slackware::SlackMan::Parser qw(:all);

my $repository = {};

my @files = grep { -f } glob(sprintf('%s/repos.d/*.repo', $slackman_conf->{directory}->{conf}));

foreach my $file (@files) {

  $file =~ /(.*)\.repo/;

  my $config_name = basename($1);
  my %repo_config = read_config($file);
  my @repos       = keys %repo_config;

  foreach my $repo (@repos) {

    my $repo_cfg = $repo_config{$repo};
    my $repo_id  = "$config_name:$repo";
    my $mirror   = $repo_cfg->{mirror};
       $mirror   =~ s/\/$//;

    $repo_cfg->{exclude} = parse_variables($repo_cfg->{exclude}) if ($repo_cfg->{exclude});

    # Set defaults
    $repo_cfg->{priority}  ||= 0;
    $repo_cfg->{enabled}   ||= 0;
    $repo_cfg->{packages}  ||= "$mirror/PACKAGES.TXT";
    $repo_cfg->{manifest}  ||= "$mirror/MANIFEST.bz2";
    $repo_cfg->{checksums} ||= "$mirror/CHECKSUMS.md5";
    $repo_cfg->{changelog} ||= "$mirror/ChangeLog.txt";
    $repo_cfg->{gpgkey}    ||= "$mirror/GPG-KEY";
    $repo_cfg->{filelist}  ||= "$mirror/FILELIST.TXT";
    $repo_cfg->{exclude}   ||= undef;

    my @keys_to_parse = qw( name mirror packages manifest checksums changelog
                            gpgkey filelist );

    foreach (@keys_to_parse) {
      $repo_cfg->{$_} = parse_variables($repo_cfg->{$_});
    }

    $repo_cfg->{priority} += 0;
    $repo_cfg->{id}        = $repo_id;

    $repository->{"$config_name:$repo"} = $repo_cfg;

  }

}

sub _write_repository_config {

  my ($repo_id, $key, $value) = @_;

  my ($repo_conf, $repo_section) = split(/:/, $repo_id);
  my $repo_file = sprintf('%s/repos.d/%s.repo', $slackman_conf->{directory}->{conf}, $repo_conf);

  unless (-f $repo_file) {
    warn qq/Repository configuration file ($repo_conf.repo) not found!\n/;
    exit(255);
  }

  unless ($repository->{$repo_id}) {
    warn qq/Repository "$repo_id" not found!\n/;
    exit(255);
  }

  file_write($repo_file, set_config(file_read($repo_file), "[$repo_section]", $key, $value));

}

sub disable_repository {

  my ($repo_id) = @_;

  _write_repository_config($repo_id, 'enabled', 'false');
  return 1;

}

sub enable_repository {

  my ($repo_id) = @_;

  _write_repository_config($repo_id, 'enabled', 'true');
  return 1;

}

sub get_repository_list {
  return $repository;
}

sub get_enabled_repositories {

  my @enabled      = ();
  my @repositories = get_repositories();

  foreach my $repo (@repositories) {
    push (@enabled, $repo) if ($repository->{$repo}->{enabled});
  }

  return @enabled;

}

sub get_disabled_repositories {

  my @enabled      = ();
  my @repositories = get_repositories();

  foreach my $repo (@repositories) {
    push (@enabled, $repo) unless ($repository->{$repo}->{enabled});
  }

  return @enabled;

}

sub get_repository {

  my $repo = shift;
  return $repository->{$repo};

}

sub get_repositories {

  my @repositories = ();

  foreach my $repo (sort keys %{$repository}) {
    push (@repositories, $repo);
  }

  return @repositories;

}


1;
__END__

=head1 NAME

Slackware::SlackMan::Repo - SlackMan Repo module

=head1 SYNOPSIS

  use Slackware::SlackMan::Repo qw(:all);

  my $repo_info = get_repository('slackware:packages');

=head1 DESCRIPTION

Repo module for SlackMan.

=head1 EXPORT

No subs are exported by default.

=head1 SUBROUTINES

=head2 get_disabled_repositories

=head2 get_enabled_repositories

=head2 get_repositories

=head2 get_repository

=head2 get_repository_list

=head1 AUTHOR

Giuseppe Di Terlizzi, C<< <giuseppe.diterlizzi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<giuseppe.diterlizzi at gmail.com>, or through
the web interface at L<https://github.com/LotarProject/slackman/issues>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

  perldoc Slackware::SlackMan::Repo

You can also look for information at:

=over 4

=item * GitHub issues (report bugs here)

L<https://github.com/LotarProject/slackman/issues>

=item * SlackMan documentation

L<https://github.com/LotarProject/slackman/wiki>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2017 Giuseppe Di Terlizzi.

This module is free software, you may distribute it under the same terms
as Perl.

=cut

