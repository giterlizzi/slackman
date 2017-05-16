package Slackware::SlackMan::Repo;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.0.0';
  @ISA         = qw(Exporter);

  @EXPORT_OK   = qw{
    get_repositories
    get_repository
    get_enabled_repositories
    get_disabled_repositories
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
