package Slackware::SlackMan::Command;

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
  @EXPORT_OK   = qw(run);
  %EXPORT_TAGS = (
    all => \@EXPORT_OK,
  );

}

use File::Basename;
use Getopt::Long qw(:config);
use IO::File;
use IO::Handle;
use Sort::Versions;
use Term::ANSIColor qw(color colored :constants);
use Text::Wrap;

use Slackware::SlackMan qw(:all);
use Slackware::SlackMan qw(:commands);

my $lock_check = get_lock_pid();

$Text::Wrap::columns = 132;

exit call_help()    if $slackman_opts->{'help'};
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

# Prevent Insecure $ENV{PATH} while running with -T switch
$ENV{'PATH'} = '/bin:/usr/bin:/sbin:/usr/sbin';

sub run {

  db_init();

  my $command   = $ARGV[0] || undef;
  my @arguments = @ARGV[ 1 .. $#ARGV ];

  call_help() unless ($command);

  my @lock_commands = qw(update install upgrade remove reinstall clean);

  logger->debug(sprintf('[CMD] Call "%s" command (cmd: %s, pid: %s)', $command, join( " ", $0, @ARGV ), $$)) if ($command);

  # Check running slackman instance and block certain commands (only
  # informational command are available)
  if ($lock_check && grep(/^$command/, @lock_commands)) {

    print "Another instance of slackman is running (pid: $lock_check) If this is not correct,\n" .
          "you can remove /var/lock/slackman file and run slackman again.\n\n";

    exit(255);

  }

  # Always create lock if pid not exists
  create_lock() unless(get_lock_pid());

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

  given($command) {

    when('install')      { call_package_install(@arguments) }
    when('reinstall')    { call_package_reinstall(@arguments) }
    when('remove')       { call_package_remove(@arguments) }
    when('upgrade')      { call_package_upgrade(@arguments)  }
    when('info')         { call_package_info($ARGV[1]) }
    when('history')      { call_package_history($ARGV[1]) }

    when('changelog')    { call_package_changelog($ARGV[1]) }
    when('config')       { show_config() }
    when('search')       { call_package_search($ARGV[1]) }
    when('file-search')  { call_package_file_search($ARGV[1]) }

    when('db') {
      given($ARGV[1]) {
        when('optimize') { call_db_optimize() }
        when('info')     { call_db_info() }
        default          { call_db_help() }
      }
    }

    when('clean') {
      given($ARGV[1]) {
        when('metadata') { call_clean_metadata(); exit(0); }
        when('manifest') { call_clean_metadata('manifest'); exit(0); }
        when('cache')    { call_clean_cache(); exit(0); }
        when('db')       { call_clean_db(); exit(0); }
        when('all')      { call_clean_all(); }
        default          { call_clean_help(); }
      }
    }

    when('repo') {
      given($ARGV[1]) {
        when('list')      { call_list_repo() }
        when('disable')   { call_repo_disable($ARGV[2]) }
        when('enable')    { call_repo_enable($ARGV[2]) }
        when('info')      { call_repo_info($ARGV[2]) }
        default           { call_repo_help() }
      }
    }

    when('list') {
      given($ARGV[1]) {
        when('installed') { call_list_installed() }
        when('obsoletes') { call_list_obsoletes() }
        when('repo')      { call_list_repo() }
        when('orphan')    { call_list_orphan() }
        when('variables') { call_list_variables() }
        when('packages')  { call_list_packages() }
        default           { call_list_help() }
      }
    }

    when('update') {
      given($ARGV[1]) {
        when('packages')  { call_update_repo_packages();  exit(0); }
        when('history')   { call_update_history();        exit(0); }
        when('changelog') { call_update_repo_changelog(); exit(0); }
        when('manifest')  { call_update_repo_manifest();  exit(0); }
        when('gpg-key')   { call_update_repo_gpg_key();   exit(0); }
        when('all')       { call_update_all_metadata() }
        default           { call_update_metadata() unless ($ARGV[1]);
                            call_update_help(); }
      }
    }

    when('help') {
      given($ARGV[1]) {
        when ('list')   { call_list_help() }
        when ('update') { call_update_help() }
        when ('repo')   { call_repo_help() }
        when ('db')     { call_db_help() }
        default         { call_help() }
      }
    }

    default { call_help() }

  }

  exit(0);

}


1;
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

END {
  delete_lock() unless ($lock_check);
}
