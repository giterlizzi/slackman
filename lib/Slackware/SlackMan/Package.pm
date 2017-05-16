package Slackware::SlackMan::Package;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.0.0';
  @ISA         = qw(Exporter);

  @EXPORT_OK   = qw{
    package_info
    package_version_compare
    package_install
    package_update
    package_remove
    package_metadata
    package_is_installed
    package_dependency
    package_available_update
    package_download
    package_list_installed
    package_list_obsolete
  };

  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Data::Dumper;
use File::Basename;
use File::Path qw(make_path remove_tree);
use Sort::Versions;

use Slackware::SlackMan::Utils qw(:all);
use Slackware::SlackMan::Repo qw(:all);
use Slackware::SlackMan::DB qw(:all);
use Slackware::SlackMan::Config qw(:all);


sub package_info {

  my $package_name = shift;

  # Add default extension
  $package_name .= '.tgz' unless ($package_name =~ /\.(txz|tgz|tbz|tlz)/);

  my $package_basename;
  my $package_version;
  my $package_build;
  my $package_tag;
  my $package_arch;
  my $package_type;

  my @package_name_parts    = split(/-/, $package_name);
  my $package_build_tag_ext = $package_name_parts[$#package_name_parts];
     $package_build_tag_ext =~ /^(\d+)(.*)\.(txz|tgz|tbz|tlz)/;

  $package_build   = $1;
  $package_tag     = $2;
  $package_type    = $3;

  $package_arch    = $package_name_parts[$#package_name_parts-1];
  $package_version = $package_name_parts[$#package_name_parts-2];

  for (my $i=0; $i<$#package_name_parts-2; $i++) {
    $package_basename .= $package_name_parts[$i] . '-';
  }

  $package_tag      =~ s/^_// if ($package_tag);
  $package_basename =~ s/-$// if ($package_basename);

  return {
    'name'    => $package_basename,
    'package' => $package_name,
    'version' => $package_version,
    'build'   => $package_build,
    'tag'     => $package_tag,
    'arch'    => $package_arch,
    'type'    => $package_type,
  }

}

sub package_metadata {

  my $metadata = shift;

  my $package_name        = '';
  my $package_category    = '';
  my $package_description = '';
  my $package_summary     = '';
  my $mirror              = '';
  my $location            = '';
  my $required            = undef;
  my $conflicts           = undef;
  my $suggests            = undef;
  my $size_compressed     = 0;
  my $size_uncompressed   = 0;
  my $file_list           = '';
  my @file_list           = ();

  foreach (split(/\n/, $metadata)) {
    $package_name      = $1 if ($_ =~ /^PACKAGE NAME:\s+(.*)/);
    $mirror            = $1 if ($_ =~ /^PACKAGE MIRROR:\s+(.*)/);
    $location          = $1 if ($_ =~ /^PACKAGE LOCATION:\s+(.*)/);
    $required          = $1 if ($_ =~ /^PACKAGE REQUIRED:\s+(.*)/);
    $conflicts         = $1 if ($_ =~ /^PACKAGE CONFLICTS:\s+(.*)/);
    $suggests          = $1 if ($_ =~ /^PACKAGE SUGGESTS:\s+(.*)/);
    $size_compressed   = $1 if ($_ =~ /^PACKAGE SIZE \(compressed\):\s+((.*)\s(K|M))/);
    $size_uncompressed = $1 if ($_ =~ /^PACKAGE SIZE \(uncompressed\):\s+((.*)\s(K|M))/);
    $size_compressed   = $1 if ($_ =~ /^COMPRESSED PACKAGE SIZE:\s+((.*)(K|M))/);
    $size_uncompressed = $1 if ($_ =~ /^UNCOMPRESSED PACKAGE SIZE:\s+((.*)(K|M))/);
  }

  if ($size_compressed =~ /M/) {
    $size_compressed =~ s/M//;
    $size_compressed = trim($size_compressed) * 1024;
  }

  if ($size_compressed =~ /K/) {
    $size_compressed =~ s/K//;
    $size_compressed = trim($size_compressed);
  }

  if ($size_uncompressed =~ /M/) {
    $size_uncompressed =~ s/M//;
    $size_uncompressed = trim($size_uncompressed) * 1024;
  }

  if ($size_uncompressed =~ /K/) {
    $size_uncompressed =~ s/K//;
    $size_uncompressed = trim($size_uncompressed);
  }

  {
    $metadata  =~ /^FILE LIST:\n(.*)/sm;
    $file_list = $1;
    @file_list = split(/\n/, $file_list) if ($file_list);
  }

  my $package_info     = package_info($package_name);
  my $package_basename = $package_info->{name};

  return unless $package_basename;

  # SlackBuilds categor*y
  {
    $location =~ /(academic|accessibility|audio|business|desktop|development|games|gis|graphics|ham|haskell|libraries|misc|multimedia|network|office|perl|python|ruby|system)/;

    $package_category = $1;
  }

  # Slackware standard series
  {
    $location =~ /(\/a|\/ap|\/d|\/e|\/f|\/k|\/kdei|\/kde|\/l|\/n|\/t|\/tcl|\/x|\/xap|\/xfce|\/y)$/;
    $package_category = $1;
    $package_category =~ s/\/// if ($package_category);
  }

  my $package_basename_quote = quotemeta($package_basename);

  $package_summary     = $1 if ($metadata =~ /$package_basename_quote: (.*)/);
  $package_description = join("\n", map { trim $_ } $metadata =~ /$package_basename_quote:(.*)\n/g);
  $package_description =~ s/^\s+|\s+$//g;


  return {
    'name'              => $package_info->{name},
    'package'           => $package_name,
    'version'           => $package_info->{version},
    'build'             => $package_info->{build},
    'tag'               => $package_info->{tag},
    'arch'              => $package_info->{arch},
    'category'          => $package_category,
    'summary'           => $package_summary,
    'description'       => $package_description,
    'mirror'            => $mirror,
    'location'          => $location,
    'required'          => $required,
    'conflicts'         => $conflicts,
    'suggests'          => $suggests,
    'size_compressed'   => $size_compressed,
    'size_uncompressed' => $size_uncompressed,
    'file_list'         => \@file_list
  };

}

sub package_version_compare {

  my ($old, $new) = @_;

  my $old_info = package_info($old);
  my $new_info = package_info($new);

  my $old_version  = $old_info->{version};
  my $new_version  = $new_info->{version};

  # FIX for MPlayer version (x.y_YYYYMMDD -> YYYYMMDD)
  if ($old_info->{name} eq 'MPlayer') {
    $old_version = $1 if ($old_version =~ /(\d{8})/);
    $new_version = $1 if ($new_version =~ /(\d{8})/);
  }

  $old_version .= '-' . $old_info->{build};
  $new_version .= '-' . $new_info->{build};

  return versioncmp($old_version, $new_version);

}

sub package_install {

  my $package = shift;

  logger->debug(qq/Install $package/);

  system('/sbin/installpkg', '--terse', $package);
  unlink($package) or warn "Failed to delete file: $!";

}

sub package_update {

  my $package = shift;

  logger->debug(qq/Upgrade $package/);

  system('/sbin/upgradepkg', '--reinstall', '--install-new', $package);
  unlink($package) or warn "Failed to delete file: $!";

}

sub package_remove {

  my $package = shift;

  logger->debug(qq/Remove $package/);
  system('/sbin/removepkg', $package);

}

sub package_is_installed {

  my $package = shift;
  my $row     = $dbh->selectrow_hashref('SELECT * FROM history WHERE name = ? AND status = "installed"', undef, $package);

  return $row;

}


sub package_dependency {

  my ($package, $repository) = @_;

  my $rows = $dbh->selectall_hashref('SELECT * FROM packages WHERE name = ? AND repository = ?', 'id', undef, $package, $repository);
  my @dependency = ();

  foreach (keys %$rows) {

    my $row      = $rows->{$_};
    my @required = ();
       @required = split(/\,/, $row->{required}) if ($row->{required});

    foreach my $pkg_required (@required) {
      push(@dependency, $pkg_required);
      push(@dependency, package_dependency($pkg_required, $repository));
    }
  }

  return @dependency;

}


sub package_available_update {

  my ($package_name) = @_;

  my $query = qq/SELECT packages.id,
                        packages.name,
                        packages.arch,
                        packages.required,
                        packages.package,
                        packages.package AS new_package,
                        history.package  AS old_package,
                        packages.version AS new_version,
                        history.version  AS old_version,
                        history.build    AS old_build,
                        packages.build   AS new_build,
                        packages.priority AS new_priority,
                        (SELECT p.priority FROM packages p WHERE p.name = history.name) AS old_priority,
                        packages.version || '-' || packages.build AS new_version_build,
                        history.version  || '-' || history.build  AS old_version_build,
                        packages.size_uncompressed,
                        packages.size_compressed,
                        packages.repository,
                        packages.mirror,
                        packages.location,
                        packages.checksum
                   FROM packages, history
                  WHERE history.status = "installed"
                    AND history.name   = packages.name
                    AND packages.arch  = history.arch
                    AND packages.name = ?
                    AND version_compare(old_version_build, new_version_build) < 0
                    AND packages.repository IN (%s)
                    AND packages.repository NOT IN (%s)
               ORDER BY packages.name, old_priority, new_priority/;

  my $enabled_repository  = '"' . join('", "', get_enabled_repositories())  . '"';
  my $disabled_repository = '"' . join('", "', get_disabled_repositories()) . '"';

  $query = sprintf($query, $enabled_repository, $disabled_repository);

  my $sth = $dbh->prepare($query);
  $sth->execute($package_name);

  my $row = $sth->fetchrow_hashref();

  return unless($row);
  return $row;

}

sub package_download {

  my ($pkg, $packages, $errors) = @_;

  my $package_url  = sprintf('%s/%s/%s', $pkg->{'mirror'}, $pkg->{'location'}, $pkg->{'package'});
  my $save_path    = sprintf('%s/%s/%s', $slackman_conf->{directory}->{'cache'}, $pkg->{'repository'}, $pkg->{'location'});
  my $package_path = sprintf('%s/%s', $save_path, $pkg->{'package'});

  make_path($save_path);

  unless (-e $package_path) {

    $package_url =~ s/\/\/\.//;
    print "$package_url\n";

    logger->info(sprintf("Starting download of %s package", $pkg->{'package'}));

    if (download_file($package_url, "$package_path.part")) {
      rename("$package_path.part", $package_path);
      logger->info(sprintf("Downloaded %s package", $pkg->{'package'}));
    } else {
      logger->error(sprintf("Error during download of %s package", $pkg->{'package'}));
      push(@$errors, $pkg->{'package'});
    }

  }

  unless (-e "$package_path.asc") {

    if (download_file("$package_url.asc", "$package_path.asc", "-s")) {
      logger->info(sprintf("Downloaded signature of %s package", $pkg->{'package'}));
    }

  }

  if (-e $package_path) {

    my $md5_check  = 0;
    my $gpg_verify = 0;

    unless ($slackman_conf->{main}->{'checkmd5'}) {
      $md5_check = 1;
    }

    unless ($slackman_conf->{main}->{'checkgpg'}) {
      $gpg_verify = 1;
    }

    if (md5_check($package_path, $pkg->{'checksum'})) {
      $md5_check = 1;
      logger->info(sprintf("MD5 checksum success for %s package", $pkg->{'package'}));
    } else {
      logger->error(sprintf("Error during MD5 checksum of %s package", $pkg->{'package'}));
    }

    if (gpg_verify($package_path)) {
      logger->info(sprintf("GPG signature verify success for %s package", $pkg->{'package'}));
      $gpg_verify = 1;
    } else {
      logger->error(sprintf("Error during GPG signature verify of %s package", $pkg->{'package'}));
    }

    if ($md5_check && $gpg_verify) {
      push(@$packages, $package_path);
    } else {
      unlink($package_path) or warn "Failed to remove file: $!";
      push(@$errors, $pkg->{'package'});
    }

  }

}

sub package_list_installed {
  return $dbh->selectall_hashref(qq/SELECT * FROM history WHERE status = 'installed' ORDER BY name/, 'name', undef);
}

sub package_list_obsolete {

  my $repo = shift;

  my $query = qq/SELECT DISTINCT(changelogs.name) AS changelog_name,
                        changelogs.repository     AS changelog_repository,
                        changelogs.version        AS changelog_version,
                        changelogs.timestamp      AS changelog_timestamp,
                        history.version           AS installed_version,
                        history.timestamp         AS installed_timestamp
                   FROM changelogs, history
                  WHERE changelogs.name   = history.name
                    AND changelogs.status = "removed"
                    AND history.status    = "installed"
                    AND %s
                    AND changelogs.repository NOT IN (%s)
                    AND EXISTS (SELECT 1
                                  FROM changelogs clog
                                 WHERE clog.name = changelogs.name
                                   AND changelogs.timestamp >= clog.timestamp)/;

  my $enabled_repository  = 'changelogs.repository IN (%s)"' . join('", "', get_enabled_repositories())  . '"';
  my $disabled_repository = '"' . join('", "', get_disabled_repositories()) . '"';

  $enabled_repository = sprintf('changelogs.repository LIKE "%s"', $repo) if ($repo);

  $query = sprintf($query, $enabled_repository, $disabled_repository);

  return $dbh->selectall_hashref($query, 'changelog_name', undef);

}


sub package_history {


}

1;
