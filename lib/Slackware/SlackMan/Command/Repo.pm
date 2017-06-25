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
    call_repo_disable
    call_repo_enable
    call_repo_info
  );
  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use Slackware::SlackMan::DB     qw(:all);
use Slackware::SlackMan::Repo   qw(:all);
use Slackware::SlackMan::Utils  qw(:all);
use Slackware::SlackMan::Commands::Core qw(:all);

use Term::ANSIColor qw(color colored :constants);


sub call_repo_disable {

  my ($repo_id) = @_;

  disable_repository($repo_id);
  print qq/Repository "$repo_id" disabled\n/;

}

sub call_repo_enable {

  my ($repo_id) = @_;

  enable_repository($repo_id);
  print qq/Repository "$repo_id" enabled\n\n/;

  print sprintf("%s: Remember to launch \"slackman update --repo $repo_id\" command!\n", colored('NOTE', 'bold'));

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
