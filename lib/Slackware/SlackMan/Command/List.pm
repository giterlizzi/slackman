package Slackware::SlackMan::Command::List;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.1.0_09';
  @ISA         = qw(Exporter);
  @EXPORT_OK   = qw();
  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Slackware::SlackMan;
use Slackware::SlackMan::Config  qw(:all);
use Slackware::SlackMan::DB      qw(:all);
use Slackware::SlackMan::Package qw(:all);
use Slackware::SlackMan::Parser  qw(:all);
use Slackware::SlackMan::Repo    qw(:all);
use Slackware::SlackMan::Utils   qw(:all);

use Term::ANSIColor qw(color colored :constants);
use Pod::Usage;

use constant COMMANDS_DISPATCHER => {
  'help:list'      => \&call_list_help,
  'list'           => \&call_list_help,
  'list:help'      => \&call_list_help,
  'list:installed' => \&call_list_installed,
  'list:obsoletes' => \&call_list_obsoletes,
  'list:orphan'    => \&call_list_orphan,
  'list:packages'  => \&call_list_packages,
  'list:variables' => \&call_list_variables,
};


sub call_list_help {

  pod2usage(
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'COMMANDS/LIST COMMANDS' ]
  );

}

sub call_list_obsoletes {

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

sub call_list_variables {

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

sub call_list_orphan {

  print "\nOrphan package(s)\n\n";
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

sub call_list_installed {

  my (@search) = @_;

  print "\nInstalled packages\n\n";
  print sprintf("%s\n", "-"x132);
  print sprintf("%-40s %-10s\t%-25s %-10s %s\n", "Name", "Arch", "Version", "Tag", "Installed");
  print sprintf("%s\n", "-"x132);

  my $rows_ref = package_list_installed(@search);

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

sub call_list_packages {

  my (@search) = @_;

  print "\nAvailable packages\n\n";
  print sprintf("%s\n", "-"x132);
  print sprintf("%-40s %-10s\t%-25s %-10s %s\n", "Name", "Arch", "Version", "Tag", "Repository");
  print sprintf("%s\n", "-"x132);

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


1;
