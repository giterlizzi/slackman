package Slackware::SlackMan::Command::Config;

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
use Slackware::SlackMan::Config qw(:all);
use Slackware::SlackMan::Utils  qw(:all);

use Term::ANSIColor qw(color colored :constants);
use Pod::Usage;

use constant COMMANDS_DISPATCHER => {
  'help.config'  => \&call_config_help,
  'config'       => \&call_config,
  'config.help'  => \&call_config_help,
};

my $log_file = $slackman_conf{'logger'}->{'file'};

sub call_config_help {

  pod2usage(
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'COMMANDS/CONFIG COMMANDS' ]
  );

}

sub call_config {

  my ($config_key, $config_value) = @_;

  # Set SlackMan config value
  if ($config_key && $config_value) {

    my $slackman_conf_file = $slackman_conf{'config'}->{'file'};

    my ($section, $parameter) = split(/\./, $config_key);
    file_write($slackman_conf_file, set_config(file_read($slackman_conf_file), "[$section]", $parameter, $config_value));

    exit(0);

  }

  # Get or display all SlackMan config values

  foreach my $section (sort keys %slackman_conf) {
    foreach my $parameter (sort keys %{$slackman_conf{$section}}) {

      my $param_value = $slackman_conf{$section}->{$parameter};
      my $param_name  = "$section.$parameter";

      if ($config_key) {

        if ($config_key eq $param_name) {
          print "$param_value\n";
        }

      } else {
        print sprintf("%s=%s\n", $param_name, $param_value);
      }

    }
  }

  exit(0);

}

1;
