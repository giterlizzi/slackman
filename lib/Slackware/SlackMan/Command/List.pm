package Slackware::SlackMan::Command::List;

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
use Slackware::SlackMan::DB      qw(:all);
use Slackware::SlackMan::Package qw(:all);
use Slackware::SlackMan::Parser  qw(:all);
use Slackware::SlackMan::Repo    qw(:all);
use Slackware::SlackMan::Utils   qw(:all);

use Term::ANSIColor qw(color colored :constants);
use Pod::Usage;


use constant COMMANDS_DISPATCHER => {

  'help.list'      => \&call_list_help,
  'list'           => \&call_list_help,
  'list.help'      => \&call_list_help,

  'list.installed' => \&call_list_installed,
  'list.removed'   => \&call_list_removed,
  'list.upgraded'  => \&call_list_upgraded,
  'list.obsoletes' => \&call_list_obsoletes,
  'list.orphan'    => \&call_list_orphan,
  'list.packages'  => \&call_list_packages,
  'list.variables' => \&call_list_variables,

};

use constant COMMANDS_MAN => {
  'list' => \&call_list_man
};

use constant COMMANDS_HELP => {
  'list' => \&call_list_help
};

sub call_list_man {

 pod2usage(
    -input   => __FILE__,
    -exitval => 0,
    -verbose => 2
  );

}

sub call_list_help {

  pod2usage(
    -input    => __FILE__,
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'OPTIONS' ]
  );

}

sub call_list_obsoletes {

  my $obsolete_rows = package_list_obsoletes($slackman_opts->{'repo'});
  my $num_rows      = scalar keys %$obsolete_rows;

  unless ($num_rows) {
    print "\nNo obsolete packages found!\n\n";
    exit(0);
  }

  my @obsolete = ();
  my @rows = ();

  foreach(keys %$obsolete_rows) {

    my $row = $obsolete_rows->{$_};

    push(@rows, [
      $row->{changelog_name},
      $row->{changelog_repository},
      $row->{changelog_version},
      $row->{changelog_timestamp},
      $row->{installed_version},
      $row->{installed_timestamp}
    ]);

    push(@obsolete, $row->{changelog_name});

  }

  print "\nObsolete package(s)\n\n" if ($slackman_opts->{'format'} eq 'default');

  print table({
    'rows'      => \@rows,
    'separator' => { 'column' => '   ', 'header' => '-' },
    'headers'   => [ 'Package', 'ChangeLog Repository', 'Version', 'Obsolete from', 'Actual Version', 'Installed at' ],
    'format'    => $slackman_opts->{'format'},
  });

  return (@obsolete);

}

sub call_list_variables {

  my @variables = ( 'arch', 'arch.bit', 'arch.family',
                    'release', 'release.real', 'release.suffix', 'release.arch' );

  my @rows = ();

  foreach (@variables) {
    push(@rows, [ $_, parse_variables("\$$_") ]);
  }

  print table({
    'rows'      => \@rows,
    'separator' => { 'column' => '    ', 'header' => '-' },
    'headers'   => [ 'Variable', 'Value' ],
    'format'    => $slackman_opts->{'format'},
  });

  print "\n";

  exit(0);

}

sub call_list_orphan {

  print "\nOrphan package(s)\n\n" if ($slackman_opts->{'format'} eq 'default');

  my $rows_ref = package_list_orphan();
  my @rows = ();

  foreach (sort keys %$rows_ref) {

    my $row = $rows_ref->{$_};

    push(@rows, [
      $row->{name},
      $row->{arch},
      $row->{version},
      $row->{tag},
      filesize_h(($row->{size_compressed} * 1024), 1, 1),
      $row->{timestamp},
    ]);

  }

  print table({
    'rows'      => \@rows,
    'separator' => { 'column' => '   ', 'header' => '-' },
    'headers'   => [ 'Name', 'Arch', 'Version', 'Tag', 'Size', 'Installed/Upgraded at' ],
    'format'    => $slackman_opts->{'format'},
  });

  exit(0);

}

sub call_list_installed {

  my (@search) = @_;

  print "\nInstalled packages\n\n" if ($slackman_opts->{'format'} eq 'default');

  my $rows_ref = package_list_installed(@search);
  my @rows = ();

  foreach (sort keys %$rows_ref) {

    my $row = $rows_ref->{$_};

    push(@rows, [
      $row->{'name'},
      $row->{'arch'},
      ( $row->{'version'} . '-' . $row->{'build'} ),
      $row->{'tag'},
      filesize_h(($row->{'size_compressed'} * 1024), 1, 1),
      $row->{'timestamp'}
    ]);

  }

  print table({
    'rows'      => \@rows,
    'separator' => { 'column' => '   ', 'header' => '-' },
    'headers'   => [ 'Name', 'Arch', 'Version', 'Tag', 'Size', 'Installed/Upgraded at' ],
    'format'    => $slackman_opts->{'format'},
  });

  exit(0);

}


sub call_list_upgraded {

  print "\nUpgraded packages\n\n" if ($slackman_opts->{'format'} eq 'default');

  my @query_filters;

  push(@query_filters, "status = 'upgraded'");

  if (my $timestamp_options = timestamp_options_to_sql()) {
    push(@query_filters, $timestamp_options);
  }

  my $query = "SELECT * FROM history WHERE %s ORDER BY timestamp DESC";
     $query = sprintf($query, join(' AND ', @query_filters));

  my $sth = $dbh->prepare($query);
  $sth->execute();

  my @rows = ();

  while (my $row = $sth->fetchrow_hashref()) {

    push(@rows, [
      $row->{name},
      $row->{arch},
      "$row->{version}-$row->{build}",
      $row->{tag},
      filesize_h(($row->{size_compressed} * 1024), 1, 1),
      $row->{'timestamp'}
    ]);

  }

  print table({
    'rows'      => \@rows,
    'separator' => { 'column' => '   ', 'header' => '-' },
    'headers'   => [ 'Name', 'Arch', 'Version', 'Tag', 'Size', 'Timestamp' ],
    'format'    => $slackman_opts->{'format'},
  });

  exit(0);

}


sub call_list_removed {

  print "\nRemoved packages\n\n" if ($slackman_opts->{'format'} eq 'default');

  my @query_filters;

  push(@query_filters, "status = 'removed'");

  if (my $timestamp_options = timestamp_options_to_sql()) {
    push(@query_filters, $timestamp_options);
  }

  my $query = "SELECT * FROM history WHERE %s ORDER BY timestamp DESC";
     $query = sprintf($query, join(' AND ', @query_filters));

  my $sth = $dbh->prepare($query);
  $sth->execute();

  my @rows = ();

  while (my $row = $sth->fetchrow_hashref()) {

    push(@rows, [
      $row->{name},
      $row->{arch},
      "$row->{version}-$row->{build}",
      $row->{tag},
      filesize_h(($row->{size_compressed} * 1024), 1, 1),
      $row->{'timestamp'}
    ]);

  }

  print table({
    'rows'      => \@rows,
    'separator' => { 'column' => '   ', 'header' => '-' },
    'headers'   => [ 'Name', 'Arch', 'Version', 'Tag', 'Size', 'Timestamp' ],
    'format'    => $slackman_opts->{'format'},
  });

  exit(0);

}

sub call_list_packages {

  my (@search) = @_;

  print "\nAvailable packages\n\n" if ($slackman_opts->{'format'} eq 'default');

  my $option_repo = $slackman_opts->{'repo'};

  if ($option_repo) {
    $option_repo .= ":%" unless ($option_repo =~ m/\:/);
  }

  my $filter = sprintf('repository IN ("%s")', join('", "', get_enabled_repositories()));
     $filter = sprintf('repository LIKE %s', $dbh->quote($option_repo)) if ($option_repo);

  if ($slackman_opts->{'exclude-installed'}) {
    $filter .= ' AND name NOT IN (SELECT name FROM history WHERE status = "installed")';
  }

  my @search_filters      = ();
  my $query_search_filter = '';

  foreach my $item (@search) {
    $item =~ s/\*/%/g;
    push(@search_filters, sprintf('(name LIKE %s)', $dbh->quote($item)));
  }

  if (@search_filters) {
    $query_search_filter = sprintf(' AND (%s)', join(' OR ', @search_filters));
  }

  $filter .= $query_search_filter;

  my $query = 'SELECT * FROM packages WHERE %s ORDER BY name';
     $query = sprintf($query, $filter);

  my $sth = $dbh->prepare($query);
  $sth->execute();

  my @rows = ();

  while (my $row = $sth->fetchrow_hashref()) {

    push(@rows, [
      $row->{name},
      $row->{arch},
      "$row->{version}-$row->{build}",
      $row->{tag},
      $row->{repository},
      filesize_h(($row->{size_compressed} * 1024), 1, 1)
    ]);

  }

  print table({
    'rows'      => \@rows,
    'separator' => { 'column' => '   ', 'header' => '-' },
    'headers'   => [ 'Name', 'Arch', 'Version', 'Tag', 'Repository', 'Size' ],
    'format'    => $slackman_opts->{'format'},
  });

  exit(0);

}


1;
__END__
=head1 NAME

slackman-list - List packages and other info

=head1 SYNOPSIS

  slackman list packages [--repo=REPOSITORY]
  slackman list installed
  slackman list removed
  slackman list upgraded
  slackman list obsoletes
  slackman list orphan
  slackman list variables
  slackman list repo
  slackman list help

=head1 DESCRIPTION

B<slackman list> display information of:

    * installed packages
    * available packages
    * orphan packages
    * obsolete packages
    * available repositories

=head1 COMMANDS

  slackman list obsoletes      List obsolete packages
  slackman list installed      List installed packages
  slackman list packages       List available packages
  slackman list orphan         List orphan packages installed from unknown repository
  slackman list variables      List variables for ".repo" configurations
  slackman list repo           List available repositories (alias of "slackman repo list" command)

=head1 OPTIONS

  --after=DATE                 Filter list after date
  --before=DATE                Filter list before date
  --repo=REPOSITORY            Use specified repository
  --exclude-installed          Exclude installed packages from list
  -h, --help                   Display help and exit
  --man                        Display man pages
  --version                    Display version information
  -c, --config=FILE            Configuration file
  --color=[always|auto|never]  Colorize the output
  --format=[default|csv|tsv]   Output format for list

=head1 SEE ALSO

L<slackman(8)>, L<slackman.repo(5)>

=head1 BUGS

Please report any bugs or feature requests to 
L<https://github.com/LotarProject/slackman/issues> page.

=head1 AUTHOR

Giuseppe Di Terlizzi <giuseppe.diterlizzi@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2016-2019 Giuseppe Di Terlizzi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
