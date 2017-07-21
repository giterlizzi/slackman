package Slackware::SlackMan::DBus;

use strict;
use warnings;

use 5.010;

our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {

  require Exporter;

  $VERSION   = 'v1.1.0_09';
  @ISA       = qw(Exporter);
  @EXPORT_OK = qw{};

}

use Slackware::SlackMan;
use Slackware::SlackMan::DB      qw(:all);
use Slackware::SlackMan::Package qw(:all);
use Slackware::SlackMan::Utils   qw(:all);

use Net::DBus::Exporter 'org.lotarproject.slackman';
use base qw(Net::DBus::Object);


dbus_method('ChangeLog',    [], [[ 'dict', 'string', [ 'array', [ 'dict', 'string', 'string' ] ]]]);
dbus_method('SecurityFix',  [], [[ 'dict', 'string', [ 'array', [ 'dict', 'string', 'string' ] ]]]);
dbus_method('CheckUpgrade', [], [[ 'dict', 'string', [ 'dict', 'string', 'string' ] ]]);


sub new {

  my $class   = shift;
  my $service = shift;

  my $self = $class->SUPER::new($service, '/org/lotarproject/slackman');

  bless $self, $class;

  return $self;

}

sub ChangeLog {

  my $self = shift;

  logger->debug('Call org.lotarproject.slackman.ChangeLog method');

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

  logger->debug('Call org.lotarproject.slackman.SecurityFix method');

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

sub CheckUpgrade {

  my $self = shift;

  logger->debug('Call org.lotarproject.slackman.CheckUpgrade method');

  # Re-Init DB Connection
  our $dbh = undef;
      $dbh = Slackware::SlackMan::DB::dbh();

  my ($update_pkgs, $install_pkgs) = package_check_updates();
  return $update_pkgs;

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

