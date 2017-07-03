package Slackware::SlackMan::Command::Package;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.1.0-beta7';
  @ISA         = qw(Exporter);
  @EXPORT_OK   = qw();
  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

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

  my @packages_to_installed;

  print "Installed package(s)\n";
  print sprintf("%s\n\n", "-"x80);

  foreach (keys %$installed_rows) {

    my $row = $installed_rows->{$_};

    push @packages_to_installed, $row->{name};

    my $pkg_dependency = $dbh->selectrow_hashref('SELECT * FROM packages WHERE package LIKE ?', undef, $row->{'package'}.'%');

    print sprintf("%-10s : %s\n",     'Name',    $row->{name});
    print sprintf("%-10s : %s\n",     'Arch',    $row->{arch});
    print sprintf("%-10s : %s\n",     'Tag',     $row->{tag}) if ($row->{tag});
    print sprintf("%-10s : %s\n",     'Version', $row->{version});
    print sprintf("%-10s : %s\n",     'Size',    filesize_h(($row->{size_uncompressed} * 1024), 1));
    print sprintf("%-10s : %s\n",     'Require', $pkg_dependency->{'required'}) if ($pkg_dependency->{'required'});
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
    '"' . join('","', @packages_to_installed) . '"',
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
    print sprintf("%-10s : %s\n",     'Size',     filesize_h(($row->{size_uncompressed} * 1024), 1));
    print sprintf("%-10s : %s\n",     'Require',  $row->{required}) if ($row->{required});
    print sprintf("%-10s : %s\n",     'Repo',     $row->{repository});
    print sprintf("%-10s : %s\n",     'Summary',  $row->{description});

    if ($slackman_opts->{'show-files'}) {

      print sprintf("\n%-10s :\n", 'File lists');

      my $sth = $dbh->prepare('SELECT * FROM manifest WHERE package = ? ORDER BY directory, file');
      $sth->execute($row->{'package'});

      while(my $row = $sth->fetchrow_hashref()) {
        print sprintf("\t%s%s\n", $row->{'directory'}, ($row->{'file'} || ''));
      }

    }

    print sprintf("\n%s\n\n", "-"x80);

  }

  print "No packages available found\n\n" unless (scalar keys %$available_rows);

  exit(0);

}

sub call_package_reinstall {

  my (@packages) = @_;

  my @is_installed = ();
  my $option_repo  = $slackman_opts->{'repo'};

  my @packages_to_downloads = ();
  my @packages_for_pkgtool  = ();
  my $packages_errors       = {};

  unless (@packages) {
    print "Usage: slackman reinstall PACKAGE [...]\n";
    exit(255);
  }

  _check_last_metadata_update();

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
    exit(0) unless(confirm("Are you sure? [Y/N]"));
  }

  my @filters = ();

  foreach (@is_installed) {
    push(@filters, sprintf('( package LIKE "%s%%" )', $_->{'package'}));
  }

  if ($option_repo) {
    $option_repo .= ":%" unless ($option_repo =~ m/\:/);
    push(@filters, sprintf('repository LIKE %s', $dbh->quote($option_repo)));
  } else {
    push(@filters, 'repository IN ("' . join('", "', get_enabled_repositories()) . '")');
  }

  push(@filters, 'repository NOT IN ("' . join('", "', get_disabled_repositories()) . '")');

  my $query = 'SELECT * FROM packages WHERE ' . join(' AND ', @filters);
  my $rows  = $dbh->selectall_hashref($query, 'id', undef);

  @packages_to_downloads = values(%$rows);

  exit(0) unless (@packages_to_downloads);

  print "\n\n";
  print "Download package(s)\n\n";
  print sprintf("%s\n", "-"x132);

  _packages_download(\@packages_to_downloads, \@packages_for_pkgtool, $packages_errors);

  exit(0) if ($slackman_opts->{'download-only'});

  _check_root();

  if (@packages_for_pkgtool) {

    print "\n\n";
    print "Reinstall package(s)\n\n";
    print sprintf("%s\n", "-"x132);

    foreach (@packages_for_pkgtool) {
      package_update($_);
    }

  }

  _packages_errors($packages_errors);

  _fork_update_history();
  exit(0);

}

sub call_package_remove {

  my (@packages) = @_;

  my @is_installed = ();

  if ($slackman_opts->{'obsolete-packages'}) {

    # Get list from "slackman list obsoletes"
    @is_installed = call_list_obsoletes();

  } else {

    print "Remove package(s)\n\n";
    print sprintf("%s\n", "-"x132);
    print sprintf("%-20s %-20s %-10s %s\n", "Package", "Version", "Tag", "Installed");
    print sprintf("%s\n", "-"x132);

    foreach (@packages) {

      if ($_ =~ /^aaa\_(base|elflibs|terminfo)/) {
        print sprintf("%-20s Never remove this package !!!\n", colored(sprintf('%-20s', $_), 'red bold'));
      } else {

        my $pkg = package_is_installed($_);

        if ($pkg) {
          print sprintf("%-20s %-20s %-10s %s\n", $_, "$pkg->{version}-$pkg->{build}", $pkg->{'tag'}, $pkg->{'timestamp'});
          push(@is_installed, $_);
        } else {
          print sprintf("%-50s   not installed\n", colored(sprintf('%-50s', $_), 'red bold'));
        }

      }

    }

    print "\n\n";

  }

  exit(0) unless(@is_installed);
  exit(0) if ($slackman_opts->{'no'});

  unless ($slackman_opts->{'yes'}) {
    exit(0) unless(confirm("Are you sure? [Y/N]"));
  }

  _check_root();

  foreach (@is_installed) {
    package_remove($_);
  }

  _fork_update_history();
  exit(0);

}

sub call_package_install {

  my (@install_packages) = @_;

  if (   ! @install_packages
      && ! $slackman_opts->{'repo'}
      && ! $slackman_opts->{'new-packages'}) {

    print "Usage: slackman install PACKAGE\n";
    exit(255);

  }

  _check_last_metadata_update();

  my $packages_to_install   = {};
  my @packages_to_downloads = ();
  my @packages_for_pkgtool  = ();
  my $packages_errors       = {};
  my $dependency_pkgs       = {};

  my $total_compressed_size   = 0;
  my $total_uncompressed_size = 0;

  foreach (@install_packages) {
    if (package_is_installed($_)) {
      print sprintf("%s package is already installed!\n", colored($_, 'bold'));
      exit(1);
    }
  }

  STDOUT->printflush('Search packages... ');

  update_repo_data();

  ($packages_to_install, $dependency_pkgs) = package_check_install(@install_packages);

  STDOUT->printflush(colored("done\n\n", 'green'));

  if (scalar keys %$packages_to_install) {

    print "Package(s) to install\n\n";
    print sprintf("%s\n", "-"x132);

    print sprintf("%-30s %-8s %-40s %-40s %s\n",
      'Name', 'Arch', 'Version', 'Repository', 'Size');

    print sprintf("%s\n", "-"x132);

    foreach (sort keys %$packages_to_install) {

      my $pkg = $packages_to_install->{$_};

      $total_uncompressed_size += $pkg->{size_uncompressed};
      $total_compressed_size   += $pkg->{size_compressed};

      print sprintf("%-30s %-8s %-40s %-40s %s\n",
        $pkg->{name}, $pkg->{arch}, $pkg->{version},
        $pkg->{repository}, filesize_h(($pkg->{size_compressed} * 1024), 1, 1)
      );

      push(@packages_to_downloads, $pkg);

    }

  }

  if (scalar keys %$dependency_pkgs) {

    print "\n\n";
    print "Required package(s) to install\n\n";

    print sprintf("%s\n", "-"x132);

    print sprintf("%-30s %-8s %-20s %-20s %-40s %s\n",
      'Name', 'Arch', 'Version', 'Needed by', 'Repository', 'Size');

    print sprintf("%s\n", "-"x132);

    foreach (sort keys %$dependency_pkgs) {

      my $pkg       = $dependency_pkgs->{$_};
      my $needed_by = join(',', @{$pkg->{needed_by}});

      $total_uncompressed_size += $pkg->{size_uncompressed};
      $total_compressed_size   += $pkg->{size_compressed};

      print sprintf("%-30s %-8s %-20s %-20s %-40s %s\n",
        $pkg->{name}, $pkg->{arch}, $pkg->{version}, $needed_by,
        $pkg->{repository}, filesize_h(($pkg->{size_uncompressed} * 1024), 1, 1)
      );

      push(@packages_to_downloads, $pkg);
    }

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
    exit(0) unless(confirm("Install selected packages? [Y/N]"));
  }

  print "\n\n";
  print "Download package(s)\n";
  print sprintf("%s\n\n", "-"x132);

  _packages_download(\@packages_to_downloads, \@packages_for_pkgtool, $packages_errors);

  exit(0) if ($slackman_opts->{'download-only'});

  _check_root();

  if (@packages_for_pkgtool) {

    print "\n\n";
    print "Install package(s)\n";
    print sprintf("%s\n\n", "-"x132);

    foreach (@packages_for_pkgtool) {
      package_install($_);
    }

  }

  _packages_errors($packages_errors);
  _packages_installed(\@packages_for_pkgtool);

  _fork_update_history() if (@packages_for_pkgtool);

  exit(0);

}

sub call_package_search {

  my ($search) = @_;

  unless ($search) {
    print "Usage: slackman search PATTERN\n";
    exit(255);
  }

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

  my $rows = 0;

  print sprintf("%s\n", "-"x132);
  print sprintf("%-80s %-15s %-8s %-10s %s\n",
    'Name', 'Version', 'Arch', 'Status', 'Repository');
  print sprintf("%s\n", "-"x132);

  while (my $row = $sth->fetchrow_hashref()) {

    $rows++;

    my $name    = $row->{'name'};
    my $summary = $row->{'summary'};

    $summary =~ s/^$name//;
    $summary =~ s/^\s+//;

    print sprintf("%-80s %-15s %-8s %-10s %s\n",
      "$name $summary",
      $row->{'version'},
      $row->{'arch'},
      colored(sprintf('%-10s', $row->{'status'} ||' '), 'green'),
      $row->{'repository'}
    );

  }

  unless ($rows) {
    print "Package not found!\n";
    exit(255);
  }

  exit(0);

}

sub call_package_history {

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

  print sprintf("History of @{[ BOLD ]}%s@{[ RESET ]} package:\n\n", $package);
  print sprintf("%-10s %-15s %-25s %-15s %-25s\n", "Status", "Version", "Timestamp", "Previous", "Upgraded");
  print sprintf("%s\n", "-"x100);

  my $prev_version   = '';
  my $prev_status    = '';
  my $status_history = '';

  foreach (sort keys %$rows_ref) {

    my $row       = $rows_ref->{$_};
    my $status    = $row->{'status'};
    my $version   = $row->{'version'} . '-' . $row->{'build'};
    my $timestamp = $row->{'timestamp'};
    my $upgraded  = $row->{'upgraded'};

    $status_history = $status;
    $status_history = 'upgraded'       if ($status eq 'installed');
    $status_history = 'installed'      if (! $prev_status);
    $status_history = $row->{'status'} if ($row_nums == 1);
    $status_history = 'installed'      if ($prev_status eq 'removed');
    $prev_version   = ''               if ($status_history eq 'removed');
    $prev_version   = ''               if ($status_history eq 'installed');

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

sub call_package_upgrade {

  my (@update_package) = @_;

  _check_last_metadata_update();

  my $packages_to_update    = {};  # Updatable packages list
  my $packages_to_install   = {};  # Required packages to install
  my @packages_to_downloads = ();  # Download packages list
  my @packages_for_pkgtool  = ();  # Packages for upgradepkg command
  my $packages_errors       = {};  # Download, checksum & gpg verify errors
  my $kernel_upgrade        = 0;   # Check Kernel Upgrade

  my $total_compressed_size   = 0;
  my $total_uncompressed_size = 0;

  STDOUT->printflush('Search packages update... ');

  update_repo_data();

  ($packages_to_update, $packages_to_install) = package_check_updates(@update_package);

  STDOUT->printflush(colored("done\n\n", 'green'));

  if (scalar keys %$packages_to_update) {

    print "Package(s) to update\n\n";
    print sprintf("%s\n", "-"x132);

    print sprintf("%-30s %-8s %-40s %-40s %s\n",
      'Name', 'Arch', 'Version', 'Repository', 'Size');

    print sprintf("%s\n", "-"x132);

    foreach (sort keys %$packages_to_update) {

      my $pkg = $packages_to_update->{$_};

      $total_uncompressed_size += $pkg->{size_uncompressed};
      $total_compressed_size   += $pkg->{size_compressed};

      print sprintf("%-30s %-8s %-40s %-40s %s\n",
        $pkg->{name}, $pkg->{arch},
        sprintf('%s %s %s', $pkg->{old_version_build}, '->', $pkg->{new_version_build}),
        $pkg->{repository}, filesize_h(($pkg->{size_compressed} * 1024), 1, 1)
      );

      push(@packages_to_downloads, $pkg);

    }

  }

  if (scalar keys %$packages_to_install) {

    print "\n\n";
    print "Required package(s) to install\n\n";

    print sprintf("%s\n", "-"x132);

    print sprintf("%-30s %-8s %-9s %-20s %-40s %s\n",
      'Name', 'Arch', 'Version', 'Needed by', 'Repository', 'Size');

    print sprintf("%s\n", "-"x132);

    foreach (sort keys %$packages_to_install) {

      my $pkg       = $packages_to_install->{$_};
      my $needed_by = join(',', @{$pkg->{needed_by}});

      $total_uncompressed_size += $pkg->{size_uncompressed};
      $total_compressed_size   += $pkg->{size_compressed};

      print sprintf("%-30s %-8s %-9s %-20s %-40s %s\n",
        $pkg->{name}, $pkg->{arch}, $pkg->{version}, $needed_by,
        $pkg->{repository}, filesize_h(($pkg->{size_uncompressed} * 1024), 1, 1)
      );

      push(@packages_to_downloads, $pkg);
    }

  }

  unless (scalar keys %$packages_to_update) {
    print "Already up-to-date!\n";
    exit(0);
  }

  print "\n\n";
  print "Update summary\n";
  print sprintf("%s\n", "-"x40);
  print sprintf("%-20s %s package(s)\n", 'Install', scalar keys %$packages_to_install) if (scalar keys %$packages_to_install);
  print sprintf("%-20s %s package(s)\n", 'Update',  scalar keys %$packages_to_update);

  print sprintf("%-20s %s\n", 'Download size',   filesize_h(($total_compressed_size   * 1024), 1));
  print sprintf("%-20s %s\n", 'Installed size',  filesize_h(($total_uncompressed_size * 1024), 1));
  print "\n\n";

  exit(0) if ($slackman_opts->{'no'} || $slackman_opts->{'summary'});

  if (@packages_to_downloads) {

    unless ($slackman_opts->{'yes'} || $slackman_opts->{'download-only'}) {
      exit(0) unless(confirm("Perform update of selected packages? [Y/N]"));
    }

    print "\n\n";
    print "Download package(s)\n";
    print sprintf("%s\n\n", "-"x132);

    _packages_download(\@packages_to_downloads, \@packages_for_pkgtool, $packages_errors);

    exit(0) if ($slackman_opts->{'download-only'});

    _check_root();

    if (@packages_for_pkgtool) {

      print "\n\n";
      print "Update package(s)\n";
      print sprintf("%s\n\n", "-"x132);

      foreach my $package_path (@packages_for_pkgtool) {
        $kernel_upgrade = 1 if ($package_path =~ /kernel-(modules|generic|huge)/);
        package_update($package_path);
      }

    }

    # Display packages error list
    _packages_errors($packages_errors);

    # Display packages upgraded
    _packages_upgraded(\@packages_for_pkgtool);

    # Display Kernel Update message
    _kernel_update_message() if ($kernel_upgrade);

    # Update history metadata in background
    _fork_update_history() if (@packages_for_pkgtool);

    # Search new configuration files (same as 'slackman new-config' command)
    call_package_new_config() if (@packages_for_pkgtool);

  }

  exit(0);

}


sub call_package_file_search {

  my ($file) = @_;

  unless($file) {
    print "Usage: slackman file-search FILE\n";
    exit(1);
  }

  my $rows = package_search_files($file);

  foreach my $row (@$rows) {

    print sprintf("%s/@{[ BOLD ]}%s@{[ RESET ]}: %s (%s)\n",
      $row->{'directory'}, $row->{'file'}, $row->{'package'}, $row->{'repository'});

  }

  exit(0);

}


sub call_package_changelog {

  my ($package) = @_;
  my $changelogs = package_changelogs($package);

  print sprintf("%-60s %-20s %-1s %-10s %-20s %s\n", "Package", "Version", " ", "Status", "Timestamp", "Repository");
  print sprintf("%s\n", "-"x132);

  foreach my $row (@{$changelogs}) {

    print sprintf("%-60s %-20s %-1s %-10s %-20s %s\n",
      ($row->{'package'}      || ''),
      ($row->{'version'}      || ''),
      ($row->{'security_fix'} ? "@{[ BLINK ]}@{[ RED ]}!@{[ RESET ]}" : ''),
      ($row->{'status'}       || ''),
      ($row->{'timestamp'}    || ''),
      ($row->{'repository'}   || '')
    );
  }

}


sub call_package_new_config {

  my @new_config_files = ();

  my $etc_directory = '/etc';

  if (defined($ENV{ROOT})) {
    $etc_directory = $ENV{ROOT} . '/etc';
  }

  print "Search for new configuration files... ";

  # Find .new files in /etc directory excluding files listed in UPGRADE.TXT doc:
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
    use Data::Dumper;

    if (defined($manifest->[0]->{'package'})) {
      $package = "(" . $manifest->[0]->{'package'} . ")";
    }

    print "  * $new_config_file\t\t$package\n";

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

  my $answer = sprintf("What do you want [%seep/%svervrite/%semove/%siff/%serge] ?", 
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

    STDOUT->printflush(sprintf("[%d/%d] %s\n", $count_downloads, $num_downloads, $pkg->{'package'}));

    my ($package_path, $package_errors) = package_download($pkg);

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

    my $pkg = package_info(basename($_));

    print sprintf("  * %s upgraded to %s version\n",
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
    my $pkg = package_info(basename($_));
    print sprintf("  * installed %s %s version\n", $pkg->{'name'}, $pkg->{'version'});
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
    print sprintf("  * %-50s (%s error)\n", $pkg, join(' error, ', @{$packages_errors->{$pkg}}));
  }

  print "\n\n";

}


sub _kernel_update_message {

  # Detect the EFI System Partition (ESP)
  my $efi_partition = qx{ mount | grep vfat | grep efi };

  # lilo is default command on x86 arch or machine can't have UEFI bios (generally x86_64 arch)
  my $lilo_command  = 'lilo';
#      $lilo_command  = 'eliloconfig' if ($efi_partition);

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
           .  "  * /boot/README.initrd\n"
           .  "  * mkinitrd(8)\n\n";

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

sub _check_root {

  unless ($< == 0) {
    print sprintf("%s This action require root privilege!\n", colored('ERROR', 'bold red'));
    exit(1);
  }

}

sub _fork_update_history {

  # Delete all lock file
  delete_lock();

  # Call update history command in background and set ROOT environment
  my $update_history_cmd  = "slackman update history --force";
     $update_history_cmd .= sprintf(" --root %s", $ENV{ROOT}) if ($ENV{ROOT});
     $update_history_cmd .= " > /dev/null &";

  logger->debug("Call update history command in background ($update_history_cmd)");

  qx{ $update_history_cmd };

}


1;
