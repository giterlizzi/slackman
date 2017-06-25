package Slackware::SlackMan::Command::Core;

use strict;
use warnings;

no if ($] >= 5.018), 'warnings' => 'experimental';
use feature "switch";

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.1.0-beta3';
  @ISA         = qw(Exporter);
  @EXPORT_OK   = qw(
    show_version
    update_repo_data
  );
  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Slackware::SlackMan::DB    qw(:all);
use Slackware::SlackMan::Repo  qw(:all);

sub show_version {
  print sprintf("SlackMan - Slackware Package Manager %s\n\n", $VERSION);
  exit(0);
}





sub show_config {

  my %slackman_conf = get_conf();

  foreach my $section (sort keys %slackman_conf) {
    foreach my $parameter (sort keys %{$slackman_conf{$section}}) {
      my $value = $slackman_conf{$section}->{$parameter};
      print sprintf("%s=%s\n", "$section.$parameter", $value);
    }
  }

  exit(0);
}


sub update_repo_data {

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


1;
