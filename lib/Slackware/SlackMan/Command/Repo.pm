package Slackware::SlackMan::Command::Repo;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.1.0-beta5';
  @ISA         = qw(Exporter);
  @EXPORT_OK   = qw();
  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Slackware::SlackMan::DB     qw(:all);
use Slackware::SlackMan::Repo   qw(:all);
use Slackware::SlackMan::Utils  qw(:all);

use Term::ANSIColor qw(color colored :constants);
use Pod::Usage;

sub call_repo_help {

  pod2usage(
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'COMMANDS/REPOSITORY COMMANDS' ]
  );

}

sub call_repo_list {

  my @repositories = get_repositories();

  print "\nAvailable repository\n\n";
  print sprintf("%s\n", "-"x132);
  print sprintf("%-30s %-70s %-10s %-10s %-4s\n", "Repository ID",  "Description", "Status", "Priority", "Packages");
  print sprintf("%s\n", "-"x132);

  foreach my $repo_id (@repositories) {

    my $repo_info = get_repository($repo_id);
    my $num_pkgs  = $dbh->selectrow_array('SELECT COUNT(*) AS packages FROM packages WHERE repository = ?', undef, $repo_id);

    print sprintf("%-30s %-70s %-10s %-10s %-4s\n",
      $repo_id,
      $repo_info->{name},
      ($repo_info->{enabled} ? colored(sprintf("%-10s", 'Enabled'), 'GREEN') : 'Disabled'),
      $repo_info->{priority},
      $num_pkgs
    );

  }

  exit(0);

}

sub call_repo_disable {

  my ($repo_id) = @_;

  disable_repository($repo_id);
  print qq/Repository "$repo_id" disabled\n/;

}

sub call_repo_enable {

  my ($repo_id) = @_;

  enable_repository($repo_id);
  print qq/Repository "$repo_id" enabled\n\n/;

  print sprintf("%s: Remember to launch 'slackman update --repo $repo_id' command!\n", colored('NOTE', 'bold'));

  exit(0);

}

sub call_repo_info {

  my ($repo_id) = @_;

  unless($repo_id) {
    print "Usage: slackman repo info REPOSITORY\n";
    exit(255);
  }

  my $repo_data = get_repository($repo_id);

  unless($repo_data) {
    print "Repository not found!\n";
    exit(255);
  }

  update_repo_data();

  my $package_nums = $dbh->selectrow_array('SELECT COUNT(*) AS packages FROM packages WHERE repository = ?', undef, $repo_id);
  my $last_update  = time_to_timestamp(db_meta_get("last-update.$repo_id.packages"));

  my @urls = qw/changelog packages manifest checksums gpgkey/;

  print "\n";
  print sprintf("%-20s %s\n", "Name:",          $repo_data->{name});
  print sprintf("%-20s %s\n", "ID:",            $repo_data->{id});
  print sprintf("%-20s %s\n", "Configuration:", $repo_data->{config_file});
  print sprintf("%-20s %s\n", "Mirror:",        $repo_data->{mirror});
  print sprintf("%-20s %s\n", "Status:",        (($repo_data->{enabled}) ? 'enabled' : 'disabled'));
  print sprintf("%-20s %s\n", "Last Update:",   ($last_update || ''));
  print sprintf("%-20s %s\n", "Priority:",      $repo_data->{priority});
  print sprintf("%-20s %s\n", "Packages:",      $package_nums);

  print "\nRepository URLs:\n";

  foreach (@urls) {
    next unless($repo_data->{$_});
    print sprintf("%-20s %s\n", "  * $_", $repo_data->{$_});
  }

  print "\n";

  exit(0);

}


1;
