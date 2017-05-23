package Slackware::SlackMan::Command;

use strict;
use warnings;

no if ($] >= 5.018), 'warnings' => 'experimental';
use feature "switch";

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.0.1';
  @ISA         = qw(Exporter);
  @EXPORT_OK   = qw(run);
  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Data::Dumper;
use File::Basename;
use File::Path qw(make_path remove_tree);
use Getopt::Long qw(:config );
use IO::File;
use IO::Handle;
use Sort::Versions;
use Term::ANSIColor qw(:constants);
use Pod::Usage;

use Slackware::SlackMan::Utils   qw(:all);
use Slackware::SlackMan::Repo    qw(:all);
use Slackware::SlackMan::DB      qw(:all);
use Slackware::SlackMan::Package qw(:all);
use Slackware::SlackMan::Parser  qw(:all);
use Slackware::SlackMan::Config  qw(:all);

my $lock_check = get_lock_pid();

exit _show_help()    if $slackman_opts->{'help'};
exit _show_version() if $slackman_opts->{'version'};

pod2usage(-exitval => 0, -verbose => 2) if $slackman_opts->{'man'};

# Force exit on CTRL-C
$SIG{INT} = sub {
  exit(1);
};

# Write all die to log
$SIG{__DIE__} = sub {
  logger->critical(trim($_[0]));
  die @_;
};

# Write all warn to log
$SIG{__WARN__} = sub {
  logger->warning(trim($_[0]));
  warn @_;
};

sub run {

  db_init();

  my $command   = $ARGV[0] || undef;
  my @arguments = @ARGV[ 1 .. $#ARGV ];

  _show_help() unless ($command);

  logger->debug(sprintf('Call %s command (cmd: slackman %s)', $command, join(' ', @ARGV)));

  if ($lock_check) {

    print "Another instance of slackman is running (pid: $lock_check) If this is not correct,\n" .
          "you can remove /var/lock/slackman file and run slackman again.\n\n";

    exit(255);

  }

  # Always create lock if pid not exists
  create_lock() unless(get_lock_pid());

  _update_repo_data();

  given($command) {

    when('install')      { _call_package_install(@arguments) }
    when('reinstall')    { _call_package_reinstall(@arguments) }
    when('remove')       { _call_package_remove(@arguments) }
    when('upgrade')      { _call_package_update(@arguments)  }
    when('check-update') { $slackman_opts->{'no'} = 1 ; _call_package_update(@arguments) }
    when('info')         { _call_package_info($ARGV[1]) }
    when('history')      { _call_package_history($ARGV[1]) }

    when('changelog')    { _call_changelog() }
    when('config')       { _call_config() }
    when('search')       { _call_package_search($ARGV[1]) }
    when('file-search')  { _call_file_search($ARGV[1]) }

    when('db') {
      given($ARGV[1]) {
        when('optimize') { _call_db_optimize() }
        when('info')     { _call_db_info() }
        default          { _show_db_help() }
      }
    }

    when('clean') {
      given($ARGV[1]) {
        when('metadata') { _call_clean_metadata(); exit(0); }
        when('manifest') { _call_clean_metadata('manifest'); exit(0); }
        when('cache')    { _call_clean_cache(); exit(0); }
        when('all')      { _call_clean_all(); }
        default          { _show_clean_help(); }
      }
    }

    when('repo') {
      given($ARGV[1]) {
        when('list')      { _call_list_repo() }
        when('disable')   { _call_repo_disable($ARGV[2]) }
        when('enable')    { _call_repo_enable($ARGV[2]) }
        when('info')      { _call_repo_info($ARGV[2]) }
        default           { _show_repo_help() }
      }
    }

    when('list') {
      given($ARGV[1]) {
        when('installed') { _call_list_installed() }
        when('obsoletes') { _call_list_obsoletes() }
        when('repo')      { _call_list_repo() }
        when('orphan')    { _call_list_orphan() }
        when('variables') { _call_list_variables() }
        when('packages')  { _call_list_packages() }
        default           { _show_list_help() }
      }
    }

    when('update') {
      given($ARGV[1]) {
        when('packages')  { _call_update_repo_packages();  exit(0); }
        when('history')   { _call_update_history();        exit(0); }
        when('changelog') { _call_update_repo_changelog(); exit(0); }
        when('manifest')  { _call_update_repo_manifest();  exit(0); }
        when('gpg-key')   { _call_update_repo_gpg_key();   exit(0); }
        when('all')       { _call_update_all_metadata() }
        default           { _call_update_metadata() }
      }
    }

    when('help') {
      given($ARGV[1]) {
        when ('list')   { _show_list_help() }
        when ('update') { _show_update_help() }
        when ('repo')   { _show_repo_help() }
        when ('db')     { _show_db_help() }
        default         { _show_help() }
      }
    }

    default { _show_help() }

  }

  exit(0);

}


sub _update_repo_data {

  foreach my $repo_id (get_repositories())  {

    my $repo_info     = get_repository($repo_id);
    my $repo_priority = $repo_info->{'priority'};
    my $repo_exclude  = $repo_info->{'exclude'};

    $dbh->do('UPDATE packages SET priority = ? WHERE repository = ?', undef, $repo_priority, $repo_id);
    $dbh->do('UPDATE packages SET excluded = 0 WHERE repository = ?', undef, $repo_id);

    if ($repo_exclude) {

      my @exclude = split(/,/, $repo_exclude);

      foreach my $pkg (@exclude) {
        $pkg =~ s/\*/\%/g;
        $dbh->do('UPDATE packages SET excluded = 1 WHERE repository = ? AND name LIKE ?', undef, $repo_id, $pkg);
      }

    }

  }

}


sub _show_help {

  print "SlackMan - Slackware Package Manager $VERSION\n\n";

  pod2usage(
  -exitval  => 0,
  -verbose  => 99,
  -sections => 'SYNOPSIS|COMMANDS|OPTIONS',
  );

}

sub _show_list_help {

  pod2usage(
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'COMMANDS/LIST COMMANDS' ]
  );

}

sub _show_clean_help {

  pod2usage(
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'COMMANDS/CLEAN COMMANDS' ]
  );

}

sub _show_update_help {

  pod2usage(
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'COMMANDS/UPDATE COMMANDS' ]
  );

}

sub _show_repo_help {

  pod2usage(
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'COMMANDS/REPOSITORY COMMANDS' ]
  );

}

sub _show_db_help {

  pod2usage(
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'COMMANDS/DATABASE COMMANDS' ]
  );

}

sub _show_version {
  print sprintf("SlackMan - Slackware Package Manager %s\n\n", $VERSION);
  exit(0);
}

sub _call_db_optimize {

  STDOUT->printflush("Reindex tables... ");
  db_reindex();
  STDOUT->printflush("done!\n");

  STDOUT->printflush("Compact database... ");
  db_compact();
  STDOUT->printflush("done!\n");

  exit(0);

}

sub _call_db_info {

  my $db_path = $slackman_conf->{directory}->{lib} . '/db.sqlite';

  my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,
      $atime, $mtime, $ctime, $blksize, $blocks) = stat($db_path);

  print sprintf("%-20s %s\n",     'Path:', $db_path);
  print sprintf("%-20s %.1f M\n", 'Size:', ($size/1024/1024));

  my $quick_check  = ($dbh->selectrow_arrayref('PRAGMA quick_check', undef))->[0];
  print sprintf("%-20s %s\n", 'Quick check:', uc($quick_check));

  my $integrity_check = ($dbh->selectrow_arrayref('PRAGMA integrity_check', undef))->[0];
  print sprintf("%-20s %s\n", 'Integrity check:', uc($integrity_check));

}

sub _call_config {

  foreach my $section (keys %$slackman_conf) {
    foreach my $parameter (keys %{$slackman_conf->{$section}}) {
      print sprintf("%-20s %s\n", "$section.$parameter", $slackman_conf->{$section}->{$parameter});
    }
  }

  exit(0);
}

sub _call_clean_all {

  _call_clean_metadata();
  _call_clean_cache();

  exit(0);

}

sub _call_clean_cache {

  my $cache_dir = $slackman_conf->{'directory'}->{'cache'};
  logger->debug(qq/Clear packages cache directory "$cache_dir"/);

  STDOUT->printflush("\nClean packages download cache... ");
  remove_tree($cache_dir, { keep_root => 1 });
  STDOUT->printflush("done\n");


}

sub _call_clean_metadata {

  my $table = shift;

  STDOUT->printflush("\nClean database metadata... ");

  db_wipe_tables()       unless ($table);
  db_wipe_table($table)      if ($table);

  db_reindex();
  db_compact();
  STDOUT->printflush("done\n");

}

sub _call_update_repo_packages {

  STDOUT->printflush("\nUpdate repository packages metadata:\n");

  my @repos = get_enabled_repositories();
     @repos = ( $slackman_opts->{'repo'} ) if ($slackman_opts->{'repo'});

  foreach my $repo (@repos) {

    logger->info(qq/Update "$repo" repository packages/);
    my $repo_data = get_repository($repo);

    STDOUT->printflush("  * $repo... ");
    parse_packages($repo_data, \&callback_status);
    STDOUT->printflush("done\n");

  }

}

sub _call_update_repo_gpg_key {

  STDOUT->printflush("\nUpdate repository GPG key:\n");

  my @repos = get_enabled_repositories();
     @repos = ( $slackman_opts->{'repo'} ) if ($slackman_opts->{'repo'});

  foreach my $repo (@repos) {

    logger->info(qq/Update "$repo" repository GPG-KEY/);
    my $repo_data = get_repository($repo);

    STDOUT->printflush("  * $repo... ");

    my $gpg_key_url  = $repo_data->{gpgkey};
    my $gpg_key_path = sprintf('%s/%s/GPG-KEY', $slackman_conf->{directory}->{cache}, $repo);

    unless (-e $gpg_key_path) {

      make_path(dirname($gpg_key_path));

      if (download_file($gpg_key_url, $gpg_key_path, "-s")) {
        gpg_import_key($gpg_key_path) if (-e $gpg_key_path);
      }

    }

    STDOUT->printflush("done\n");

  }

}

sub _call_update_repo_changelog {

  STDOUT->printflush("\nUpdate repository ChangeLog:\n");

  my @repos = get_enabled_repositories();
     @repos = ( $slackman_opts->{'repo'} ) if ($slackman_opts->{'repo'});

  foreach my $repo (@repos) {

    logger->info(qq/Update "$repo" repository ChangeLog/);
    my $repo_data = get_repository($repo);

    STDOUT->printflush("  * $repo... ");
    parse_changelog($repo_data, \&callback_status);
    STDOUT->printflush("done\n");

  }

}

sub _call_update_repo_manifest {

  STDOUT->printflush("\nUpdate repository Manifest (very slow for big repository ... be patient):\n");

  my @repos = get_enabled_repositories();
     @repos = ( $slackman_opts->{'repo'} ) if ($slackman_opts->{'repo'});

  foreach my $repo (@repos) {

    my $repo_data = get_repository($repo);

    STDOUT->printflush("  * $repo... ");
    parse_manifest($repo_data, \&callback_status);
    STDOUT->printflush("done\n");

  }

}

sub _call_update_history {

  STDOUT->printflush("\nUpdate local packages metadata:\n");

  STDOUT->printflush("  * installed... ");
  parse_history('installed', \&callback_status);
  STDOUT->printflush("done\n");

  STDOUT->printflush("  * removed/updated... ");
  parse_history('removed', \&callback_status);
  STDOUT->printflush("done\n");

}

sub _call_update_metadata {

  _call_update_repo_packages();
  _call_update_repo_changelog();
  _call_update_history();

  exit(0);

}

sub _call_update_all_metadata {

  _call_update_repo_gpg_key();
  _call_update_repo_packages();
  _call_update_repo_changelog();
  _call_update_repo_manifest();
  _call_update_history();

  exit(0);

}

sub _call_package_info {

  my $package = shift;

  unless ($package) {
    warn("Specify package!\n");
    exit(255);
  }

  $package =~ s/\*/%/g;

  my $installed_rows = $dbh->selectall_hashref('SELECT * FROM history WHERE name LIKE ? AND status = "installed"', 'id', undef, parse_module_name($package));

  my @installed;

  print "Installed package(s)\n";
  print sprintf("%s\n\n", "-"x80);

  foreach (keys %$installed_rows) {

    my $row = $installed_rows->{$_};

    push @installed, $row->{name};

    my $pkg_dependency = $dbh->selectrow_hashref('SELECT * FROM packages WHERE package LIKE ?', undef, $row->{'package'}.'%');

    print sprintf("%-10s : %s\n",     'Name',    $row->{name});
    print sprintf("%-10s : %s\n",     'Arch',    $row->{arch});
    print sprintf("%-10s : %s\n",     'Tag',     $row->{tag}) if ($row->{tag});
    print sprintf("%-10s : %s\n",     'Version', $row->{version});
    print sprintf("%-10s : %.1f M\n", 'Size',    ($row->{size_uncompressed}/1024));
    print sprintf("%-10s : %s\n",     'Require', $pkg_dependency->{'required'}) if ($pkg_dependency);
    print sprintf("%-10s : %s\n",     'Summary', $row->{description});

    if ($slackman_opts->{'show-files'}) {

      print sprintf("\n%-10s :\n", 'File lists');

      my $package_meta = package_metadata(file_read("/var/log/packages/".$row->{'package'}));

      foreach (@{$package_meta->{'file_list'}}) {
        next if (/^(install|\.\/)/);
        print "\t/$_\n";
      }

    }

    print sprintf("\n%s\n\n", "-"x80);

  }

  print "No packages installed found\n" unless (scalar keys %$installed_rows);

  my $available_query = sprintf('SELECT * FROM packages WHERE name LIKE ? AND name NOT IN (%s) AND repository NOT IN (%s)',
    '"' . join('","', @installed) . '"',
    '"' . join('","', get_disabled_repositories()) . '"');
  my $available_rows  = $dbh->selectall_hashref($available_query, 'id', undef, $package);

  print "\n\n";

  print "Available package(s)\n";
  print sprintf("%s\n\n", "-"x80);

  foreach (keys %$available_rows) {

    my $row = $available_rows->{$_};

    print sprintf("%-10s : %s\n",     'Name',     $row->{name});
    print sprintf("%-10s : %s\n",     'Arch',     $row->{arch});
    print sprintf("%-10s : %s\n",     'Tag',      $row->{tag})      if ($row->{tag});
    print sprintf("%-10s : %s\n",     'Category', $row->{category}) if ($row->{category});
    print sprintf("%-10s : %s\n",     'Version',  $row->{version});
    print sprintf("%-10s : %.1f M\n", 'Size',     ($row->{size_uncompressed}/1024));
    print sprintf("%-10s : %s\n",     'Require',  $row->{required}) if ($row->{required});
    print sprintf("%-10s : %s\n",     'Repo',     $row->{repository});
    print sprintf("%-10s : %s\n",     'Summary',  $row->{description});

    if ($slackman_opts->{'show-files'}) {

      print sprintf("\n%-10s :\n", 'File lists');

      my $sth = $dbh->prepare('SELECT * FROM manifest WHERE package_id = ? ORDER BY directory, file');
      $sth->execute($row->{'id'});

      while(my $row = $sth->fetchrow_hashref()) {
        print sprintf("\t%s%s\n", $row->{'directory'}, ($row->{'file'} || ''));
      }

    }

    print sprintf("\n%s\n\n", "-"x80);

  }

  print "No packages available found\n\n" unless (scalar keys %$available_rows);

  exit(0);

}

sub _call_file_search {

  my $search = shift;

  unless($search) {
    print "Missing search paramater!\n";
    exit(1);
  }

  $search =~ s/\*/%/;

  my $sth = $dbh->prepare('SELECT * FROM manifest m, packages p WHERE m.package_id = p.id AND m.file LIKE ?');
  $sth->execute($search);

  while (my $row = $sth->fetchrow_hashref()) {
    print sprintf("%s/@{[ BOLD ]}%s@{[ RESET ]}: %s (%s)\n",
      $row->{'directory'}, $row->{'file'}, $row->{'package'}, $row->{'repository'});
  }

  exit(0);

}

sub _call_package_search {

  my $search = shift;

  unless ($search) {
    warn "Specify package!\n";
    exit(255);
  }

  $search =~ s/\*/%/g;

  my $query = 'SELECT p1.name,
                      p1.version,
                      p1.arch,
                      p1.summary,
                      p1.repository,
                      (SELECT "installed"
                         FROM history h1
                        WHERE h1.name    = p1.name
                          AND h1.version = p1.version
                          AND h1.tag     = p1.tag
                          AND h1.status  = "installed") AS status
                 FROM packages p1
                WHERE (    p1.name    LIKE ?
                        OR p1.summary LIKE ? )
                UNION
               SELECT h2.name,
                      h2.version,
                      h2.arch,
                      h2.summary,
                      ""          AS repository,
                      "installed" AS status
                 FROM history h2
                WHERE h2.status = "installed"
                  AND (    h2.name    LIKE ?
                        OR h2.summary LIKE ?)
                  AND NOT EXISTS (SELECT 1
                                    FROM packages p2
                                   WHERE p2.name    = h2.name
                                     AND p2.version = h2.version
                                     AND p2.tag     = h2.tag)';

  my $sth = $dbh->prepare($query);
  $sth->execute($search, $search, $search, $search);

  while (my $row = $sth->fetchrow_hashref()) {

    my $name    = $row->{'name'};
    my $summary = $row->{'summary'};

    print sprintf("%-35s %-15s %-8s %-75s %-10s %s\n", $name, $row->{'version'}, $row->{'arch'}, $summary, ($row->{'status'}||' '), $row->{'repository'});

  }

  exit(0);

}

sub _call_package_history {

  my ($package) = @_;

  unless ($package) {
    warn("Specify package!\n");
    exit(255);
  }

  my $rows_ref = $dbh->selectall_hashref('SELECT * FROM history WHERE name = ? ORDER BY timestamp', 'timestamp', undef, $package);
  my $row_nums = scalar keys %$rows_ref;

  unless ($row_nums) {
    print "Package $package not found!\n";
    exit 1;
  }

  print sprintf("History of @{[ BOLD ]}%s@{[ RESET ]} package:\n\n", $package);
  print sprintf("%-10s %-15s %-25s %-15s %-25s\n", "Status", "Version", "Timestamp", "Previous", "Upgraded");
  print sprintf("%s\n", "-"x100);

  my $prev_version   = '';
  my $prev_status    = '';
  my $status_history = '';

  foreach (sort keys %$rows_ref) {

    my $row       = $rows_ref->{$_};
    my $status    = $row->{status};
    my $version   = $row->{version} . '-' . $row->{build};
    my $timestamp = $row->{timestamp};
    my $upgraded  = $row->{upgraded};

    $status_history = $status;
    $status_history = 'upgraded'     if ($status eq 'installed');
    $status_history = 'installed'    if (! $prev_status);
    $status_history = $row->{status} if ($row_nums == 1);

    print sprintf("%-10s %-15s %-25s %-15s %-25s\n",
      $status_history,
      $version,  $timestamp,
      $prev_version, $upgraded);

    $prev_version = $version;
    $prev_status  = $status;

  }

  print "\n";

  exit(0);

}

sub _call_package_update {

  my @update_package = @_;

  my $updatable_packages_query = qq/SELECT packages.name,
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
                                       AND packages.arch  = history.arch
                                       AND history.status = "installed"
                                       AND old_version_build != new_version_build
                                       AND version_compare(old_version_build, new_version_build) < 0
                                       AND (%s)/;

  my $dependency_query = qq/SELECT package,
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
                               AND arch IN (?, "noarch") AND repository IN (?)/;


  STDOUT->printflush('Search packages update... ');

  my $arch = get_arch();

  my $option_repo    = $slackman_opts->{'repo'};
  my $option_exclude = $slackman_opts->{'exclude'};

  my @filters;

  if ($option_exclude) {
    $option_exclude =~ s/\*/%/g;
    push(@filters, qq/packages.name NOT LIKE "$option_exclude"/);
  }

  if ($option_repo) {
    $option_repo .= ":%" unless ($option_repo =~ m/\:/);
    push(@filters, qq/packages.repository LIKE "$option_repo"/);
  } else {
    push(@filters, 'packages.repository IN ("' . join('", "', get_enabled_repositories()) . '")');
  }

  push(@filters, 'packages.excluded = 0') unless ($slackman_opts->{'no-excludes'});
  push(@filters, 'packages.repository NOT IN ("' . join('", "', get_disabled_repositories()) . '")');

  @update_package = map { parse_module_name($_) } @update_package if (@update_package);

  if (@update_package) {

    my $packages_filter = '';
    my @packages_in     = ();
    my @packages_like   = ();

    foreach my $pkg (@update_package) {
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

    push(@filters, $packages_filter);

  }

  $updatable_packages_query = sprintf($updatable_packages_query, join(' AND ', @filters));

  my $sth = $dbh->prepare($updatable_packages_query);
  $sth->execute();

  my $update_pkgs     = {};  # Updatable packages
  my $install_pkgs    = {};  # Required packages to install
  my @downloads       = ();  # Download packages
  my @packages        = ();  # Packages for upgradepkg command
  my @errors          = ();  # Download, checksum & gpg verify errors

  my $total_compressed_size   = 0;
  my $total_uncompressed_size = 0;
  my $spinner = 0;

  while (my $row = $sth->fetchrow_hashref()) {

    callback_spinner($spinner);
    $spinner++;

    next if (($row->{old_priority} > $row->{new_priority}) && ! $slackman_opts->{'no-priority'});

    $update_pkgs->{$row->{name}} = $row;

    foreach my $pkg_required (package_dependency($row->{name}, $row->{repository})) {

      callback_spinner($spinner);
      $spinner++;

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

  STDOUT->printflush("done!\n\n");

  if (scalar keys %$update_pkgs) {

    print "Package(s) to update\n\n";
    print sprintf("%s\n", "-"x132);
    print sprintf("%-30s %-8s %-35s %-40s %s\n", 'Name', 'Arch', 'Version', 'Repository', 'Size');
    print sprintf("%s\n", "-"x132);

    foreach (sort keys %$update_pkgs) {

      my $pkg = $update_pkgs->{$_};

      $total_uncompressed_size += $pkg->{size_uncompressed};
      $total_compressed_size   += $pkg->{size_compressed};

      print sprintf("%-30s %-8s %-35s %-40s %.1f M\n",
        $pkg->{name}, $pkg->{arch},
        ($pkg->{old_version_build} .' -> '. $pkg->{new_version_build}),
        $pkg->{repository}, ($pkg->{size_compressed}/1024)
      );

      push(@downloads, $pkg);

    }

  }

  if (scalar keys %$install_pkgs) {

    print "\n\n";
    print "Required package(s) to install\n\n";
    print sprintf("%s\n", "-"x132);
    print sprintf("%-30s %-8s %-9s %-20s %-40s %s\n", 'Name', 'Arch', 'Version', 'Needed by', 'Repository', 'Size');
    print sprintf("%s\n", "-"x132);

    foreach (sort keys %$install_pkgs) {

      my $pkg       = $install_pkgs->{$_};
      my $needed_by = join(',', @{$pkg->{needed_by}});

      $total_uncompressed_size += $pkg->{size_uncompressed};
      $total_compressed_size   += $pkg->{size_compressed};

      print sprintf("%-30s %-8s %-9s %-20s %-40s %.1f M\n",
        $pkg->{name}, $pkg->{arch}, $pkg->{version}, $needed_by, $pkg->{repository}, ($pkg->{size_uncompressed}/1024)
      );

      push(@downloads, $pkg);
    }

  }


  print "\n\n";
  print "Update summary\n";
  print sprintf("%s\n", "-"x40);
  print sprintf("%-20s %s package(s)\n", 'Install', scalar keys %$install_pkgs);
  print sprintf("%-20s %s package(s)\n", 'Update',  scalar keys %$update_pkgs);

  print sprintf("%-20s %.1f M\n", 'Download size', $total_compressed_size/1024);
  print sprintf("%-20s %.1f M\n", 'Installed size',  $total_uncompressed_size/1024);
  print "\n\n";

  exit(0) if ($slackman_opts->{'no'} || $slackman_opts->{'summary'});

  if (@downloads) {

    unless ($slackman_opts->{'yes'} || $slackman_opts->{'download-only'}) {
      exit(0) unless(confirm("Perform update of selected packages? [Y/N] "));
    }

    print "\n\n";
    print "Download package(s)\n\n";
    print sprintf("%s\n", "-"x132);

    my $num_downloads   = scalar @downloads;
    my $count_downloads = 0;

    foreach my $pkg (@downloads) {

      $count_downloads++;
      STDOUT->printflush(sprintf("[%d/%d] %s\n", $count_downloads, $num_downloads, $pkg->{'package'}));
      package_download($pkg, \@packages, \@errors);

    }

    exit(0) if ($slackman_opts->{'download-only'});

    unless ($< == 0) {
      warn "\nPackage update requires root privileges!\n";
      exit(1);
    }

    if (@packages) {

      print "\n\n";
      print "Update package(s)\n\n";
      print sprintf("%s\n", "-"x132);

      foreach my $package_path (@packages) {
        package_update($package_path);
        my $pkg_info = package_info(basename($package_path));
        logger->info(sprintf("Upgraded %s package to %s version", $pkg_info->{name}, $pkg_info->{version}));
      }

    }

    if (@errors) {

      print "\n\n";
      print "Error(s) during package integrity check or download\n\n";
      print sprintf("%s\n", "-"x132);

      foreach (@errors) {
        print sprintf("  * %s\n", $_);
      }

    }

    print "\n\n";

    _fork_update_history();
    exit(0);

  }

  exit(0);

}

sub _call_list_repo {

  my @repositories = get_repositories();

  print "\nAvailable repository\n\n";
  print sprintf("%s\n", "-"x132);
  print sprintf("%-30s %-70s %-10s %-10s %-4s\n", "Repository ID",  "Description", "Status", "Priority", "Packages");
  print sprintf("%s\n", "-"x132);

  foreach my $repo_id (@repositories) {
    my $info     = get_repository($repo_id);
    my $packages = $dbh->selectrow_array('SELECT COUNT(*) AS packages FROM packages WHERE repository = ?', undef, $repo_id);
    print sprintf("%-30s %-70s %-10s %-10s %-4s\n", $repo_id, $info->{name}, ($info->{enabled} ? 'Enabled' : 'Disabled'), $info->{priority}, $packages);

  }

  exit(0);

}

sub _call_changelog {

  my $query   = 'SELECT * FROM changelogs WHERE %s ORDER BY timestamp DESC LIMIT %s';
  my $option_repo = $slackman_opts->{'repo'};

  my @repositories = get_enabled_repositories();
  my @filters      = ();

  # Get only machine arch and noarch changelogs
  my $arch = get_arch();

     if ($arch eq 'x86_64')        { push(@filters, 'arch IN ("x86_64", "noarch")') }
  elsif ($arch =~ /x86|i[3456]86/) { push(@filters, '(arch = "noarch" OR arch = "x86" OR arch LIKE "i%86")') }
  elsif ($arch =~ /arm(.*)/)       { push(@filters, '(arch = "noarch" OR arch LIKE "arm%")')}

  # Filter repository
  if ($option_repo) {
    $option_repo .= ":%" unless ($option_repo =~ m/\:/);
    push(@filters, qq/repository LIKE "$option_repo"/);
  } else {
    push(@filters, 'repository IN ("' . join('", "', get_enabled_repositories()) . '")');
  }

  # Filter disabled repository
  push(@filters, sprintf('repository NOT IN ("%s")', join('","', get_disabled_repositories())));

  my $sth = $dbh->prepare(sprintf($query, join(' AND ', @filters), $slackman_opts->{'limit'}));
  $sth->execute();

  print sprintf("%-60s %-10s %-25s %s\n", "Package",  "Status", "Timestamp", "Repository");
  print sprintf("%s\n", "-"x132);

  while (my $row = $sth->fetchrow_hashref()) {
    print sprintf("%-60s %-10s %-25s %s\n", $row->{'package'}, $row->{'status'}, $row->{'timestamp'}, $row->{'repository'});
  }

}

sub _call_repo_disable {

  my ($repo_id) = @_;

  disable_repository($repo_id);
  print qq/Repository "$repo_id" disabled\n/;

}

sub _call_repo_enable {

  my ($repo_id) = @_;

  enable_repository($repo_id);
  print qq/Repository "$repo_id" enabled\n/;

}

sub _call_repo_info {

  my ($repo_id) = @_;

  unless($repo_id) {
    warn "Specicy repository!\n";
    exit(255);
  }

  my $repo_data = get_repository($repo_id);

  unless($repo_data) {
    warn "Repository not found!\n";
    exit(255);
  }

  my $package_nums = $dbh->selectrow_array('SELECT COUNT(*) AS packages FROM packages WHERE repository = ?', undef, $repo_id);
  my $last_update  = time_to_timestamp(db_meta_get("packages-last-update.$repo_id"));

  my @urls = qw/changelog packages manifest checksums gpgkey/;

  print "\n";
  print sprintf("%-20s %s\n", "Name:",        $repo_data->{name});
  print sprintf("%-20s %s\n", "ID:",          $repo_data->{id});
  print sprintf("%-20s %s\n", "Mirror:",      $repo_data->{mirror});
  print sprintf("%-20s %s\n", "Status:",      (($repo_data->{enabled}) ? 'enabled' : 'disabled'));
  print sprintf("%-20s %s\n", "Last Update:", $last_update);
  print sprintf("%-20s %s\n", "Priority:",    $repo_data->{priority});
  print sprintf("%-20s %s\n", "Packages:",    $package_nums);

  print "\nRepository URLs:\n";

  foreach (@urls) {
    print sprintf("%-20s %s\n", "  * $_", $repo_data->{$_});
  }

  print "\n";

  exit(0);

}

sub _call_list_obsoletes {

  my $obsolete_rows = package_list_obsoletes($slackman_opts->{'repo'});
  my $num_rows      = scalar keys %$obsolete_rows;

  print "\nObsolete package(s)\n\n";
  print sprintf("%s\n", "-"x132);
  print sprintf("%-30s %-25s %-15s %-25s %-15s %-25s\n", "Package", "ChangeLog Repository", "Version", "Obsolete from", "Actual Version", "Installed at");
  print sprintf("%s\n", "-"x132);

  unless ($num_rows) {
    print "\nNo obsolete packages found!\n\n";
    exit(0);
  }

  my @obsolete = ();

  foreach(keys %$obsolete_rows) {

    my $row = $obsolete_rows->{$_};

    print sprintf("%-30s %-25s %-15s %-25s %-15s %-25s\n",
      $row->{changelog_name},    $row->{changelog_repository},
      $row->{changelog_version}, $row->{changelog_timestamp},
      $row->{installed_version}, $row->{installed_timestamp});

    push(@obsolete, $row->{changelog_name});

  }

  print "\n\n";

  return (@obsolete);

}

sub _call_package_reinstall {

  my @packages     = @_;
  my @is_installed = ();
  my $option_repo  = $slackman_opts->{'repo'};

  unless (@packages) {
    warn "Specify package!\n";
    exit(255);
  }

  print "\nReinstall package(s)\n\n";
  print sprintf("%s\n", "-"x132);
  print sprintf("%-20s %-20s %-10s %s\n", "Package", "Version", "Tag", "Installed");
  print sprintf("%s\n", "-"x132);

  foreach (@packages) {

    my $pkg = package_is_installed($_);

    if ($pkg) {
      push(@is_installed, $pkg);
      print sprintf("%-20s %-20s %-10s %s\n", $_, "$pkg->{version}-$pkg->{build}", $pkg->{tag}, $pkg->{timestamp});
    } else {
      print sprintf("%-20s not installed\n", $_);
    }

  }

  exit(0) unless(@is_installed);

  print "\n\n";

  unless ($slackman_opts->{'yes'}) {
    exit(0) unless(confirm("Are you sure? [Y/N] "));
  }

  my @filters = ();

  foreach (@is_installed) {
    push(@filters, sprintf('( package LIKE "%s%%" )', $_->{'package'}));
  }

  if ($option_repo) {
    $option_repo .= ":%" unless ($option_repo =~ m/\:/);
    push(@filters, qq/repository LIKE "$option_repo"/);
  } else {
    push(@filters, 'repository IN ("' . join('", "', get_enabled_repositories()) . '")');
  }

  push(@filters, 'repository NOT IN ("' . join('", "', get_disabled_repositories()) . '")');

  my $query = 'SELECT * FROM packages WHERE ' . join(' AND ', @filters);
  my $rows  = $dbh->selectall_hashref($query, 'id', undef);

  my $i = 0;
  my $num_reinstall = scalar keys %$rows;
  my @pkg_reinstall = ();
  my @pkg_errors    = ();

  exit(0) unless ($num_reinstall);

  print "\n\n";

  foreach (keys %$rows) {

    $i++;

    my $pkg = $rows->{$_};

    STDOUT->printflush(sprintf("[%d/%d] %s\n", $i, $num_reinstall, $pkg->{'package'}));
    package_download($pkg, \@pkg_reinstall, \@pkg_errors);

  }

  exit(0) if ($slackman_opts->{'download-only'});

  unless ($< == 0) {
    warn "\nPackage reinstall requires root privileges!\n";
    exit(1);
  }

  if (@pkg_reinstall) {

    print "\n\n";
    print "Reinstall package(s)\n\n";
    print sprintf("%s\n", "-"x132);

    foreach my $package_path (@pkg_reinstall) {
      package_update($package_path);
      my $pkg_info = package_info(basename($package_path));
      logger->info(sprintf("Reinstalled %s package to %s version", $pkg_info->{name}, $pkg_info->{version}));
    }

  }

  if (@pkg_errors) {

    print "\n\n";
    print "Error(s) during package integrity check or download\n\n";
    print sprintf("%s\n", "-"x132);

    foreach (@pkg_errors) {
      print sprintf("  * %s\n", $_);
    }

  }

  _fork_update_history();
  exit(0);

}

sub _call_package_remove {

  my @packages = @_;
  my @is_installed = ();

  if ($slackman_opts->{'obsolete-packages'}) {

    # Get list from "slackman list obsoletes"
    @is_installed = _call_list_obsoletes();

  } else {

    print "Remove package(s)\n\n";
    print sprintf("%s\n", "-"x132);
    print sprintf("%-20s %-20s %-10s %s\n", "Package", "Version", "Tag", "Installed");
    print sprintf("%s\n", "-"x132);

    foreach (@packages) {

      if ($_ =~ /^aaa\_(base|elflibs|terminfo)/) {
        print sprintf("%-20s never remove this package\n", $_);
      } else {

        my $pkg = package_is_installed($_);

        if ($pkg) {
          push(@is_installed, $_);
          print sprintf("%-20s %-20s %-10s %s\n", $_, "$pkg->{version}-$pkg->{build}", $pkg->{tag}, $pkg->{timestamp});
        } else {
          print sprintf("%-20s not installed\n", $_);
        }

      }

    }

    print "\n\n";

  }

  exit(0) unless(@is_installed);
  exit(0) if ($slackman_opts->{'no'});

  unless ($slackman_opts->{'yes'}) {
    exit(0) unless(confirm("Are you sure? [Y/N] "));
  }

  unless ($< == 0) {
    warn "\nPackage remove requires root privileges!\n";
    exit(1);
  }

  foreach (@is_installed) {
    package_remove($_);
  }

  _fork_update_history();
  exit(0);

}

sub _call_package_install {

  my @packages       = @_;
  my $arch           = get_arch();
  my $option_repo    = $slackman_opts->{'repo'};
  my $option_exclude = $slackman_opts->{'exclude'};

  my $check = $dbh->selectrow_array(sprintf('SELECT COUNT(*) FROM history WHERE name IN (%s) AND status = "installed"', '"' . join('","', @packages) . '"'), undef);

  if ($check) {
    print "Package already installed!\n";
    exit(1);
  }

  my @repositories = get_enabled_repositories();
  my (@filters, @filter_repository);

  @repositories = qq\$option_repo\ if ($option_repo); # TODO verificare se repository è disabilitato

  foreach my $repository (@repositories) {
    $repository .= ":%" unless ($repository =~ m/\:/);
    my $repo_exclude = '';
    push(@filter_repository, qq/packages.repository LIKE "$repository" $repo_exclude/);
  }

  @packages = map { parse_module_name($_) } @packages if (@packages);

  if (@packages) {

    my $packages_filter = '';
    my @packages_in     = ();
    my @packages_like   = ();

    foreach my $pkg (@packages) {
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

    push(@filters, $packages_filter);

  }

  push(@filters, '( ' . join(' OR ', @filter_repository) . ' )');

  if ($option_exclude) {
    $option_exclude =~ s/\*/%/g;
    push(@filters, qq/packages.name NOT LIKE "$option_exclude"/);
  }

  foreach my $repository (get_disabled_repositories()) {
    push(@filters, qq/( packages.repository != "$repository" )/);
  }

  push(@filters, 'packages.excluded = 0') unless ($slackman_opts->{'no-excludes'});

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
                                   location,
                                   mirror,
                                   checksum
                              FROM packages
                             WHERE name = ?
                               AND repository = ?
                               AND arch IN (?, "noarch")/;

  if ($slackman_opts->{'new-packages'}) {
    $query_packages = $query_new_packages;
  }

  $query_packages = sprintf($query_packages, join(' AND ', @filters));

  my $sth_packages = $dbh->prepare($query_packages);
  $sth_packages->execute();

  print "\nPackage(s) install\n\n";
  print sprintf("%s\n", "-"x132);
  print sprintf("%-30s %-8s %-30s %-40s %s\n", 'Name', 'Arch', 'Version', 'Repository', 'Size');
  print sprintf("%s\n", "-"x132);

  my @install = ();
  my $dependency_pkgs = {};

  while (my $row = $sth_packages->fetchrow_hashref()) {

    print sprintf("%-30s %-8s %-30s %-40s %.1f M\n",
      $row->{name}, $row->{arch}, $row->{version},
      $row->{repository}, ($row->{size_uncompressed}/1024)
    );

    foreach my $pkg_required (package_dependency($row->{name}, $row->{repository})) {

      my $dependency_row = $dbh->selectrow_hashref($dependency_query, undef, $pkg_required, $row->{repository}, $arch);

      next unless ($dependency_row->{name});

      unless (package_is_installed($pkg_required)) {
        $dependency_pkgs->{$pkg_required} = $dependency_row;
        push(@install, $dependency_row);
      }

    }

    push(@install, $row);

  }

  if (scalar keys %$dependency_pkgs) {

    print "\n\n";
    print sprintf("%s\n", "-"x132);
    print sprintf("%-30s %-8s %-9s %-20s %-40s %s\n", 'Dependency Name', 'Arch', 'Version', 'Needed by', 'Repository', 'Size');
    print sprintf("%s\n", "-"x132);

    foreach (sort keys %$dependency_pkgs) {

      my $pkg = $dependency_pkgs->{$_};

      print sprintf("%-30s %-8s %-30s %-40s %.1f M\n",
        $pkg->{name}, $pkg->{arch}, $pkg->{version}, $pkg->{repository}, ($pkg->{size_uncompressed}/1024)
      );

      push(@install, $pkg);
    }

  }

  print "\n\n";

  exit(0)     if ($slackman_opts->{'no'});
  exit(0) unless (@install);

  unless ($slackman_opts->{'yes'} || $slackman_opts->{'download-only'}) {
    exit(0) unless(confirm("Install selected packages? [Y/N] "));
  }


  my $num_install   = scalar @install;
  my $count_install = 0;
  my @pkg_install   = ();
  my @errors        = ();

  print "\n\n";
  print "Download package(s)\n\n";
  print sprintf("%s\n", "-"x132);

  foreach my $install (@install) {

    $count_install++;

    STDOUT->printflush(sprintf("[%d/%d] %s\n", $count_install, $num_install, $install->{'package'}));
    package_download($install, \@pkg_install, \@errors);
  }

  exit(0) if ($slackman_opts->{'download-only'});

  unless ($< == 0) {
    warn "\nPackage update requires root privileges!\n";
    exit(1);
  }

  if (@pkg_install) {

    print "\n\n";
    print "Install package(s)\n\n";
    print sprintf("%s\n", "-"x132);

    foreach (@pkg_install) {
      package_install($_);
      my $pkg_info = package_info(basename($_));
      logger->info(sprintf("Installed %s package %s version", $pkg_info->{name}, $pkg_info->{version}));
    }

  }

  if (@errors) {

    print "\n\n";
    print "Error(s) during package integrity check or download\n\n";
    print sprintf("%s\n", "-"x132);

    foreach (@errors) {
        print sprintf("  * %s\n", $_);
    }
    print "\n\n";
  }

  _fork_update_history();
  exit(0);

}

sub _call_list_variables {

  my @variables = ( 'arch', 'arch.bit', 'arch.family',
                    'release', 'release.real', 'release.suffix' );

  print "\n";
  print sprintf("%-20s %s\n", "Variable", "Value");
  print sprintf("%s\n", "-"x40);

  foreach (@variables) {
    print sprintf("%-20s %s\n", "$_", parse_variables("\$$_"));
  }

  print "\n";

  exit(0);

}

sub _call_list_orphan {

  print "\nOrphan packages\n\n";
  print sprintf("%s\n", "-"x132);
  print sprintf("%-40s %-10s\t%-25s %-10s %s\n", "Name", "Arch", "Version", "Tag", "Installed");
  print sprintf("%s\n", "-"x132);

  my $rows_ref = $dbh->selectall_hashref(qq/SELECT h.* FROM history h WHERE h.status = 'installed' AND NOT EXISTS (SELECT 1 FROM packages p WHERE p.name = h.name) ORDER BY name/, 'name', undef);

  foreach (sort keys %$rows_ref) {

    my $row = $rows_ref->{$_};

    print sprintf("%-40s %-10s\t%-25s %-10s %s\n",
      $row->{name},
      $row->{arch},
      $row->{version},
      $row->{tag},
      $row->{timestamp});

  }

  exit(0);

}

sub _call_list_installed {

  print "\nInstalled packages\n\n";
  print sprintf("%s\n", "-"x132);
  print sprintf("%-40s %-10s\t%-25s %-10s %s\n", "Name", "Arch", "Version", "Tag", "Installed");
  print sprintf("%s\n", "-"x132);

  my $rows_ref = package_list_installed;

  foreach (sort keys %$rows_ref) {

    my $row = $rows_ref->{$_};

    print sprintf("%-40s %-10s\t%-25s %-10s %s\n",
      $row->{name},
      $row->{arch},
      "$row->{version}-$row->{build}",
      $row->{tag},
      $row->{timestamp});

  }

  exit(0);

}

sub _call_list_packages {

  print "\nAvailable packages\n\n";
  print sprintf("%s\n", "-"x132);
  print sprintf("%-40s %-10s\t%-25s %-10s %s\n", "Name", "Arch", "Version", "Tag", "Repository");
  print sprintf("%s\n", "-"x132);

  my $option_repo = $slackman_opts->{'repo'};

  if ($option_repo) {
    $option_repo .= ":%" unless ($option_repo =~ m/\:/);
  }

  my $active_repositories = sprintf('IN ("%s")', join('", "', get_enabled_repositories()));
     $active_repositories = sprintf('LIKE "%s"', $option_repo) if ($option_repo);

  my $query = 'SELECT * FROM packages WHERE repository %s ORDER BY name';
     $query = sprintf($query, $active_repositories);

  my $sth = $dbh->prepare($query);
  $sth->execute();

  while (my $row = $sth->fetchrow_hashref()) {

    print sprintf("%-40s %-10s\t%-25s %-10s %s\n",
      $row->{name},
      $row->{arch},
      "$row->{version}-$row->{build}",
      $row->{tag},
      $row->{repository});

  }

  exit(0);

}

sub _fork_update_history {

  # Delete all lock file
  delete_lock();

  # Call update history command in background and set ROOT environment
  my $update_history_cmd  = "slackman update history";
     $update_history_cmd .= sprintf(" --root %s", $ENV{ROOT}) if ($ENV{ROOT});
     $update_history_cmd .= " > /dev/null &";

  logger->debug("Call update history command in background ($update_history_cmd)");

  qx{ $update_history_cmd };

}

1;
__END__

=head1 NAME

Slackware::SlackMan::Command - SlackMan Command module

=head1 SYNOPSIS

  Slackware::SlackMan::Command::run();

=head1 DESCRIPTION

Command module for SlackMan.

=head1 EXPORT

No subs are exported by default.

=head1 SUBROUTINES

=head2 run

C<run> execute slackman command

=head1 AUTHOR

Giuseppe Di Terlizzi, C<< <giuseppe.diterlizzi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<giuseppe.diterlizzi at gmail.com>, or through
the web interface at L<https://github.com/LotarProject/slackman/issues>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

  perldoc Slackware::SlackMan::Command

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

END {
  delete_lock() unless ($lock_check);
}
