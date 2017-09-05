package Slackware::SlackMan::DBus;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION   = 'v1.1.2';
  @ISA       = qw(Exporter);
  @EXPORT_OK = qw{};

}

use Slackware::SlackMan;
use Slackware::SlackMan::DB      qw(:all);
use Slackware::SlackMan::Package qw(:all);
use Slackware::SlackMan::Utils   qw(:all);

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

dbus_signal('PackageInstalled', [ 'string' ]);
dbus_signal('PackageRemoved',   [ 'string' ]);
dbus_signal('PackageUpgraded',  [ 'string' ]);

dbus_property('version', 'string', 'read');

dbus_method('ChangeLog',    [ 'string' ], [[ 'dict', 'string', [ 'array', [ 'dict', 'string', 'string' ] ]]], { 'param_names' => [ 'repo_id' ] });
dbus_method('SecurityFix',  [], [[ 'dict', 'string', [ 'array', [ 'dict', 'string', 'string' ] ]]]);
dbus_method('CheckUpgrade', [], [[ 'dict', 'string', [ 'dict', 'string', 'string' ] ]]);
dbus_method('PackageInfo',  [ 'string' ], [[ 'dict', 'string', 'string' ]], { 'param_names' => [ 'package_name' ] });

# PkgTools D-Bus methods
dbus_method('InstallPkg',   [ 'string', 'caller' ], [ 'uint16' ], { 'param_names' => [ 'package_path' ] });
dbus_method('RemovePkg',    [ 'string', 'caller' ], [ 'uint16' ], { 'param_names' => [ 'package_name' ] });
dbus_method('UpgradePkg',   [ 'string', 'caller' ], [ 'uint16' ], { 'param_names' => [ 'package_path' ] });


sub version {
  return $VERSION;
}

sub ChangeLog {

  my $self = shift;
  my ($repo_id) = @_;

  logger->debug("Call org.lotarproject.SlackMan.ChangeLog method (args: repo_id=$repo_id)");

  $slackman_opts = {};

  $slackman_opts->{'after'}  = '-7 days';
  $slackman_opts->{'limits'} = 256;
  $slackman_opts->{'repo'}   = $repo_id if ($repo_id);

  # Re-Init DB Connection
  our $dbh = undef;
      $dbh = Slackware::SlackMan::DB::dbh();

  my $changelogs = package_changelogs();
  my $result     = {};

  foreach (@{$changelogs}) {
    push( @{ $result->{ $_->{'repository'} } } , $_ );
  }

  return $result;

}


sub SecurityFix {

  my $self = shift;

  logger->debug('Call org.lotarproject.SlackMan.SecurityFix method');

  $slackman_opts = {};

  $slackman_opts->{'repo'}         = 'slackware';
  $slackman_opts->{'after'}        = '-7 days';
  $slackman_opts->{'limits'}       = 256;
  $slackman_opts->{'security-fix'} = 1;

  # Re-Init DB Connection
  our $dbh = undef;
      $dbh = Slackware::SlackMan::DB::dbh();

  my $changelogs = package_changelogs();

  my $security_fix = {};

  foreach (@{$changelogs}) {
    push( @{$security_fix->{$_->{'repository'}}} , $_ ) if ($_->{'security_fix'});
  }

  return $security_fix;

}


sub CheckUpgrade {

  my $self = shift;

  logger->debug('Call org.lotarproject.SlackMan.CheckUpgrade method');

  # Re-Init DB Connection
  our $dbh = undef;
      $dbh = Slackware::SlackMan::DB::dbh();

  $slackman_opts = {};

  my ($update_pkgs, $install_pkgs) = package_check_updates();
  return $update_pkgs;

}


sub PackageInfo {

  my $self = shift;
  my ($package) = @_;

  logger->debug("Call org.lotarproject.SlackMan.PackageInfo method (args: package_name=$package)");

  return package_info($package);

}


sub InstallPkg {

  my $self = shift;
  my ($package, $caller) = @_;

  logger->debug("Call org.lotarproject.SlackMan.InstallPkg method (args: package_path=$package)");

  return (1)   unless ($package);
  return (255) unless (_polkit_check('InstallPkg', $caller));
  return (2)   unless (-f $package);

  package_install($package);

  $self->emit_signal('PackageInstalled', $package);

  return 0;

}


sub RemovePkg {

  my $self = shift;
  my ($package, $caller) = @_;

  logger->debug("Call org.lotarproject.SlackMan.RemovePkg method (args: package_name=$package)");

  return (1)   unless ($package);
  return (255) unless (_polkit_check('RemovePkg', $caller));

  package_remove($package);

  $self->emit_signal('PackageRemoved', $package);

  return 0;

}


sub UpgradePkg {

  my $self = shift;
  my ($package, $caller) = @_;

  logger->debug("Call org.lotarproject.SlackMan.UpgradePkg method (args: package_path=$package) from $caller caller");

  return (1)   unless ($package);
  return (255) unless (_polkit_check('UpgradePkg', $caller));
  return (2)   unless (-f $package);

  package_upgrade($package);

  $self->emit_signal('PackageUpgraded', $package);

  return 0;

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

Copyright 2016-2017 Giuseppe Di Terlizzi.

This module is free software, you may distribute it under the same terms
as Perl.

=cut

