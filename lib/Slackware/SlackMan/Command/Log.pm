package Slackware::SlackMan::Command::Log;

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
use Slackware::SlackMan::Config;
use Slackware::SlackMan::Utils qw(:all);

use Term::ANSIColor qw(color colored :constants);
use Pod::Usage;

use constant COMMANDS_DISPATCHER => {
  'help:log'  => \&call_log_help,
  'log'       => \&call_log_help,
  'log:help'  => \&call_log_help,
  'log:clean' => \&call_log_clean,
  'log:tail'  => \&call_log_tail,
};


my $log_file = $slackman_conf{'logger'}->{'file'};

sub call_log_help {
print colored('foo', 'red');
  pod2usage(
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'COMMANDS/LOG COMMANDS' ]
  );

}

sub call_log_clean {

  if (confirm('Are you sure? [Y/N]')) {

    STDOUT->printflush("\nClean $log_file...");
    qx { >$log_file > /dev/null 2>&1 };
    STDOUT->printflush(colored("\tdone\n", 'green'));

  }

  exit(0);

}

sub call_log_tail {

  system("tail -f $log_file");
  exit(0);

}

1;
