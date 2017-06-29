package Slackware::SlackMan::Command;

use strict;
use warnings;

no if ($] >= 5.018), 'warnings' => 'experimental';
use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.1.0-beta6';
  @ISA         = qw(Exporter);
  @EXPORT_OK   = qw(
    run
    $slackman_opts
  );
  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use File::Basename;
use IO::File;
use IO::Handle;
use Sort::Versions;
use Term::ANSIColor qw(color colored :constants);
use Text::Wrap;
use Pod::Usage;
use Module::Load;

use Slackware::SlackMan qw(:all);

my @command_modules = qw(Clean Config DB List Log Package Update Repo);

my $lock_check  = get_lock_pid();
my $command     = $ARGV[0] || undef;
my $sub_command = $ARGV[1] || undef;
my @arguments   = @ARGV[ 1 .. $#ARGV ];

$Text::Wrap::columns = 132;

exit show_help()    if $slackman_opts->{'help'};
exit show_version() if $slackman_opts->{'version'};

pod2usage(-exitval => 0, -verbose => 2) if $slackman_opts->{'man'};

# Force exit on CTRL-C
$SIG{INT} = sub {
  exit(1);
};

# Write all die to log
$SIG{__DIE__} = sub {
  logger->critical(trim($_[0]));
  die @_;
};

# Write all warn to log
$SIG{__WARN__} = sub {
  logger->warning(trim($_[0]));
  warn @_;
};

sub run {

  db_init();

  show_help() unless ($command);

  my @lock_commands = qw(update install upgrade remove reinstall clean);

  my $cmd  = join( " ", $0, @ARGV );
  my $opts = join( ', ', map { $_ . '=' . $slackman_opts->{$_} } keys %$slackman_opts);

  logger->debug(sprintf('[CMD] Call "%s" command (cmd: "%s", opts: "%s", pid: %s)', $command, $cmd, $opts, $$)) if ($command);

  # Check running slackman instance and block certain commands
  #
  # NOTE: only informational commands are available
  #
  if ($lock_check && grep(/^$command/, @lock_commands)) {

    my $message = sprintf("%s Another instance of slackman is running (pid: $lock_check). " .
                          "If this is not correct, you can remove /var/lock/slackman file and run slackman again.",
                          colored('WARNING', 'yellow bold'));

    print wrap("", "\t", $message);
    print "\n\n";

    exit(255);

  }

  # Always create lock if PID not exists (excluding "log" command)
  create_lock() if ( ! get_lock_pid() && $command ne 'log' );

  # Check repository option
  if ($command && $slackman_opts->{'repo'}) {

    my @repos = get_repositories();

    my $repo  = $slackman_opts->{'repo'};
       $repo .= ':' unless ($repo =~ /:/);

    unless (/^$repo/ ~~ @repos) {
      print "Unknown repository!\n\n";
      exit(1);
    }

  }

  # Load Commands Modules
  foreach (@command_modules) {
    load "Slackware::SlackMan::Command::$_";
  }

  # Commands dispatch table
  my $commands_dispatcher = {
    'version' => \&show_version,
    'help'    => \&show_help,
  };

  foreach (@command_modules) {

    my $module = "Slackware::SlackMan::Command::$_";
    my $module_dispatcher = $module->COMMANDS_DISPATCHER;

    # Merge all submodules dispatch table into main dispatch table
    $commands_dispatcher = { %$commands_dispatcher, %$module_dispatcher };

  }

  my $dispatch_key = undef;

  if ($sub_command && exists($commands_dispatcher->{"$command:$sub_command"})) {
    $dispatch_key =  "$command:$sub_command";       # Command + Sub Command
    @arguments    = @arguments[ 1 .. $#arguments ]; # Shift 1st argument (aka sub_command)
  }

  if ($command && ! $dispatch_key && exists($commands_dispatcher->{"$command"})) {
    $dispatch_key = "$command";
  }

  if ($dispatch_key) {
    $commands_dispatcher->{$dispatch_key}->(@arguments);
  } else {
    print "slackman: '$command' is not a slackman command. See 'slackman help'\n\n";
    exit(1);
  }

  exit(0);

}


sub show_version {
  print sprintf("SlackMan - Slackware Package Manager %s\n\n", $VERSION);
  exit(0);
}


sub show_help {

  print "SlackMan - Slackware Package Manager $VERSION\n\n";

  pod2usage(
  -exitval  => 0,
  -verbose  => 99,
  -sections => 'SYNOPSIS|COMMANDS|OPTIONS',
  );

}

1;

END {
  # Delete lock file at the END of script (excluding "log" command)
  delete_lock() if (! $lock_check && defined($command) && $command ne 'log');
}

__END__

=head1 NAME

Slackware::SlackMan::Command - SlackMan Command module

=head1 SYNOPSIS

  Slackware::SlackMan::Command::run();

=head1 DESCRIPTION

Command module for SlackMan.

=head1 EXPORT

No subs are exported by default.

=head1 SUBROUTINES

=head2 run

C<run> execute slackman command

=head1 AUTHOR

Giuseppe Di Terlizzi, C<< <giuseppe.diterlizzi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<giuseppe.diterlizzi at gmail.com>, or through
the web interface at L<https://github.com/LotarProject/slackman/issues>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

  perldoc Slackware::SlackMan::Command

You can also look for information at:

=over 4

=item * GitHub issues (report bugs here)

L<https://github.com/LotarProject/slackman/issues>

=item * SlackMan documentation

L<https://github.com/LotarProject/slackman/wiki>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2017 Giuseppe Di Terlizzi.

This module is free software, you may distribute it under the same terms
as Perl.

=cut
