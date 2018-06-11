package Slackware::SlackMan::DBus;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION   = 'v1.3.0';
  @ISA       = qw(Exporter);
  @EXPORT_OK = qw{};

}

use Slackware::SlackMan;
use Slackware::SlackMan::DB      qw(:all);
use Slackware::SlackMan::Package qw(:all);
use Slackware::SlackMan::Utils   qw(:all);
use Slackware::SlackMan::Repo    qw(:all);

use Net::DBus::Exporter 'org.lotarproject.SlackMan';
use base qw(Net::DBus::Object);

use constant DBUS_PATH      => '/org/lotarproject/SlackMan';
use constant DBUS_INTERFACE => 'org.lotarproject.SlackMan';

sub new {

  my $class   = shift;
  my $service = shift;

  my $self = $class->SUPER::new($service, DBUS_PATH);

  bless $self, $class;

  return $self;

}


dbus_no_strict_exports();

# Signals

# Signal with Installed/Removed/Upgraded packages
dbus_signal('PackageInstalled', [ 'string' ]);
dbus_signal('PackageRemoved',   [ 'string' ]);
dbus_signal('PackageUpgraded',  [ 'string' ]);

# Signal for "slackman update" command
dbus_signal('UpdatedChangeLog', [ 'string' ]);
dbus_signal('UpdatedPackages',  [ 'string' ]);
dbus_signal('UpdatedManifest',  [ 'string' ]);


# Properties

# Slackware and SlackMan version properties
dbus_property('version',   'string', 'read');
dbus_property('slackware', 'string', 'read');


# Methods

# ChangeLog methods
dbus_method('ChangeLog',   [ 'string' ], [[ 'dict', 'string', [ 'array', [ 'dict', 'string', 'string' ] ]]], { 'param_names' => [ 'repo_id' ] });
dbus_method('SecurityFix', [], [[ 'dict', 'string', [ 'array', [ 'dict', 'string', 'string' ] ]]]);
dbus_method('Announce',    [ 'string' ], [[ 'dict', 'string', [ 'array', [ 'dict', 'string', 'string' ] ]]], { 'param_names' => [ 'repo_id' ] });

# Package methods
dbus_method('PackageInfo',  [ 'string' ], [[ 'dict', 'string', 'string' ]], { 'param_names' => [ 'package_name' ] });
dbus_method('GetPackages',  [ 'string' ], [[ 'array', 'string' ]], { 'param_names' => [ 'filter' ] });
dbus_method('CheckUpgrade', [], [[ 'dict', 'string', [ 'dict', 'string', 'string' ] ]]);

# Repo methods
dbus_method('GetRepositories', [ 'string' ], [[ 'array', 'string' ]], { 'param_names' => [ 'type' ] });
dbus_method('GetRepository',   [ 'string' ], [[ 'dict', 'string', 'string' ]], { 'param_names' => [ 'repo_id' ] });

# PkgTools D-Bus methods
dbus_method('InstallPkg', [ 'string', 'caller' ], [ 'uint16' ], { 'param_names' => [ 'package_path' ] });
dbus_method('RemovePkg',  [ 'string', 'caller' ], [ 'uint16' ], { 'param_names' => [ 'package_name' ] });
dbus_method('UpgradePkg', [ 'string', 'caller' ], [ 'uint16' ], { 'param_names' => [ 'package_path' ] });

# SlackMan notification
dbus_method('Notify', [ 'string', 'string', 'string' ], [], { no_return => 1, param_names => [ 'action', 'summary', 'body' ] });


sub version {
  return $VERSION;
}


sub slackware {

  my $release = get_slackware_release();
     $release = $slackman_conf->{'slackware'}->{'version'} if (defined $slackman_conf->{'slackware'});

  return $release;

}


sub Notify {

  my ($self, $action, $summary, $body) = @_;

  logger->debug("Call org.lotarproject.SlackMan.Notify method (args: action=$action,summary=$summary,body=$body)");

  my $action_to_signal = {

    'PackageInstalled'  => 'PackageInstalled',
    'PackageRemoved'    => 'PackageRemoved',
    'PackageUpgraded'   => 'PackageUpgraded',

    'UpdatedChangeLog'  => 'UpdatedChangeLog',
    'UpdatedPackages'   => 'UpdatedPackages',
    'UpdatedManifest'   => 'UpdatedManifest',

  };

  if (defined($action_to_signal->{$action})) {
    logger->debug(sprintf("Emit signal org.lotarproject.Slackman.%s for %s action", $action_to_signal->{$action}, $action));
    $self->emit_signal($action_to_signal->{$action}, $body);
  } else {
    logger->error("Unknown action: $action");
  }

}


sub GetRepositories {

  my ($self, $type) = @_;

  logger->debug("Call org.lotarproject.SlackMan.GetRepositories method (args: type=$type)");

  my @repositories = ();

       if ($type eq 'enabled') {
    @repositories = get_enabled_repositories();
  } elsif ($type eq 'disabled') {
    @repositories = get_disabled_repositories();
  } else {
    @repositories = get_repositories();
  }

  return \@repositories;

}


sub GetRepository {

  my ($self, $repo_id) = @_;

  logger->debug("Call org.lotarproject.SlackMan.GetRepository method (args: repo_id=$repo_id)");

  my $repository = get_repository($repo_id);

  return $repository || {};

}


sub ChangeLog {

  my ($self, $repo_id) = @_;

  logger->debug("Call org.lotarproject.SlackMan.ChangeLog method (args: repo_id=$repo_id)");

  $slackman_opts = {};

  $slackman_opts->{'after'}  = '-7d';
  $slackman_opts->{'limits'} = 256;
  $slackman_opts->{'repo'}   = $repo_id if ($repo_id);

  _reload_data();

  my $changelogs = package_changelogs();
  my $result     = {};

  foreach (@{$changelogs}) {
    push( @{ $result->{ $_->{'repository'} } } , $_ );
  }

  return $result;

}


sub Announce {

  my ($self, $repo_id) = @_;

  logger->debug("Call org.lotarproject.SlackMan.Announce method (args: repo_id=$repo_id)");

  $slackman_opts = {};

  $slackman_opts->{'after'}  = '-7d';
  $slackman_opts->{'limits'} = 256;
  $slackman_opts->{'repo'}   = $repo_id if ($repo_id);

  _reload_data();

  my $changelogs = package_changelog_announces();
  my $result     = {};

  foreach (@{$changelogs}) {
    push( @{ $result->{ $_->{'repository'} } } , $_ );
  }

  return $result;

}


sub SecurityFix {

  my ($self) = @_;

  logger->debug('Call org.lotarproject.SlackMan.SecurityFix method');

  $slackman_opts = {};

  $slackman_opts->{'repo'}         = 'slackware';
  $slackman_opts->{'after'}        = '-7d';
  $slackman_opts->{'limits'}       = 256;
  $slackman_opts->{'security-fix'} = 1;

  _reload_data();

  my $changelogs = package_changelogs();

  my $security_fix = {};

  foreach (@{$changelogs}) {
    push( @{$security_fix->{$_->{'repository'}}} , $_ ) if ($_->{'security_fix'});
  }

  return $security_fix;

}


sub CheckUpgrade {

  my ($self) = @_;

  logger->debug('Call org.lotarproject.SlackMan.CheckUpgrade method');

  _reload_data();

  $slackman_opts = {};

  my ($update_pkgs, $install_pkgs) = package_check_updates();
  return $update_pkgs;

}


sub PackageInfo {

  my ($self, $package) = @_;

  logger->debug("Call org.lotarproject.SlackMan.PackageInfo method (args: package_name=$package)");

  return package_info($package);

}


sub GetPackages {

  my ($self, $filter) = @_;

  logger->debug("Call org.lotarproject.SlackMan.GetPackages method (args: filter=$filter)");

  my @results = ();

  if ($filter eq 'installed') {
    @results = sort keys %{ package_list_installed() };
  }

  if ($filter eq 'removed') {
    @results = sort keys %{ package_list_removed() };
  }

  if ($filter eq 'obsoletes') {
    @results = sort keys %{ package_list_obsoletes() };
  }

  if ($filter eq 'orphan') {
    @results = sort keys %{ package_list_orphan() };
  }

  return \@results;

}


sub InstallPkg {

  my ($self, $package, $caller) = @_;

  logger->debug("Call org.lotarproject.SlackMan.InstallPkg method (args: package_path=$package)");

  return (1)   unless ($package);
  return (255) unless (_polkit_check('InstallPkg', $caller));
  return (2)   unless (-f $package);

  package_install($package);

  $self->emit_signal('PackageInstalled', $package);

  return 0;

}


sub RemovePkg {

  my ($self, $package, $caller) = @_;

  logger->debug("Call org.lotarproject.SlackMan.RemovePkg method (args: package_name=$package)");

  return (1)   unless ($package);
  return (255) unless (_polkit_check('RemovePkg', $caller));

  package_remove($package);

  $self->emit_signal('PackageRemoved', $package);

  return 0;

}


sub UpgradePkg {

  my ($self, $package, $caller) = @_;

  logger->debug("Call org.lotarproject.SlackMan.UpgradePkg method (args: package_path=$package) from $caller caller");

  return (1)   unless ($package);
  return (255) unless (_polkit_check('UpgradePkg', $caller));
  return (2)   unless (-f $package);

  package_upgrade($package);

  $self->emit_signal('PackageUpgraded', $package);

  return 0;

}


sub _reload_data {

  # Re-Init DB Connection
  our $dbh = undef;
      $dbh = Slackware::SlackMan::DB::dbh();

  # Reload repositories data
  load_repositories();

}


sub _polkit_check {

  my ($action, $caller) = @_;

  my $action_id        = DBUS_INTERFACE . ".$action";
  my $system_bus       = Net::DBus->system;
  my @subject          = ( 'system-bus-name', { 'name' => $caller } );
  my $details          = {};
  my $flags            = 1;   # AllowUserInteraction flag
  my $cancellation_id  = '';  # No cancellation id

  my $polkit_authority = $system_bus->get_service ( 'org.freedesktop.PolicyKit1' )
                                    ->get_object  ( '/org/freedesktop/PolicyKit1/Authority',
                                                    'org.freedesktop.PolicyKit1.Authority' );

  logger->debug("[PolicyKit] Checking Authorization for $action_id action from $caller caller");

  my $result = $polkit_authority->CheckAuthorization(\@subject, $action_id, $details, $flags, $cancellation_id);

  my $is_authorized = $result->[0];

  logger->warning("[PolicyKit] Check Authorization failed for $action_id action from $caller caller") unless ($is_authorized);

  return $is_authorized;

}

1;
__END__

=head1 NAME

Slackware::SlackMan::DBus - SlackMan DBus module

=head1 SYNOPSIS

  use Slackware::SlackMan::DBus;

=head1 DESCRIPTION

D-Bus interface module for SlackMan.

=head1 EXPORT

No subs are exported by default.

=head1 SUBROUTINES

=head1 AUTHOR

Giuseppe Di Terlizzi, C<< <giuseppe.diterlizzi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<giuseppe.diterlizzi at gmail.com>, or through
the web interface at L<https://github.com/LotarProject/slackman/issues>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

  perldoc Slackware::SlackMan::DBus

You can also look for information at:

=over 4

=item * GitHub issues (report bugs here)

L<https://github.com/LotarProject/slackman/issues>

=item * SlackMan documentation

L<https://github.com/LotarProject/slackman/wiki>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2018 Giuseppe Di Terlizzi.

This module is free software, you may distribute it under the same terms
as Perl.

=cut

