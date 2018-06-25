package Slackware::SlackMan::Command::Package;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.3.0';
  @ISA         = qw(Exporter);
  @EXPORT_OK   = qw();
  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Slackware::SlackMan;

use Slackware::SlackMan::DB      qw(:all);
use Slackware::SlackMan::Utils   qw(:all);
use Slackware::SlackMan::Package qw(:all);
use Slackware::SlackMan::Parser  qw(:all);
use Slackware::SlackMan::Repo    qw(:all);

use File::Basename;
use File::Copy;
use File::Find qw( find );
use Term::ANSIColor qw(color colored :constants);
use Term::ReadLine;
use Text::Wrap;
use Pod::Usage;


use constant COMMANDS_DISPATCHER => {
  'changelog'   => \&call_package_changelog,
  'file-search' => \&call_package_file_search,
  'history'     => \&call_package_history,
  'info'        => \&call_package_info,
  'install'     => \&call_package_install,
  'reinstall'   => \&call_package_reinstall,
  'remove'      => \&call_package_remove,
  'search'      => \&call_package_search,
  'upgrade'     => \&call_package_upgrade,
  'new-config'  => \&call_package_new_config,
};

use constant COMMANDS_MAN => {
  'changelog'   => \&call_package_man,
  'file-search' => \&call_package_man,
  'history'     => \&call_package_man,
  'info'        => \&call_package_man,
  'install'     => \&call_package_man,
  'reinstall'   => \&call_package_man,
  'remove'      => \&call_package_man,
  'search'      => \&call_package_man,
  'upgrade'     => \&call_package_man,
  'new-config'  => \&call_package_man,
};

use constant COMMANDS_HELP => {
  'changelog'   => \&call_package_help,
  'file-search' => \&call_package_help,
  'history'     => \&call_package_help,
  'info'        => \&call_package_help,
  'install'     => \&call_package_help,
  'reinstall'   => \&call_package_help,
  'remove'      => \&call_package_help,
  'search'      => \&call_package_help,
  'upgrade'     => \&call_package_help,
  'new-config'  => \&call_package_help,
};


sub call_package_man {

 pod2usage(
    -input   => __FILE__,
    -exitval => 0,
    -verbose => 2
  );

}

sub call_package_help {

  pod2usage(
    -input    => __FILE__,
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'OPTIONS' ]
  );

}


sub call_package_info {

  my ($package) = @_;

  unless ($package) {
    print "Usage: slackman info PACKAGE\n";
    exit(255);
  }

  _check_last_metadata_update();

  $package =~ s/\*/%/g;

  my $installed_rows = $dbh->selectall_hashref('SELECT * FROM history WHERE name LIKE ? AND status = "installed"',
    'id', undef, parse_module_name($package)
  );

  my @packages_installed;

  print "\nInstalled package(s)\n";
  print sprintf("%s\n\n", "-"x80);

  foreach (keys %$installed_rows) {

    my $row = $installed_rows->{$_};
    my $description = $row->{description};

    push @packages_installed, $row->{name};

    my $pkg_dependency = $dbh->selectrow_hashref('SELECT * FROM packages WHERE package LIKE ?', undef, $row->{'package'}.'%');

    my @rows = ();

    push(@rows, [ 'Name',          $row->{name} ]);
    push(@rows, [ 'Arch',          $row->{arch} ]);
    push(@rows, [ 'Tag',           $row->{tag} ]) if ($row->{tag});
    push(@rows, [ 'Version',       $row->{version} ]);
    push(@rows, [ 'Size',          filesize_h(($row->{size_uncompressed} * 1024), 1) ]);
    push(@rows, [ 'Download Size', filesize_h(($row->{size_compressed}   * 1024), 1) ]);
    push(@rows, [ 'Require',       $pkg_dependency->{'required'} ]) if ($pkg_dependency->{'required'});

    my $skip_summary_column = 0;

    LINE: foreach my $line ( split(/\n/, $description ) ) {
      push(@rows, [ (($skip_summary_column++) ? '' : 'Summary'), trim($line) ]);
    }

    push(@rows, [ '', '' ]);

    if ($slackman_opts->{'show-files'}) {

      my $skip_first_column = 0;

      my $package_meta = package_metadata(file_read("/var/log/packages/".$row->{'package'}));

      foreach (@{$package_meta->{'file_list'}}) {
        next if (/^(install|\.\/)/);
        my $file = $_;
           $file = "/$file" unless ($file =~ /^\//);
        push(@rows, [ (($skip_first_column++) ? '' : 'File list'), $file ]);
      }

    }

    print table({
      'rows'      => \@rows,
      'separator' => { 'column' => ' : ' },
      'widths'    => [ undef, 1 ],
    });

    print sprintf("\n%s\n\n", "-"x80);

  }

  print "No installed packages found\n" unless (scalar keys %$installed_rows);

  my $available_query = sprintf('SELECT * FROM packages WHERE name LIKE ? AND name NOT IN (%s) AND repository NOT IN (%s)',
    '"' . join('","', @packages_installed) . '"',
    '"' . join('","', get_disabled_repositories()) . '"');
  my $available_rows  = $dbh->selectall_hashref($available_query, 'id', undef, $package);

  print "\n\n";

  print "Available package(s)\n";
  print sprintf("%s\n\n", "-"x80);

  foreach (keys %$available_rows) {

    my $row = $available_rows->{$_};
    my $description = $row->{description};

    my @rows = ();

    push(@rows, [ 'Name',          $row->{name} ]);
    push(@rows, [ 'Arch',          $row->{arch} ]);
    push(@rows, [ 'Tag',           $row->{tag} ])      if ($row->{tag});
    push(@rows, [ 'Category',      $row->{category} ]) if ($row->{category});
    push(@rows, [ 'Version',       $row->{version} ]);
    push(@rows, [ 'Size',          filesize_h(($row->{size_uncompressed} * 1024), 1) ]);
    push(@rows, [ 'Download Size', filesize_h(($row->{size_compressed}   * 1024), 1) ]);
    push(@rows, [ 'Require',       $row->{required} ]) if ($row->{required});
    push(@rows, [ 'Repo',          $row->{repository} ]);

    my $skip_summary_column = 0;

    LINE: foreach my $line ( split(/\n/, $description ) ) {
      push(@rows, [ (($skip_summary_column++) ? '' : 'Summary'), trim($line) ]);
    }

    push(@rows, [ '', '' ]);

    if ($slackman_opts->{'show-files'}) {

      my $sth = $dbh->prepare('SELECT * FROM manifest WHERE package = ? ORDER BY files');
      $sth->execute($row->{'package'});

      my $row = $sth->fetchrow_hashref();

      my $skip_first_column = 0;

      foreach ( split(/\n/, $row->{'files'}) ) {
        my $file = $_;
           $file = "/$file" unless ($file =~ /^\//);
        push(@rows, [ (($skip_first_column++) ? '' : 'File list'), $file ]);
      }

    }

    print table({
      'rows'      => \@rows,
      'separator' => { 'column' => ' : ' },
      'widths'    => [ undef, 1 ],
    });

    print sprintf("\n%s\n\n", "-"x80);

  }

  print "No packages available found\n\n" unless (scalar keys %$available_rows);

  exit(0);

}

sub call_package_reinstall {

  my (@packages) = @_;

  _check_package_duplicates();

  my @is_installed = ();

  my @packages_to_downloads = ();
  my @packages_for_pkgtool  = ();
  my $packages_errors       = {};

  if ($slackman_opts->{'category'}) {

    my $packages_ref = $dbh->selectall_hashref('SELECT name FROM packages WHERE category = ?', 'name', undef, $slackman_opts->{'category'});

    @packages = sort keys %$packages_ref;

  }

  unless (@packages) {
    print "Usage: slackman reinstall PACKAGE [...]\n";
    exit(255);
  }

  _check_last_metadata_update();

  my @table1 = ();

  foreach (@packages) {

    my $pkg = package_info($_);

    if ($pkg) {
      push(@is_installed, $pkg);
      push(@table1, [ $_, $pkg->{'version'} . '-' . $pkg->{'build'}, $pkg->{'tag'}, $pkg->{'timestamp'} ]);
    } else {
      push(@table1, [ $_, 'not installed' ]);
    }

  }

  print "\nReinstall package(s)\n\n";

  print table({
    'rows'      => \@table1,
    'separator' => { 'column' => '    ', 'header' => '-' },
    'headers'   => [ 'Name', 'Version', 'Tag', 'Installed' ],
  });

  exit(0) unless(@is_installed);

  print "\n\n";

  my @filters = ();
  my @filter_packages = ();

  push(@filter_packages, sprintf('( name IN ("%s"))',   join('", "', map { $_->{'name'} } @is_installed)));
  push(@filter_packages, sprintf('( category = "%s" )', $slackman_opts->{'category'})), if ($slackman_opts->{'category'});

  push(@filters, sprintf('( %s )', join(' AND ', @filter_packages)));

  # Filter repository
  push(@filters, repo_option_to_sql());

  my $query = 'SELECT * FROM packages WHERE ' . join(' AND ', @filters);
  my $rows  = $dbh->selectall_hashref($query, 'id', undef);

  if ($slackman_opts->{'category'}) {

    my @table_category = ();

    foreach (keys %{$rows}) {
      my $row = $rows->{$_};
      push(@table_category, [ $row->{'name'}, $row->{'version'} . '-' . $row->{'build'}, $row->{'tag'}, $row->{'repository'} ]);
    }

    print "\nCategory Package(s)\n\n";

    print table({
      'rows'      => \@table_category,
      'separator' => { 'column' => '    ', 'header' => '-' },
      'headers'   => [ 'Name', 'Version', 'Tag', 'Repository' ],
    });

    print "\n";

    exit(0) unless(confirm("Are you sure? [Y/N]"));

    @packages_to_downloads = values(%$rows);

  } else {

    my @table_found_packages = ();
    my $pkg_id   = 0;
    my @packages = ();

    foreach (keys %{$rows}) {

      my $row = $rows->{$_};
      push(@packages, $row);

      push(@table_found_packages, [ ++$pkg_id, $row->{'name'}, $row->{'version'} . '-' . $row->{'build'}, $row->{'tag'}, $row->{'repository'} ]);

    }

    print "\nFound Package(s)\n\n";

    print table({
      'rows'      => \@table_found_packages,
      'separator' => { 'column' => '    ', 'header' => '-' },
      'headers'   => [ '#', 'Name', 'Version', 'Tag', 'Repository' ],
    });

    print "\n";

    my $pkg_id_regex = "([1-$pkg_id])";
    my $choice = confirm_choice("Select package number [1-$pkg_id] ?", qr/$pkg_id_regex/);

    @packages_to_downloads = $packages[$choice-1];

  }

  exit(0) unless (@packages_to_downloads);

  print "\n\n";
  print "Download package(s)\n\n";
  print sprintf("%s\n", "-"x80);

  _packages_download(\@packages_to_downloads, \@packages_for_pkgtool, $packages_errors);

  exit(0) if ($slackman_opts->{'download-only'});

  if (@packages_for_pkgtool) {

    print "\n\n";
    print "Reinstall package(s)\n\n";
    print sprintf("%s\n", "-"x80);

    foreach my $package_path (@packages_for_pkgtool) {

      package_upgrade($package_path);

    }

  }

  _packages_errors($packages_errors);

  exit(0);

}

sub call_package_remove {

  my (@packages) = @_;

  if ( ! @packages && ! $slackman_opts->{'obsolete-packages'} && ! $slackman_opts->{'category'} ) {
    print "Usage: slackman remove PACKAGE\n";
    exit(1);
  }

  _check_package_duplicates();

  my @is_installed = ();

  if ($slackman_opts->{'obsolete-packages'}) {

    # Get list from "slackman list obsoletes" command
    @is_installed = Slackware::SlackMan::Command::List::call_list_obsoletes();

  } else {

    if ($slackman_opts->{'category'}) {

      my $packages_ref = $dbh->selectall_hashref('SELECT name FROM packages WHERE category = ?', 'name', undef, $slackman_opts->{'category'});

      @packages = sort keys %$packages_ref;

    }

    print "Remove package(s)\n\n";

    my @rows = ();

    foreach (@packages) {

      if ($_ =~ /^(aaa\_(base|elflibs|terminfo)|slackman)$/) {
        push(@rows, [ $_, colored('Don\'t remove this package', 'RED') ]);
      } else {

        my $pkg = package_info($_);

        if ($pkg) {
          push(@rows , [ $_, "$pkg->{version}-$pkg->{build}", $pkg->{'tag'}, $pkg->{'timestamp'} ]);
          push(@is_installed, $_);
        } else {
          push(@rows, [ $_, colored('Not installed', 'RED') ]);
        }

      }

    }

    print table({
      'rows'      => \@rows,
      'separator' => { 'column' => '    ', 'header' => '-' },
      'headers'   => [ 'Package', 'Version', 'Tag', 'Installed' ],
    });

    print "\n\n";

  }

  exit(0) unless(@is_installed);
  exit(0) if ($slackman_opts->{'no'});

  unless ($slackman_opts->{'yes'}) {
    exit(0) unless(confirm("Are you sure? [Y/N]"));
  }

  foreach my $package_path (@is_installed) {

    package_remove($package_path);

  }

  # Send the list of removed packages via D-Bus
  dbus_slackman->Notify( 'PackageRemoved', undef, join(',', @is_installed) ) if (@is_installed);

  exit(0);

}

sub call_package_install {

  my (@install_packages) = @_;

  if (   ! @install_packages
      && ! $slackman_opts->{'repo'}
      && ! $slackman_opts->{'category'}
      && ! $slackman_opts->{'new-packages'}) {

    print "Usage: slackman install PACKAGE\n";
    exit(255);

  }

  _check_last_metadata_update();
  _check_package_duplicates();

  my $packages_to_install   = {};
  my @packages_to_downloads = ();
  my @packages_for_pkgtool  = ();
  my $packages_errors       = {};
  my $dependency_pkgs       = {};

  my $total_compressed_size   = 0;
  my $total_uncompressed_size = 0;

  foreach my $package (@install_packages) {

    # Detect local install package and create on-the-fly a fake repository metadata for local package
    if ($slackman_opts->{'local'}) {

      unless ( -e $package ) {
        print sprintf("%s package not found!\n", colored($package, 'bold'));
        exit(1);
      }

      unless ( $package =~ /\.(txz|tgz|tbz|tlz)$/) {
        print sprintf("%s is not Slackware package!\n", colored($package, 'bold'));
        exit(1);
      }

      my $pkg_meta = get_package_info(basename($package));

      $pkg_meta->{'repository'}      = '(local)';
      $pkg_meta->{'size_compressed'} = ((stat($package))[7] / 1024);

      $packages_to_install->{$pkg_meta->{'name'}} = $pkg_meta;

      if (package_info($pkg_meta->{'name'})) {
        print sprintf("%s package is already installed!\n", colored($package, 'bold'));
        exit(1);
      }

    }

    if (package_info($package)) {
      print sprintf("%s package is already installed!\n", colored($package, 'bold'));
      exit(1);
    }

  }

  STDOUT->printflush('Search packages... ');

  update_all_repo_data();

  unless ($slackman_opts->{'local'}) {
    ($packages_to_install, $dependency_pkgs) = package_check_install(@install_packages);
  }

  STDOUT->printflush(colored("done\n\n", 'green'));

  if (scalar keys %$packages_to_install) {

    print "Package(s) to install\n\n";

    my @rows = ();

    foreach (sort keys %$packages_to_install) {

      my $pkg = $packages_to_install->{$_};

      $total_uncompressed_size += $pkg->{size_uncompressed};
      $total_compressed_size   += $pkg->{size_compressed};

      push(@rows, [
        $pkg->{name}, $pkg->{arch}, $pkg->{version},
        $pkg->{repository}, filesize_h(($pkg->{size_compressed} * 1024), 1, 1)
      ]);

      push(@packages_to_downloads, $pkg);

    }

    print table({
      'rows'      => \@rows,
      'separator' => { 'column' => '    ', 'header' => '-' },
      'headers'   => [ 'Name', 'Arch', 'Version', 'Repository', 'Size' ],
    });

  }

  if (scalar keys %$dependency_pkgs) {

    print "\n\n";
    print "Required package(s) to install\n\n";

    my @rows = ();

    foreach (sort keys %$dependency_pkgs) {

      my $pkg       = $dependency_pkgs->{$_};
      my $needed_by = join(',', @{$pkg->{needed_by}});

      $total_uncompressed_size += $pkg->{size_uncompressed};
      $total_compressed_size   += $pkg->{size_compressed};

      push(@rows, [
        $pkg->{name}, $pkg->{arch}, $pkg->{version}, $needed_by,
        $pkg->{repository}, filesize_h(($pkg->{size_compressed} * 1024), 1, 1)
      ]);

      push(@packages_to_downloads, $pkg);
    }

    print table({
      'rows'      => \@rows,
      'separator' => { 'column' => '    ', 'header' => '-' },
      'headers'   => [ 'Name', 'Arch', 'Version', 'Needed by', 'Repository', 'Size' ],
    });

  }

  unless (scalar keys %$packages_to_install) {
    print "Package not found!\n";
    exit(0);
  }

  print "\n\n";
  print "Install summary\n";
  print sprintf("%s\n", "-"x40);
  print sprintf("%-20s %s package(s)\n", 'Install', scalar @packages_to_downloads);

  print sprintf("%-20s %s\n", 'Download size',   filesize_h(($total_compressed_size   * 1024)));
  print sprintf("%-20s %s\n", 'Installed size',  filesize_h(($total_uncompressed_size * 1024)));
  print "\n\n";

  exit(0) if     ($slackman_opts->{'no'} || $slackman_opts->{'summary'});
  exit(0) unless (@packages_to_downloads);

  unless ($slackman_opts->{'yes'} || $slackman_opts->{'download-only'}) {

    my $choice = confirm_choice("Install selected packages? [Y/N/d]", qr/(Y|N|D)/i);

    exit(0) unless ($choice);
    exit(0)     if ($choice eq 'N');

    $slackman_opts->{'download-only'} = 1 if ($choice eq 'D');

  }


  if ($slackman_opts->{'local'}) {
    @packages_for_pkgtool = @install_packages;

  } else {

    print "\n\n";
    print "Download package(s)\n";
    print sprintf("%s\n\n", "-"x80);

    _packages_download(\@packages_to_downloads, \@packages_for_pkgtool, $packages_errors);

    exit(0) if ($slackman_opts->{'download-only'});

  }

  if (@packages_for_pkgtool) {

    print "\n\n";
    print "Install package(s)\n";
    print sprintf("%s\n\n", "-"x80);

    foreach my $package_path (@packages_for_pkgtool) {

      package_install($package_path);

    }

  }

  _packages_errors($packages_errors);
  _packages_installed(\@packages_for_pkgtool);

  # Send the list of installed packages via D-Bus
  dbus_slackman->Notify( 'PackageInstalled', undef, join(',', @packages_for_pkgtool) ) if (@packages_for_pkgtool);

  exit(0);

}

sub call_package_search {

  my ($search) = @_;

  unless ($search) {
    print "Usage: slackman search PATTERN\n";
    exit(255);
  }

  $search = parse_module_name($search);

  _check_last_metadata_update();

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
                      AND p1.repository IN (%s)
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

  # Query only enabled repository
  $query = sprintf($query, '"' . join('","', get_enabled_repositories()) . '"');

  my $sth = $dbh->prepare($query);
  $sth->execute($search, $search, $search, $search);

  my $n_rows = 0;
  my @rows   = ();

  while (my $row = $sth->fetchrow_hashref()) {

    $n_rows++;

    my $name    = $row->{'name'};
    my $summary = $row->{'summary'};

    $summary =~ s/^$name//;
    $summary =~ s/^\s+//;

    push(@rows , [
      "$name $summary",
      $row->{'version'},
      $row->{'arch'},
      colored(sprintf('%-10s', $row->{'status'} ||' '), 'green'),
      $row->{'repository'}
    ]);

  }

  if ($n_rows > 0) {

    print table({
      'rows'      => \@rows,
      'separator' => { 'column' => '    ', 'header' => '-' },
      'headers'   => [ 'Name', 'Version', 'Arch', 'Status', 'Repository' ],
      'widths'    => [ 0, 0, 0, 10, 0 ]
    });

  }


  unless ($n_rows) {
    print "Package not found!\n";
    exit(255);
  }

  exit(0);

}

sub call_package_history {

  # FIXME Packages installed and removed but not upgraded and reinstalled

  my ($package) = @_;

  unless ($package) {
    print "Usage: slackman history PACKAGE\n";
    exit(255);
  }

  my $rows_ref = $dbh->selectall_hashref('SELECT * FROM history WHERE name = ? ORDER BY timestamp', 'timestamp', undef, $package);
  my $row_nums = scalar keys %$rows_ref;

  unless ($row_nums) {
    print "Package $package not found!\n";
    exit 1;
  }

  my @table = ();

  print sprintf("History of @{[ BOLD ]}%s@{[ RESET ]} package:\n\n", $package);

  my $prev_version   = '';
  my $prev_status    = '';
  my $status_history = '';

  foreach (sort keys %$rows_ref) {

    my $row       = $rows_ref->{$_};
    my $status    = $row->{'status'};
    my $version   = $row->{'version'} . '-' . $row->{'build'};
    my $timestamp = $row->{'timestamp'};
    my $upgraded  = $row->{'upgraded'};
    my $tag       = $row->{'tag'};

    $status_history = $status;
    $status_history = 'upgraded'       if ($status eq 'installed');
    $status_history = 'installed'      if (! $prev_status);
    $status_history = $row->{'status'} if ($row_nums == 1);
    $status_history = 'installed'      if ($prev_status eq 'removed');
    $prev_version   = ''               if ($status_history eq 'removed');
    $prev_version   = ''               if ($status_history eq 'installed');

    push(@table, [ $status_history, $version, $tag, $timestamp, $prev_version, $upgraded ]);

    $prev_version = $version;
    $prev_status  = $status;

  }

  print table({
    'rows'      => \@table,
    'separator' => { 'column' => '    ', 'header' => '-' },
    'headers'   => [ 'Status', 'Version', 'Tag', 'Timestamp', 'Previous', 'Upgraded' ],
  });

  print "\n";

  exit(0);

}

sub call_package_upgrade {

  my (@update_packages) = @_;

  _check_last_metadata_update();
  _check_package_duplicates();

  my $packages_to_update    = {};  # Updatable packages list
  my $packages_to_install   = {};  # Required packages to install
  my @packages_to_downloads = ();  # Download packages list
  my @packages_for_pkgtool  = ();  # Packages for upgradepkg command
  my $packages_errors       = {};  # Download, checksum & gpg verify errors
  my $kernel_upgrade        = 0;   # Check Kernel Upgrade

  my $total_compressed_size   = 0;
  my $total_uncompressed_size = 0;

  foreach my $package (@update_packages) {

    # Detect local install package and create on-the-fly a fake repository metadata for local package
    if ($slackman_opts->{'local'}) {

      unless ( -e $package ) {
        print sprintf("%s package not found!\n", colored($package, 'bold'));
        exit(1);
      }

      unless ( $package =~ /\.(txz|tgz|tbz|tlz)$/) {
        print sprintf("%s is not Slackware package!\n", colored($package, 'bold'));
        exit(1);
      }

      my $pkg_meta = get_package_info(basename($package));
      my $old_meta = package_info($pkg_meta->{'name'});

      $pkg_meta->{'repository'}        = '(local)';
      $pkg_meta->{'size_compressed'}   = ((stat($package))[7] / 1024);
      $pkg_meta->{'new_version_build'} = sprintf('%s-%s', $pkg_meta->{'version'}, $pkg_meta->{'build'});
      $pkg_meta->{'old_version_build'} = sprintf('%s-%s', $old_meta->{'version'}, $old_meta->{'build'});

      $pkg_meta->{'old_name'} = $pkg_meta->{'name'};
      $pkg_meta->{'new_name'} = $pkg_meta->{'name'};

      next if ( versioncmp($pkg_meta->{'old_version_build'}, $pkg_meta->{'new_version_build'}) >= 0);

      $packages_to_update->{$pkg_meta->{'name'}} = $pkg_meta;

      unless( package_info($pkg_meta->{'name'}) ) {
        print sprintf("%s package not installed!\n", colored($package, 'bold'));
        exit(1);
      }

    } else {

      if ( $package !~ /\*/ && ! package_info($package) ) {
        print sprintf("%s package not installed!\n", colored($package, 'bold'));
        exit(1);
      }

    }

  }

  STDOUT->printflush('Search upgraded packages... ');

  update_all_repo_data();

  unless ($slackman_opts->{'local'}) {
    ($packages_to_update, $packages_to_install) = package_check_updates(@update_packages);
  }

  STDOUT->printflush(colored("done\n\n", 'green'));

  if (scalar keys %$packages_to_update) {

    print "Package(s) to upgrade\n\n";

    my @rows = ();

    foreach (sort keys %$packages_to_update) {

      my $pkg = $packages_to_update->{$_};

      my $pkg_name       = $pkg->{'name'};
      my $pkg_arch       = $pkg->{'arch'};
      my $pkg_version    = sprintf("%s -> %s", $pkg->{'old_version_build'},$pkg->{'new_version_build'});
      my $pkg_repository = $pkg->{'repository'};
      my $pkg_size       = filesize_h(($pkg->{'size_compressed'} * 1024), 1, 1);

      # Detect renamed package name
      if ($pkg->{'new_name'} ne $pkg->{'old_name'}) {
        $pkg_name = sprintf("%s -> %s", $pkg->{'old_name'}, $pkg->{'new_name'});
      }

      $total_uncompressed_size += $pkg->{'size_uncompressed'};
      $total_compressed_size   += $pkg->{'size_compressed'};

      push(@rows, [ $pkg_name, $pkg_arch, $pkg_version, $pkg_repository, $pkg_size ]);

      push(@packages_to_downloads, $pkg);

    }

    print table({
      'rows'      => \@rows,
      'separator' => { 'column' => '    ', 'header' => '-' },
      'headers'   => [ 'Name', 'Arch', 'Version', 'Repository', 'Size' ],
    });

  }

  if (scalar keys %$packages_to_install) {

    print "\n\n";
    print "Required package(s) to install\n\n";

    my @rows = ();

    foreach (sort keys %$packages_to_install) {

      my $pkg       = $packages_to_install->{$_};
      my $needed_by = join(',', @{$pkg->{needed_by}});

      $total_uncompressed_size += $pkg->{size_uncompressed};
      $total_compressed_size   += $pkg->{size_compressed};

      push(@rows, [
        $pkg->{name}, $pkg->{arch}, $pkg->{version}, $needed_by,
        $pkg->{repository}, filesize_h(($pkg->{size_uncompressed} * 1024), 1, 1)
      ]);

      push(@packages_to_downloads, $pkg);

    }

    print table({
      'rows'      => \@rows,
      'separator' => { 'column' => '    ', 'header' => '-' },
      'headers'   => [ 'Name', 'Arch', 'Version', 'Needed by', 'Repository', 'Size' ],
    });


  }

  unless (scalar keys %$packages_to_update) {
    print "Already up-to-date!\n";
    exit(0);
  }

  print "\n\n";
  print "Upgrade summary\n";
  print sprintf("%s\n", "-"x40);
  print sprintf("%-20s %s package(s)\n", 'Install', scalar keys %$packages_to_install) if (scalar keys %$packages_to_install);
  print sprintf("%-20s %s package(s)\n", 'Update',  scalar keys %$packages_to_update);

  print sprintf("%-20s %s\n", 'Download size',   filesize_h(($total_compressed_size   * 1024), 1));
  print sprintf("%-20s %s\n", 'Installed size',  filesize_h(($total_uncompressed_size * 1024), 1));
  print "\n\n";

  exit(0) if ($slackman_opts->{'no'} || $slackman_opts->{'summary'});


  unless ($slackman_opts->{'yes'} || $slackman_opts->{'download-only'}) {

    my $choice = confirm_choice("Perform upgrade of selected packages? [Y/N/d]", qr/(Y|N|D)/i);

    exit(0) unless ($choice);
    exit(0)     if ($choice eq 'N');

    $slackman_opts->{'download-only'} = 1 if ($choice eq 'D');

  }

  if ($slackman_opts->{'local'}) {
    @packages_for_pkgtool = @update_packages;

  } else {

    print "\n\n";
    print "Download package(s)\n";
    print sprintf("%s\n\n", "-"x80);

    _packages_download(\@packages_to_downloads, \@packages_for_pkgtool, $packages_errors);

    exit(0) if ($slackman_opts->{'download-only'});

  }

  if (@packages_for_pkgtool) {

    print "\n\n";
    print "Upgrade package(s)\n";
    print sprintf("%s\n\n", "-"x80);

    foreach my $package_path (@packages_for_pkgtool) {

      $kernel_upgrade = 1 if ($package_path =~ /kernel-(modules|generic|huge)/);

      package_upgrade($package_path);

    }

  }

  # Display packages error list
  _packages_errors($packages_errors);

  # Display packages upgraded
  _packages_upgraded(\@packages_for_pkgtool);

  # Display Kernel Update message
  _kernel_update_message() if ($kernel_upgrade);

  # Send the list of upgraded packages via D-Bus
  dbus_slackman->Notify( 'PackageUpgraded', undef, join(',', @packages_for_pkgtool) ) if (@packages_for_pkgtool);

  # Search new configuration files (same as 'slackman new-config' command)
  call_package_new_config() if (@packages_for_pkgtool);

  exit(0);

}


sub call_package_file_search {

  my ($file) = @_;

  unless($file) {
    print "Usage: slackman file-search FILE\n";
    exit(1);
  }

  _check_last_metadata_update();

  my $rows = package_search_files($file);

  foreach my $row ( @{$rows} ) {

    my @files = split(/\n/, $row->{'files'});

    foreach my $path (@files) {
      if ( $path =~ /$file$/ ) {
        print sprintf("%-50s: %s (%s)\n", $path, $row->{'package'}, $row->{'repository'});
      }
    }

  }

  exit(0);

}


sub _changelog_announces {

  my $announces = package_changelog_announces();

  foreach my $row ( @{$announces} ) {

    print sprintf("%s (%s)\n\n%s\n\n\n",
      $row->{'timestamp'},
      colored($row->{'repository'}, 'BOLD'),
      wrap("  ", "  ", $row->{'announce'})
    );

  }

}


sub call_package_changelog {

  my ($package) = @_;
  my $changelogs = package_changelogs($package);

  unless ( @{$changelogs} ) {
    print "No Changelog!\n\n";
    exit(1);
  }

  if ($slackman_opts->{'announces'}) {
    _changelog_announces();
    exit(0);
  }

  unless ($slackman_opts->{'details'}) {

    my @rows = ();

    foreach my $row ( @{$changelogs} ) {

      push(@rows, [
        ($row->{'package'}      || ''),
        ($row->{'version'}      || ''),
        ($row->{'status'}       || ''),
        ($row->{'timestamp'}    || ''),
        ($row->{'repository'}   || ''),
        ($row->{'security_fix'} ? colored('!', 'RED') : ''),
      ]);

    }

    print table({
      'rows'      => \@rows,
      'separator' => { 'column' => '   ', 'header' => '-' },
      'headers'   => [ 'Package', 'Version', 'Status', 'Timestamp', 'Repository', '' ],
      'widths'    => [ 0, 0, 0, 0, 0, 1 ]
    });

    exit(0);

  }

  if ($slackman_opts->{'details'}) {

    foreach my $row (@{$changelogs}) {

      my $description = $row->{'description'};
         $description =~ s/\(\* Security fix \*\)/colored("(* Security fix *)", 'red')/ge if $row->{'security_fix'};

      print sprintf("%s (%s)\n%s:  %s\n%s\n\n",
        $row->{'timestamp'},
        $row->{'repository'},
        colored($row->{'package'}, 'bold'),
        ucfirst($row->{'status'}),
        (($description) ? wrap("  ", "  ", $description) . "\n" : '')
      );
    }

  }

}


sub call_package_new_config {

  my @new_config_files = ();

  my $etc_directory = '/etc';

  if (defined($ENV{ROOT})) {
    $etc_directory = $ENV{ROOT} . '/etc';
  }

  STDOUT->printflush("Search for new configuration files... ");

  # Find .new files in /etc directory excluding files listed in Slackware UPGRADE.TXT doc:
  #
  #  * /etc/rc.d/rc.inet1.conf.new
  #  * /etc/rc.d/rc.local.new
  #  * /etc/group.new
  #  * /etc/passwd.new
  #  * /etc/shadow.new
  #  * /etc/gshadow.new
  #

  find({
    no_chdir   => 1,
    wanted     => sub { push(@new_config_files, $_) if /\.new$/ },
    preprocess => sub { grep( !/(rc.local|rc.inet1.conf|group|passwd|shadow|gshadow)\.new/, @_) }
  }, $etc_directory );

  unless (@new_config_files) {
    print "no files found!\n\n";
    exit(0);
  }

  print "done!\n\n";

  foreach my $new_config_file (@new_config_files) {

    my $manifest = package_search_files($new_config_file);
    my $package  = '';

    if (defined($manifest->[0]->{'package'})) {
      $package = "(" . $manifest->[0]->{'package'} . ")";
    }

    print sprintf("  %-50s %s\n", $new_config_file, $package);

  }

  print "\n\n";

  print "Actions:\n\n"
        . sprintf("\t%seep the old files and consider .new files later\n",
            colored('K', 'bold'))
        . sprintf("\t%sverwrite all old files with the new ones. The old files will be stored with the suffix .orig\n",
            colored('O', 'bold'))
        . sprintf("\t%semove all .new files\n",
            colored('R', 'bold'))
        . sprintf("\t%srompt K, O, R selection for every single file\n\n",
            colored('P', 'bold'));

  my $choice = confirm_choice("What do you want [K/O/R/P] ?", qr/(K|O|R|P)/i);

  if ($choice eq 'K') {
    print "Edit and merge this configuration files manually or check later!\n\n";
    exit(0);
  }

  _new_config_files_delete(\@new_config_files)    if ($choice eq 'R');
  _new_config_files_overwrite(\@new_config_files) if ($choice eq 'O');
  _new_config_files_manual(\@new_config_files)    if ($choice eq 'P');

  print "\n\n";

}

sub _new_config_files_manual {

  my ($new_config_files) = @_;
  _new_config_file_manual($_) foreach(@$new_config_files);

}


sub _new_config_files_delete {

  my ($new_config_files) = @_;

  if (confirm('Are you sure [Y/N] ?')) {
    foreach my $file (@$new_config_files) {
      logger->debug("Delete new config file $file");
      unlink($file);
    }
  }

}


sub _new_config_files_overwrite {

  my ($new_config_files) = @_;

  if (confirm('Are you sure [Y/N] ?')) {

    print "Overwrite configuration with new configuration files\n";

    foreach my $new_config_file (@$new_config_files) {

      my $file = basename($new_config_file, '.new');
      my $path = dirname($new_config_file);

      my $config_file = "$path/$file";

      move($config_file, "$config_file.orig");
      logger->debug("Configuration file renamed from $config_file to $config_file.orig");

      move($new_config_file, $config_file);
      logger->debug("Configuration file renamed from $new_config_file to $config_file");

    }

  }


}


sub _new_config_file_manual {

  my ($new_config_file) = @_;

  print "\n\n$new_config_file\n";

  my $answer = sprintf("What do you want [%seep/%sverwrite/%semove/%siff/%serge] ?", 
                        colored('K', 'bold'),
                        colored('O', 'bold'),
                        colored('R', 'bold'),
                        colored('D', 'bold'),
                        colored('M', 'bold')
                      );

  my $choice = confirm_choice($answer, qr/(K|O|R|D|M)/i);

  my $file = basename($new_config_file, '.new');
  my $path = dirname($new_config_file);
  my $config_file = "$path/$file";

  # Display diff(1) command output
  #
  if ($choice eq 'D') {

    system("diff -u $config_file $new_config_file | more");
    _new_config_file_manual($new_config_file);

  }

  # Overwrite new with old configuration file
  #
  if ($choice eq 'O') {

    move($config_file, "$config_file.orig");
    logger->debug("Configuration file renamed from $config_file to $config_file.orig");

    move($new_config_file, $config_file);
    logger->debug("Configuration file renamed from $new_config_file to $config_file");
  }

  # Delete new configuration file
  #
  if ($choice eq 'R') {
    if (confirm('Are you sure [Y/N] ?')) {
      unlink($new_config_file);
      logger->debug("Deleted new configuration file $new_config_file");
    }
  }

  # Merge file using git-merge-file(1)
  #
  if ($choice eq 'M') {

    system("git merge-file -p $config_file $config_file $new_config_file > $config_file.merged");

    if ($? > 0) {
      print "Merge failed! Manually check new and old configuration file.";
    } else {
      copy("$config_file", "$config_file.orig");
      copy("$config_file.merged", $config_file);
      unlink($new_config_file);
      logger->debug("New configuration file merged into $config_file");
    }

    unlink("$config_file.merged");

  }

}


sub _packages_download {

  my ($packages_to_downloads, $packages_for_pkgtool, $packages_errors) = @_;

  return 1 unless(@$packages_to_downloads);

  my $num_downloads   = scalar @$packages_to_downloads;
  my $count_downloads = 0;

  foreach my $pkg (@$packages_to_downloads) {

    $count_downloads++;

    print sprintf("%-72s %s\r", $pkg->{'package'}, filesize_h(($pkg->{'size_compressed'} * 1024), 1));

    my ($package_path, $package_errors) = package_download($pkg);

    print "\n";

    if (scalar @$package_errors) {
      $packages_errors->{$pkg->{'package'}} = $package_errors;
    }

    if (-e $package_path) {
      push(@$packages_for_pkgtool, $package_path);
    }

  }

}

sub _packages_upgraded {

  my ($packages) = @_;

  return 1 unless(@$packages);

  print "\n\n";
  print sprintf("%s Package(s) upgraded\n", colored('SUCCESS', 'green bold'));
  print sprintf("%s\n\n", "-"x80);

  foreach (@$packages) {

    my $pkg = get_package_info(basename($_));

    print sprintf("  %s upgraded to %s version\n",
      colored($pkg->{'name'}, 'bold'),
      colored($pkg->{'version'}, 'bold')
    );

  }

  print "\n\n";

}

sub _packages_installed {

  my ($packages) = @_;

  return 1 unless(@$packages);

  print "\n\n";
  print sprintf("%s Package(s) installed\n", colored('SUCCESS', 'green bold'));
  print sprintf("%s\n\n", "-"x80);

  foreach (@$packages) {
    my $pkg = get_package_info(basename($_));
    print sprintf("  installed %s %s version\n",
      colored($pkg->{'name'}, 'bold'),
      colored($pkg->{'version'}, 'bold')
    );
  }

  print "\n\n";

}

sub _packages_errors {

  my ($packages_errors) = @_;

  return 1 unless(scalar keys %$packages_errors);

  print "\n\n";
  print sprintf("%s Problems during package integrity check or download\n", colored('WARNING', 'yellow bold'));
  print sprintf("%s\n\n", "-"x80);

  foreach my $pkg (keys %$packages_errors) {
    print sprintf("  %-50s %s\n", $pkg, join(', ', @{$packages_errors->{$pkg}}));
  }

  print "\n\n";

}


sub _kernel_update_message {

  # Detect the EFI System Partition (ESP)
  my $efi_partition = qx{ mount | grep vfat | grep efi };

  # lilo is default command on x86 arch or machine can't have UEFI bios (generally x86_64 arch)
  my $lilo_command  = 'lilo';
     $lilo_command  = 'eliloconfig' if ($efi_partition);

  # Follow vmlinuz file symlink
  my $vmlinuz_file  = readlink('/boot/vmlinuz');

  my ($vmlinux, $kernel_type, $kernel_version) = split(/-/, $vmlinuz_file);

  my $message = "@{[ BLINK BOLD RED ]}Linux kernel upgrade detected !@{[ RESET ]}\n\n"
              . "Before the reboot, remember to ";

  $message .= "recreate a new @{[ BOLD ]}initrd@{[ RESET ]} file and " if (-e '/boot/initrd.gz');
  $message .= "reinstall the new kernel ";
  $message .= "in your EFI System Partition " if ($efi_partition);
  $message .= "with @{[ BOLD ]}$lilo_command@{[ RESET ]} command.\n\n";

  $message .= "For more information read:\n\n"
           .  "  - /boot/README.initrd\n"
           .  "  - mkinitrd(8)\n\n";

  print "\n";
  print wrap("", "\t", $message);
  print "\n\n";

  # Update the initrd file
  _create_initrd($kernel_version) if (-e '/boot/initrd.gz');
  print "\n";

  # Install the kernel via lilo or eliloconfig command
  _install_kernel($lilo_command);
  print "\n";

}

sub _install_kernel {

  my ($lilo_command) = @_;

  if (confirm("Do you want execute @{[ BOLD ]}$lilo_command@{[ RESET ]} command now [Y/N] ?")) {

    $lilo_command .= " -v" if ($lilo_command eq 'lilo');
    system("$lilo_command");

    print "\n\n";

  }

}

sub _create_initrd {

  my ($kernel_version) = @_;

  if (confirm("Do you want recreate a new initrd file now [Y/N] ?")) {

    my $mkinitrd_command_generator_cmd = "/usr/share/mkinitrd/mkinitrd_command_generator.sh -k $kernel_version";

    print "Running @{[ BOLD ]}mkinitrd_command_generator@{[ RESET ]} to detect the required kernel modules for build a correct initrd file:\n\n";
    print "\t$mkinitrd_command_generator_cmd\n\n";

    my $mkinitrd_cmd = qx { sh $mkinitrd_command_generator_cmd -r };
    chomp($mkinitrd_cmd);

    print "Executing @{[ BOLD ]}mkinitrd@{[ RESET ]} command:\n\n";
    print "\t$mkinitrd_cmd\n\n";

    system("$mkinitrd_cmd");

    print "\n\n";

  }

}

sub _check_last_metadata_update {

  my $now    = time();
  my $last   = db_meta_get('last-metadata-update') || 0;
  my $offset = (60 * 60 * 24); # 24h

  if ($now-$last > $offset) {
    my $msg = sprintf("%s The last slackman update is older than 24h.\n" .
                      "Run 'slackman update' to check and fetch last update from your Slackware repository.",
                      colored('WARNING', 'yellow bold'));

    print "\n";
    print wrap("", "\t", $msg);
    print "\n\n";

  }

}


sub _check_package_duplicates {

  my $rows_ref = $dbh->selectall_hashref("SELECT name, count(*) AS num FROM history WHERE status = 'installed' GROUP BY LOWER(name) HAVING num > 1", 'name', undef);
  my $row_nums = scalar keys %$rows_ref;

  return (0) unless ($row_nums);

  print "Found duplicate package(s):\n\n";

  foreach my $pkg (keys %$rows_ref) {

    my $pkg_rows_ref = $dbh->selectall_hashref("SELECT * FROM history WHERE status = 'installed' AND name = ?", 'package', undef, $pkg);

    print "$pkg:\n";

    my $pkg_id = 0;
    my @packages;

    foreach (keys %$pkg_rows_ref) {

      my $row = $pkg_rows_ref->{$_};
      push(@packages, $row->{'package'});

      print sprintf("   %s) %-40s (%s)\n", $pkg_id++, $row->{'package'}, $row->{'timestamp'});

    }

    print "\n";

    my $pkg_id_regex = "([1-$pkg_id])";
    my $choice = confirm_choice("Do you want remove package [1-$pkg_id] ?", qr/$pkg_id_regex/);

    package_remove($packages[$choice-1]);

    print "\n\n";

  }

  return(0);

}


1;
__END__
=head1 NAME

slackman-package - Install, upgrade and display information of Slackware packages

=head1 SYNOPSIS

  slackman install PACKAGE [...]
  slackman upgrade [PACKAGE [...]]
  slackman reinstall PACKAGE [...]
  slackman remove PACKAGE [...]
  slackman history PACKAGE
  slackman info PACKAGE

  slackman changelog [PACKAGE]
  slackman search PATTERN
  slackman file-search PATTERN
  slackman new-config

=head1 DESCRIPTION

=head1 COMMANDS

  slackman install PACKAGE [...]        Install one or more packages
  slackman upgrade [PACKAGE [...]]      Upgrade installed packages
  slackman reinstall PACKAGE [...]      Reinstall one or more packages
  slackman remove PACKAGE [...]         Remove one or more packages
  slackman history PACKAGE              Display package history information
  slackman info PACKAGE                 Display information about installed or available packages

  slackman changelog [PACKAGE]          Display general or package ChangeLog
  slackman search PATTERN               Search packages using PATTERN
  slackman file-search PATTERN          Search files into packages using PATTERN
  slackman new-config                   Find new configuration files

=head1 OPTIONS

  --repo=REPOSITORY                     Use specified repo during upgrade or install packages
  -h, --help                            Display help and exit
  --man                                 Display man pages
  --version                             Display version information
  -c, --config=FILE                     Configuration file
  --root                                Set Slackware root directory
  --color=[always|auto|never]           Colorize the output
  --terse                               Display only a single description line when install or upgrade a package

=head2 CHANGELOG OPTIONS

  --after=DATE                          Filter changelog after date
  --before=DATE                         Filter changelog before date
  --details                             Display ChangeLog details
  --security-fix                        Display only ChangeLog Security Fix
  --cve=CVE-YYYY-NNNNNN                 Search a CVE identifier into ChangeLogs
  --announces                           Display announce in ChangeLog

=head2 INFO OPTIONS

  --show-files                          Show file lists

=head2 INSTALL, UPGRADE, REMOVE, REINSTALL OPTIONS

  --category=CATEGORY                   Use a category
  -f, --force                           Force action
  --download-only                       Download only
  --new-packages                        Check for new packages
  --obsolete-packages                   Check for obsolete packages
  -x, --exclude=PACKAGE                 Exclude package
  --tag=TAG                             Force upgrade of installed package with specified tag
  --no-priority                         Disable repository priority check
  --no-excludes                         Disable exclude repo configuration
  --no-deps                             Disable dependency check
  -y, --yes                             Assume yes
  -n, --no                              Assume no
  --no-gpg-check                        Disable GPG verify check
  --no-md5-check                        Disable MD5 checksum check
  --local=PACKAGE-FILE                  Install or upgrade from a local package

=head1 EXAMPLES

Update repository packages list and upgrade all packages:

  slackman update && slackman upgrade -y

Install, upgrade and remove obsolete packages from specific repository:

  slackman install --new-packages --repo ktown
  slackman upgrade --repo ktown
  slackman remove --obsolete-packages --repo ktown

Upgrade package excluding kernels packages

  slackman upgrade --exclude kernel-*

Install a new package from local package file:

  slackman install --local /tmp/google-chrome-62.0.3202.75-x86_64-1.txz

Search a package:

  slackman search docker

Search file using MANIFEST.bz2 repository file (C<slackman update manifest>):

  slackman file-search firefox

Display a ChangeLog:

  slackman changelog --repo slackware:packages

Search a CVE into the ChangeLog and display the detail:

  slackman changelog --cve CVE-2017-1000251 --details

=head1 SEE ALSO

L<slackman(8)>, L<slackman-repo(8)>, L<slackman-update(8)>, L<slackman.conf(5)>,
L<slackman.repo(5)>

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
