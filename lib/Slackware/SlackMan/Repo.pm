package Slackware::SlackMan::Repo;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.3.0';
  @ISA         = qw(Exporter);

  @EXPORT_OK   = qw{
    get_repositories
    get_repository
    get_enabled_repositories
    get_disabled_repositories
    disable_repository
    enable_repository
    download_repository_metadata
    update_repo_data
    update_all_repo_data
    load_repositories
    set_repository_value
    get_raw_repository_value
    get_raw_repository_values
    get_raw_repository_config
  };

  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use File::Basename;
use File::Path qw(make_path remove_tree);

use Slackware::SlackMan;
use Slackware::SlackMan::Config qw(:all);
use Slackware::SlackMan::Utils  qw(:all);
use Slackware::SlackMan::Parser qw(:all);
use Slackware::SlackMan::DB     qw(:all);

# Init repositories hash
my $repository = {};

# Load repositories data
load_repositories();

sub load_repositories {

  my @files = grep { -f } glob(sprintf('%s/*.repo', $slackman_conf->{'directory'}->{'repos'}));
  my $arch  = get_arch();

  foreach my $file (@files) {

    $file =~ /(.*)\.repo/;

    my $config_name = basename($1);
    my $config_data = get_config($file);
    my @repos       = keys %{$config_data};

    foreach my $repo (@repos) {

      # Skip main section "_"
      next if ($repo eq '_');

      my $repo_config = $config_data->{$repo};
      my $repo_id     = "$config_name:$repo";
      my $repo_arch   = {};
      my $mirror      = $repo_config->{'mirror'};
         $mirror      =~ s/\/$//;

      $repo_config->{'exclude'}     = parse_variables($repo_config->{'exclude'}) if ($repo_config->{'exclude'});
      $repo_config->{'config_file'} = $file;

      # Set defaults
      $repo_config->{'priority'} ||= 0;
      $repo_config->{'enabled'}  ||= 0;
      $repo_config->{'exclude'}  ||= undef;

      # Set repo arch support
      if (defined($repo_config->{'arch'})) {

        if (ref($repo_config->{'arch'}) ne 'ARRAY') {
          $repo_config->{'arch'} = [ $repo_config->{'arch'} ];
        }

        foreach (@{$repo_config->{'arch'}}) {

          my ($arch, $directory_prefix) = split(/:/, $_);
          my $enabled = 1;

          if ($arch =~ /^!/) {
            $enabled = 0;
            $arch =~ s/^!//;
          }

          $repo_arch->{$arch} = $enabled;
          $repo_arch->{$arch} = $directory_prefix  if ($directory_prefix);

        }

        $repo_config->{'arch'} = $repo_arch;

      } else {

        $repo_config->{'arch'} = {
          'x86'    => 1,
          'x86-64' => 1,
          'arm'    => 1,
        };

      }

      # Disable the repo if arch is not supported (eg. slackware:multilib on non x86_64 machine)
         if ($arch eq 'x86_64')        { $repo_config->{'enabled'} = 0 if (! $repo_config->{'arch'}->{'x86-64'}); }
      elsif ($arch =~ /x86|i[3456]86/) { $repo_config->{'enabled'} = 0 if (! $repo_config->{'arch'}->{'x86'});    }
      elsif ($arch =~ /arm(.*)/)       { $repo_config->{'enabled'} = 0 if (! $repo_config->{'arch'}->{'arm'});    }


      $repo_config->{'changelog'} = "$mirror/ChangeLog.txt"  unless(defined($repo_config->{'changelog'}));
      $repo_config->{'packages'}  = "$mirror/PACKAGES.TXT"   unless(defined($repo_config->{'packages'}));
      $repo_config->{'manifest'}  = "$mirror/MANIFEST.bz2"   unless(defined($repo_config->{'manifest'}));
      $repo_config->{'checksums'} = "$mirror/CHECKSUMS.md5"  unless(defined($repo_config->{'checksums'}));
      $repo_config->{'gpgkey'}    = "$mirror/GPG-KEY"        unless(defined($repo_config->{'gpgkey'}));
      $repo_config->{'filelist'}  = "$mirror/FILELIST.TXT"   unless(defined($repo_config->{'filelist'}));

      my @keys_to_parse = qw( name mirror packages manifest checksums changelog
                              gpgkey filelist );

      foreach (@keys_to_parse) {

        $repo_config->{$_} =~ s/(\{|\})//g;
        $repo_config->{$_} =~ s/\$mirror/$mirror/;

        # Replace repo arch in $arch variable
        if ($repo_config->{'arch'}->{'x86'} =~ /x86|i[3456]86/) {
          my $repo_arch = $repo_config->{'arch'}->{'x86'};
          $repo_config->{$_} =~ s/\$arch/$repo_arch/;
        }

        if ($repo_config->{'arch'}->{'arm'} =~ /arm(.*)/) {
          my $repo_arch = $repo_config->{'arch'}->{'arm'};
          $repo_config->{$_} =~ s/\$arch/$repo_arch/;
        }

      }

      foreach (@keys_to_parse) {
        $repo_config->{$_} = parse_variables($repo_config->{$_});
      }

      my $repo_cache_directory = $repo_id;
         $repo_cache_directory =~ s|\:|/|g;

      $repo_config->{'priority'}       += 0;
      $repo_config->{'id'}              = $repo_id;
      $repo_config->{'cache_directory'} = sprintf("%s/%s", $slackman_conf->{'directory'}->{'cache'}, $repo_cache_directory);

      $repository->{"$config_name:$repo"} = $repo_config;

    }

  }

}

sub set_repository_value {

  my ($repo_id, $key, $value) = @_;

  my ($repo_conf, $repo_section) = split(/:/, $repo_id);
  my $repo_file = sprintf('%s/repos.d/%s.repo', $slackman_conf->{'directory'}->{'conf'}, $repo_conf);

  unless (-f $repo_file) {
    warn qq/Repository configuration file ($repo_conf.repo) not found!\n/;
    exit(255);
  }

  unless ($repository->{$repo_id}) {
    warn qq/Repository "$repo_id" not found!\n/;
    exit(255);
  }

  logger->debug(qq{$repo_id - Set "$key" = "$value"});

  my $cfg = Slackware::SlackMan::Config->new($repo_file);
     $cfg->replaceAndSave("$repo_section.$key", $value);

}

sub get_raw_repository_config {

  my ($repo_conf) = @_;
  my $repo_file = sprintf('%s/%s.repo', $slackman_conf->{'directory'}->{'repos'}, $repo_conf);

  return get_config($repo_file);

}

sub get_raw_repository_values {

  my ($repo_id) = @_;
  my ($repo_conf, $repo_section) = split(/:/, $repo_id);

  my $repo_data = get_raw_repository_config($repo_conf);

  return $repo_data->{$repo_section};

}

sub get_raw_repository_value {

  my ($repo_id, $key) = @_;

  my $repo_data = get_raw_repository_values($repo_id);

  return $repo_data->{$key};

}

sub disable_repository {

  my ($repo_id) = @_;

  set_repository_value($repo_id, 'enabled', 'false');
  return 1;

}

sub enable_repository {

  my ($repo_id) = @_;

  set_repository_value($repo_id, 'enabled', 'true');
  return 1;

}

sub get_enabled_repositories {

  my @enabled      = ();
  my @repositories = get_repositories();

  foreach my $repo (@repositories) {
    push (@enabled, $repo) if ($repository->{$repo}->{'enabled'});
  }

  return @enabled;

}

sub get_disabled_repositories {

  my @enabled      = ();
  my @repositories = get_repositories();

  foreach my $repo (@repositories) {
    push (@enabled, $repo) unless ($repository->{$repo}->{'enabled'});
  }

  return @enabled;

}

sub get_repository {

  my ($repo) = @_;
  return $repository->{$repo} if (defined($repository->{$repo}));

}

sub get_repositories {

  my @repositories = ();

  foreach my $repo ( sort keys %{$repository} ) {
    push (@repositories, $repo);
  }

  return @repositories;

}

sub download_repository_metadata {

  my ($repo_id, $metadata, $callback_status) = @_;

  my $metadata_url  = $repository->{$repo_id}->{$metadata};
  my $metadata_file = sprintf("%s/%s", $repository->{$repo_id}->{cache_directory}, basename($metadata_url));

  unless($metadata_url) {
    logger->debug(sprintf('[REPO/%s] "%s" metadata disabled', $repo_id, $metadata));
    return (1);
  }

  unless ($metadata_url =~ /^(http(|s)|ftp|file)\:\/\//) {
    die(sprintf('Malformed "%s" URI for "%s" repository', $metadata, $repo_id));
  }

  logger->debug(sprintf('[REPO/%s] Check "%s" metadata last update', $repo_id, $metadata));

  my $metadata_last_modified = get_last_modified($metadata_url);
  my $db_meta_last_modified  = db_meta_get("last-update.$repo_id.$metadata") || 0;

  # Force update
  if ($slackman_opts->{'force'}) {
    logger->debug(sprintf('[REPO/%s] Force "%s" metadata last update', $repo_id, $metadata));
    $db_meta_last_modified = -1;
    unlink($metadata_file);
  }

  logger->debug(sprintf('[REPO/%s] "%s" metadata time (repo: %s - local: %s)',
    $repo_id, $metadata,
    time_to_timestamp($metadata_last_modified),
    time_to_timestamp($db_meta_last_modified)));

  if ($metadata_last_modified == 0) {
    logger->debug(sprintf('[REPO/%s] Problem during downloading of "Last-Modified" for "%s" metadata', $repo_id, $metadata));
    return (0);
  }

  if ($metadata_last_modified == $db_meta_last_modified) {
    logger->debug(sprintf('[REPO/%s] Skip "%s" metadata download', $repo_id, $metadata));
    return (0);
  }

  logger->debug(sprintf('[REPO/%s] Delete "%s" metadata file', $repo_id, $metadata));
  unlink($metadata_file);

  # Create repo cache directory if not exists
  make_path(dirname($metadata_file)) unless (-d dirname($metadata_file));

  unless ( -e $metadata_file) {

    &$callback_status(sprintf("%s %s", (($metadata_url =~ /^file/) ? 'linking' : 'downloading'), basename($metadata_file))) if ($callback_status);

    if ($metadata_url =~ /^file/) {

      my $local_file = $metadata_url;
         $local_file =~ s/file:\/\///;

      logger->debug(sprintf('[REPO/%s] Create link of %s metadata file', $repo_id, $metadata));
      symlink($local_file, $metadata_file);

    } else {
      logger->debug(sprintf('[REPO/%s] Download %s metadata file', $repo_id, $metadata));
      download_file($metadata_url, $metadata_file);
    }

  }

  db_meta_set("last-update.$repo_id.$metadata", $metadata_last_modified);

  return(1);

}

sub update_repo_data {

  my ($repo_id) = @_;

  my $repo_info     = get_repository($repo_id);
  my $repo_priority = $repo_info->{'priority'};
  my $repo_exclude  = $repo_info->{'exclude'};

  $dbh->do('UPDATE packages SET priority = ? WHERE repository = ?', undef, $repo_priority, $repo_id);
  $dbh->do('UPDATE packages SET excluded = 0 WHERE repository = ?', undef, $repo_id);

  if ($repo_exclude) {

    foreach my $package ( @{$repo_exclude} ) {

      logger->debug(sprintf("[%s] Set excluded flag for %s package", $repo_id, $package));
      $package =~ s/\*/\%/g;
      $dbh->do('UPDATE packages SET excluded = 1 WHERE repository = ? AND name LIKE ?', undef, $repo_id, $package);
      $package =~ s/\%/\*/g;

    }

  }

}

sub update_all_repo_data {

  foreach ( get_enabled_repositories() ) {
    update_repo_data($_);
  }

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

=head2 download_repository_metadata

=head2 update_repo_data

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

Copyright 2016-2018 Giuseppe Di Terlizzi.

This module is free software, you may distribute it under the same terms
as Perl.

=cut

