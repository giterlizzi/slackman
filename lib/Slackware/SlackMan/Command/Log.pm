package Slackware::SlackMan::Command::Log;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.2.0';
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
use Pod::Find qw(pod_where);

use constant COMMANDS_DISPATCHER => {

  'help.log'  => \&call_log_help,
  'log'       => \&call_log_help,
  'log.help'  => \&call_log_help,

  'log.clean' => \&call_log_clean,
  'log.tail'  => \&call_log_tail,

};

use constant COMMANDS_MAN => {
  'log' => \&call_log_man
};

use constant COMMANDS_HELP => {
  'log' => \&call_log_help
};


my $log_file = $slackman_conf{'logger'}->{'file'};

sub call_log_man {

 pod2usage(
    -input   => pod_where({-inc => 1}, __PACKAGE__),
    -exitval => 0,
    -verbose => 2
  );

}

sub call_log_help {

  pod2usage(
    -input    => pod_where({-inc => 1}, __PACKAGE__),
    -exitval  => 0,
    -verbose  => 99,
    -sections => [ 'SYNOPSIS', 'OPTIONS' ]
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
__END__
=head1 NAME

slackman-log - Display SlackMan log

=head1 SYNOPSIS

  slackman log clean
  slackman log tail
  slackman log help

=head1 DESCRIPTION

B<slackman config> get and set SlackMan configuration in L<slackman.conf(5)> file.

The default location of SlackMan log is C<directory.log/slackman.log>.

To see the current location of C<directory.log> use L<slackman-config(8)> command:

    slackman config directory.log

=head1 COMMANDS

  slackman log clean         Clean log file
  slackman log tail          Display log file in real time

=head1 OPTIONS

  -h, --help                 Display help and exit
  --man                      Display man pages
  --version                  Display version information
  -c, --config=FILE          Configuration file

=head1 SEE ALSO

L<slackman(8)>, L<slackman.conf(5)>

=head1 BUGS

Please report any bugs or feature requests to 
L<https://github.com/LotarProject/slackman/issues> page.

=head1 AUTHOR

Giuseppe Di Terlizzi <giuseppe.diterlizzi@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2016-2017 Giuseppe Di Terlizzi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
