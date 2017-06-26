package Slackware::SlackMan::Command;

use strict;
use warnings;

no if ($] >= 5.018), 'warnings' => 'experimental';
use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION     = 'v1.1.0-beta4';
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

use Slackware::SlackMan qw(:all);

my $lock_check = get_lock_pid();

$Text::Wrap::columns = 132;

exit _show_help()    if $slackman_opts->{'help'};
exit _show_version() if $slackman_opts->{'version'};

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

  my $command     = $ARGV[0] || undef;
  my $sub_command = $ARGV[1] || undef;
  my @arguments   = @ARGV[ 1 .. $#ARGV ];

  _show_help() unless ($command);

  my @lock_commands = qw(update install upgrade remove reinstall clean);

  logger->debug(sprintf('[CMD] Call "%s" command (cmd: %s, pid: %s)', $command, join( " ", $0, @ARGV ), $$)) if ($command);

  # Check running slackman instance and block certain commands (only
  # informational command are available)
  if ($lock_check && grep(/^$command/, @lock_commands)) {

    my $message = sprintf("%s Another instance of slackman is running (pid: $lock_check). " .
                          "If this is not correct, you can remove /var/lock/slackman file and run slackman again.",
                          colored('WARNING', 'yellow bold'));

    print wrap("", "\t", $message);
    print "\n\n";

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

  my $dispatch = {

    'changelog'        => \&Slackware::SlackMan::Command::Package::call_package_changelog,
    'file-search'      => \&Slackware::SlackMan::Command::Package::call_package_file_search,
    'history'          => \&Slackware::SlackMan::Command::Package::call_package_history,
    'info'             => \&Slackware::SlackMan::Command::Package::call_package_info,
    'install'          => \&Slackware::SlackMan::Command::Package::call_package_install,
    'reinstall'        => \&Slackware::SlackMan::Command::Package::call_package_reinstall,
    'remove'           => \&Slackware::SlackMan::Command::Package::call_package_remove,
    'search'           => \&Slackware::SlackMan::Command::Package::call_package_search,
    'upgrade'          => \&Slackware::SlackMan::Command::Package::call_package_upgrade,

    'config'           => \&_show_config,
    'help'             => \&_show_help,

    'clean'            => \&Slackware::SlackMan::Command::Clean::call_clean_help,
    'clean::cache'     => \&Slackware::SlackMan::Command::Clean::call_clean_cache,
    'clean::db'        => \&Slackware::SlackMan::Command::Clean::call_clean_db,
    'clean::help'      => \&Slackware::SlackMan::Command::Clean::call_clean_help,
    'clean::manifest'  => \&Slackware::SlackMan::Command::Clean::call_clean_metadata_manifest,
    'clean::metadata'  => \&Slackware::SlackMan::Command::Clean::call_clean_metadata,
    'clen::all'        => \&Slackware::SlackMan::Command::Clean::call_clean_all,

    'db'               => \&Slackware::SlackMan::Command::DB::call_db_help,
    'db::help'         => \&Slackware::SlackMan::Command::DB::call_db_help,
    'db::info'         => \&Slackware::SlackMan::Command::DB::call_db_info,
    'db::optimize'     => \&Slackware::SlackMan::Command::DB::call_db_optimize,

    'help::clean'      => \&Slackware::SlackMan::Command::Clean::call_clean_help,
    'help::db'         => \&Slackware::SlackMan::Command::DB::call_db_help,
    'help::list'        => \&Slackware::SlackMan::Command::List::call_list_help,
    'help::repo'        => \&Slackware::SlackMan::Command::Repo::call_repo_help,
    'help::update'      => \&Slackware::SlackMan::Command::Update::call_update_help,

    'list'              => \&Slackware::SlackMan::Command::List::call_list_help,
    'list::help'        => \&Slackware::SlackMan::Command::List::call_list_help,
    'list::installed'   => \&Slackware::SlackMan::Command::List::call_list_installed,
    'list::obsoletes'   => \&Slackware::SlackMan::Command::List::call_list_obsoletes,
    'list::orphan'      => \&Slackware::SlackMan::Command::List::call_list_orphan,
    'list::packages'    => \&Slackware::SlackMan::Command::List::call_list_packages,
    'list::variables'   => \&Slackware::SlackMan::Command::List::call_list_variables,

    'repo'              => \&Slackware::SlackMan::Command::Repo::call_repo_help,
    'repo::disable'     => \&Slackware::SlackMan::Command::Repo::call_repo_disable,
    'repo::enable'      => \&Slackware::SlackMan::Command::Repo::call_repo_enable,
    'repo::help'        => \&Slackware::SlackMan::Command::Repo::call_repo_help,
    'repo::info'        => \&Slackware::SlackMan::Command::Repo::call_repo_info,
    'repo::list'        => \&Slackware::SlackMan::Command::Repo::call_repo_list,

    'update'            => \&Slackware::SlackMan::Command::Update::call_update_metadata,
    'update::all'       => \&Slackware::SlackMan::Command::Update::call_update_all_metadata,
    'update::changelog' => \&Slackware::SlackMan::Command::Update::call_update_repo_changelog,
    'update::gpg-key'   => \&Slackware::SlackMan::Command::Update::call_update_repo_gpg_key,
    'update::help'      => \&Slackware::SlackMan::Command::Update::call_update_help,
    'update::history'   => \&Slackware::SlackMan::Command::Update::call_update_history,
    'update::manifest'  => \&Slackware::SlackMan::Command::Update::call_update_repo_manifest,
    'update::packages'  => \&Slackware::SlackMan::Command::Update::call_update_repo_packages,


  };

  my $dispatch_key = undef;

  if ($sub_command && exists($dispatch->{"$command::$sub_command"})) {
    $dispatch_key =  "$command::$sub_command";      # Command + Sub Command
    @arguments    = @arguments[ 1 .. $#arguments ]; # Shift 1st argument (aka sub_command)
  }

  if ($command && ! $dispatch_key && exists($dispatch->{"$command"})) {
    $dispatch_key = "$command";
  }

  if ($dispatch_key) {
    $dispatch->{$dispatch_key}->(@arguments);
  } else {
    print "slackman: '$command' is not a slackman command. See 'slackman help'\n\n";
    exit(1);
  }

  exit(0);

}


sub _show_version {
  print sprintf("SlackMan - Slackware Package Manager %s\n\n", $VERSION);
  exit(0);
}

sub _show_config {

  my %slackman_conf = get_conf();

  foreach my $section (sort keys %slackman_conf) {
    foreach my $parameter (sort keys %{$slackman_conf{$section}}) {
      my $value = $slackman_conf{$section}->{$parameter};
      print sprintf("%s=%s\n", "$section.$parameter", $value);
    }
  }

  exit(0);

}

sub _show_help {

  print "SlackMan - Slackware Package Manager $VERSION\n\n";

  pod2usage(
  -exitval  => 0,
  -verbose  => 99,
  -sections => 'SYNOPSIS|COMMANDS|OPTIONS',
  );

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
