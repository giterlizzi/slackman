package Slackware::SlackMan::Package;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION = 'v1.1.0_08';
  @ISA     = qw(Exporter);

  @EXPORT_OK = qw{
    package_info
    package_version_compare
    package_install
    package_upgrade
    package_remove
    package_metadata
    package_is_installed
    package_dependency
    package_available_update
    package_download
    package_list_installed
    package_list_obsoletes
    package_changelogs
    package_check_updates
    package_check_install
    package_search_files
  };

  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use File::Basename;
use File::Path qw(make_path remove_tree);
use Sort::Versions;
use Term::ANSIColor qw(color colored :constants);

use Slackware::SlackMan;
use Slackware::SlackMan::Config;

use Slackware::SlackMan::Utils  qw(:all);
use Slackware::SlackMan::Repo   qw(:all);
use Slackware::SlackMan::DB     qw(:all);
use Slackware::SlackMan::Parser qw(:all);


sub package_changelogs {

  my ($package) = @_;

  my $option_repo   = $slackman_opts->{'repo'};
  my @repositories  = get_enabled_repositories();
  my @query_filters = ();

  # Get only machine arch and "noarch" changelogs
  my $arch = get_arch();

     if ($arch eq 'x86_64')        { push(@query_filters, '(arch IN ("x86_64", "noarch") OR arch IS NULL)') }
  elsif ($arch =~ /x86|i[3456]86/) { push(@query_filters, '(arch = "noarch" OR arch = "x86" OR arch LIKE "i%86" OR arch IS NULL)') }
  elsif ($arch =~ /arm(.*)/)       { push(@query_filters, '(arch = "noarch" OR arch LIKE "arm%" OR arch IS NULL)')}

  # Filter repository
  if ($option_repo) {
    $option_repo .= ":%" unless ($option_repo =~ m/\:/);
    push(@query_filters, qq/repository LIKE "$option_repo"/);
  } else {
    push(@query_filters, 'repository IN ("' . join('", "', get_enabled_repositories()) . '")');
  }

  # Filter disabled repository
  push(@query_filters, sprintf('repository NOT IN ("%s")', join('","', get_disabled_repositories())));

  # Filter specified package name
  if ($package) {
    $package =~ s/\*/%/g;
    push(@query_filters, sprintf('name LIKE %s', $dbh->quote($package)));
  }

  if (my $timestamp_options = parse_timestamp_options_to_sql()) {
    push(@query_filters, $timestamp_options);
  }

  if ($slackman_opts->{'security-fix'}) {
    push(@query_filters, 'security_fix = 1');
  }

  my $query = 'SELECT * FROM changelogs WHERE %s ORDER BY timestamp DESC LIMIT %s';
     $query = sprintf($query, join(' AND ', @query_filters), $slackman_opts->{'limit'});

  my $sth = $dbh->prepare($query);
  $sth->execute();

  return $sth->fetchall_arrayref({});

}

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

  return undef unless($package_basename);

  # SlackBuilds category
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

  system('/sbin/upgradepkg', '--install-new', $package);
  unlink($package) or warn "Failed to delete file $package: $!";

  my $pkg_info = package_info(basename($package));

  logger->info(sprintf("Installed %s package with %s version",
    $pkg_info->{'name'}, $pkg_info->{'version'}));

}


sub package_upgrade {

  my $package = shift;

  logger->debug(qq/Upgrade $package/);

  system('/sbin/upgradepkg', '--reinstall', '--install-new', $package);
  unlink($package) or warn "Failed to delete file: $!";

  my $pkg_info = package_info(basename($package));

  logger->info(sprintf("Upgraded %s package to %s version",
    $pkg_info->{'name'}, $pkg_info->{'version'}));

}


sub package_remove {

  my $package = shift;

  logger->debug(qq/Remove $package/);
  system('/sbin/removepkg', $package);

}


sub package_is_installed {

  my ($package) = @_;

  $package = parse_module_name($package);

  my $row = $dbh->selectrow_hashref('SELECT * FROM history WHERE name = ? AND status = "installed"', undef, $package);

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

  return undef unless($row);
  return $row;

}


sub package_check_install {

  my (@install_packages) = @_;

  my $install_pkgs          = {};
  my $dependency_pkgs       = {};
  my $arch                  = get_arch();
  my $option_repo           = $slackman_opts->{'repo'};
  my $option_exclude        = $slackman_opts->{'exclude'};
  my @repositories          = get_enabled_repositories();
  my @query_filters         = ();
  my @filter_repository     = ();

  @repositories = qq\$option_repo\ if ($option_repo); # TODO verificare se repository è disabilitato

  foreach my $repository (@repositories) {
    $repository .= ":%" unless ($repository =~ m/\:/);
    push(@filter_repository, sprintf('packages.repository LIKE %s', $dbh->quote($repository)));
  }

  @install_packages = map { parse_module_name($_) } @install_packages if (@install_packages);

  if (@install_packages) {

    my $packages_filter = '';
    my @packages_in     = ();
    my @packages_like   = ();

    foreach my $pkg (@install_packages) {
      if ($pkg =~ /\*/) {
        $pkg =~ s/\*/%/g;
        push(@packages_like, qq/packages.name LIKE "$pkg"/);
      } else {
        push(@packages_in, $pkg);
      }
    }

    $packages_filter .= '(';
    $packages_filter .= sprintf('packages.name IN ("%s")', join('","', @packages_in)) if (@packages_in);
    $packages_filter .= ' OR '                                                        if (@packages_in && @packages_like);
    $packages_filter .= sprintf('(%s)', join(' OR ', @packages_like))                 if (@packages_like);
    $packages_filter .= ')';

    push(@query_filters, $packages_filter);

  }

  push(@query_filters, '( ' . join(' OR ', @filter_repository) . ' )');

  if ($option_exclude) {
    $option_exclude =~ s/\*/%/g;
    push(@query_filters, sprintf('packages.name NOT LIKE %s', $dbh->quote($option_exclude)));
  }

  foreach my $repository (get_disabled_repositories()) {
    push(@query_filters, sprintf('( packages.repository != %s )', $dbh->quote($repository)));
  }

  push(@query_filters, 'packages.excluded = 0') unless ($slackman_opts->{'no-excludes'});

  my $query_packages = qq/SELECT *
                            FROM packages
                           WHERE name NOT IN (SELECT name
                                                FROM history
                                               WHERE status = "installed")
                             AND %s
                        ORDER BY name/;

  my $query_new_packages = qq/SELECT DISTINCT(packages.name), packages.*
                                FROM packages, changelogs
                               WHERE packages.repository = changelogs.repository
                                 AND packages.name = changelogs.name
                                 AND changelogs.status = 'added'
                                 AND %s
                                 AND packages.name NOT IN (SELECT history.name
                                                             FROM history
                                                            WHERE history.status = "installed")
                            ORDER BY name/;

  my $dependency_query = qq/SELECT package,
                                   name,
                                   arch,
                                   MAX(version) AS version,
                                   repository,
                                   size_uncompressed,
                                   size_compressed,
                                   location,
                                   mirror,
                                   checksum
                              FROM packages
                             WHERE name = ?
                               AND repository = ?
                               AND arch IN (?, "noarch")/;

  $query_packages = $query_new_packages if ($slackman_opts->{'new-packages'});
  $query_packages = sprintf($query_packages, join(' AND ', @query_filters));

  my $sth_packages = $dbh->prepare($query_packages);
     $sth_packages->execute();

  while (my $row = $sth_packages->fetchrow_hashref()) {

    $install_pkgs->{$row->{name}} = $row;

    # Skip dependency check
    next if ($slackman_opts->{'no-deps'});

    foreach my $pkg_required (package_dependency($row->{'name'}, $row->{'repository'})) {

      my $dependency_row = $dbh->selectrow_hashref($dependency_query, undef, $pkg_required, $row->{'repository'}, $arch);

      next unless ($dependency_row->{'name'});

      unless (package_is_installed($pkg_required)) {

        $dependency_pkgs->{$pkg_required} = $dependency_row;
        push(@{$dependency_pkgs->{$pkg_required}->{'needed_by'}}, $row->{'name'});

      }

    }

  }

  return ($install_pkgs, $dependency_pkgs);

}


sub package_check_updates {

  my (@update_packages) = @_;

  my $updatable_packages_query = qq/
    SELECT packages.name,
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
     WHERE history.name   = packages.name
       AND history.status = "installed"
       AND old_version_build != new_version_build
       AND version_compare(old_version_build, new_version_build) < 0
       AND (%s)/;

  my $dependency_query = qq/
    SELECT package,
           package AS new_package,
           name,
           arch,
           MAX(version) AS version,
           repository,
           size_uncompressed,
           location,
           mirror,
           checksum
      FROM packages
     WHERE name = ?
       AND arch IN (?, "noarch")
       AND repository IN (?)/;

  my $arch           = get_arch();
  my @query_filters  = ();
  my $update_pkgs    = {};  # Updatable packages
  my $install_pkgs   = {};  # Required packages to install
  my $option_repo    = $slackman_opts->{'repo'};
  my $option_exclude = $slackman_opts->{'exclude'};

  if ($option_exclude) {
    $option_exclude =~ s/\*/%/g;
    push(@query_filters, qq/packages.name NOT LIKE "$option_exclude"/);
  }

  if ($option_repo) {
    $option_repo .= ":%" unless ($option_repo =~ m/\:/);
    push(@query_filters, qq/packages.repository LIKE "$option_repo"/);
  } else {
    push(@query_filters, 'packages.repository IN ("' . join('", "', get_enabled_repositories()) . '")');
  }

  push(@query_filters, 'packages.excluded = 0') unless ($slackman_opts->{'no-excludes'});
  push(@query_filters, 'packages.repository NOT IN ("' . join('", "', get_disabled_repositories()) . '")');

  @update_packages = map { parse_module_name($_) } @update_packages if (@update_packages);

  if (@update_packages) {

    my $packages_filter = '';
    my @packages_in     = ();
    my @packages_like   = ();

    foreach my $pkg (@update_packages) {
      if ($pkg =~ /\*/) {
        $pkg =~ s/\*/%/g;
        push(@packages_like, qq/packages.name LIKE "$pkg"/);
      } else {
        push(@packages_in, $pkg);
      }
    }

    $packages_filter .= '(';

    $packages_filter .= sprintf('packages.name IN ("%s")', join('","', @packages_in)) if (@packages_in);
    $packages_filter .= ' OR '                                                        if (@packages_in && @packages_like);
    $packages_filter .= sprintf('(%s)', join(' OR ', @packages_like))                 if (@packages_like);

    $packages_filter .= ')';

    push(@query_filters, $packages_filter);

  }

  $updatable_packages_query = sprintf($updatable_packages_query, join(' AND ', @query_filters));

  my $sth = $dbh->prepare($updatable_packages_query);
  $sth->execute();

  while (my $row = $sth->fetchrow_hashref()) {

    next if (($row->{old_priority} > $row->{new_priority}) && ! $slackman_opts->{'no-priority'});

    $update_pkgs->{$row->{name}} = $row;

    # Skip dependency check
    next if ($slackman_opts->{'no-deps'});

    foreach my $pkg_required (package_dependency($row->{name}, $row->{repository})) {

      my $updatable_pkg_required_row = package_available_update($pkg_required, $option_repo);

      next unless($updatable_pkg_required_row);
      next if (($updatable_pkg_required_row->{old_priority} > $updatable_pkg_required_row->{new_priority}) && ! $slackman_opts->{'no-priority'});

      $update_pkgs->{$updatable_pkg_required_row->{name}} = $updatable_pkg_required_row;

      my $dependency_row = $dbh->selectrow_hashref($dependency_query, undef, $pkg_required, $arch, '"' . join('", "', get_disabled_repositories()) . ' "');

      next unless ($dependency_row->{name});

      unless (package_is_installed($pkg_required)) {
        $install_pkgs->{$pkg_required} = $dependency_row;
        push(@{$install_pkgs->{$pkg_required}->{needed_by}}, $row->{name});
      }

    }

  }

  return ($update_pkgs, $install_pkgs);

}


sub package_download {

  my ($pkg) = @_;

  my $package_url    = sprintf('%s/%s/%s', $pkg->{'mirror'}, $pkg->{'location'}, $pkg->{'package'});
  my $save_path      = sprintf('%s/%s/%s', $slackman_conf{'directory'}->{'cache'}, $pkg->{'repository'}, $pkg->{'location'});
  my $package_path   = sprintf('%s/%s', $save_path, $pkg->{'package'});
  my @package_errors = ();

  make_path($save_path) unless (-d $save_path);

  unless (-e $package_path) {

    $package_url =~ s/\/\/\.//;

    logger->info(sprintf("Starting download of %s package", $pkg->{'package'}));

    if (download_file($package_url, "$package_path.part")) {
      rename("$package_path.part", $package_path);
      logger->info(sprintf("Downloaded %s package", $pkg->{'package'}));
    } else {
      logger->error(sprintf("Error during download of %s package", $pkg->{'package'}));
      push(@package_errors, 'download');
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
    my $skip_check = 0;

    unless ($slackman_conf{'main'}->{'checkmd5'}) {
      $md5_check = 1;
    }

    unless ($slackman_conf{'main'}->{'checkgpg'}) {
      $gpg_verify = 1;
    }

    unless ($pkg->{'checksum'}) {
      exit(0) unless(confirm(sprintf("%s %s package don't have a valid checksum. Do you want continue ? [Y/N]", colored('WARNING', 'yellow bold'), colored($pkg->{'package'}, 'bold'))));
      $skip_check = 1;
    }

    if ($pkg->{'checksum'} && md5_check($package_path, $pkg->{'checksum'})) {
      $md5_check = 1;
      logger->info(sprintf("MD5 checksum success for %s package", $pkg->{'package'}));
    } else {
      logger->error(sprintf("Error during MD5 checksum of %s package", $pkg->{'package'}));
      push(@package_errors, 'checksum');
    }

    if (gpg_verify($package_path)) {
      logger->info(sprintf("GPG signature verify success for %s package", $pkg->{'package'}));
      $gpg_verify = 1;
    } else {
      logger->error(sprintf("Error during GPG signature verify of %s package", $pkg->{'package'}));
      push(@package_errors, 'gpg');
    }

    unless ($skip_check) {

      unless ($md5_check && $gpg_verify) {
        unlink($package_path) or warn "Failed to remove file: $!";
      }

    }

  }

  return ($package_path, \@package_errors);

}


sub package_list_installed {

  my (@search) = @_;

  my @filters      = ();
  my $query_filter = '';

  foreach my $item (@search) {
    $item =~ s/\*/%/g;
    push(@filters, sprintf('(name LIKE %s)', $dbh->quote($item)));
  }

  if (@filters) {
    $query_filter = sprintf('AND (%s)', join(' OR ', @filters));
  }

  my $query = sprintf("SELECT * FROM history WHERE status = 'installed' %s ORDER BY name", $query_filter);

  return $dbh->selectall_hashref($query, 'name', undef)

}


sub package_list_obsoletes {

  my ($repo) = @_;

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
                    AND changelogs.repository %s
                    AND changelogs.repository NOT IN (%s)
                    AND NOT EXISTS (SELECT 1
                                      FROM changelogs clog
                                     WHERE clog.name = changelogs.name
                                       AND clog.timestamp >= changelogs.timestamp)/;

  my $enabled_repositories  = 'IN ("' . join('", "', get_enabled_repositories())  . '")';
  my $disabled_repositories = '"' . join('", "', get_disabled_repositories()) . '"';

  if ($repo) {
    $repo =~ s/\*/\%/;
    $enabled_repositories = sprintf('LIKE "%s"', $repo);
  }

  $query = sprintf($query, $enabled_repositories, $disabled_repositories);

  return $dbh->selectall_hashref($query, 'changelog_name', undef);

}


sub package_search_files {

  my ($file) = @_;

  $file =~ s/\*/%/g;

  my $dir = '';

  my $query = qq{ SELECT *, directory || '/' || file AS fullpath FROM manifest WHERE file LIKE ? };

  if ($file =~ /\//) {

    $dir    = dirname($file);
    $file   = basename($file);
    $query .= ' AND directory LIKE ?';

  }

  my $sth = $dbh->prepare($query);

  if ($dir) {
    $sth->execute($file, $dir);
  } else {
    $sth->execute($file);
  }

  return $sth->fetchall_arrayref({});

}


1;
__END__

=head1 NAME

Slackware::SlackMan::Package - SlackMan Package module

=head1 SYNOPSIS

  use Slackware::SlackMan::Package qw(:all);

  my $pkg_info = package_info('aaa_base-14.2-x86_64-1.tgz');

=head1 DESCRIPTION

Package module for SlackMan.

=head1 EXPORT

No subs are exported by default.

=head1 SUBROUTINES

=head2 package_available_update

=head2 package_dependency

=head2 package_download

=head2 package_info

=head2 package_install

=head2 package_list_installed

=head2 package_list_obsoletes

=head2 package_metadata

=head2 package_remove

=head2 package_search_files

=head2 package_upgrade

=head2 package_version_compare

=head1 AUTHOR

Giuseppe Di Terlizzi, C<< <giuseppe.diterlizzi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<giuseppe.diterlizzi at gmail.com>, or through
the web interface at L<https://github.com/LotarProject/slackman/issues>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

  perldoc Slackware::SlackMan::Package

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
