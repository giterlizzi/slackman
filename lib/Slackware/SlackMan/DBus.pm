package Slackware::SlackMan::DBus;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION   = 'v1.1.1';
  @ISA       = qw(Exporter);
  @EXPORT_OK = qw{};

}

use Slackware::SlackMan;
use Slackware::SlackMan::DB      qw(:all);
use Slackware::SlackMan::Package qw(:all);
use Slackware::SlackMan::Utils   qw(:all);

use Net::DBus::Exporter 'org.lotarproject.SlackMan';
use base qw(Net::DBus::Object);


sub new {

  my $class   = shift;
  my $service = shift;

  my $self = $class->SUPER::new($service, '/org/lotarproject/SlackMan');

  bless $self, $class;

  return $self;

}


dbus_method('ChangeLog', [], [[ 'dict', 'string', [ 'array', [ 'dict', 'string', 'string' ] ]]]);

sub ChangeLog {

  my $self = shift;

  logger->debug('Call org.lotarproject.SlackMan.ChangeLog method');

  $slackman_opts = {};

  $slackman_opts->{'after'}  = '-7 days';
  $slackman_opts->{'limits'} = 100;

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


dbus_method('SecurityFix', [], [[ 'dict', 'string', [ 'array', [ 'dict', 'string', 'string' ] ]]]);

sub SecurityFix {

  my $self = shift;

  logger->debug('Call org.lotarproject.SlackMan.SecurityFix method');

  $slackman_opts = {};

  $slackman_opts->{'repo'}         = 'slackware';
  $slackman_opts->{'after'}        = '-7 days';
  $slackman_opts->{'limits'}       = 1000;
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


dbus_method('CheckUpgrade', [], [[ 'dict', 'string', [ 'dict', 'string', 'string' ] ]]);

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


dbus_method('PackageInfo',  [ 'string' ], [[ 'dict', 'string', 'string' ]]);

sub PackageInfo {

  my $self = shift;
  my ($package) = @_;

  logger->debug("Call org.lotarproject.SlackMan.PackageInfo method (arg=$package)");

  return package_info($package);

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

